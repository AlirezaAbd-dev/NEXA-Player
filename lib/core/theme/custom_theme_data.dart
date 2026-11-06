import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable representation of user-authored HSL theme parameters.
///
/// Implements automatic contrast clamping conforming to WCAG 2.1 AA
/// standards to prevent unreadable dark-on-dark or light-on-light color combinations.
class CustomThemeData extends Equatable {
  const CustomThemeData({
    this.primaryHue = 185.0,
    this.primarySaturation = 0.90,
    this.primaryLightness = 0.55,
    this.surfaceLightness = 0.08,
    this.isDark = true,
    this.name = 'Custom',
  });

  /// Primary color hue in degrees [0.0, 360.0).
  final double primaryHue;

  /// Primary color saturation [0.0, 1.0].
  final double primarySaturation;

  /// Primary color lightness [0.0, 1.0].
  final double primaryLightness;

  /// Surface background lightness [0.0, 1.0].
  final double surfaceLightness;

  /// Whether this custom theme targets dark mode or light mode.
  final bool isDark;

  /// Optional display name.
  final String name;

  /// Default dark custom theme preset (Electric Cyan accent on dark canvas).
  static const defaultDark = CustomThemeData(
    primaryHue: 185.0,
    primarySaturation: 0.90,
    primaryLightness: 0.55,
    surfaceLightness: 0.08,
    isDark: true,
    name: 'Custom Dark',
  );

  /// Default light custom theme preset (Royal Blue accent on crisp canvas).
  static const defaultLight = CustomThemeData(
    primaryHue: 215.0,
    primarySaturation: 0.85,
    primaryLightness: 0.45,
    surfaceLightness: 0.96,
    isDark: false,
    name: 'Custom Light',
  );

  /// Normalized hue wrapped into [0.0, 360.0).
  double get normalizedHue => (primaryHue % 360.0 + 360.0) % 360.0;

  /// Normalized saturation clamped into [0.0, 1.0].
  double get normalizedSaturation => primarySaturation.clamp(0.0, 1.0);

  /// Contrast-clamped primary lightness ensuring WCAG 3.0:1 visibility
  /// against [scaffoldBackgroundColor] across all 360 degrees of hue.
  ///
  /// In dark mode, starts with baseline clamp [0.50, 0.85] and dynamically
  /// increases lightness for low-luminance hues (e.g. deep blue ~240°) until
  /// contrast ratio >= 3.0:1 is reached.
  ///
  /// In light mode, starts with baseline clamp [0.20, 0.35] and dynamically
  /// decreases lightness for high-luminance hues (e.g. yellow ~60°) until
  /// contrast ratio >= 3.0:1 is reached.
  double get clampedPrimaryLightness {
    final raw = primaryLightness.clamp(0.0, 1.0);
    final bg = scaffoldBackgroundColor;

    if (isDark) {
      // Dark mode baseline clamp [0.50, 0.85]
      var candidate = raw.clamp(0.50, 0.85);
      var color = HSLColor.fromAHSL(
        1.0,
        normalizedHue,
        normalizedSaturation,
        candidate,
      ).toColor();

      // If contrast < 3.0 against dark background, increase lightness via bisection
      if (computeContrastRatio(color, bg) < 3.0) {
        var low = candidate;
        var high = 0.95;
        candidate = high;
        for (var i = 0; i < 8; i++) {
          final mid = (low + high) / 2.0;
          final testColor = HSLColor.fromAHSL(
            1.0,
            normalizedHue,
            normalizedSaturation,
            mid,
          ).toColor();
          if (computeContrastRatio(testColor, bg) >= 3.0) {
            candidate = mid;
            high = mid; // Dark mode: try lower lightness closer to requested
          } else {
            low = mid; // Need more brightness
          }
        }
      }
      return candidate;
    } else {
      // Light mode baseline clamp [0.20, 0.35]
      var candidate = raw.clamp(0.20, 0.35);
      var color = HSLColor.fromAHSL(
        1.0,
        normalizedHue,
        normalizedSaturation,
        candidate,
      ).toColor();

      // If contrast < 3.0 against light background, decrease lightness via bisection
      if (computeContrastRatio(color, bg) < 3.0) {
        var low = 0.05;
        var high = candidate;
        candidate = low;
        for (var i = 0; i < 8; i++) {
          final mid = (low + high) / 2.0;
          final testColor = HSLColor.fromAHSL(
            1.0,
            normalizedHue,
            normalizedSaturation,
            mid,
          ).toColor();
          if (computeContrastRatio(testColor, bg) >= 3.0) {
            candidate = mid;
            low = mid; // Light mode: dark enough, try higher lightness closer to requested
          } else {
            high = mid; // Too light, must go darker
          }
        }
      }
      return candidate;
    }
  }

  /// Contrast-clamped surface lightness.
  double get clampedSurfaceLightness {
    final raw = surfaceLightness.clamp(0.0, 1.0);
    return isDark ? raw.clamp(0.0, 0.25) : raw.clamp(0.80, 1.0);
  }

  /// Resolves the effective Primary accent color.
  Color get primaryColor {
    return HSLColor.fromAHSL(
      1.0,
      normalizedHue,
      normalizedSaturation,
      clampedPrimaryLightness,
    ).toColor();
  }

  /// Resolves an analogous Secondary accent color shifted by +35°.
  Color get secondaryColor {
    final secHue = (normalizedHue + 35.0) % 360.0;
    final secSat = (normalizedSaturation * 0.85).clamp(0.0, 1.0);
    final secLight = isDark
        ? (clampedPrimaryLightness * 0.9).clamp(0.30, 0.80)
        : (clampedPrimaryLightness * 1.1).clamp(0.25, 0.70);
    return HSLColor.fromAHSL(1.0, secHue, secSat, secLight).toColor();
  }

