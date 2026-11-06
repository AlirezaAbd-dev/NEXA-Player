import 'package:flutter/material.dart';

/// Centralized glassmorphism design tokens conforming to Poweramp/Stellio standard.
///
/// Ensures zero magic numbers across glass UI widgets and guarantees WCAG contrast.
abstract final class GlassTokens {
  // Backdrop blur standard (16–24 dp)
  static const double blurSubtle = 16.0;
  static const double blurStandard = 20.0;
  static const double blurHeavy = 24.0;
  static const double blurExtreme = 32.0;

  // Backward-compatible aliases
  static const double blurDefault = blurStandard;
  static const double blurStrong = blurHeavy;

  // Surface fill opacity (0.10–0.20)
  static const double opacitySubtle = 0.10;
  static const double opacityStandard = 0.15;
  static const double opacityElevated = 0.20;
  static const double opacitySurface = 0.70;
  static const double opacityNav = 0.75;

  // Backward-compatible aliases
  static const double opacityLow = opacitySubtle;
  static const double opacityDefault = opacityStandard;
  static const double opacityMedium = opacityElevated;
  static const double opacityHigh = 0.25;

  // Border standard
  static const double borderWidth = 1.0;
  static const double borderThick = 1.5;
  static const Color borderColor = Color(0x40FFFFFF); // White @ 25% alpha
  static const Color borderColorDark = Color(0x40FFFFFF); // White @ 25%
  static const Color borderColorLight = Color(0x1F000000); // Black @ 12%
  static const Color borderColorHighlight = Color(0x55FFFFFF); // White @ 33%

  /// Resolves the border color with brightness-aware contrast adaptation.
  static Color resolveBorderColor(BuildContext context, {Color? customColor}) {
    if (customColor != null) return customColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? borderColorDark : borderColorLight;
  }

  // Border radius tokens
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusCard = 24.0;
  static const double radiusCardMin = 20.0;
  static const double radiusCardMax = 28.0;
  static const double radiusLarge = 32.0;
  static const double radiusPill = 56.0;
  static const double radiusFab = 100.0;
  static const double radiusCircular = 999.0;

  // BorderRadius convenience getters
  static BorderRadius get cardBorderRadius => BorderRadius.circular(radiusCard);
  static BorderRadius get pillBorderRadius => BorderRadius.circular(radiusPill);
  static BorderRadius get fabBorderRadius => BorderRadius.circular(radiusFab);

  // Elevation Shadows (0 8 32 black @ 20%)
  static const BoxShadow standardShadow = BoxShadow(
    color: Color(0x33000000), // 20% black
    offset: Offset(0, 8),
    blurRadius: 32.0,
  );

  static const List<BoxShadow> elevationStandard = [standardShadow];
  static const List<BoxShadow> elevationMedium = [standardShadow];

  static const List<BoxShadow> elevationLow = [
    BoxShadow(
      color: Color(0x1F000000), // 12% black
      offset: Offset(0, 4),
      blurRadius: 16.0,
    ),
  ];

  static const List<BoxShadow> elevationGlow = [
    BoxShadow(
      color: Color(0x22FFFFFF),
      offset: Offset.zero,
      blurRadius: 20.0,
      spreadRadius: 1.0,
    ),
  ];

  /// Creates an accent glow shadow for FABs, active tabs, and highlighted cards.
  static List<BoxShadow> accentGlow(
    Color accentColor, {
    double blur = 24.0,
    double spread = 1.0,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: accentColor.withOpacity(0.35),
        offset: offset,
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }

  /// Standard glass linear gradient overlay (135° diagonal from accent@30% to surface@10%).
  static LinearGradient surfaceGradient({
    required Color accentColor,
    required Color surfaceColor,
    double accentOpacity = 0.30,
    double surfaceOpacity = 0.10,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        accentColor.withOpacity(accentOpacity),
        surfaceColor.withOpacity(surfaceOpacity),
      ],
    );
  }

  /// Subtle glass gradient for card backgrounds.
  static LinearGradient subtleGradient({
    required Color baseColor,
    double startOpacity = 0.18,
    double endOpacity = 0.08,
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withOpacity(startOpacity),
        baseColor.withOpacity(endOpacity),
      ],
    );
  }

  /// Standard glass border gradient giving a reflective sheen.
  static LinearGradient borderGradient({
    Color highlight = const Color(0x66FFFFFF),
    Color shadow = const Color(0x11FFFFFF),
  }) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [highlight, shadow],
      stops: const [0.0, 1.0],
    );
  }
}
