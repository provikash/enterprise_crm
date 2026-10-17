import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_crm/core/theme/theme_mode_controller.dart';

void main() {
  group('ThemeModeController Tests', () {
    test('toggles theme mode between light and dark', () {
      final controller = ThemeModeController.instance;

      controller.setThemeMode(ThemeMode.light);
      expect(controller.value, ThemeMode.light);

      controller.toggleTheme(Brightness.light);
      expect(controller.value, ThemeMode.dark);

      controller.toggleTheme(Brightness.dark);
      expect(controller.value, ThemeMode.light);
    });
  });
}
