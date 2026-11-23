import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../utils/contrast_validator.dart';

/// Represents an extracted color palette for dynamic album art theme adaptation.
class ExtractedPalette {
  const ExtractedPalette({
    required this.dominant,
    required this.vibrant,
    required this.muted,
    required this.darkVibrant,
    required this.lightVibrant,
  });

  /// The most prominent color in the album artwork.
  final Color dominant;

  /// Highly saturated, energetic color optimal for glowing accents and primary controls.
  final Color vibrant;

  /// Subdued, atmospheric tint suitable for subtle borders and secondary tags.
  final Color muted;

  /// Deep, low-luminance tone tailored for AMOLED backdrops and cards.
  final Color darkVibrant;

  /// High-luminance accent suitable for icons and labels on dark cards.
  final Color lightVibrant;

  /// High-contrast primary accent for controls and active progress.
  Color get primary => vibrant;

  /// Secondary complementary accent for headers and badges.
  Color get secondary => dominant;

  /// Atmospheric tertiary accent for subtle glass cards and glows.
  Color get tertiary => muted;

  /// Atmospheric background ambient tint, guaranteed contrast on L0 canvas.
  Color get atmosphere => ensureContrast(muted, const Color(0xFF050507), minRatio: 3.0);

  /// Guaranteed contrast accent for primary controls.
  Color get accent => ensureContrast(vibrant, const Color(0xFF050507), minRatio: 4.5);

  /// High-luminance specular highlight.
  Color get specular => ensureContrast(lightVibrant, const Color(0xFF050507), minRatio: 4.5);

  /// Canonical default fallback palette (Neon Cyan & Electric Orchid).
  static const fallback = ExtractedPalette(
    dominant: Color(0xFF00E5FF),
    vibrant: Color(0xFFD946EF),
    muted: Color(0xFF334155),
    darkVibrant: Color(0xFF0D1B2A),
    lightVibrant: Color(0xFFE0F2FE),
  );

  /// Linearly interpolates between two palettes.
  static ExtractedPalette lerp(ExtractedPalette a, ExtractedPalette b, double t) {
    return ExtractedPalette(
      dominant: Color.lerp(a.dominant, b.dominant, t) ?? a.dominant,
      vibrant: Color.lerp(a.vibrant, b.vibrant, t) ?? a.vibrant,
      muted: Color.lerp(a.muted, b.muted, t) ?? a.muted,
      darkVibrant: Color.lerp(a.darkVibrant, b.darkVibrant, t) ?? a.darkVibrant,
      lightVibrant: Color.lerp(a.lightVibrant, b.lightVibrant, t) ?? a.lightVibrant,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractedPalette &&
          runtimeType == other.runtimeType &&
          dominant == other.dominant &&
          vibrant == other.vibrant &&
          muted == other.muted &&
          darkVibrant == other.darkVibrant &&
          lightVibrant == other.lightVibrant;

  @override
  int get hashCode => Object.hash(
        dominant,
        vibrant,
        muted,
        darkVibrant,
        lightVibrant,
      );
}

/// Service that analyzes album art files or metadata seeds to generate
/// high-fidelity, contrast-checked color palettes for dynamic theming.
class DynamicPaletteService {
  const DynamicPaletteService();

  static final Map<String, ExtractedPalette> _cache = {};

  /// Extracts or computes an [ExtractedPalette] from a track's artwork path and metadata.
  Future<ExtractedPalette> extractPalette({
    required String trackId,
    String? albumArtPath,
    String? seedText,
  }) async {
    final cacheKey = '$trackId|${albumArtPath ?? ''}|${seedText ?? ''}';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // 1. If an actual image file exists on disk, sample its bytes
    if (albumArtPath != null && albumArtPath.isNotEmpty) {
      final file = File(albumArtPath);
      if (await file.exists()) {
        try {
          final palette = await _extractFromFile(file);
          _cache[cacheKey] = palette;
          return palette;
        } catch (_) {
          // Graceful fallback to procedural seed
        }
      }
    }

    // 2. Procedural high-vibrancy palette derived deterministically from metadata seed
    final seed = (seedText != null && seedText.isNotEmpty)
        ? seedText
        : trackId;
    final palette = computeSeedPalette(seed);
    _cache[cacheKey] = palette;
    return palette;
  }

  /// Synchronously computes a procedural dynamic palette from a text seed.
  ExtractedPalette computeSeedPalette(String seed) {
    // Generate deterministic hash
    int hash = 0;
    for (int i = 0; i < seed.length; i++) {
      hash = (hash * 31 + seed.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    final rand = math.Random(hash);

    // Primary hue selection
    final hue1 = (rand.nextDouble() * 360.0);
    // Complementary or analogous secondary hue
    final hue2 = (hue1 + 45.0 + rand.nextDouble() * 90.0) % 360.0;

    // Vibrant accent: high saturation, medium-high lightness
    final vibrant = HSLColor.fromAHSL(1.0, hue1, 0.85, 0.60).toColor();

    // Secondary dominant: slightly shifted hue, rich saturation
    final dominant = HSLColor.fromAHSL(1.0, hue2, 0.80, 0.55).toColor();

    // Muted: low saturation
    final muted = HSLColor.fromAHSL(1.0, hue1, 0.30, 0.35).toColor();

    // Dark vibrant: low lightness for AMOLED dark backdrops
    final darkVibrant = HSLColor.fromAHSL(1.0, hue1, 0.65, 0.12).toColor();

    // Light vibrant: high lightness for crisp contrast
    final lightVibrant = HSLColor.fromAHSL(1.0, hue2, 0.70, 0.88).toColor();

    return ExtractedPalette(
      dominant: dominant,
      vibrant: vibrant,
      muted: muted,
      darkVibrant: darkVibrant,
      lightVibrant: lightVibrant,
    );
  }

  Future<ExtractedPalette> _extractFromFile(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 54) {
      return ExtractedPalette.fallback;
    }

    // Fast subsampled byte histogram (sample every N bytes to keep extraction under 2ms)
    final step = math.max(1, bytes.length ~/ 256);
    int totalR = 0, totalG = 0, totalB = 0;
    int sampled = 0;

    for (int i = 0; i < bytes.length; i += step) {
      if (i + 2 < bytes.length) {
        totalR += bytes[i];
        totalG += bytes[i + 1];
        totalB += bytes[i + 2];
        sampled++;
      }
    }

    if (sampled == 0) return ExtractedPalette.fallback;

    final avgR = (totalR ~/ sampled).clamp(0, 255);
    final avgG = (totalG ~/ sampled).clamp(0, 255);
    final avgB = (totalB ~/ sampled).clamp(0, 255);

    final rawColor = Color.fromARGB(255, avgR, avgG, avgB);
    final hsl = HSLColor.fromColor(rawColor);

    // Normalize for vibrancy and contrast
    final vibrantHsl = hsl.withSaturation(math.max(0.75, hsl.saturation)).withLightness(0.58);
    final dominantHsl = hsl.withSaturation(math.max(0.60, hsl.saturation)).withLightness(0.48);
    final darkHsl = hsl.withSaturation(0.50).withLightness(0.12);
    final lightHsl = hsl.withSaturation(0.60).withLightness(0.85);
    final mutedHsl = hsl.withSaturation(0.25).withLightness(0.30);

    return ExtractedPalette(
      dominant: dominantHsl.toColor(),
      vibrant: vibrantHsl.toColor(),
      muted: mutedHsl.toColor(),
      darkVibrant: darkHsl.toColor(),
      lightVibrant: lightHsl.toColor(),
    );
  }
}
