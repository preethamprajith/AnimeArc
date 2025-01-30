import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/login.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://rrtzbtfyffafzqgiwrtv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJydHpidGZ5ZmZhZnpxZ2l3cnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDY5MjgsImV4cCI6MjA0OTkyMjkyOH0.CIMMUagr7aI5vNRffV3T7klOuCBPfFKqd6O3FIW1uxE',
  );
  runApp(const MainApp());
}
final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner:false,
      home:InvictusLogin() ,

      
    );
  }
}
