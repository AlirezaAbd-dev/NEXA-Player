import 'package:flutter/material.dart';
import '../theme/dynamic_palette_service.dart';

/// Elevation tiers for the NEXA Player borderless tonal design system.
///
/// Surfaces are distinguished strictly by luminance elevation and chromatic tint,
/// never by raw 1.0px borders (outside of explicit [SurfaceBorderReason] exceptions).
enum NexaSurfaceTier {
  /// L0: Baseline application canvas.
  /// Dark: #050507 | Daylight: #F4F5F7 | AMOLED Car/Standby: #000000.
  l0,

  /// L1: Recessed troughs, search well backgrounds, waveform inactive tracks.
  /// Dark: #0D0E12 | Daylight: #E8EAF0.
  l1,

  /// L2: Elevated content containers, track rows, grouped settings blocks, album cards.
  /// Dark: #14151B (+ optional 4% album tint) | Daylight: #FFFFFF.
  l2,

  /// L3: Floating elements, mini-player pill, modal bottom sheets, contextual action bars.
  /// Dark: #1D1F28 (+ optional 8% album tint) | Daylight: #FFFFFF + soft diffuse shadow.
  l3,

  /// L4: High-chroma interactive accent fills (primary playback controls, active tab indicators).
  l4,
}

/// Backwards-compatibility alias for [NexaSurfaceTier].
typedef NexaSurfaceLevel = NexaSurfaceTier;

/// Centralized Material 3 [ThemeExtension] encapsulating the 5 tonal surface tiers ($L_0$ to $L_4$),
/// foreground contrast pairings, diffuse floating shadows, and tabular telemetry typography.
@immutable
class NexaSurfaceTokens extends ThemeExtension<NexaSurfaceTokens> {
  const NexaSurfaceTokens({
    required this.l0,
    required this.l1,
    required this.l2,
    required this.l3,
    required this.l4,
    required this.onL0,
    required this.onL1,
    required this.onL2,
    required this.onL3,
    required this.onL4,
    required this.l3Shadow,
    required this.telemetryTextStyle,
  });

  /// L0: Canvas background color.
  final Color l0;

  /// L1: Recessed trough and well surface color.
  final Color l1;

  /// L2: Primary content card and container surface color.
  final Color l2;

  /// L3: Floating pill and modal sheet surface color.
  final Color l3;

  /// L4: High-chroma active accent fill color.
  final Color l4;

  /// Foreground text/icon color on [l0].
  final Color onL0;

  /// Foreground text/icon color on [l1].
  final Color onL1;

  /// Foreground text/icon color on [l2].
  final Color onL2;

  /// Foreground text/icon color on [l3].
  final Color onL3;

  /// Foreground text/icon color on [l4].
  final Color onL4;

  /// Soft diffuse shadow used exclusively for [l3] floating elements.
  final List<BoxShadow> l3Shadow;

  /// High-precision tabular typography for timers, dB readouts, bit-depth badges, and BPM.
  final TextStyle telemetryTextStyle;

  /// Backwards-compatibility aliases
  static final NexaSurfaceTokens midnightBlack = NexaSurfaceTokens.dark();
  Color get level0 => l0;
  Color get level1 => l1;
  Color get level2 => l2;
  Color get level3 => l3;
  Color get level4 => l4;
  Color get onLevel0 => onL0;
  Color get onLevel1 => onL1;
  Color get onLevel2 => onL2;
  Color get onLevel3 => onL3;
  Color get onLevel4 => onL4;

