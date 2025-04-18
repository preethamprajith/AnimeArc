
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/dashboard.dart';
import 'package:user/screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is ready before async operations

  try {
    await Supabase.initialize(
      url: 'https://rrtzbtfyffafzqgiwrtv.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJydHpidGZ5ZmZhZnpxZ2l3cnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDY5MjgsImV4cCI6MjA0OTkyMjkyOH0.CIMMUagr7aI5vNRffV3T7klOuCBPfFKqd6O3FIW1uxE',
    );
  } catch (e) {
    print("Supabase Initialization Failed: $e");
  }

  runApp(const MainApp()); // ✅ Now inside main()
}

final supabase = Supabase.instance.client; // ✅ Defined after initialization

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthWrapper(), // ✅ Use AuthWrapper to check authentication state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return session != null ? Dashboard() : Login(); // ✅ Properly switch based on login state
  }
}
