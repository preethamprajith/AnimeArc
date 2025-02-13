import 'package:flutter/material.dart';

class mylist extends StatefulWidget {
  const mylist({super.key});

  @override
  State<mylist> createState() => _mylistState();
}

class _mylistState extends State<mylist> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("mylist"),
    );
  }
}