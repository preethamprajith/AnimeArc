import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screens/dashboard.dart';
import 'package:user/screens/login.dart';
import 'package:google_fonts/google_fonts.dart';

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

// Custom anime theme colors
class AnimeTheme {
  // Main colors
  static const Color primaryPurple = Color(0xFF2A0845);
  static const Color darkPurple = Color(0xFF1A0527);
  static const Color brightPurple = Color(0xFF6A3093);
  static const Color accentPink = Color(0xFFFF6B95);
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color darkBg = Color(0xFF121212);
  static const Color textWhite = Colors.white;
  static const Color textGrey = Color(0xFFBBBBBB);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryPurple, darkPurple],
  );
  
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brightPurple, accentPink],
  );
  
  // Text styles
  static TextStyle headingStyle = GoogleFonts.montserrat(
    fontSize: 26,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  
  static TextStyle subheadingStyle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
  
  static TextStyle bodyStyle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white.withOpacity(0.9),
  );
  
  // Decoration styles
  static BoxDecoration cardDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        brightPurple.withOpacity(0.2),
        darkPurple.withOpacity(0.3),
      ],
    ),
    border: Border.all(
      color: accentPink.withOpacity(0.3),
      width: 1,
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.25),
        blurRadius: 10,
        spreadRadius: 0,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Button styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: accentPink,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    elevation: 5,
    shadowColor: accentPink.withOpacity(0.5),
  );
  
  // Input decoration
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: accentPink),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: accentPink),
      ),
      filled: true,
      fillColor: darkPurple.withOpacity(0.6),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AnimeHub',
      theme: ThemeData(
        // Basic theme settings
        scaffoldBackgroundColor: AnimeTheme.darkPurple,
        primaryColor: AnimeTheme.primaryPurple,
        colorScheme: ColorScheme.dark(
          primary: AnimeTheme.accentPink,
          secondary: AnimeTheme.brightPurple,
          surface: AnimeTheme.darkPurple,
          background: AnimeTheme.darkPurple,
        ),
        
        // Text theme using Google Fonts
        textTheme: TextTheme(
          displayLarge: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AnimeTheme.textWhite,
          ),
          displayMedium: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AnimeTheme.textWhite,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: AnimeTheme.textWhite,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: AnimeTheme.textWhite,
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AnimeTheme.brightPurple,
            foregroundColor: AnimeTheme.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AnimeTheme.accentPink.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AnimeTheme.accentPink.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: AnimeTheme.accentPink),
          ),
          hintStyle: GoogleFonts.poppins(color: Colors.white60),
        ),
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: GoogleFonts.montserrat(
            color: AnimeTheme.textWhite,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AnimeTheme.textWhite),
        ),
      ),
      home: const AuthWrapper(), // ✅ Use AuthWrapper to check authentication state
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    return session != null ? Dashboard() : const Login(); // ✅ Properly switch based on login state
  }
}
