import 'package:audientflutter/main.dart';
import 'package:audientflutter/screens/web/fileUploadPage.dart';
import 'package:audientflutter/services/auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_platform/universal_platform.dart';

bool isIos = UniversalPlatform.isIOS;
bool isAndroid = UniversalPlatform.isAndroid;
bool isWeb = UniversalPlatform.isWeb;

class loginPage extends StatefulWidget {
  @override
  _loginPageState createState() => _loginPageState();
}

class _loginPageState extends State<loginPage> {
  FirebaseUser user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initCust();
  }

  Future<void> initCust() async {
    user = await authService.currentUser();
    print("DBGauto");

    //Setup auth change listener
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      if (user != null) {
        print("DBGGING ${user?.displayName}");
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(
            builder: (BuildContext context) => new MyHomePage(title: "Audient",)));
      } else {

      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SignInButton(
              Buttons.Google,
              onPressed: () {
                if(!kIsWeb && !UniversalPlatform.isWindows){
                  authService.handleSignIn();
                }else{

                  Navigator.push(context, MaterialPageRoute(
                      builder: (BuildContext context) => new MyHomePage()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
