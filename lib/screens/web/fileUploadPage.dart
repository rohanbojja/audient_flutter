//import 'dart:convert';
//import 'dart:html';
//import 'dart:typed_data';
//import 'package:dio/dio.dart';
//import 'package:file_picker_web/file_picker_web.dart';
//import 'package:flutter/material.dart';
//import 'package:http/http.dart' as http;
//import 'dart:html' as html;
//import '../../models/Genre.dart';
//import '../../services/global.dart';
//
//List<int> imageFileBytes;
//
//class FileUploadPage extends StatefulWidget {
//  @override
//  _FileUploadPageState createState() => _FileUploadPageState();
//}
//
//
//class _FileUploadPageState extends State<FileUploadPage> {
//  List<int> _selectedFile;
//  Uint8List _bytesData;
//  void _handleResult(Object result)async {
//    setState(() {
//      _bytesData = Base64Decoder().convert(result.toString().split(",").last);
//      _selectedFile = _bytesData;
//      print("SEL :${_selectedFile.length}");
//    });
//  }
//
//  Future <void> getGenreList() async {
//    var dio = Dio();
//    dio.options.baseUrl = "https://audient.azurewebsites.net";
//    var thefile = await MultipartFile.fromBytes(_selectedFile,filename: "jam.wav");
//    print("${thefile.filename}, LOL");
//    FormData formData = FormData.fromMap({
//      "name": "file",
//      "dur" : 30,
//      "file": thefile
//    });
//    print("GELLOW");
//    //record and stuff
//
//    var url = Uri.parse(
//        "https://audient.azurewebsites.net/getPredictions");
//    var request = new http.MultipartRequest("POST", url)..fields["name"]="file"..fields["dur"]="30";
//    request.files.add(await http.MultipartFile.fromBytes('file', _selectedFile,
//        filename: "jam.wav"));
//
//    request.send().then((response) {
//      print("test");
//      print(response.statusCode);
//      if (response.statusCode == 200) print("Uploaded!");
//    });
//
//
////    var response = await dio.post("/getPredictions", data: formData);
////    var tmp = response.data;
////    print("THIS IS IT-> ${tmp}");
////    globalObjects.glList = List<List<Genre>>();
////    int curind=0;
////
////    bool generateColors = true;
////    var colorMap = Map();
////    tmp.forEach((i){
////      var tmpList = List<Genre>();
////      print("Current index==0$curind");
////      curind+=1;
////      i.forEach((k,v){
////        print("KEV VAL PAIRS $k $v");
////        if(generateColors){
////          var randColor = _randomColor.randomColor( colorHue: ColorHue.multiple(colorHues: [ColorHue.purple,ColorHue.red]));
////          tmpList.add(Genre(k,double.parse(v), segmentColor: randColor));
////          colorMap[k] = randColor;
////        }else{
////          var randColor = colorMap[k];
////          tmpList.add(Genre(k,double.parse(v), segmentColor: randColor));
////        }
////      });
////      generateColors = false;
////      globalObjects.glList.add(tmpList);
////    });
////    duration = Duration(seconds: 0);
////    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => new accuraciesPage()));
////    params_progress_button = "record";
////    setState(() {
////
////    });
//  }
//
//  final reader  = new html.FileReader();
//  File file;
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      appBar: AppBar(),
//      body: Center(
//        child: Column(
//          mainAxisAlignment: MainAxisAlignment.center,
//          children: <Widget>[
//            OutlineButton(
//              child: Text("TEST HTTP"),
//              onPressed: () async {
//
//
//                try {
//                  Response response = await Dio().get("http://www.google.com");
//                  print(response);
//                } catch (e) {
//                  print(e);
//                }
//              },
//            ),
//            RaisedButton(
//              onPressed: () async {
//                file = await FilePicker.getFile();
//                reader.onLoadEnd.listen((e) async {
//                  print("Handling result");
//                  await _handleResult(reader.result);
//                  getGenreList();
//                });
//                reader.readAsDataUrl(file);
//              },
//              child: Text("Select a file"),
//            )
//          ],
//        )
//      ),
//    );
//  }
//}
