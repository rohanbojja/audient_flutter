import 'package:audientflutter/models/Genre.dart';
import 'package:audientflutter/models/GenreList.dart';
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

import 'package:path_provider/path_provider.dart';
class accuraciesPage extends StatefulWidget {
  @override
  _accuraciesPageState createState() => _accuraciesPageState();
}
AudioPlayer audioPlayer = AudioPlayer();
List<Genre> displayList =List<Genre>();
Genre predictedGenre = Genre("init","0");
void modifDL(int index){


}

class _accuraciesPageState extends State<accuraciesPage> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    custInit();
  }

  void custInit(){
    displayList = globalObjects.glList[0];
    globalObjects.glList[globalObjects.glList.length-1].forEach((Genre genre){
      if(double.parse(genre.accuracy)>double.parse(predictedGenre.accuracy)){
        predictedGenre = genre;
      }
    });
    audioPlayer.onAudioPositionChanged.listen((Duration  p){
      print('Current position: $p $position');
      if(position?.inSeconds!=p.inSeconds) {
        print("Blues: ${globalObjects.glList[p?.inSeconds][0].accuracy} ${position?.inSeconds}");
        position = p;
        globalObjects.glList[position?.inSeconds].sort((a,b) => b.accuracy.compareTo(a.accuracy));
        displayList = globalObjects.glList[position?.inSeconds];
        setState(() {

        });
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
    isPlaying = true;
    int result = await audioPlayer.play(globalObjects.path+".wav", isLocal: true);
  }
  Duration duration, position;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Analysis: ${position}"),
      ),
        body: Column(
          children: <Widget>[
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
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
                              "file": await MultipartFile.fromFile(globalObjects.path+".wav",filename: "jam.wav")
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
                              LinearProgressIndicator(value: double.parse(displayList[index].accuracy), backgroundColor: Colors.orangeAccent,),
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

