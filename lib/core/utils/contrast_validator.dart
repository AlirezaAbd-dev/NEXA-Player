import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Pure Dart utility for perceptual luminance, contrast ratio calculation,
/// and automated WCAG AA/AAA contrast clamping.
abstract final class ContrastValidator {
  ContrastValidator._();

  /// Calculates the WCAG 2.1 relative luminance of [color].
  ///
  /// Formula: L = 0.2126 * R_linear + 0.7152 * G_linear + 0.0722 * B_linear
  static double relativeLuminance(Color color) {
    double linearize(double channel) {
      return channel <= 0.04045
          ? channel / 12.92
          : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = linearize(color.red / 255.0);
    final g = linearize(color.green / 255.0);
    final b = linearize(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Calculates the contrast ratio between [c1] and [c2] according to WCAG 2.1.
  /// Result is between 1.0 (identical) and 21.0 (pure black on pure white).
  static double calculateContrastRatio(Color c1, Color c2) {
    final l1 = relativeLuminance(c1);
    final l2 = relativeLuminance(c2);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Evaluates whether [fg] against [bg] satisfies WCAG AA guidelines.
  ///
  /// - Normal body text requires ratio >= 4.5:1
  /// - Large text (>=18pt or >=14pt bold) and UI components/icons require ratio >= 3.0:1
  static bool meetsWcagAA(Color fg, Color bg, {bool isLargeText = false}) {
    final ratio = calculateContrastRatio(fg, bg);
    return ratio >= (isLargeText ? 3.0 : 4.5);
  }

  /// Evaluates whether [fg] against [bg] satisfies WCAG AAA guidelines.
  static bool meetsWcagAAA(Color fg, Color bg, {bool isLargeText = false}) {
    final ratio = calculateContrastRatio(fg, bg);
    return ratio >= (isLargeText ? 4.5 : 7.0);
  }

  /// Guarantees that [fg] satisfies [minRatio] (default 4.5:1) against [bg].
  ///
  /// If the current contrast is already >= [minRatio], returns [fg] unchanged.
  /// Otherwise, it performs a binary search between [fg] and either pure white or pure black
  /// (depending on whether [bg] is dark or light), returning the minimally modified color
  /// that meets [minRatio] while preserving as much of the original chromaticity as possible.
  static Color ensureContrast(Color fg, Color bg, {double minRatio = 4.5}) {
    if (calculateContrastRatio(fg, bg) >= minRatio) {
      return fg;
    }

    final bgLum = relativeLuminance(bg);
    final target = bgLum < 0.5 ? const Color(0xFFFFFFFF) : const Color(0xFF000000);

    // If even the extreme target cannot achieve minRatio, return target as maximum possible contrast
    if (calculateContrastRatio(target, bg) < minRatio) {
      return target;
    }

    // Binary search for minimum interpolation factor t in [0.0, 1.0]
    double low = 0.0;
    double high = 1.0;
    Color best = target;

    for (int i = 0; i < 16; i++) {
      final mid = (low + high) / 2.0;
      final candidate = Color.lerp(fg, target, mid) ?? target;
      final ratio = calculateContrastRatio(candidate, bg);

      if (ratio >= minRatio) {
        best = candidate;
        high = mid; // Try smaller shift to preserve more original hue/chroma
      } else {
        low = mid;
      }
    }

    return best;
  }
}

/// Top-level pure Dart helper function guaranteeing contrast against [bg].
Color ensureContrast(Color fg, Color bg, {double minRatio = 4.5}) =>
    ContrastValidator.ensureContrast(fg, bg, minRatio: minRatio);
