import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/dynamic_palette_service.dart';
import 'package:nexa_player/core/utils/contrast_validator.dart';

void main() {
  group('ContrastValidator Unit Tests', () {
    test('relativeLuminance computes precise WCAG 2.1 values', () {
      expect(ContrastValidator.relativeLuminance(const Color(0xFF000000)), equals(0.0));
      expect(ContrastValidator.relativeLuminance(const Color(0xFFFFFFFF)), closeTo(1.0, 0.0001));

      // Pure red, green, blue relative luminances
      final rLum = ContrastValidator.relativeLuminance(const Color(0xFFFF0000));
      final gLum = ContrastValidator.relativeLuminance(const Color(0xFF00FF00));
      final bLum = ContrastValidator.relativeLuminance(const Color(0xFF0000FF));

      expect(rLum, closeTo(0.2126, 0.001));
      expect(gLum, closeTo(0.7152, 0.001));
      expect(bLum, closeTo(0.0722, 0.001));
    });

    test('calculateContrastRatio computes standard bounds', () {
      final maxRatio = ContrastValidator.calculateContrastRatio(
        const Color(0xFFFFFFFF),
        const Color(0xFF000000),
      );
      expect(maxRatio, closeTo(21.0, 0.01));

      final minRatio = ContrastValidator.calculateContrastRatio(
        const Color(0xFF123456),
        const Color(0xFF123456),
      );
      expect(minRatio, closeTo(1.0, 0.01));
    });

    // 20 extreme artwork colors
    const extremeColors = <String, Color>{
      'pureWhite': Color(0xFFFFFFFF),
      'pureBlack': Color(0xFF000000),
      'saturatedYellow': Color(0xFFFFFF00),
      'neonCyan': Color(0xFF00FFFF),
      'neonGreen': Color(0xFF00FF00),
      'neonMagenta': Color(0xFFFF00FF),
      'deepNavy': Color(0xFF000033),
      'deepMaroon': Color(0xFF330000),
      'brightOrange': Color(0xFFFF6600),
      'electricLime': Color(0xFFBFFF00),
      'midGray': Color(0xFF808080),
      'lightGray': Color(0xFFD3D3D3),
      'darkGray': Color(0xFF202020),
      'pastelPink': Color(0xFFFFD1DC),
      'pastelBlue': Color(0xFFAEC6CF),
      'saturatedRed': Color(0xFFFF0000),
      'saturatedBlue': Color(0xFF0000FF),
      'goldenYellow': Color(0xFFFFD700),
      'teal': Color(0xFF008080),
      'violet': Color(0xFF8A2BE2),
    };

    const darkCanvas = Color(0xFF050507);
    const daylightCanvas = Color(0xFFF4F5F7);

    test('verifies exactly 20 extreme colors are included in the audit suite', () {
      expect(extremeColors.length, equals(20));
    });

    group('ensureContrast asserts >= 4.5 for body text on all 20 extreme colors', () {
      for (final entry in extremeColors.entries) {
        test('validates ${entry.key} on dark canvas ($darkCanvas)', () {
          final clamped = ensureContrast(entry.value, darkCanvas, minRatio: 4.5);
          final ratio = ContrastValidator.calculateContrastRatio(clamped, darkCanvas);
          expect(ratio, greaterThanOrEqualTo(4.5),
              reason: 'Failed 4.5:1 ratio for ${entry.key} on dark canvas');
          expect(ContrastValidator.meetsWcagAA(clamped, darkCanvas), isTrue);
        });

        test('validates ${entry.key} on daylight canvas ($daylightCanvas)', () {
          final clamped = ensureContrast(entry.value, daylightCanvas, minRatio: 4.5);
          final ratio = ContrastValidator.calculateContrastRatio(clamped, daylightCanvas);
          expect(ratio, greaterThanOrEqualTo(4.5),
              reason: 'Failed 4.5:1 ratio for ${entry.key} on daylight canvas');
          expect(ContrastValidator.meetsWcagAA(clamped, daylightCanvas), isTrue);
        });
      }
    });

    group('ensureContrast asserts >= 3.0 for icons/large text on all 20 extreme colors', () {
      for (final entry in extremeColors.entries) {
        test('validates ${entry.key} on dark canvas for icons', () {
          final clamped = ensureContrast(entry.value, darkCanvas, minRatio: 3.0);
          final ratio = ContrastValidator.calculateContrastRatio(clamped, darkCanvas);
          expect(ratio, greaterThanOrEqualTo(3.0),
              reason: 'Failed 3.0:1 icon ratio for ${entry.key} on dark canvas');
          expect(ContrastValidator.meetsWcagAA(clamped, darkCanvas, isLargeText: true), isTrue);
        });

        test('validates ${entry.key} on daylight canvas for icons', () {
          final clamped = ensureContrast(entry.value, daylightCanvas, minRatio: 3.0);
          final ratio = ContrastValidator.calculateContrastRatio(clamped, daylightCanvas);
          expect(ratio, greaterThanOrEqualTo(3.0),
              reason: 'Failed 3.0:1 icon ratio for ${entry.key} on daylight canvas');
          expect(ContrastValidator.meetsWcagAA(clamped, daylightCanvas, isLargeText: true), isTrue);
        });
      }
    });

    test('ExtractedPalette getters atmosphere, accent, and specular satisfy contrast', () {
      const palette = ExtractedPalette(
        dominant: Color(0xFF102030),
        vibrant: Color(0xFF00FFCC),
        muted: Color(0xFF334155),
        darkVibrant: Color(0xFF05101A),
        lightVibrant: Color(0xFFC0E0FF),
      );

      final accentRatio = ContrastValidator.calculateContrastRatio(palette.accent, darkCanvas);
      expect(accentRatio, greaterThanOrEqualTo(4.5));

      final atmosphereRatio = ContrastValidator.calculateContrastRatio(palette.atmosphere, darkCanvas);
      expect(atmosphereRatio, greaterThanOrEqualTo(3.0));

      final specularRatio = ContrastValidator.calculateContrastRatio(palette.specular, darkCanvas);
      expect(specularRatio, greaterThanOrEqualTo(4.5));
    });
  });
}
