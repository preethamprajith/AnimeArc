import 'package:flutter/material.dart';

class AnimeTheme {
  // Colors
  static const primaryPurple = Color(0xFF4A1A70);
  static const darkPurple = Color(0xFF2A0A40);
  static const brightPurple = Color(0xFF6B2A90);
  static const accentPink = Color(0xFFFF69B4);

  // Animation Properties
  static const defaultDuration = Duration(milliseconds: 300);
  static const defaultCurve = Curves.easeInOut;

  // Gradients
  static const profileGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF8A2BE2),
      Color(0xFF4A1A70),
    ],
  );

  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      brightPurple,
      accentPink,
    ],
  );

  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaryPurple,
      darkPurple,
    ],
  );
}