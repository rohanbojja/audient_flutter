import 'package:audientflutter/models/GenreList.dart';
import 'package:flutter/material.dart';

class accuraciesPage extends StatefulWidget {
  @override
  _accuraciesPageState createState() => _accuraciesPageState();
}

class _accuraciesPageState extends State<accuraciesPage> {
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
                  children: <Widget>[
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
                              LinearProgressIndicator(value: double.parse(genreList.accuracies[index].accuracy),),
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

