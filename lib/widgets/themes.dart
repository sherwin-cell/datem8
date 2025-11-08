import 'package:flutter/material.dart';

class AppThemes {
  // Light Theme
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: const Color(0xFFF5F3F7),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF6A6969),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.red),
    cardColor: Colors.white,
    iconTheme:
        const IconThemeData(color: Colors.black87), // Icons in light mode
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      textStyle: TextStyle(color: Colors.black87),
    ),
  );

  // Dark Theme
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.red,
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1F1F1F),
      foregroundColor: Colors.white,
    ),
    floatingActionButtonTheme:
        const FloatingActionButtonThemeData(backgroundColor: Colors.red),
    cardColor: const Color(0xFF1E1E1E),
    iconTheme: const IconThemeData(color: Colors.white), // Icons in dark mode
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Color(0xFF1E1E1E),
      textStyle: TextStyle(color: Colors.white),
    ),
  );
}
