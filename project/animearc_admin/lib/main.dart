import 'package:animearc_admin/screens/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://rrtzbtfyffafzqgiwrtv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJydHpidGZ5ZmZhZnpxZ2l3cnR2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDY5MjgsImV4cCI6MjA0OTkyMjkyOH0.CIMMUagr7aI5vNRffV3T7klOuCBPfFKqd6O3FIW1uxE',
  );
  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

// Custom theme colors
class AnimeArcTheme {
  static const Color primaryPurple = Color(0xFF8A2BE2);
  static const Color deepPurple = Color(0xFF5D1E9E);
  static const Color lightPurple = Color(0xFFAA7EE0);
  static const Color accentColor = Color(0xFF42E8E0);
  static const Color backgroundDark = Color(0xFF1A0933);
  static const Color cardDark = Color(0xFF2D1155);
  static const Color textLight = Color(0xFFF0F0F5);
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AnimeArc Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.dark(
          primary: AnimeArcTheme.primaryPurple,
          onPrimary: AnimeArcTheme.textLight,
          secondary: AnimeArcTheme.accentColor,
          onSecondary: Colors.black,
          background: AnimeArcTheme.backgroundDark,
          surface: AnimeArcTheme.cardDark,
          onSurface: AnimeArcTheme.textLight,
        ),
        scaffoldBackgroundColor: AnimeArcTheme.backgroundDark,
        cardTheme: CardTheme(
          color: AnimeArcTheme.cardDark,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData.dark().textTheme,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AnimeArcTheme.primaryPurple,
            foregroundColor: AnimeArcTheme.textLight,
            elevation: 5,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AnimeArcTheme.cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AnimeArcTheme.accentColor, width: 2),
          ),
          hintStyle: TextStyle(color: Colors.grey[400]),
        ),
      ),
      home: const AdminLoginPage(),
    );
  }
}
