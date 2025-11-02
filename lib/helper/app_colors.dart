import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFFEAEBD0);
  static const Color cardBackground = Colors.white;

  // Brand / Primary Colors
  static const Color primary = Color(0xFFCD5656); // Main brand color
  static const Color secondary =
      Color(0xFFDA6C6C); // Accent buttons or highlights
  static const Color darkRed = Color(0xFFAF3E3E); // Alerts or headers

  // Text Colors
  static const Color textPrimary =
      Color(0xFF333333); // Dark text for readability
  static const Color textSecondary = Color(0xFF666666); // Light/secondary text
  static const Color buttonText = Colors.white; // Text on primary buttons

  // Icons
  static const Color iconColor = Color(0xFFCD5656); // Icon highlights

  // Optional: Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Optional semantic helpers (FlutterFlow style)
  static Color get inputBackground => cardBackground;
  static Color get linkColor => Colors.blue;
}
