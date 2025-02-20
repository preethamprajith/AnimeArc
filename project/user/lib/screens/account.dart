import 'package:flutter/material.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
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