  /// Resolves the Surface color with subtle hue tinting.
  Color get surfaceColor {
    final surfSat = (normalizedSaturation * 0.12).clamp(0.0, 0.20);
    return HSLColor.fromAHSL(
      1.0,
      normalizedHue,
      surfSat,
      clampedSurfaceLightness,
    ).toColor();
  }

  /// Resolves the Scaffold background color (supports AMOLED black in dark mode).
  Color get scaffoldBackgroundColor {
    if (isDark) {
      if (clampedSurfaceLightness <= 0.02) {
        return const Color(0xFF000000); // Pure AMOLED Black
      }
      return HSLColor.fromAHSL(
        1.0,
        normalizedHue,
        (normalizedSaturation * 0.08).clamp(0.0, 0.15),
        (clampedSurfaceLightness * 0.6).clamp(0.0, 1.0),
      ).toColor();
    }
    return HSLColor.fromAHSL(
      1.0,
      normalizedHue,
      (normalizedSaturation * 0.05).clamp(0.0, 0.10),
      0.98,
    ).toColor();
  }

  /// Alias for scaffoldBackgroundColor.
  Color get backgroundColor => scaffoldBackgroundColor;

  /// Calculates WCAG 2.1 relative luminance for a given [Color].
  static double computeRelativeLuminance(Color color) {
    return color.computeLuminance();
  }

  /// Calculates WCAG contrast ratio between [foreground] and [background].
  static double computeContrastRatio(Color foreground, Color background) {
    final l1 = computeRelativeLuminance(foreground);
    final l2 = computeRelativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// High-contrast text/icon color atop [primaryColor].
  Color get onPrimary {
    final whiteRatio = computeContrastRatio(Colors.white, primaryColor);
    final blackRatio = computeContrastRatio(Colors.black, primaryColor);
    return whiteRatio >= blackRatio ? Colors.white : Colors.black;
  }

  /// High-contrast text/icon color atop [surfaceColor].
  Color get onSurface {
    return isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
  }

  /// High-contrast text/icon color atop [scaffoldBackgroundColor].
  Color get onBackground => onSurface;

  /// Current contrast ratio between [primaryColor] and [scaffoldBackgroundColor].
  double get accentContrastRatio {
    return computeContrastRatio(primaryColor, scaffoldBackgroundColor);
  }

  /// Produces a complete Material 3 [ColorScheme].
  ColorScheme toColorScheme() {
    final primary = primaryColor;
    final surface = surfaceColor;

    return ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: isDark
          ? HSLColor.fromColor(primary).withLightness(0.25).toColor()
          : HSLColor.fromColor(primary).withLightness(0.90).toColor(),
      onPrimaryContainer: isDark
          ? HSLColor.fromColor(primary).withLightness(0.90).toColor()
          : HSLColor.fromColor(primary).withLightness(0.15).toColor(),
      secondary: secondaryColor,
      onSecondary: computeContrastRatio(Colors.white, secondaryColor) >= 4.5
          ? Colors.white
          : Colors.black,
      surface: surface,
      onSurface: onSurface,
      error: isDark ? const Color(0xFFCF6679) : const Color(0xFFB00020),
      onError: isDark ? Colors.black : Colors.white,
    );
  }

  /// Produces a complete Material 3 [ThemeData].
  ThemeData toThemeData() {
    final scheme = toColorScheme();
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
    );
  }

  /// Serializes instance to a JSON Map.
  Map<String, dynamic> toJson() => {
        'primaryHue': primaryHue,
        'primarySaturation': primarySaturation,
        'primaryLightness': primaryLightness,
        'surfaceLightness': surfaceLightness,
        'isDark': isDark,
        'name': name,
      };

  /// Serializes instance to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Safely deserializes from a JSON Map with resilient fallback defaults.
  factory CustomThemeData.fromJson(Map<String, dynamic> json) {
    return CustomThemeData(
      primaryHue: (json['primaryHue'] as num?)?.toDouble() ?? 185.0,
      primarySaturation: (json['primarySaturation'] as num?)?.toDouble() ?? 0.90,
      primaryLightness: (json['primaryLightness'] as num?)?.toDouble() ?? 0.55,
      surfaceLightness: (json['surfaceLightness'] as num?)?.toDouble() ?? 0.08,
      isDark: json['isDark'] as bool? ?? true,
      name: json['name'] as String? ?? 'Custom',
    );
  }

  /// Safely deserializes from a JSON String.
  static CustomThemeData? fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return CustomThemeData.fromJson(decoded);
      }
    } catch (_) {
      // Graceful fallback for corrupted data
    }
    return null;
  }

  CustomThemeData copyWith({
    double? primaryHue,
    double? primarySaturation,
    double? primaryLightness,
    double? surfaceLightness,
    bool? isDark,
    String? name,
  }) {
    return CustomThemeData(
      primaryHue: primaryHue ?? this.primaryHue,
      primarySaturation: primarySaturation ?? this.primarySaturation,
      primaryLightness: primaryLightness ?? this.primaryLightness,
      surfaceLightness: surfaceLightness ?? this.surfaceLightness,
      isDark: isDark ?? this.isDark,
      name: name ?? this.name,
    );
  }

  @override
  List<Object?> get props => [
        primaryHue,
        primarySaturation,
        primaryLightness,
        surfaceLightness,
        isDark,
        name,
      ];
}
