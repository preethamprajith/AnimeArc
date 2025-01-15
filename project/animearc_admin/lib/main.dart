//import 'package:animearc_admin/screens/dashboard.dart';
import 'package:animearc_admin/screens/login.dart';

import 'package:flutter/material.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AdminLoginApp(),
    );
  }
}
