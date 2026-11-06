import 'package:flutter/material.dart';

/// Centralized Material 3 Typography tokens for NEXA Player.
abstract final class AppTypography {
  // Display styles (Now Playing track title, large banners)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32.0,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 26.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.25,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  // Headline styles (Section headers, screen headers)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.3,
  );

  // Title styles (List item primary text, card titles, app bar titles)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.0,
    height: 1.35,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 13.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.4,
  );

  // Body styles (Metadata, timestamps, lyrics, descriptions)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.15,
    height: 1.45,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
  );

  // Label styles (Buttons, chips, tags, navigation items)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.4,
    height: 1.3,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.3,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 10.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.2,
  );

  /// Generates a comprehensive Material 3 [TextTheme] based on these tokens.
  static TextTheme createTextTheme([Color? textColor]) {
    final base = textColor != null
        ? TextTheme(
            displayLarge: displayLarge.copyWith(color: textColor),
            displayMedium: displayMedium.copyWith(color: textColor),
            displaySmall: displaySmall.copyWith(color: textColor),
            headlineLarge: headlineLarge.copyWith(color: textColor),
            headlineMedium: headlineMedium.copyWith(color: textColor),
            headlineSmall: headlineSmall.copyWith(color: textColor),
            titleLarge: titleLarge.copyWith(color: textColor),
            titleMedium: titleMedium.copyWith(color: textColor),
            titleSmall: titleSmall.copyWith(color: textColor),
            bodyLarge: bodyLarge.copyWith(color: textColor),
            bodyMedium: bodyMedium.copyWith(color: textColor),
            bodySmall: bodySmall.copyWith(color: textColor),
            labelLarge: labelLarge.copyWith(color: textColor),
            labelMedium: labelMedium.copyWith(color: textColor),
            labelSmall: labelSmall.copyWith(color: textColor),
          )
        : const TextTheme(
            displayLarge: displayLarge,
            displayMedium: displayMedium,
            displaySmall: displaySmall,
            headlineLarge: headlineLarge,
            headlineMedium: headlineMedium,
            headlineSmall: headlineSmall,
            titleLarge: titleLarge,
            titleMedium: titleMedium,
            titleSmall: titleSmall,
            bodyLarge: bodyLarge,
            bodyMedium: bodyMedium,
            bodySmall: bodySmall,
            labelLarge: labelLarge,
            labelMedium: labelMedium,
            labelSmall: labelSmall,
          );
    return base;
  }
}
