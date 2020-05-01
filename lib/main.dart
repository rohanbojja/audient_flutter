import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:typed_data';
import 'package:audientflutter/screens/loginPage.dart';
import 'package:audientflutter/services/auth.dart';
import 'package:audientflutter/services/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http;
import 'package:audientflutter/models/Genre.dart';
import 'package:audientflutter/models/GenreList.dart';
import 'package:audientflutter/screens/accuraciesPage.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
import 'package:mlkit/mlkit.dart';

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
  brightness: Brightness.dark,
  fontFamily: 'Montserrat',
  accentColor: Colors.purple,
  primaryColor: Colors.black,
  primarySwatch: Colors.purple,
  cursorColor: Colors.deepPurple,
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
  int _counter = 0;
  FirebaseUser user;
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
  GenreList genreList;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCust();
    isRecording = true;
  }

  Future<void> initCust() async {
    _animationController = AnimationController(vsync: this,duration: Duration(seconds: 1));
    genreList = GenreList();
    bool hasPermission = await FlutterAudioRecorder.hasPermissions;
    user = await authService.currentUser();
    print("DBGauto OHME");

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

  Future <GenreList> getGenreList(String _path) async {

    genreList = GenreList();
    genreList.accuracies = List<Genre>();
    print("DBG-> Create genrelist list of length ${genreList.accuracies.length}");
    var dio = Dio();
    dio.options.baseUrl = "https://audient.azurewebsites.net";
    FormData formData = FormData.fromMap({
      "name": "file",
      "file": await MultipartFile.fromFile(_path,filename: "jam.wav")
    });
    var response = await dio.post("/receiveWav", data: formData);
    if(response.statusCode != 400 ){
      var tmp = response.data;
      print("THIS IS IT-> ${tmp["Blues"]}");
//      For azure or other service with tensorflow
      double high=0;
      tmp.forEach((k,v){
        print("KEV VAL PAIRS $k $v");
        genreList.accuracies.add(Genre(k,v));
        if(double.parse(v)>high){
          high = double.parse(v);
          genreList.predictedLabel = k.toString().toUpperCase();
          genreList.confidence = double.parse(v);
        }
      });

      //For heroku

//      var res2 = tmp.substring(2,tmp.length-2).split(",");
//      List<double> myList = List<double>();
//      res2.forEach((f){
//        myList.add(double.parse(f));
//      });

    }
    else{
      print("DBG-> HTTP ERROR ${response.statusCode}");

    }
    return genreList;
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
    showLoader();
    //HTTP POST HERE
    genreList = await getGenreList(_recording.path).whenComplete((){
      print("DBG-> Got genre list of length ${genreList.accuracies} ${_recording.path}");
      genreList.accuracies.sort((a,b) => double.parse(b.accuracy).compareTo(double.parse(a.accuracy)));
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (BuildContext context) => new accuraciesPage(),settings:
      RouteSettings(
          arguments: genreList
      )));
    });
    // Inflate genreList

    //Update the view here
    setState(() {

    });

    return;
  }
  void _play() {
    AudioPlayer player = AudioPlayer();
    player.play(_recording.path, isLocal: true);
  }

  Future<void> _theButton() async {
    //record and stuff here

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
//      customPath = appDocDirectory.path +
//          customPath +
//          "thefile";
      recorder = FlutterAudioRecorder(customPath, audioFormat: AudioFormat.WAV);
      await recorder.initialized;
      print("DBG-> INIT RECORD");
      await recorder.start();
      print("DBG-> STARTED");
      recording = await recorder?.current(channel: 0);
      _t = new Timer.periodic(Duration(milliseconds: 10), (Timer t) async {
        var current = await recorder.current(channel: 0);
        // Update meter
        setState(() {
          _recording = current;
          _power = _recording?.metering?.peakPower;
          print(_power);
        });
      });
    }
    else{
      isRecording = true;
      var result = await recorder.stop();
      _recording = result;
      _t.cancel();
      await _sendAudio();
//      _play();
    }
    setState(() {

    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Center(child: Center(child: Text(widget.title),),),
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
            )
          ],
        ),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircularProgressIndicator(value: _power,),
            Visibility(
              visible: !isRecording,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    disabledColor: Colors.red,
                    icon: Icon(Icons.fiber_manual_record),
                  ),
                  Text("Recording")
                ],
              ),
              maintainAnimation: true,
              maintainSize: false,
              maintainState: true,
            ),
            IconButton(icon: Icon(Icons.album), onPressed: _theButton, iconSize: 256,),
          ],
        ),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
