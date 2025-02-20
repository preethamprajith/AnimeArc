import 'package:flutter/material.dart';

class Store extends StatefulWidget {
  const Store({super.key});

  @override
  State<Store> createState() => _StoreState();
}

class _StoreState extends State<Store> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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