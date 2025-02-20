import 'package:flutter/material.dart';

class Browse extends StatefulWidget {
  const Browse({super.key});

  @override
  State<Browse> createState() => _BrowseState();
}

class _BrowseState extends State<Browse> {
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      body:Container(
       decoration: BoxDecoration(color:Colors.black87),
      ),
      appBar: AppBar(
      backgroundColor:const Color.fromARGB(255, 0, 0, 0),
      
      actions: [
           IconButton(onPressed: (){}, icon: Icon(Icons.notification_add)),
           IconButton(onPressed: () {}, icon: Icon(Icons.search)),
      ],
    ),
    );
  }
}