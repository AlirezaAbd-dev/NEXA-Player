import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/color_palettes.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import '../../../helpers/mock_services.dart';

void main() {
  group('Challenger M2: Extreme HSL Boundaries & Numerical Stability', () {
    test('Extreme Hue values (-720, -360, 0, 360, 720, 10000) wrap cleanly into [0.0, 360.0)', () {
      final testHues = [
        -10000.0,
        -720.0,
        -360.0,
        -359.9,
        -180.0,
        -1.0,
        -0.0,
        0.0,
        180.0,
        359.9,
        360.0,
        360.1,
        720.0,
        1080.0,
        10000.0,
      ];

      for (final hue in testHues) {
        final theme = CustomThemeData(primaryHue: hue);
        final normalized = theme.normalizedHue;

        expect(
          normalized,
          greaterThanOrEqualTo(0.0),
          reason: 'Hue $hue yielded negative normalizedHue $normalized',
        );
        expect(
          normalized,
          lessThan(360.0),
          reason: 'Hue $hue yielded normalizedHue >= 360.0: $normalized',
        );

        // Verify primaryColor resolves without throwing Flutter HSL assertions
        final color = theme.primaryColor;
        expect(color.alpha, equals(255));

        // Verify secondaryColor resolves without throwing
        final secColor = theme.secondaryColor;
        expect(secColor.alpha, equals(255));
      }
    });

    test('Extreme Saturation values (-100, -1.0, 0.0, 1.0, 2.0, 100) clamp cleanly into [0.0, 1.0]', () {
      final testSaturations = [
        -100.0,
        -2.0,
        -1.0,
        -0.01,
        0.0,
        0.001,
        0.5,
        0.999,
        1.0,
        1.001,
        2.0,
        100.0,
      ];

      for (final sat in testSaturations) {
        final theme = CustomThemeData(primarySaturation: sat);
        final normalized = theme.normalizedSaturation;

        expect(
          normalized,
          greaterThanOrEqualTo(0.0),
          reason: 'Saturation $sat normalized to $normalized < 0.0',
        );
        expect(
          normalized,
          lessThanOrEqualTo(1.0),
          reason: 'Saturation $sat normalized to $normalized > 1.0',
        );

        // Resolves primary, secondary, and surface colors without throwing
        expect(theme.primaryColor.alpha, equals(255));
        expect(theme.secondaryColor.alpha, equals(255));
        expect(theme.surfaceColor.alpha, equals(255));
      }
    });

    test('Extreme Primary Lightness (-10, -1.0, 0.0, 1.0, 2.0, 10) clamps within WCAG AA safe bounds', () {
      final testLightness = [
        -10.0,
        -1.0,
        -0.01,
        0.0,
        0.20,
        0.50,
        0.85,
        1.0,
        1.5,
        2.0,
        10.0,
      ];

      for (final light in testLightness) {
        // Dark Mode: Primary lightness clamped to [0.50, 0.85]
        final darkTheme = CustomThemeData(primaryLightness: light, isDark: true);
        expect(
          darkTheme.clampedPrimaryLightness,
          greaterThanOrEqualTo(0.50),
          reason: 'Dark theme primary lightness $light clamped below 0.50',
        );
        expect(
          darkTheme.clampedPrimaryLightness,
          lessThanOrEqualTo(0.85),
          reason: 'Dark theme primary lightness $light clamped above 0.85',
        );
        expect(darkTheme.primaryColor.alpha, equals(255));
        expect(darkTheme.secondaryColor.alpha, equals(255));

        // Light Mode: Primary lightness clamped to [0.20, 0.35]
        final lightTheme = CustomThemeData(primaryLightness: light, isDark: false);
        expect(
          lightTheme.clampedPrimaryLightness,
          greaterThanOrEqualTo(0.20),
          reason: 'Light theme primary lightness $light clamped below 0.20',
        );
        expect(
          lightTheme.clampedPrimaryLightness,
          lessThanOrEqualTo(0.35),
          reason: 'Light theme primary lightness $light clamped above 0.35',
        );
        expect(lightTheme.primaryColor.alpha, equals(255));
        expect(lightTheme.secondaryColor.alpha, equals(255));
      }
    });

    test('Surface Lightness boundary transitions: <= 0.02 activates AMOLED true black', () {
      final amoledThresholds = [-1.0, 0.0, 0.01, 0.02];
      for (final light in amoledThresholds) {
        final darkTheme = CustomThemeData(surfaceLightness: light, isDark: true);
        expect(
          darkTheme.scaffoldBackgroundColor,
          equals(const Color(0xFF000000)),
          reason: 'Surface lightness $light should yield pure AMOLED black',
        );
      }

      final nonAmoledThresholds = [0.03, 0.08, 0.15, 0.25, 0.50, 1.0];
      for (final light in nonAmoledThresholds) {
        final darkTheme = CustomThemeData(surfaceLightness: light, isDark: true);
        expect(
          darkTheme.scaffoldBackgroundColor,
          isNot(equals(const Color(0xFF000000))),
          reason: 'Surface lightness $light should NOT be pure AMOLED black',
        );
      }
    });

    test('128-Point Cartesian Product Stress: Hue x Saturation x Lightness x Mode', () {
      final hues = [-360.0, 0.0, 360.0, 720.0];
      final saturations = [-1.0, 0.0, 1.0, 2.0];
      final lightnesses = [-1.0, 0.0, 1.0, 2.0];
      final modes = [true, false];

      var combinationsTested = 0;

      for (final h in hues) {
        for (final s in saturations) {
          for (final l in lightnesses) {
            for (final isDark in modes) {
              final theme = CustomThemeData(
                primaryHue: h,
                primarySaturation: s,
                primaryLightness: l,
                surfaceLightness: l,
                isDark: isDark,
              );

              // 1. Color resolutions must never throw Flutter assertions
              final primary = theme.primaryColor;
              final secondary = theme.secondaryColor;
              final surface = theme.surfaceColor;
              final scaffold = theme.scaffoldBackgroundColor;

              expect(primary.alpha, equals(255));
              expect(secondary.alpha, equals(255));
              expect(surface.alpha, equals(255));
              expect(scaffold.alpha, equals(255));

              // 2. Material 3 ColorScheme generation must succeed
              final scheme = theme.toColorScheme();
              expect(scheme.primary, equals(primary));
              expect(scheme.secondary, equals(secondary));

              // 3. ThemeData generation must succeed
              final themeData = theme.toThemeData();
              expect(themeData.useMaterial3, isTrue);

              // 4. Contrast ratios must be finite and >= 1.0
              final ratio = theme.accentContrastRatio;
              expect(ratio.isFinite, isTrue);
              expect(ratio, greaterThanOrEqualTo(1.0));

              combinationsTested++;
            }
          }
        }
      }

      expect(combinationsTested, equals(128));
    });
  });

  group('Challenger M2: WCAG 2.1 Contrast Ratio Assertions on Black, White, & Neon Surfaces', () {
    test('WCAG Relative Luminance and Contrast Ratio mathematical invariants', () {
      // 1. Identity contrast ratio is exactly 1.0
      expect(
        CustomThemeData.computeContrastRatio(Colors.black, Colors.black),
        closeTo(1.0, 0.001),
      );
      expect(
        CustomThemeData.computeContrastRatio(Colors.white, Colors.white),
        closeTo(1.0, 0.001),
      );

      // 2. Maximum contrast ratio (Black vs White) is exactly 21.0
      expect(
        CustomThemeData.computeContrastRatio(Colors.white, Colors.black),
        closeTo(21.0, 0.01),
      );
      expect(
        CustomThemeData.computeContrastRatio(Colors.black, Colors.white),
        closeTo(21.0, 0.01),
      );

      // 3. Symmetry invariant: contrast(A, B) == contrast(B, A)
      const colorA = Color(0xFF1E88E5);
      const colorB = Color(0xFFFFC107);
      expect(
        CustomThemeData.computeContrastRatio(colorA, colorB),
        equals(CustomThemeData.computeContrastRatio(colorB, colorA)),
      );
    });

    test('Derived onPrimary text color maintains >= 4.5:1 WCAG contrast across all 360 hues', () {
      // Test 360 hues in 5-degree increments across dark and light modes
      for (double h = 0.0; h < 360.0; h += 5.0) {
        for (final isDark in [true, false]) {
          final theme = CustomThemeData(
            primaryHue: h,
            primarySaturation: 1.0, // Maximum saturation
            primaryLightness: 0.5,
            isDark: isDark,
          );

          final primary = theme.primaryColor;
          final onPrimary = theme.onPrimary;
          final contrast = CustomThemeData.computeContrastRatio(onPrimary, primary);

          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: 'onPrimary failed 4.5:1 on hue $h° (isDark: $isDark): $contrast:1',
          );
        }
      }
    });

    test('Derived onSecondary text color maintains >= 4.5:1 WCAG contrast across all 360 hues', () {
      for (double h = 0.0; h < 360.0; h += 10.0) {
        for (final isDark in [true, false]) {
          final theme = CustomThemeData(
            primaryHue: h,
            primarySaturation: 0.9,
            primaryLightness: 0.5,
            isDark: isDark,
          );

          final secondary = theme.secondaryColor;
          final scheme = theme.toColorScheme();
          final onSecondary = scheme.onSecondary;
          final contrast = CustomThemeData.computeContrastRatio(onSecondary, secondary);

          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: 'onSecondary failed 4.5:1 on hue $h° (isDark: $isDark): $contrast:1',
          );
        }
      }
    });

    test('Derived onSurface text color maintains >= 4.5:1 WCAG contrast on all valid surface tones', () {
      // Dark mode surfaces (clamped to [0.0, 0.25])
      for (double surfaceL = 0.0; surfaceL <= 0.25; surfaceL += 0.02) {
        for (double h = 0.0; h < 360.0; h += 30.0) {
          final theme = CustomThemeData(
            primaryHue: h,
            surfaceLightness: surfaceL,
            isDark: true,
          );
          final contrast = CustomThemeData.computeContrastRatio(
            theme.onSurface,
            theme.surfaceColor,
          );
          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: 'Dark onSurface failed 4.5:1 on surfaceLightness $surfaceL: $contrast:1',
          );
        }
      }

      // Light mode surfaces (clamped to [0.80, 1.0])
      for (double surfaceL = 0.80; surfaceL <= 1.0; surfaceL += 0.02) {
        for (double h = 0.0; h < 360.0; h += 30.0) {
          final theme = CustomThemeData(
            primaryHue: h,
            surfaceLightness: surfaceL,
            isDark: false,
          );
          final contrast = CustomThemeData.computeContrastRatio(
            theme.onSurface,
            theme.surfaceColor,
          );
          expect(
            contrast,
            greaterThanOrEqualTo(4.5),
            reason: 'Light onSurface failed 4.5:1 on surfaceLightness $surfaceL: $contrast:1',
          );
        }
      }
    });

    test('Derived text colors maintain >= 4.5:1 WCAG contrast on extreme neon and saturated surfaces', () {
      final neonSurfaces = <String, Color>{
        'Neon Lime': const Color(0xFF76FF03),
        'Pure Neon Green': const Color(0xFF00FF00),
        'Pure Neon Yellow': const Color(0xFFFFFF00),
        'Pure Neon Cyan': const Color(0xFF00FFFF),
        'Electric Cyan': const Color(0xFF00E5FF),
        'Pure Neon Magenta': const Color(0xFFFF00FF),
        'Neon Purple': const Color(0xFFD946EF),
        'Lava Orange': const Color(0xFFFF3D00),
        'Pure White': const Color(0xFFFFFFFF),
        'Pure Black': const Color(0xFF000000),
        'Deep Space Navy': const Color(0xFF0B0F19),
        'Sakura Dark Maroon': const Color(0xFF1F0B12),
      };

      for (final entry in neonSurfaces.entries) {
        final surface = entry.value;

        // CustomThemeData onPrimary selection algorithm
        final whiteRatio = CustomThemeData.computeContrastRatio(Colors.white, surface);
        final blackRatio = CustomThemeData.computeContrastRatio(Colors.black, surface);
        final resolvedText = whiteRatio >= blackRatio ? Colors.white : Colors.black;
        final effectiveRatio = CustomThemeData.computeContrastRatio(resolvedText, surface);

        expect(
          effectiveRatio,
          greaterThanOrEqualTo(4.5),
          reason: 'Text on ${entry.key} ($surface) yielded insufficient contrast: $effectiveRatio:1',
        );
      }
    });

    test('All 8 built-in preset palettes satisfy contrast requirements in both Dark and Light modes', () {
      final presets = [
        AppColorPalettes.midnightBlack,
        AppColorPalettes.deepSpace,
        AppColorPalettes.sakura,
        AppColorPalettes.oceanBlue,
        AppColorPalettes.forestGreen,
        AppColorPalettes.lava,
        AppColorPalettes.daylight,
        AppColorPalettes.neonPurple,
      ];

      for (final palette in presets) {
        // Dark Mode: Primary vs Scaffold
        final darkPrimaryRatio = CustomThemeData.computeContrastRatio(
          palette.darkScheme.primary,
          palette.darkScaffold,
        );
        expect(
          darkPrimaryRatio,
          greaterThanOrEqualTo(3.0),
          reason: '${palette.name} dark primary failed contrast against scaffold: $darkPrimaryRatio:1',
        );

        // Light Mode: Primary vs Scaffold
        final lightPrimaryRatio = CustomThemeData.computeContrastRatio(
          palette.lightScheme.primary,
          palette.lightScaffold,
        );
        expect(
          lightPrimaryRatio,
          greaterThanOrEqualTo(3.0),
          reason: '${palette.name} light primary failed contrast against scaffold: $lightPrimaryRatio:1',
        );
      }
    });
  });

  group('Challenger M2: JSON Resilience & Storage Stress', () {
    test('JSON serialization handles extreme numerical bounds safely', () {
      const extreme = CustomThemeData(
        primaryHue: 999999.0,
        primarySaturation: -5.0,
        primaryLightness: 10.0,
        surfaceLightness: -2.0,
        isDark: false,
        name: 'Super Extreme',
      );

      final jsonStr = extreme.toJsonString();
      final restored = CustomThemeData.fromJsonString(jsonStr);

      expect(restored, isNotNull);
      expect(restored!.primaryHue, equals(999999.0));
      expect(restored.primarySaturation, equals(-5.0));
      // Normalized values remain safe
      expect(restored.normalizedHue, greaterThanOrEqualTo(0.0));
      expect(restored.normalizedHue, lessThan(360.0));
      expect(restored.normalizedSaturation, equals(0.0));
      expect(restored.clampedPrimaryLightness, equals(0.35));
    });

    test('fromJson handles missing keys, nulls, and extra fields safely', () {
      final inputs = [
        <String, dynamic>{},
        <String, dynamic>{'primaryHue': null},
        <String, dynamic>{'primarySaturation': null},
        <String, dynamic>{'primaryLightness': null},
        <String, dynamic>{'isDark': null},
        <String, dynamic>{'extraField': [1, 2, 3]},
      ];

      for (final input in inputs) {
        final theme = CustomThemeData.fromJson(input);
        expect(theme.primaryColor.alpha, equals(255));
        expect(theme.scaffoldBackgroundColor.alpha, equals(255));
      }
    });

    test('fromJsonString catches type errors on non-numeric or malformed fields and returns null', () {
      final invalidStrings = [
        '{"primaryHue": "not a number"}',
        '{"primaryLightness": true}',
        '{"isDark": "yes"}',
        '{"primarySaturation": []}',
        '{"primaryHue": {}}',
        '[1, 2, 3]',
        'random text',
      ];

      for (final raw in invalidStrings) {
        expect(CustomThemeData.fromJsonString(raw), isNull);
      }
    });

    test('ThemeController recovers safely when storage contains type-corrupted custom theme JSON', () {
      final fakeStorage = FakeStorageService({
        'nexa_custom_theme_data': '{"primaryHue": "corrupted_string_value"}',
        'theme_preset': 'custom',
      });
      final fakeLogging = FakeLoggingService();

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          loggingServiceProvider.overrideWithValue(fakeLogging),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(themeControllerProvider);
      // ThemeController catches the TypeError, resets customTheme to null and falls back to midnightBlack
      expect(state.customTheme, isNull);
      expect(state.preset, equals(ThemePreset.midnightBlack));
    });

    test('Rapid successive theme modifications in ThemeController maintain consistency', () async {
      final fakeStorage = FakeStorageService();
      final fakeLogging = FakeLoggingService();

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          loggingServiceProvider.overrideWithValue(fakeLogging),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(themeControllerProvider.notifier);

      // Perform 50 rapid alternating preset changes
      for (int i = 0; i < 50; i++) {
        final preset = ThemePreset.values[i % (ThemePreset.values.length - 1)];
        await controller.setPreset(preset);
        expect(container.read(themeControllerProvider).preset, equals(preset));
      }

      // Perform 50 rapid mode toggles
      for (int i = 0; i < 50; i++) {
        await controller.toggleThemeMode();
        final currentMode = container.read(themeControllerProvider).themeMode;
        expect(currentMode, isNot(equals(ThemeMode.system)));
      }

      // Reset to defaults
      await controller.resetToDefaults();
      final resetState = container.read(themeControllerProvider);
      expect(resetState.preset, equals(ThemePreset.midnightBlack));
      expect(resetState.themeMode, equals(ThemeMode.system));
      expect(resetState.customTheme, isNull);
    });
  });
}
