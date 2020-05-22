import 'package:flutter/material.dart';

class ProgressButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String buttonText;
  ProgressButton({@required this.buttonText,this.onPressed});
  @override
  _ProgressButtonState createState() => _ProgressButtonState();
}

class _ProgressButtonState extends State<ProgressButton> with TickerProviderStateMixin{

  GlobalKey globalKey = GlobalKey();
  double button_width = 200;
  Animation _animation;
  bool _isPressed;

  @override
  Widget build(BuildContext context) {
    if(widget.buttonText=="record"){
      button_width = 200;
      return PhysicalModel(
        color: Theme.of(context).accentColor,
        elevation: 5.0,
        borderRadius: BorderRadius.circular(25.0),
        child: Container(
          key: globalKey,
          height: 48.0,
          width: button_width,
          child: MaterialButton(
            padding: EdgeInsets.all(0.0),
            onPressed: widget.onPressed,
            onHighlightChanged: (isPressed){
              _isPressed = isPressed;
              animateButton();
            },
            child: Center(child: Icon(Icons.mic),),
          ),
        ),
      );
    }
    else if(widget.buttonText=="stop"){
      return PhysicalModel(
        color: Theme.of(context).accentColor,
        elevation: 5.0,
        borderRadius: BorderRadius.circular(25.0),
        child: Container(
          key: globalKey,
          height: 48.0,
          width: button_width,
          child: MaterialButton(
            padding: EdgeInsets.all(0.0),
            onPressed: widget.onPressed,
            onHighlightChanged: (isPressed){
              _isPressed = isPressed;
              animateButton();
            },
            child: Icon(Icons.stop),
          ),
        ),
      );
    }
    else{
      return PhysicalModel(
        color: Theme.of(context).accentColor,
        elevation: 5.0,
        borderRadius: BorderRadius.circular(25.0),
        child: Container(
          key: globalKey,
          height: 48.0,
          width: button_width,
          child: MaterialButton(
            padding: EdgeInsets.all(0.0),
            onPressed: widget.onPressed,
            onHighlightChanged: (isPressed){
              _isPressed = isPressed;
              animateButton();
            },
            child: CircularProgressIndicator(value: null, valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 2.0,),
          ),
        ),
      );
    }
  }
  void animateButton(){
    double init_width  = globalKey.currentContext.size.width;
    var controller = AnimationController(duration: Duration(milliseconds: 200), vsync: this);
    _animation  = Tween(begin: 0.0, end: 1.0)
    .animate(controller)
    ..addListener((){
      setState(() {
        button_width = init_width - ((init_width-48.0) * _animation.value);
        if(button_width<48){
          button_width = 48.0;
        }
      });
    });
    controller.forward();
  }
}


