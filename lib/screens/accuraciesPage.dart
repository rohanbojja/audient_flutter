import 'package:audientflutter/models/GenreList.dart';
import 'package:audientflutter/services/auth.dart';
import 'package:audientflutter/services/global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'dart:io' as io;

import 'package:path_provider/path_provider.dart';
class accuraciesPage extends StatefulWidget {
  @override
  _accuraciesPageState createState() => _accuraciesPageState();
}

class _accuraciesPageState extends State<accuraciesPage> {

  void showLoader(){
    showDialog(context: context, builder: (BuildContext context){
      return SpinKitPouringHourglass(
        color: Colors.white,
        size: 50.0,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    GenreList genreList = ModalRoute.of(context).settings.arguments;
    print("DBG-> ${genreList.accuracies[0].label}");
    return Scaffold(
      appBar: AppBar(),
        body: Column(
          children: <Widget>[
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: OutlineButton(
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
                                          itemCount: genreList.accuracies.length,
                                          itemBuilder: (BuildContext context, index) {

                                            return OutlineButton(
                                              child: Text("${genreList.accuracies[index].label}"),
                                              onPressed: () async {
                                                showLoader();
                                                FirebaseUser user = await authService.currentUser();
                                                //Post feature string to firestore
                                                Firestore.instance.collection('users').document(user.uid)
                                                    .setData({DateTime.now().millisecondsSinceEpoch.toString()+"_${genreList.accuracies[index].label}_${genreList.accuracies[index].accuracy}": "$featureString}"},merge: true).then((onValue){
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
                    ),
                    Container(
                      child: CircularProgressIndicator(value: genreList.confidence, strokeWidth: 8,),
                      width: 100,
                      height: 100,
                    ),
                    Divider(height: 32,),
                    Text(genreList.predictedLabel
                      ,style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),),
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
                    itemCount: genreList.accuracies.length,
                    itemBuilder: (context,index){
                      return Card(
                          child: Column(
                            children: <Widget>[
                              ListTile(title: Text("${genreList.accuracies[index].label}")
                              ),
                              LinearProgressIndicator(value: double.parse(genreList.accuracies[index].accuracy), backgroundColor: Colors.orangeAccent,),
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

