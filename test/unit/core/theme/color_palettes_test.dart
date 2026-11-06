import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/theme.dart';

void main() {
  group('AppColorPalettes Unit Tests', () {
    test('All 8 presets are defined in AppColorPalettes.all and AppColorPalettes.presets', () {
      expect(AppColorPalettes.all.length, equals(8));
      expect(AppColorPalettes.presets.length, equals(8));
    });

    test('Midnight Black dark scaffold is pure AMOLED #000000 with cyan and lime accents', () {
      const palette = AppColorPalettes.midnightBlack;
      expect(palette.isOledBlack, isTrue);
      expect(palette.darkScaffold, equals(const Color(0xFF000000)));
      expect(palette.darkSurface, equals(const Color(0xFF0D0D0D)));
      expect(palette.darkScheme.primary, equals(const Color(0xFF00E5FF)));
      expect(palette.darkScheme.secondary, equals(const Color(0xFF76FF03)));
      expect(palette.lightScaffold, equals(const Color(0xFFF5F5F7)));
    });

    test('Deep Space dark scaffold is #0B0F19 with indigo #6366F1', () {
      const palette = AppColorPalettes.deepSpace;
      expect(palette.isOledBlack, isFalse);
      expect(palette.darkScaffold, equals(const Color(0xFF0B0F19)));
      expect(palette.darkSurface, equals(const Color(0xFF131B2E)));
      expect(palette.darkScheme.primary, equals(const Color(0xFF6366F1)));
      expect(palette.lightScaffold, equals(const Color(0xFFF0F4FA)));
    });

    test('Sakura dark and light scaffolds match specification', () {
      const palette = AppColorPalettes.sakura;
      expect(palette.darkScaffold, equals(const Color(0xFF1F0B12)));
      expect(palette.lightScaffold, equals(const Color(0xFFFFF5F7)));
      expect(palette.darkScheme.primary, equals(const Color(0xFFE91E63)));
      expect(palette.darkScheme.secondary, equals(const Color(0xFFFF80AB)));
    });

    test('Ocean Blue dark scaffold is #0B192C with azure waves primary #00B4D8', () {
      const palette = AppColorPalettes.oceanBlue;
      expect(palette.darkScaffold, equals(const Color(0xFF0B192C)));
      expect(palette.darkSurface, equals(const Color(0xFF1E3E62)));
      expect(palette.darkScheme.primary, equals(const Color(0xFF00B4D8)));
      expect(palette.lightScaffold, equals(const Color(0xFFF0F9FF)));
    });

    test('Forest Green dark scaffold is #0B170E with neon canopy #00E676', () {
      const palette = AppColorPalettes.forestGreen;
      expect(palette.darkScaffold, equals(const Color(0xFF0B170E)));
      expect(palette.darkSurface, equals(const Color(0xFF14291A)));
      expect(palette.darkScheme.primary, equals(const Color(0xFF00E676)));
      expect(palette.lightScaffold, equals(const Color(0xFFF2FBF5)));
    });

    test('Lava dark scaffold is #150806 with molten blaze #FF3D00', () {
      const palette = AppColorPalettes.lava;
      expect(palette.darkScaffold, equals(const Color(0xFF150806)));
      expect(palette.darkSurface, equals(const Color(0xFF29100C)));
      expect(palette.darkScheme.primary, equals(const Color(0xFFFF3D00)));
      expect(palette.lightScaffold, equals(const Color(0xFFFFF7F5)));
    });

    test('Daylight light scaffold is #F8FAFC with royal blue primary #2563EB', () {
      const palette = AppColorPalettes.daylight;
      expect(palette.darkScaffold, equals(const Color(0xFF0F172A)));
      expect(palette.lightScaffold, equals(const Color(0xFFF8FAFC)));
      expect(palette.lightScheme.primary, equals(const Color(0xFF2563EB)));
      expect(palette.lightScheme.secondary, equals(const Color(0xFF0D9488)));
    });

    test('Neon Purple dark scaffold is #0F071A with fuchsia #D946EF', () {
      const palette = AppColorPalettes.neonPurple;
      expect(palette.darkScaffold, equals(const Color(0xFF0F071A)));
      expect(palette.darkSurface, equals(const Color(0xFF1D1133)));
      expect(palette.darkScheme.primary, equals(const Color(0xFFD946EF)));
      expect(palette.lightScaffold, equals(const Color(0xFFFAF5FF)));
    });

    test('toFlexSchemeData returns valid paired scheme for all presets', () {
      for (final palette in AppColorPalettes.all) {
        final schemeData = palette.toFlexSchemeData();
        expect(schemeData.name, equals(palette.name));
        expect(schemeData.light.primary, equals(palette.lightScheme.primary));
        expect(schemeData.dark.primary, equals(palette.darkScheme.primary));
      }
    });

    test('scaffoldBackground, surfaceColor, cardColor, and primaryColor resolve correctly by Brightness', () {
      const palette = AppColorPalettes.midnightBlack;
      expect(palette.scaffoldBackground(Brightness.dark), equals(palette.darkScaffold));
      expect(palette.scaffoldBackground(Brightness.light), equals(palette.lightScaffold));
      expect(palette.surfaceColor(Brightness.dark), equals(palette.darkSurface));
      expect(palette.surfaceColor(Brightness.light), equals(palette.lightSurface));
      expect(palette.cardColor(Brightness.dark), equals(palette.darkCard));
      expect(palette.cardColor(Brightness.light), equals(palette.lightCard));
      expect(palette.primaryColor(Brightness.dark), equals(palette.darkScheme.primary));
      expect(palette.primaryColor(Brightness.light), equals(palette.lightScheme.primary));
    });

    test('ThemePreset.fromString safely handles unknown, empty, case variations, and null', () {
      expect(ThemePreset.fromString(null), equals(ThemePreset.midnightBlack));
      expect(ThemePreset.fromString(''), equals(ThemePreset.midnightBlack));
      expect(ThemePreset.fromString('   '), equals(ThemePreset.midnightBlack));
      expect(ThemePreset.fromString('invalid_preset'), equals(ThemePreset.midnightBlack));
      expect(ThemePreset.fromString('oceanBlue'), equals(ThemePreset.oceanBlue));
      expect(ThemePreset.fromString('OCEANBLUE'), equals(ThemePreset.oceanBlue));
      expect(ThemePreset.fromString('midnightBlack'), equals(ThemePreset.midnightBlack));
      expect(ThemePreset.fromString('sakura'), equals(ThemePreset.sakura));
      expect(ThemePreset.fromString('custom'), equals(ThemePreset.custom));
    });

    test('All presets have distinct user-facing display names', () {
      final names = ThemePreset.values.map((p) => p.displayName).toSet();
      expect(names.length, equals(ThemePreset.values.length));
    });
  });
}
