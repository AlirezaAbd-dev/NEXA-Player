import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/theme.dart';

void main() {
  group('AppTheme Unit Tests', () {
    test('AppTheme.dark creates dark ThemeData with Material 3', () {
      final theme = AppTheme.dark(preset: ThemePreset.midnightBlack);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFF000000)));
      expect(theme.colorScheme.primary, equals(const Color(0xFF00E5FF)));
    });

    test('AppTheme.light creates light ThemeData with Material 3', () {
      final theme = AppTheme.light(preset: ThemePreset.daylight);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, equals(const Color(0xFFF8FAFC)));
      expect(theme.colorScheme.primary, equals(const Color(0xFF2563EB)));
    });

    test('AppTheme.buildTheme respects ThemeMode and systemBrightness', () {
      final darkTheme = AppTheme.buildTheme(
        preset: ThemePreset.oceanBlue,
        mode: ThemeMode.dark,
      );
      expect(darkTheme.brightness, equals(Brightness.dark));
      expect(darkTheme.scaffoldBackgroundColor, equals(const Color(0xFF0B192C)));

      final lightTheme = AppTheme.buildTheme(
        preset: ThemePreset.oceanBlue,
        mode: ThemeMode.light,
      );
      expect(lightTheme.brightness, equals(Brightness.light));
      expect(lightTheme.scaffoldBackgroundColor, equals(const Color(0xFFF0F9FF)));

      final systemDark = AppTheme.buildTheme(
        preset: ThemePreset.oceanBlue,
        mode: ThemeMode.system,
        systemBrightness: Brightness.dark,
      );
      expect(systemDark.brightness, equals(Brightness.dark));

      final systemLight = AppTheme.buildTheme(
        preset: ThemePreset.oceanBlue,
        mode: ThemeMode.system,
        systemBrightness: Brightness.light,
      );
      expect(systemLight.brightness, equals(Brightness.light));
    });

    test('AppTheme creates valid ThemeData for custom primary color in dark mode', () {
      final customTheme = AppTheme.buildTheme(
        preset: ThemePreset.custom,
        mode: ThemeMode.dark,
        customPrimary: const Color(0xFF8B5CF6),
        customSurface: const Color(0xFF1E1E2E),
        customBackground: const Color(0xFF11111B),
      );
      expect(customTheme.colorScheme.primary, equals(const Color(0xFF8B5CF6)));
      expect(customTheme.useMaterial3, isTrue);
      expect(customTheme.brightness, equals(Brightness.dark));
      expect(customTheme.scaffoldBackgroundColor, equals(const Color(0xFF11111B)));
    });

    test('AppTheme creates valid ThemeData for custom primary color in light mode', () {
      final customTheme = AppTheme.buildTheme(
        preset: ThemePreset.custom,
        mode: ThemeMode.light,
        customPrimary: const Color(0xFF8B5CF6),
        customSurface: const Color(0xFFFFFFFF),
        customBackground: const Color(0xFFF5F5F7),
      );
      expect(customTheme.colorScheme.primary, equals(const Color(0xFF8B5CF6)));
      expect(customTheme.useMaterial3, isTrue);
      expect(customTheme.brightness, equals(Brightness.light));
      expect(customTheme.scaffoldBackgroundColor, equals(const Color(0xFFF5F5F7)));
    });

    test('All 8 presets generate valid dark and light ThemeData without errors', () {
      final builtInPresets = ThemePreset.values.where((p) => p != ThemePreset.custom);
      for (final preset in builtInPresets) {
        final dark = AppTheme.dark(preset: preset);
        final light = AppTheme.light(preset: preset);
        expect(dark.useMaterial3, isTrue);
        expect(light.useMaterial3, isTrue);
        expect(dark.brightness, equals(Brightness.dark));
        expect(light.brightness, equals(Brightness.light));
      }
    });
  });
}
