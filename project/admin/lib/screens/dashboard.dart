import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Row(
        children: [
          Container(
            width:240,
            height:585,
            decoration:BoxDecoration(color:Colors.blue),
            child:Column(
              children: [
                Text("DASHBOARD"),
              ],
            ),
          ),

        ],
      ) ,
    );
  }
}