import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/dynamic_palette_service.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/utils/contrast_validator.dart';

void main() {
  group('NexaSurfaceTokens Unit Tests', () {
    test('NexaSurfaceTokens.dark defaults conform to smooth dark slate L0-L4 specifications', () {
      final tokens = NexaSurfaceTokens.dark();

      expect(tokens.l0, equals(const Color(0xFF12141C)));
      expect(tokens.l1, equals(const Color(0xFF1A1D28)));
      expect(tokens.l2, equals(const Color(0xFF222634)));
      expect(tokens.l3, equals(const Color(0xFF2B3042)));
      expect(tokens.l4, equals(const Color(0xFF00E5FF)));

      // Verify WCAG AA contrast (>= 4.5:1) across all surface tiers
      expect(ContrastValidator.calculateContrastRatio(tokens.onL0, tokens.l0), greaterThanOrEqualTo(4.5));
      expect(ContrastValidator.calculateContrastRatio(tokens.onL1, tokens.l1), greaterThanOrEqualTo(4.5));
      expect(ContrastValidator.calculateContrastRatio(tokens.onL2, tokens.l2), greaterThanOrEqualTo(4.5));
      expect(ContrastValidator.calculateContrastRatio(tokens.onL3, tokens.l3), greaterThanOrEqualTo(4.5));
      expect(ContrastValidator.calculateContrastRatio(tokens.onL4, tokens.l4), greaterThanOrEqualTo(4.5));

      expect(tokens.onL0, isNotNull);
      expect(tokens.onL1, isNotNull);
      expect(tokens.onL2, isNotNull);
      expect(tokens.onL3, isNotNull);
      expect(tokens.onL4, isNotNull);

      expect(tokens.l3Shadow, isNotEmpty);
      expect(tokens.telemetryTextStyle.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('NexaSurfaceTokens.dark with seedTint blends subtle chroma into L2 and L3', () {
      const seedTint = Color(0xFFFF0055);
      final tokensWithTint = NexaSurfaceTokens.dark(seedTint: seedTint);
      final tokensWithoutTint = NexaSurfaceTokens.dark();

      expect(tokensWithTint.l2, isNot(equals(tokensWithoutTint.l2)));
      expect(tokensWithTint.l3, isNot(equals(tokensWithoutTint.l3)));
      // Canvas L0 and trough L1 remain neutral
      expect(tokensWithTint.l0, equals(tokensWithoutTint.l0));
      expect(tokensWithTint.l1, equals(tokensWithoutTint.l1));
    });

    test('NexaSurfaceTokens.light defaults conform to daylight specifications', () {
      final tokens = NexaSurfaceTokens.light();

      expect(tokens.l0, equals(const Color(0xFFF4F5F7)));
      expect(tokens.l1, equals(const Color(0xFFE8EAF0)));
      expect(tokens.l2, equals(const Color(0xFFFFFFFF)));
      expect(tokens.l3, equals(const Color(0xFFFFFFFF)));
      expect(tokens.l4, equals(const Color(0xFF007AFF)));

      expect(tokens.onL0, equals(const Color(0xFF1A1C22)));
      expect(tokens.l3Shadow, isNotEmpty);
    });

    test('NexaSurfaceTokens.pureBlack reserves pure #000000 canvas for Car and Standby modes', () {
      final tokens = NexaSurfaceTokens.pureBlack();

      expect(tokens.l0, equals(const Color(0xFF000000)));
      expect(tokens.l1, equals(const Color(0xFF0A0A0C)));
      expect(tokens.l2, equals(const Color(0xFF121216)));
      expect(tokens.l3, equals(const Color(0xFF1A1A20)));
      expect(tokens.l4, equals(const Color(0xFFFF3B30)));
    });

    test('colorForTier and textColorForTier correctly resolve every tier', () {
      final tokens = NexaSurfaceTokens.dark();

      expect(tokens.colorForTier(NexaSurfaceTier.l0), equals(tokens.l0));
      expect(tokens.colorForTier(NexaSurfaceTier.l1), equals(tokens.l1));
      expect(tokens.colorForTier(NexaSurfaceTier.l2), equals(tokens.l2));
      expect(tokens.colorForTier(NexaSurfaceTier.l3), equals(tokens.l3));
      expect(tokens.colorForTier(NexaSurfaceTier.l4), equals(tokens.l4));

      expect(tokens.textColorForTier(NexaSurfaceTier.l0), equals(tokens.onL0));
      expect(tokens.textColorForTier(NexaSurfaceTier.l1), equals(tokens.onL1));
      expect(tokens.textColorForTier(NexaSurfaceTier.l2), equals(tokens.onL2));
      expect(tokens.textColorForTier(NexaSurfaceTier.l3), equals(tokens.onL3));
      expect(tokens.textColorForTier(NexaSurfaceTier.l4), equals(tokens.onL4));
    });

    test('NexaSurfaceTokens.fromDynamicPalette generates valid tokens across dark and light', () {
      const palette = ExtractedPalette(
        dominant: Color(0xFF9C27B0),
        vibrant: Color(0xFFFF4081),
        muted: Color(0xFF4A148C),
        darkVibrant: Color(0xFF311B92),
        lightVibrant: Color(0xFFF48FB1),
      );

      final darkTokens = NexaSurfaceTokens.fromDynamicPalette(
        palette,
        brightness: Brightness.dark,
      );
      expect(darkTokens.l4, equals(palette.vibrant));
      expect(darkTokens.l0, equals(const Color(0xFF12141C)));

      final lightTokens = NexaSurfaceTokens.fromDynamicPalette(
        palette,
        brightness: Brightness.light,
      );
      expect(lightTokens.l4, equals(palette.vibrant));
      expect(lightTokens.l0, equals(const Color(0xFFF4F5F7)));

      final oledTokens = NexaSurfaceTokens.fromDynamicPalette(
        palette,
        brightness: Brightness.dark,
        isOledBlack: true,
      );
      expect(oledTokens.l0, equals(const Color(0xFF000000)));
    });

    test('lerp interpolates cleanly between dark and light surface tokens', () {
      final darkTokens = NexaSurfaceTokens.dark();
      final lightTokens = NexaSurfaceTokens.light();

      final midway = darkTokens.lerp(lightTokens, 0.5);
      expect(midway.l0, equals(Color.lerp(darkTokens.l0, lightTokens.l0, 0.5)));
      expect(midway.l4, equals(Color.lerp(darkTokens.l4, lightTokens.l4, 0.5)));
    });

    test('all 8 preset themes instantiate ThemeData containing NexaSurfaceTokens without null assertions', () {
      for (final preset in ThemePreset.values) {
        if (preset == ThemePreset.custom) continue;

        // Dark theme instantiation
        final darkTheme = AppTheme.dark(preset: preset);
        final darkTokens = darkTheme.extension<NexaSurfaceTokens>();
        expect(darkTokens, isNotNull, reason: 'Failed for dark preset ${preset.name}');
        expect(darkTokens!.l0, isNotNull);
        expect(darkTokens.l4, isNotNull);
        expect(darkTokens.telemetryTextStyle.fontFeatures, contains(const FontFeature.tabularFigures()));

        // Light theme instantiation
        final lightTheme = AppTheme.light(preset: preset);
        final lightTokens = lightTheme.extension<NexaSurfaceTokens>();
        expect(lightTokens, isNotNull, reason: 'Failed for light preset ${preset.name}');
        expect(lightTokens!.l0, isNotNull);
        expect(lightTokens.l4, isNotNull);
      }
    });

    test('custom HSL theme builds ThemeData containing NexaSurfaceTokens', () {
      const customPrimary = Color(0xFFE91E63);
      const customSurface = Color(0xFF1E1E28);
      const customBackground = Color(0xFF121218);

      final darkTheme = AppTheme.dark(
        preset: ThemePreset.custom,
        customPrimary: customPrimary,
        customSurface: customSurface,
        customBackground: customBackground,
      );

      final darkTokens = darkTheme.extension<NexaSurfaceTokens>();
      expect(darkTokens, isNotNull);
      expect(darkTokens!.l4, equals(customPrimary));

      final lightTheme = AppTheme.light(
        preset: ThemePreset.custom,
        customPrimary: customPrimary,
        customSurface: Colors.white,
        customBackground: const Color(0xFFF5F5F5),
      );

      final lightTokens = lightTheme.extension<NexaSurfaceTokens>();
      expect(lightTokens, isNotNull);
      expect(lightTokens!.l4, equals(customPrimary));
    });

    testWidgets('NexaSurfaceTokens.of and context.nexaSurfaces resolve in widget tree', (tester) async {
      final theme = AppTheme.dark(preset: ThemePreset.midnightBlack);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              final direct = NexaSurfaceTokens.of(context);
              final viaExtension = context.nexaSurfaces;

              expect(direct, isNotNull);
              expect(viaExtension, equals(direct));
              expect(viaExtension.l0, equals(const Color(0xFF000000))); // Midnight Black uses pure black
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
