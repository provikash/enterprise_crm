import 'package:flutter/material.dart';

/// Centralized Enterprise CRM Theme definitions.
///
/// Features a refined Lavender & Deep Violet brand palette with high-contrast
/// typography and container styling across both Light and Dark modes.
class AppTheme {
  const AppTheme._();

  static const Color primaryLavender = Color(0xFF7C3AED);
  static const Color primaryDarkLavender = Color(0xFFA78BFA);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryLavender,
      brightness: Brightness.light,
    ).copyWith(
      primary: primaryLavender,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFEDE9FE),
      onPrimaryContainer: const Color(0xFF4C1D95),
      surface: Colors.white,
      onSurface: const Color(0xFF1E1B2E),
      onSurfaceVariant: const Color(0xFF6B7280),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFF9F8FD),
      surfaceContainer: const Color(0xFFF3F0FA),
      surfaceContainerHigh: const Color(0xFFEDE8F7),
      outline: const Color(0xFFCBD5E1),
      outlineVariant: const Color(0xFFE2E8F0),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F7FC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E1B2E),
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE2E8F0),
      thickness: 1,
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryDarkLavender,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryDarkLavender,
      onPrimary: const Color(0xFF1E1B2E),
      primaryContainer: const Color(0xFF3B2E58),
      onPrimaryContainer: const Color(0xFFEDE9FE),
      surface: const Color(0xFF181524),
      onSurface: const Color(0xFFF5F3FF),
      onSurfaceVariant: const Color(0xFFB4ACCE),
      surfaceContainerLowest: const Color(0xFF13101D),
      surfaceContainerLow: const Color(0xFF1C182B),
      surfaceContainer: const Color(0xFF221E33),
      surfaceContainerHigh: const Color(0xFF2B263E),
      outline: const Color(0xFF554D6E),
      outlineVariant: const Color(0xFF38324D),
    ),
    scaffoldBackgroundColor: const Color(0xFF100E19),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181524),
      foregroundColor: Color(0xFFF5F3FF),
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C182B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF38324D)),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF38324D),
      thickness: 1,
    ),
  );
}
