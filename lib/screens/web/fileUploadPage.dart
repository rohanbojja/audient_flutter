//import 'package:audioplayers/audioplayers.dart';
//import 'package:dio/dio.dart';
//import 'package:flutter/material.dart';
//import 'dart:async';
//import 'dart:convert';
//import 'dart:io' as io;
//import 'dart:typed_data';
//import 'package:flutter/material.dart';
//import 'dart:html' as html;
//import 'dart:typed_data';
//import 'dart:convert';
//import 'package:http_parser/http_parser.dart';
//import 'package:path_provider/path_provider.dart';
//
//List<int> imageFileBytes;
//
//class FileUploadPage extends StatefulWidget {
//  @override
//  _FileUploadPageState createState() => _FileUploadPageState();
//}
//
//startWebFilePicker() async {
//  InputElement uploadInput = FileUploadInputElement();
//  uploadInput.click();
//
//  uploadInput.onChange.listen((e) {
//    // read file content as dataURL
//    final files = uploadInput.files;
//    if (files.length == 1) {
//      final file = files[0];
//      final reader = new FileReader();
//      reader.onLoadEnd.listen((e) {
//        var _bytesData = Base64Decoder().convert(reader.result.toString().split(",").last);
//        imageFileBytes = _bytesData;
//        _handleResult(imageFileBytes);
//      });
//      reader.readAsDataUrl(file);
//    }
//  });
//}
//
//Future<void> _handleResult(Object result) async {
//  var dio = Dio();
//  dio.options.baseUrl = "https://audient.azurewebsites.net";
//
//  AudioPlayer player = AudioPlayer();
//  final dir = await getApplicationDocumentsDirectory();
//  //final file = File('${dir.path}/audio.mp3');
//
////  await file.writeAsBytes(bytes);
////  if (await file.exists()) {
////  setState(() {
////  localFilePath = file.path;
////  });
////  }
//  player.play(result);
//
////  FormData formData = FormData.fromMap({
////    "name": "file",
////    "dur" : _recording.duration.inSeconds,
////    "file": await MultipartFile.fromFile(_recording.path,filename: "jam.wav")
////  });
////  //record and stuff here
////  var response = await dio.post("/getPredictions", data: formData);
////  var tmp = response.data;
////  print("THIS IS IT-> ${tmp}");
////  globalObjects.glList = List<List<Genre>>();
////  int curind=0;
////
////  bool generateColors = true;
////  var colorMap = Map();
////  tmp.forEach((i){
////    var tmpList = List<Genre>();
////    print("Current index==0$curind");
////    curind+=1;
////    i.forEach((k,v){
////      print("KEV VAL PAIRS $k $v");
////      if(generateColors){
////        var randColor = _randomColor.randomColor( colorHue: ColorHue.multiple(colorHues: [ColorHue.purple,ColorHue.red]));
////        tmpList.add(Genre(k,double.parse(v), segmentColor: randColor));
////        colorMap[k] = randColor;
////      }else{
////        var randColor = colorMap[k];
////        tmpList.add(Genre(k,double.parse(v), segmentColor: randColor));
////      }
////    });
////    generateColors = false;
////    globalObjects.glList.add(tmpList);
////  });
////  duration = Duration(seconds: 0);
////  Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => new accuraciesPage()));
//}
//class _FileUploadPageState extends State<FileUploadPage> {
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(),
//      body: Center(
//        child: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            RaisedButton(
//              onPressed: startWebFilePicker,
//              child: Text("Select a file"),
//            )
//          ],
//        )
//      ),
//    );
//  }
//}
