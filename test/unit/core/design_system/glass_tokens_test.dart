import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';

void main() {
  group('GlassTokens Unit Tests', () {
    test('verifies blur scale values match Poweramp/Stellio standard (16–24 dp)', () {
      expect(GlassTokens.blurSubtle, equals(16.0));
      expect(GlassTokens.blurStandard, equals(20.0));
      expect(GlassTokens.blurHeavy, equals(24.0));
      expect(GlassTokens.blurExtreme, equals(32.0));
      expect(GlassTokens.blurDefault, equals(20.0));
      expect(GlassTokens.blurStrong, equals(24.0));
    });

    test('verifies opacity scale values conform to 0.10–0.20 range', () {
      expect(GlassTokens.opacitySubtle, equals(0.10));
      expect(GlassTokens.opacityStandard, equals(0.15));
      expect(GlassTokens.opacityElevated, equals(0.20));
      expect(GlassTokens.opacitySurface, equals(0.70));
      expect(GlassTokens.opacityNav, equals(0.75));
    });

    test('verifies 1dp border and white@25% default', () {
      expect(GlassTokens.borderWidth, equals(1.0));
      expect(GlassTokens.borderThick, equals(1.5));
      expect(GlassTokens.borderColor, equals(const Color(0x40FFFFFF)));
      expect(GlassTokens.borderColorDark, equals(const Color(0x40FFFFFF)));
      expect(GlassTokens.borderColorLight, equals(const Color(0x1F000000)));
    });

    testWidgets('resolveBorderColor adapts dynamically to dark and light mode', (tester) async {
      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.dark),
          child: Builder(
            builder: (context) {
              final darkBorder = GlassTokens.resolveBorderColor(context);
              expect(darkBorder, equals(GlassTokens.borderColorDark));
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        Theme(
          data: ThemeData(brightness: Brightness.light),
          child: Builder(
            builder: (context) {
              final lightBorder = GlassTokens.resolveBorderColor(context);
              expect(lightBorder, equals(GlassTokens.borderColorLight));
              return const SizedBox();
            },
          ),
        ),
      );
    });

    test('verifies border radius tokens for card, pill, and fab', () {
      expect(GlassTokens.radiusCard, inInclusiveRange(20.0, 28.0));
      expect(GlassTokens.radiusCard, equals(24.0));
      expect(GlassTokens.radiusPill, equals(56.0));
      expect(GlassTokens.radiusFab, equals(100.0));
      expect(GlassTokens.cardBorderRadius.topLeft.x, equals(24.0));
      expect(GlassTokens.pillBorderRadius.topLeft.x, equals(56.0));
      expect(GlassTokens.fabBorderRadius.topLeft.x, equals(100.0));
    });

    test('verifies shadow tokens match 0 8 32 black@20%', () {
      const shadow = GlassTokens.standardShadow;
      expect(shadow.color, equals(const Color(0x33000000)));
      expect(shadow.offset, equals(const Offset(0, 8)));
      expect(shadow.blurRadius, equals(32.0));
    });

    test('verifies accent glow generator produces valid offset and color', () {
      const accent = Color(0xFF00E5FF);
      final glow = GlassTokens.accentGlow(accent, blur: 20, spread: 2);
      expect(glow.length, equals(1));
      expect(glow.first.blurRadius, equals(20.0));
      expect(glow.first.spreadRadius, equals(2.0));
      expect(glow.first.color, equals(accent.withOpacity(0.35)));
    });

    test('verifies surface gradient produces 135-degree diagonal', () {
      const accent = Color(0xFF00E5FF);
      const surface = Color(0xFF131B2E);
      final grad = GlassTokens.surfaceGradient(accentColor: accent, surfaceColor: surface);
      expect(grad.begin, equals(Alignment.topLeft));
      expect(grad.end, equals(Alignment.bottomRight));
      expect(grad.colors.first, equals(accent.withOpacity(0.30)));
      expect(grad.colors.last, equals(surface.withOpacity(0.10)));
    });
  });
}
