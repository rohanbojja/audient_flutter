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

class _accuraciesPageState extends State<accuraciesPage> {
  AudioPlayer audioPlayer = AudioPlayer();
  List<Genre> displayList =List<Genre>();
  List<Genre> aggList =List<Genre>();
  Genre predictedGenre = Genre("...",0);

  Random random = new Random();
  List<charts.Series<Genre,String>> _seriesGenreData;
  List<charts.Series<Genre,String>> _seriesGenreDataAgg;
  var tot =0.0;
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

  _generateDataAgg(List<Genre> displayList){
    var genreData = displayList;
    _seriesGenreDataAgg.add(
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
  void dispose(){
    audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    custInit();
  }
  Future <void> custInit() async{
    displayList =List<Genre>();
    aggList =List<Genre>();
    predictedGenre = Genre("...",0);
    aggList =List<Genre>();
    displayList = globalObjects.glList[0];
    aggList = globalObjects.glList[0];
    _seriesGenreData = List<charts.Series<Genre,String>>();
    _seriesGenreDataAgg = List<charts.Series<Genre,String>>();
    _generateData(displayList);
    _generateDataAgg(aggList);
    audioPlayer.onAudioPositionChanged.listen((Duration  p){
      if(position?.inSeconds!=p.inSeconds) {
        position = p;
//Get 5-sec sample predictions
        int posi = ((position?.inSeconds!=0 && position!=null)? position.inSeconds/5: 0).toInt();
        if(posi<=globalObjects.glList.length){
          displayList = globalObjects.glList[posi];
          _seriesGenreData = List<charts.Series<Genre,String>>();
          _seriesGenreDataAgg = List<charts.Series<Genre,String>>();
          var ind_agg=0;
          tot=0;
          for(var j=0;j<displayList.length;j++){
            print("gen1: ${displayList[ind_agg].label} gen2: ${aggList[ind_agg].label}");
            displayList[ind_agg].accuracy += random.nextDouble()/10;
            aggList[ind_agg].accuracy += displayList[ind_agg].accuracy;
            tot += aggList[ind_agg].accuracy;
            ind_agg+=1;
          }
          aggList.forEach((element) {
            //element.accuracy = element.accuracy/tot;
            predictedGenre??=element;
            print("${predictedGenre.accuracy} and ${element.accuracy}");
            if(predictedGenre.accuracy<element.accuracy){
              predictedGenre=element;
            }
          });
          _generateData(displayList);
          _generateDataAgg(aggList);
          setState(() {

          });
//          globalObjects.glList[posi].sort((a,b) => b.accuracy.compareTo(a.accuracy));

        }else{
          _seriesGenreDataAgg = List<charts.Series<Genre,String>>();
          aggList.forEach((element) {
            element.accuracy = element.accuracy/tot;
          });
          _generateDataAgg(aggList);
          setState(() {

          });
        }
      }
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
    await custInit();
    isPlaying = true;
    int result = await audioPlayer.play(globalObjects.path, isLocal: true);
  }
  Duration duration, position;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("${predictedGenre.label}-> ${predictedGenre.accuracy/tot*100}"),
      ),
        body: Column(
          children: <Widget>[
            Card(
              color: Colors.black,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(width: 400, height: 250, child: charts.PieChart(
                      _seriesGenreData,
                      animationDuration: Duration(milliseconds: 400),
                      animate: true,
                    ),
                    ),


                    Divider(height: 32,),
                    Text(predictedGenre.label
                      ,style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Container(width: 400, height: 300, child: charts.BarChart(
                  _seriesGenreDataAgg,
                  animationDuration: Duration(milliseconds: 400),
                  animate: true,
                  primaryMeasureAxis:
                  new charts.NumericAxisSpec(renderSpec: new charts.NoneRenderSpec()),
                  domainAxis: charts.OrdinalAxisSpec(
                    renderSpec: charts.SmallTickRendererSpec(labelRotation: 60),
                  ),
                  behaviors: [
                    charts.DatumLegend(desiredMaxRows: 3, outsideJustification: charts.OutsideJustification.endDrawArea, cellPadding: EdgeInsets.all(16), horizontalFirst: false,entryTextStyle: charts.TextStyleSpec(
                        color: charts.Color(r: 255, g: 255, b: 255),
                        fontSize: 11),
                    ),
                  ]
              ),
              ),
            ),
//            Expanded(
//              child: Padding(
//                padding: EdgeInsets.symmetric(horizontal: 16),
//                child: ListView.builder(
//                    shrinkWrap: true,
//                    scrollDirection: Axis.vertical,
//                    itemCount: displayList.length,
//                    itemBuilder: (context,index){
//                      return InkWell(
//                          child: Column(
//                            children: <Widget>[
//                              ListTile(title: Text("${displayList[index].label} ${displayList[index].accuracy}",style: TextStyle(fontSize: 8),)
//                              ),
//                              LinearProgressIndicator(value: displayList[index].accuracy, backgroundColor: Colors.grey,),
//                            ],
//                          ));
//                    }),
//              )
//            )
          ],
        ),
      floatingActionButton:
      ButtonBar(
        children: <Widget>[
          OutlineButton(
            child: Text("Wrong? Help fix it!"),
            onPressed: () async {
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
                                          .setData({DateTime.now().millisecondsSinceEpoch.toString()+"_${displayList[index].label}_${displayList[index].accuracy}": "${aggList.toString()}"},merge: true).then((onValue){
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
    );
  }
}

