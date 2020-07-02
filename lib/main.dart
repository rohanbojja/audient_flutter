import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';
import 'package:audientflutter/screens/loginPage.dart';
import 'package:audientflutter/services/auth.dart';
import 'package:audientflutter/services/global.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:audientflutter/models/Genre.dart';
import 'package:audientflutter/screens/accuraciesPage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:like_button/like_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
import 'package:random_color/random_color.dart';

import 'components/progressButton.dart';

void main() => runApp(MyApp());

var myTheme = ThemeData(
  // This is the theme of your application.
  //
  // Try running your application with "flutter run". You'll see the
  // application has a blue toolbar. Then, without quitting the app, try
  // changing the primarySwatch below to Colors.green and then invoke
  // "hot reload" (press "r" in the console where you ran "flutter run",
  // or simply save your changes to "hot reload" in a Flutter IDE).
  // Notice that the counter didn't reset back to zero; the application
  // is not restarted.
  brightness: Brightness.light,
  fontFamily: 'Montserrat',
  accentColor: Colors.orange,
  primaryColor: Colors.black,
  primarySwatch: Colors.green,
  cursorColor: Colors.orange,
);

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: myTheme,
      home: loginPage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{

  bool recOrFile = false;

  String params_progress_button = "record";
  int _counter = 0;
  FirebaseUser user;
  RandomColor _randomColor = RandomColor();
  Duration lengthofRec;
  AudioPlayer player = AudioPlayer();

  double avgPower;
  Duration duration = Duration(seconds: 0);


  final List<Tab> myTabs = <Tab>[
    Tab(text: 'Home'),
    Tab(text: 'Accuracies'),
  ];
  bool isRecording = false;
  AnimationController _animationController;
  var recorder;
  var recording;
  Recording _recording;
  double _power=0;
  Timer _t;
  List<List<Genre>> genreList;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCust();
    isRecording = true;
  }

  Future<void> initCust() async {
    _animationController = AnimationController(vsync: this,duration: Duration(seconds: 1));
    bool hasPermission = await FlutterAudioRecorder.hasPermissions;
    user = await authService.currentUser();
    print("DBGauto OHME");
    player.onDurationChanged.listen((Duration d) {
      print('Max duration: $d');
      print("Duration of the recording: $d seconds?");
      lengthofRec = d;
    });

    //Setup auth change listener
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      showLoader();
      if (user == null) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) => new loginPage()));
      }
      else{
        setState(() {

        });
      }
      Navigator.pop(context);
    });
  }

  Future <void> getGenreList(String filePath, int durInSeconds) async {
    var dio = Dio();
    print("$filePath /// ${globalObjects.path}");
    globalObjects.path = filePath;
    dio.options.baseUrl = "https://audient.azurewebsites.net";
    FormData formData = FormData.fromMap({
      "name": "file",
      "label_code": 0,
      "dur" : durInSeconds,
      "file": await MultipartFile.fromFile(filePath ,filename: "jam.wav")
    });
    //record and stuff here
    var response = await dio.post("/getPredictions", data: formData);
    var tmp = response.data;
    print("THIS IS IT-> ${tmp}");
    globalObjects.glList = List<List<Genre>>();
    int curind=0;

    bool generateColors = true;
    var colorMap = Map();
    tmp.forEach((i){
      var tmpList = List<Genre>();
      print("Current index==0$curind");
      curind+=1;
      i.forEach((k,v){
        print("KEV VAL PAIRS $k $v");
        if(generateColors){
          var randColor = _randomColor.randomColor( colorHue: ColorHue.multiple(colorHues: [ColorHue.purple,ColorHue.red]));
          tmpList.add(Genre(k,double.parse(v), segmentColor: randColor));
          colorMap[k] = randColor;
        }else{
          var randColor = colorMap[k];
          tmpList.add(Genre(k,double.parse(v), segmentColor: randColor));
        }
      });
      generateColors = false;
      globalObjects.glList.add(tmpList);
    });
    duration = Duration(seconds: 0);
    if(recOrFile){
      Navigator.pop(context);
      recOrFile=false;
    }
    Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => new accuraciesPage()));
    params_progress_button = "record";
    setState(() {

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

  void _sendAudio() async {
    await player.play(globalObjects.path+".wav", isLocal: true);
    await player.stop();

    //HTTP POST HERE

    await getGenreList(_recording.path, _recording.duration.inSeconds);
    // Inflate genreList

    //Update the view here
    setState(() {

    });

    return;
  }
  void _theButton() async {
    print("Record button clicked.");
    if(isRecording){
      isRecording = false;
      String customPath = '/audient_';
      io.Directory appDocDirectory;
      if (io.Platform.isIOS) {
        appDocDirectory = await getApplicationDocumentsDirectory();
      } else {
        appDocDirectory = await getTemporaryDirectory();
      }

      // can add extension like ".mp4" ".wav" ".m4a" ".aac"
      customPath = appDocDirectory.path +
          customPath +
          DateTime.now().millisecondsSinceEpoch.toString();
      globalObjects.path = customPath;
      recorder = FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);
      await recorder.initialized;
      await recorder.start();
      recording = await recorder?.current(channel: 0);
      _t = Timer.periodic(Duration(milliseconds: 100), (_t) async {
        Recording tmp = await recorder?.current(channel: 0);
        setState(() {
          _power = (50.0 + tmp.metering.averagePower).abs()*2/100;
          print(_power);
          duration = Duration(milliseconds: duration.inMilliseconds+100);
        });
      });
      print("Recording.");
      setState(() {

      });
//      _p
    }
    else{
      _t.cancel();
      isRecording = true;
      var result = await recorder.stop();
      _recording = result;
      print("Stopped.");
      _sendAudio();
      setState(() {

      });
//      _play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: true,
        title: Text("Audient", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w100),),
      ),
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: new Text("${user?.displayName}"),
              accountEmail: new Text("${user?.email}"),
              currentAccountPicture: new CircleAvatar(backgroundImage: NetworkImage("${user?.photoUrl}"),),
            ),
            ListTile(
              title: Text("Logout"),
              onTap: (){
                authService.logout();
              },
            ),
            ListTile(
              title: Text("About"),
              onTap: (){
                showAboutDialog(
                  context: context,
                  applicationIcon: Image(height: 64, width: 64,image: AssetImage("assets/images/ic_launcher.png"),),
                  applicationName: 'Audient',
                  applicationVersion: '0.0.1',
                  applicationLegalese: '©2020 rohanbojja.com',
                  children: <Widget>[
                    Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text('This is an application to demonstrate the working of an audio classifier. Source code @ https://github.com/rohanbojja/audient_flutter')
                    )
                  ],
                );
              },
            )
          ],
        ),
      ),
      floatingActionButton: OutlineButton(
        child: Text("File upload",style: TextStyle(color: Colors.white,)),
        onPressed: () async {
          File file = await FilePicker.getFile();
          if(file!=null){
            showLoader();
            recOrFile = true;
            getGenreList(file.path, 20);
            setState(() {

            });
          }
        },
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Card(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Text("$duration", style: TextStyle(fontSize: 28),),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text("Tap to record!",style: TextStyle(color: Colors.white),),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 64),
              child: LinearProgressIndicator(value: _power, backgroundColor: Colors.grey,),
            ),
            ProgressButton(buttonText: "$params_progress_button",
            onPressed: () async{
              if(params_progress_button=="record"){
                params_progress_button = "stop";
                print("change button state?");
                setState(() {

                });
              }else{
                params_progress_button = "process";
              }
              await _theButton();
              },)
            //IconButton(icon: Icon(Icons.album), onPressed: _theButton, iconSize: 256, highlightColor: Colors.orangeAccent, color: Colors.black,),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
