import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/dashboard.dart';
import 'package:user/screens/login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures Flutter engine is ready before async operations

  await Supabase.initialize(
    url: 'https://rrtzbtfyffafzqgiwrtv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJydHpidGZ5ZmZhZnpxZ2l3cnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDY5MjgsImV4cCI6MjA0OTkyMjkyOH0.CIMMUagr7aI5vNRffV3T7klOuCBPfFKqd6O3FIW1uxE',
  );

  runApp(const MainApp()); // ✅ Now inside main()
}

final supabase = Supabase.instance.client; // ✅ Defined after initialization

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }
}
class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Check if the user is logged in
    final session = supabase.auth.currentSession;

    // Navigate to the appropriate screen based on the authentication state
    if (session != null) {
      return Dashboard(); // Replace with your home screen widget
    } else {
      return Login(); // Replace with your auth page widget
    }
  }
}