  /// Default Obsidian dark mode tonal tokens (smooth dark slate elevations).
  factory NexaSurfaceTokens.dark({Color? accent, Color? seedTint}) {
    final effectiveAccent = accent ?? const Color(0xFF00E5FF);
    const baseL0 = Color(0xFF12141C);
    const baseL1 = Color(0xFF1A1D28);
    const baseL2 = Color(0xFF222634);
    const baseL3 = Color(0xFF2B3042);

    final resolvedL2 = seedTint != null
        ? Color.alphaBlend(seedTint.withOpacity(0.04), baseL2)
        : baseL2;

    final resolvedL3 = seedTint != null
        ? Color.alphaBlend(seedTint.withOpacity(0.08), baseL3)
        : baseL3;

    return NexaSurfaceTokens(
      l0: baseL0,
      l1: baseL1,
      l2: resolvedL2,
      l3: resolvedL3,
      l4: effectiveAccent,
      onL0: const Color(0xFFE6E9F2),
      onL1: const Color(0xFFCFD4E2),
      onL2: const Color(0xFFF3F5FA),
      onL3: const Color(0xFFFFFFFF),
      onL4: ThemeData.estimateBrightnessForColor(effectiveAccent) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF050507),
      l3Shadow: const [
        BoxShadow(
          color: Color(0x38000000),
          blurRadius: 16.0,
          offset: Offset(0, 4),
        ),
      ],
      telemetryTextStyle: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Daylight mode crisp tonal tokens with soft diffuse shadows.
  factory NexaSurfaceTokens.light({Color? accent, Color? seedTint}) {
    final effectiveAccent = accent ?? const Color(0xFF007AFF);
    const baseL0 = Color(0xFFF4F5F7);
    const baseL1 = Color(0xFFE8EAF0);
    const baseL2 = Color(0xFFFFFFFF);
    const baseL3 = Color(0xFFFFFFFF);

    return NexaSurfaceTokens(
      l0: baseL0,
      l1: baseL1,
      l2: baseL2,
      l3: baseL3,
      l4: effectiveAccent,
      onL0: const Color(0xFF1A1C22),
      onL1: const Color(0xFF32353E),
      onL2: const Color(0xFF111215),
      onL3: const Color(0xFF111215),
      onL4: ThemeData.estimateBrightnessForColor(effectiveAccent) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF050507),
      l3Shadow: const [
        BoxShadow(
          color: Color(0x14000000),
          blurRadius: 16.0,
          offset: Offset(0, 6),
        ),
      ],
      telemetryTextStyle: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Pure AMOLED #000000 black canvas reserved exclusively for Car Mode and Standby Bedside Mode.
  factory NexaSurfaceTokens.pureBlack({Color? accent}) {
    final effectiveAccent = accent ?? const Color(0xFFFF3B30);
    return NexaSurfaceTokens(
      l0: const Color(0xFF000000),
      l1: const Color(0xFF0A0A0C),
      l2: const Color(0xFF121216),
      l3: const Color(0xFF1A1A20),
      l4: effectiveAccent,
      onL0: const Color(0xFFE6E8F0),
      onL1: const Color(0xFFC8CBD6),
      onL2: const Color(0xFFF2F4FA),
      onL3: const Color(0xFFFFFFFF),
      onL4: ThemeData.estimateBrightnessForColor(effectiveAccent) == Brightness.dark
          ? const Color(0xFFFFFFFF)
          : const Color(0xFF000000),
      l3Shadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 12.0,
          offset: Offset(0, 4),
        ),
      ],
      telemetryTextStyle: const TextStyle(
        fontFeatures: [FontFeature.tabularFigures()],
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );
  }

  /// Derives tonal elevation tokens dynamically from an extracted album-art palette.
  factory NexaSurfaceTokens.fromDynamicPalette(
    ExtractedPalette palette, {
    required Brightness brightness,
    bool isOledBlack = false,
  }) {
    if (brightness == Brightness.dark) {
      if (isOledBlack) {
        return NexaSurfaceTokens.pureBlack(accent: palette.vibrant);
      }
      return NexaSurfaceTokens.dark(
        accent: palette.vibrant,
        seedTint: palette.dominant,
      );
    } else {
      return NexaSurfaceTokens.light(
        accent: palette.vibrant,
        seedTint: palette.dominant,
      );
    }
  }

  /// Builds tokens matching any brightness and primary color combination.
  factory NexaSurfaceTokens.fromTheme({
    required Brightness brightness,
    required Color primary,
    Color? seedColor,
    bool isOledBlack = false,
  }) {
    if (brightness == Brightness.dark) {
      if (isOledBlack) {
        return NexaSurfaceTokens.pureBlack(accent: primary);
      }
      return NexaSurfaceTokens.dark(accent: primary, seedTint: seedColor);
    } else {
      return NexaSurfaceTokens.light(accent: primary, seedTint: seedColor);
    }
  }

  /// Resolves the surface background color corresponding to [tier].
  Color colorForTier(NexaSurfaceTier tier) => switch (tier) {
        NexaSurfaceTier.l0 => l0,
        NexaSurfaceTier.l1 => l1,
        NexaSurfaceTier.l2 => l2,
        NexaSurfaceTier.l3 => l3,
        NexaSurfaceTier.l4 => l4,
      };

  /// Resolves the high-contrast foreground text/icon color corresponding to [tier].
  Color textColorForTier(NexaSurfaceTier tier) => switch (tier) {
        NexaSurfaceTier.l0 => onL0,
        NexaSurfaceTier.l1 => onL1,
        NexaSurfaceTier.l2 => onL2,
        NexaSurfaceTier.l3 => onL3,
        NexaSurfaceTier.l4 => onL4,
      };

  /// Retrieves the active [NexaSurfaceTokens] from [BuildContext] with guaranteed safe fallback.
  static NexaSurfaceTokens of(BuildContext context) {
    final tokens = Theme.of(context).extension<NexaSurfaceTokens>();
    if (tokens != null) return tokens;
    final brightness = Theme.of(context).brightness;
    final primary = Theme.of(context).colorScheme.primary;
    return brightness == Brightness.dark
        ? NexaSurfaceTokens.dark(accent: primary)
        : NexaSurfaceTokens.light(accent: primary);
  }

  @override
  NexaSurfaceTokens copyWith({
    Color? l0,
    Color? l1,
    Color? l2,
    Color? l3,
    Color? l4,
    Color? onL0,
    Color? onL1,
    Color? onL2,
    Color? onL3,
    Color? onL4,
    List<BoxShadow>? l3Shadow,
    TextStyle? telemetryTextStyle,
  }) {
    return NexaSurfaceTokens(
      l0: l0 ?? this.l0,
      l1: l1 ?? this.l1,
      l2: l2 ?? this.l2,
      l3: l3 ?? this.l3,
      l4: l4 ?? this.l4,
      onL0: onL0 ?? this.onL0,
      onL1: onL1 ?? this.onL1,
      onL2: onL2 ?? this.onL2,
      onL3: onL3 ?? this.onL3,
      onL4: onL4 ?? this.onL4,
      l3Shadow: l3Shadow ?? this.l3Shadow,
      telemetryTextStyle: telemetryTextStyle ?? this.telemetryTextStyle,
    );
  }

  @override
  NexaSurfaceTokens lerp(ThemeExtension<NexaSurfaceTokens>? other, double t) {
    if (other is! NexaSurfaceTokens) return this;
    return NexaSurfaceTokens(
      l0: Color.lerp(l0, other.l0, t)!,
      l1: Color.lerp(l1, other.l1, t)!,
      l2: Color.lerp(l2, other.l2, t)!,
      l3: Color.lerp(l3, other.l3, t)!,
      l4: Color.lerp(l4, other.l4, t)!,
      onL0: Color.lerp(onL0, other.onL0, t)!,
      onL1: Color.lerp(onL1, other.onL1, t)!,
      onL2: Color.lerp(onL2, other.onL2, t)!,
      onL3: Color.lerp(onL3, other.onL3, t)!,
      onL4: Color.lerp(onL4, other.onL4, t)!,
      l3Shadow: BoxShadow.lerpList(l3Shadow, other.l3Shadow, t) ?? l3Shadow,
      telemetryTextStyle: TextStyle.lerp(telemetryTextStyle, other.telemetryTextStyle, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NexaSurfaceTokens &&
          runtimeType == other.runtimeType &&
          l0 == other.l0 &&
          l1 == other.l1 &&
          l2 == other.l2 &&
          l3 == other.l3 &&
          l4 == other.l4 &&
          onL0 == other.onL0 &&
          onL1 == other.onL1 &&
          onL2 == other.onL2 &&
          onL3 == other.onL3 &&
          onL4 == other.onL4 &&
          telemetryTextStyle == other.telemetryTextStyle;

  @override
  int get hashCode => Object.hash(
        l0,
        l1,
        l2,
        l3,
        l4,
        onL0,
        onL1,
        onL2,
        onL3,
        onL4,
        telemetryTextStyle,
      );
}

/// Convenience extension on [BuildContext] for ergonomic token lookup.
extension NexaSurfaceThemeX on BuildContext {
  /// Access the active [NexaSurfaceTokens] for this context.
  NexaSurfaceTokens get nexaSurfaces => NexaSurfaceTokens.of(this);
}
