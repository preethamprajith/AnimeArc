import 'package:flutter/material.dart';

class Userhome extends StatefulWidget {
  const Userhome({super.key});

  @override
  State<Userhome> createState() => _UserhomeState();
}

class _UserhomeState extends State<Userhome> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Container(
       decoration: BoxDecoration(color:Colors.black87),
      ),
      appBar: AppBar(
      backgroundColor:const Color.fromARGB(255, 0, 0, 0),
      leading: Image.asset(
        "assets/logo3.png",
        width: 100,
        height: 100,
      ),
      actions: [
           IconButton(onPressed: (){}, icon: Icon(Icons.notification_add)),
           IconButton(onPressed: () {}, icon: Icon(Icons.search)),
      ],
    ),
    );
  }
}
