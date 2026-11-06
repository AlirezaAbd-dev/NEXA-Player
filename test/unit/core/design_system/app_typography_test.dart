import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';

void main() {
  group('AppTypography Unit Tests', () {
    test('verifies M3 text styles exist and have correct sizes', () {
      expect(AppTypography.displayLarge.fontSize, equals(32.0));
      expect(AppTypography.displayMedium.fontSize, equals(26.0));
      expect(AppTypography.displaySmall.fontSize, equals(22.0));
      expect(AppTypography.headlineLarge.fontSize, equals(24.0));
      expect(AppTypography.headlineMedium.fontSize, equals(20.0));
      expect(AppTypography.headlineSmall.fontSize, equals(18.0));
      expect(AppTypography.titleLarge.fontSize, equals(17.0));
      expect(AppTypography.titleMedium.fontSize, equals(15.0));
      expect(AppTypography.titleSmall.fontSize, equals(13.0));
      expect(AppTypography.bodyLarge.fontSize, equals(16.0));
      expect(AppTypography.bodyMedium.fontSize, equals(14.0));
      expect(AppTypography.bodySmall.fontSize, equals(12.0));
      expect(AppTypography.labelLarge.fontSize, equals(14.0));
      expect(AppTypography.labelMedium.fontSize, equals(12.0));
      expect(AppTypography.labelSmall.fontSize, equals(10.0));
    });

    test('createTextTheme populates all Material 3 slots', () {
      const customColor = Colors.cyan;
      final theme = AppTypography.createTextTheme(customColor);
      expect(theme.displayLarge?.color, equals(customColor));
      expect(theme.headlineMedium?.fontSize, equals(20.0));
      expect(theme.titleLarge?.fontSize, equals(17.0));
      expect(theme.bodyMedium?.fontSize, equals(14.0));
      expect(theme.labelSmall?.fontSize, equals(10.0));

      final defaultTheme = AppTypography.createTextTheme();
      expect(defaultTheme.displayLarge?.fontSize, equals(32.0));
    });
  });
}
