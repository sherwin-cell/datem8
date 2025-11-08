import 'package:flutter/material.dart';

class DarkModeController {
  // ValueNotifier to track the current theme
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.light);

  // Toggle function to switch between light and dark
  static void toggleTheme() {
    themeModeNotifier.value = themeModeNotifier.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
