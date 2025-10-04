import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFFEAEBD0);

  // Primary colors
  static const Color primary = Color(0xFFCD5656); // Main brand color
  static const Color secondary = Color(0xFFDA6C6C); // For accents/buttons
  static const Color darkRed = Color(0xFFAF3E3E); // For headers or alerts

  // Text colors
  static const Color textPrimary =
      Color(0xFF333333); // Dark text for readability
  static const Color textSecondary = Color(0xFF666666); // Lighter text

  // Additional UI colors
  static const Color cardBackground = Colors.white; // Card background
  static const Color iconColor = Color(0xFFCD5656); // Icon highlights
  static const Color buttonText = Colors.white; // Text on primary buttons

  // Optional: Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [secondary, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
