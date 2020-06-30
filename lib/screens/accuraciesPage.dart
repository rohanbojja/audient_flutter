import 'package:audientflutter/components/pieChart.dart';
import 'package:audientflutter/models/Genre.dart';
import 'package:audientflutter/services/auth.dart';
import 'package:audientflutter/services/global.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' as io;
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
class accuraciesPage extends StatefulWidget {
  @override
  _accuraciesPageState createState() => _accuraciesPageState();
}
AudioPlayer audioPlayer = AudioPlayer();
List<Genre> displayList =List<Genre>();
Genre predictedGenre = Genre("init",0);

class _accuraciesPageState extends State<accuraciesPage> {
  Random random = new Random();
  List<charts.Series<Genre,String>> _seriesGenreData;

  _generateData(List<Genre> displayList){
    var genreData = displayList;
    _seriesGenreData.add(
      charts.Series(
        data: genreData,
        domainFn: (Genre genre,_) => genre.label,
        measureFn: (Genre genre,_) => genre.accuracy,
        colorFn: (Genre genre, _) => charts.ColorUtil.fromDartColor(genre.segmentColor),
        labelAccessorFn: (Genre genre,_) => "${genre.label}"
      )
    );
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    custInit();
  }

  void custInit(){
    displayList = globalObjects.glList[0];
    _seriesGenreData = List<charts.Series<Genre,String>>();
    _generateData(displayList);

    globalObjects.glList[globalObjects.glList.length-1].forEach((Genre genre){
      if(genre.accuracy>predictedGenre.accuracy){
        setState(() {
          predictedGenre = genre;
        });
      }
    });
    audioPlayer.onAudioPositionChanged.listen((Duration  p){
      if(position?.inSeconds!=p.inSeconds) {
        position = p;
//Get 5-sec sample predictions
        int posi = ((position?.inSeconds!=0 && position!=null)? position.inSeconds/5: 0).toInt();
        if(posi<=globalObjects.glList.length){
          print('CPOS: $p $posi');
          displayList = globalObjects.glList[posi];
          print('CPOS: $p $posi ${displayList[0].label} ${displayList[0].accuracy}');
          _seriesGenreData = List<charts.Series<Genre,String>>();
          displayList.forEach((element) {
            element.accuracy += random.nextDouble()/10;
          });
          _generateData(displayList);
          globalObjects.glList[posi].sort((a,b) => b.accuracy.compareTo(a.accuracy));

        }
      }
      setState(() {

      });
    });
  }

  void showLoader(){
    showDialog(context: context, builder: (BuildContext context){
      return SpinKitPouringHourglass(
        color: Colors.white,
        size: 50.0,
      );
    });
  }
  pauseLocal() async{
    if(isPlaying){
      await audioPlayer.pause();
      isPlaying = false;
    }else{
      isPlaying = true;
      await audioPlayer.resume();
    }
  }
  bool isPlaying = false;
  playLocal() async {
    isPlaying = true;
    int result = await audioPlayer.play(globalObjects.path, isLocal: true);
  }
  Duration duration, position;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis: ${displayList[0].accuracy?? 0}"),
      ),
        body: Column(
          children: <Widget>[
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(width: 400, height: 250, child: charts.PieChart(
                    _seriesGenreData,
                        animationDuration: Duration(milliseconds: 400),
                        animate: true,
                        behaviors: [
                      charts.DatumLegend(desiredMaxRows: 3, outsideJustification: charts.OutsideJustification.endDrawArea, cellPadding: EdgeInsets.all(16), horizontalFirst: true),
                    ]
                    ),
                    ),
                    ButtonBar(
                      children: <Widget>[
                        OutlineButton(
                          child: Text("Wrong? Help fix it!"),
                          onPressed: () async {
                            showLoader();
                            //Logic here to correct the prediciton and store to Firebase
                            var dio = Dio();
                            dio.options.baseUrl = "https://audient.herokuapp.com";
                            FormData formData = FormData.fromMap({
                              "name": "file",
                              "file": await MultipartFile.fromFile(globalObjects.path,filename: "jam.wav")
                            });
                            var response = await dio.post("/receiveWav", data: formData);
                            String featureString = response.data.toString().substring(2,response.data.toString().length-2);
                            print("${response.statusCode} ${response.data.toString().substring(2,response.data.toString().length-2)}");
                            Navigator.pop(context);
                            showDialog(context: context, builder: (BuildContext context){
                              return AlertDialog(
                                  content: Container(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: <Widget>[
                                        Text("What do you think the genre is?"),
                                        Container(
                                          width: 300,
                                          height: 400,
                                          child: ListView.builder(
                                              itemCount: displayList.length,
                                              itemBuilder: (BuildContext context, index) {

                                                return OutlineButton(
                                                  child: Text("${displayList[index].label}"),
                                                  onPressed: () async {
                                                    showLoader();
                                                    FirebaseUser user = await authService.currentUser();
                                                    //Post feature string to firestore
                                                    Firestore.instance.collection('users').document(user.uid)
                                                        .setData({DateTime.now().millisecondsSinceEpoch.toString()+"_${displayList[index].label}_${displayList[index].accuracy}": "$featureString}"},merge: true).then((onValue){
                                                      print("DONE!");
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                      showDialog(context: context, builder: (BuildContext context){
                                                        return AlertDialog(
                                                            content: Container(
                                                              height: 200,
                                                              width: 200,
                                                              child: Column(
                                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                                children: <Widget>[
                                                                  Padding(
                                                                    padding: EdgeInsets.symmetric(vertical: 8),
                                                                    child: Text("Thanks for helping out!", style: TextStyle(fontWeight: FontWeight.bold),),
                                                                  ),
                                                                  IconButton(
                                                                    onPressed: (){
                                                                      Navigator.pop(context);
                                                                    },
                                                                    icon: Icon(Icons.arrow_back,size: 32,),
                                                                  )
                                                                ],
                                                              ),
                                                            )
                                                        );
                                                      });
                                                    });
                                                  },
                                                );
                                              }),
                                        ),
                                        IconButton(
                                          onPressed: (){
                                            Navigator.pop(context);
                                          },
                                          icon: Icon(Icons.arrow_back,size: 32,),
                                        )],
                                    ),
                                  )
                              );
                            });

                          },
                        ),
                        RaisedButton(child: Text("Play"), onPressed: playLocal,),
                        RaisedButton(child: Text("Pause"), onPressed: pauseLocal,)
                      ],
                    ),
                    Divider(height: 32,),
                    Text(predictedGenre.label
                      ,style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                    shrinkWrap: true,
                    scrollDirection: Axis.vertical,
                    itemCount: displayList.length,
                    itemBuilder: (context,index){
                      return InkWell(
                          child: Column(
                            children: <Widget>[
                              ListTile(title: Text("${displayList[index].label} ${displayList[index].accuracy}",style: TextStyle(fontSize: 8),)
                              ),
                              LinearProgressIndicator(value: displayList[index].accuracy, backgroundColor: Colors.grey,),
                            ],
                          ));
                    }),
              )
            )
          ],
        )
    );
  }
}

