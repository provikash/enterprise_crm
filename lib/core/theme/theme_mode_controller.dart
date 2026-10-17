import 'package:flutter/material.dart';

/// Global controller for managing application theme mode (light, dark, system).
class ThemeModeController extends ValueNotifier<ThemeMode> {
  static final ThemeModeController instance = ThemeModeController._();

  ThemeModeController._() : super(ThemeMode.system);

  /// Toggle between light and dark mode. If system, switches based on current platform brightness.
  void toggleTheme(Brightness currentBrightness) {
    if (value == ThemeMode.dark || (value == ThemeMode.system && currentBrightness == Brightness.dark)) {
      value = ThemeMode.light;
    } else {
      value = ThemeMode.dark;
    }
  }

  void setThemeMode(ThemeMode mode) {
    value = mode;
  }
}
