import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'theme_preset.dart';

/// Immutable specification for a NEXA Theme Palette containing complete
/// dark and light color tokens and FlexColorScheme configurations.
@immutable
class NexaPalette {
  const NexaPalette({
    required this.preset,
    required this.name,
    required this.description,
    required this.darkScaffold,
    required this.darkSurface,
    required this.darkCard,
    required this.darkScheme,
    required this.lightScaffold,
    required this.lightSurface,
    required this.lightCard,
    required this.lightScheme,
    this.isOledBlack = false,
  });

  final ThemePreset preset;
  final String name;
  final String description;
  final bool isOledBlack;

  // Dark mode colors
  final Color darkScaffold;
  final Color darkSurface;
  final Color darkCard;
  final FlexSchemeColor darkScheme;

  // Light mode colors
  final Color lightScaffold;
  final Color lightSurface;
  final Color lightCard;
  final FlexSchemeColor lightScheme;

  /// Resolves scaffold background by brightness.
  Color scaffoldBackground(Brightness brightness) =>
      brightness == Brightness.dark ? darkScaffold : lightScaffold;

  /// Resolves surface color by brightness.
  Color surfaceColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;

  /// Resolves card container color by brightness.
  Color cardColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkCard : lightCard;

  /// Resolves primary accent by brightness.
  Color primaryColor(Brightness brightness) =>
      brightness == Brightness.dark ? darkScheme.primary : lightScheme.primary;

  /// Converts this palette to a paired [FlexSchemeData] object.
  FlexSchemeData toFlexSchemeData() => FlexSchemeData(
        name: name,
        description: description,
        light: lightScheme,
        dark: darkScheme,
      );
}

/// Authoritative definitions for all 8 preset theme palettes in NEXA Player.
abstract final class AppColorPalettes {
  AppColorPalettes._();

  // 1. Midnight Black (AMOLED True Black)
  static const midnightBlack = NexaPalette(
    preset: ThemePreset.midnightBlack,
    name: 'Midnight Black',
    description: 'Pure AMOLED pitch black with electric cyan and neon lime accents.',
    isOledBlack: true,
    darkScaffold: Color(0xFF000000), // Pure AMOLED #000000
    darkSurface: Color(0xFF0D0D0D),  // Deep charcoal
    darkCard: Color(0xFF0D0D0D),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFF00E5FF),          // Electric Cyan
      primaryContainer: Color(0xFF004D56),
      secondary: Color(0xFF76FF03),        // Neon Lime
      secondaryContainer: Color(0xFF235400),
      tertiary: Color(0xFFFF007F),         // Electric Rose
      tertiaryContainer: Color(0xFF5A002B),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFF5F5F7), // Apple neutral gray
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFF00838F),          // Deep Cyan (contrast protected)
      primaryContainer: Color(0xFFB2EBF2),
      secondary: Color(0xFF33691E),        // Forest Lime
      secondaryContainer: Color(0xFFDCEDC8),
      tertiary: Color(0xFFAD1457),
      tertiaryContainer: Color(0xFFF8BBD0),
      error: Color(0xFFD32F2F),
    ),
  );

  // 2. Deep Space (Cosmic Navy & Indigo)
  static const deepSpace = NexaPalette(
    preset: ThemePreset.deepSpace,
    name: 'Deep Space',
    description: 'Cosmic navy void with celestial indigo and stellar cyan highlights.',
    isOledBlack: false,
    darkScaffold: Color(0xFF0B0F19), // Cosmic navy
    darkSurface: Color(0xFF131B2E),  // Stellar surface
    darkCard: Color(0xFF1A243D),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFF6366F1),          // Indigo
      primaryContainer: Color(0xFF282A73),
      secondary: Color(0xFF00E5FF),        // Stellar Cyan
      secondaryContainer: Color(0xFF004D56),
      tertiary: Color(0xFF818CF8),         // Nebula Lilac
      tertiaryContainer: Color(0xFF3730A3),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFF0F4FA),
    lightSurface: Color(0xFFFFFFFF),
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFF4338CA),          // Deep Indigo
      primaryContainer: Color(0xFFE0E7FF),
      secondary: Color(0xFF0284C7),        // Sky Azure
      secondaryContainer: Color(0xFFE0F2FE),
      tertiary: Color(0xFF6366F1),
      tertiaryContainer: Color(0xFFEEF2FF),
      error: Color(0xFFD32F2F),
    ),
  );

  // 3. Sakura (Cherry Blossom & Rose)
  static const sakura = NexaPalette(
    preset: ThemePreset.sakura,
    name: 'Sakura',
    description: 'Cherry blossom petals with rose pinks and night blossom plum.',
    isOledBlack: false,
    darkScaffold: Color(0xFF1F0B12), // Dark Plum
    darkSurface: Color(0xFF2D121C),  // Night Blossom
    darkCard: Color(0xFF3B1A27),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFFE91E63),          // Sakura Rose
      primaryContainer: Color(0xFF5C102A),
      secondary: Color(0xFFFF80AB),        // Petal Pink
      secondaryContainer: Color(0xFF5E1332),
      tertiary: Color(0xFFFFD1DC),         // Blossom White-Pink
      tertiaryContainer: Color(0xFF4A1525),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFFFF5F7), // Pale Petal Light
    lightSurface: Color(0xFFFFE4E9),  // Blossom Surface
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFFC2185B),          // Deep Blossom Rose
      primaryContainer: Color(0xFFF8BBD0),
      secondary: Color(0xFFE91E63),        // Sakura Accent
      secondaryContainer: Color(0xFFFFCDD2),
      tertiary: Color(0xFFAD1457),
      tertiaryContainer: Color(0xFFFCE4EC),
      error: Color(0xFFD32F2F),
    ),
  );

  // 4. Ocean Blue (Marine Abyss)
  static const oceanBlue = NexaPalette(
    preset: ThemePreset.oceanBlue,
    name: 'Ocean Blue',
    description: 'Abyssal navy marine depths with azure waves and aqua highlights.',
    isOledBlack: false,
    darkScaffold: Color(0xFF0B192C), // Abyssal Navy
    darkSurface: Color(0xFF1E3E62),  // Deep Trench
    darkCard: Color(0xFF254B75),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFF00B4D8),          // Azure Waves
      primaryContainer: Color(0xFF00445E),
      secondary: Color(0xFF40C4FF),        // Aqua Ripple
      secondaryContainer: Color(0xFF004B6E),
      tertiary: Color(0xFF48CAE4),         // Seafoam
      tertiaryContainer: Color(0xFF005A7A),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFF0F9FF), // Ocean Mist
    lightSurface: Color(0xFFE0F2FE),  // Coastal Shallows
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFF0284C7),          // Deep Sea Blue
      primaryContainer: Color(0xFFBAE6FD),
      secondary: Color(0xFF0EA5E9),        // Sky Marine
      secondaryContainer: Color(0xFFE0F2FE),
      tertiary: Color(0xFF0369A1),
      tertiaryContainer: Color(0xFFE0F2FE),
      error: Color(0xFFD32F2F),
    ),
  );

  // 5. Forest Green (Neon Canopy & Pine)
  static const forestGreen = NexaPalette(
    preset: ThemePreset.forestGreen,
    name: 'Forest Green',
    description: 'Deep canopy wilderness with glowing neon canopy and fresh mint.',
    isOledBlack: false,
    darkScaffold: Color(0xFF0B170E), // Obsidian Forest
    darkSurface: Color(0xFF14291A),  // Pine Surface
    darkCard: Color(0xFF1C3A25),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFF00E676),          // Neon Canopy
      primaryContainer: Color(0xFF004D25),
      secondary: Color(0xFF69F0AE),        // Mint Glow
      secondaryContainer: Color(0xFF005331),
      tertiary: Color(0xFFB9F6CA),         // Leaf Highlight
      tertiaryContainer: Color(0xFF005C36),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFF2FBF5), // Forest Dew
    lightSurface: Color(0xFFE8F5E9),
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFF16A34A),          // Emerald Green
      primaryContainer: Color(0xFFDCFCE7),
      secondary: Color(0xFF2E7D32),        // Pine Forest
      secondaryContainer: Color(0xFFA5D6A7),
      tertiary: Color(0xFF15803D),
      tertiaryContainer: Color(0xFFDCFCE7),
      error: Color(0xFFD32F2F),
    ),
  );

  // 6. Lava (Volcanic Magma & Amber)
  static const lava = NexaPalette(
    preset: ThemePreset.lava,
    name: 'Lava',
    description: 'Smoldering volcanic rock with molten blaze and fiery amber.',
    isOledBlack: false,
    darkScaffold: Color(0xFF150806), // Charred Basalt
    darkSurface: Color(0xFF29100C),  // Warm Magma Surface
    darkCard: Color(0xFF3B1712),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFFFF3D00),          // Molten Blaze
      primaryContainer: Color(0xFF5C1400),
      secondary: Color(0xFFFF9100),        // Amber Flame
      secondaryContainer: Color(0xFF5E3500),
      tertiary: Color(0xFFFFAB40),         // Ember Glow
      tertiaryContainer: Color(0xFF663B00),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFFFF7F5), // Warm Ash White
    lightSurface: Color(0xFFFFEDE8),
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFFEA580C),          // Deep Blaze
      primaryContainer: Color(0xFFFFEDD5),
      secondary: Color(0xFFD97706),        // Burnt Amber
      secondaryContainer: Color(0xFFFEF3C7),
      tertiary: Color(0xFFC2410C),
      tertiaryContainer: Color(0xFFFFE4E6),
      error: Color(0xFFD32F2F),
    ),
  );

  // 7. Daylight (Clean Architectural Daylight)
  static const daylight = NexaPalette(
    preset: ThemePreset.daylight,
    name: 'Daylight',
    description: 'Crisp architectural daylight with royal blue and calm teal.',
    isOledBlack: false,
    darkScaffold: Color(0xFF0F172A), // Slate Twilight
    darkSurface: Color(0xFF1E293B),  // Dark Slate Surface
    darkCard: Color(0xFF334155),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFF60A5FA),          // Sky Blue
      primaryContainer: Color(0xFF1E3A8A),
      secondary: Color(0xFF14B8A6),        // Breeze Teal
      secondaryContainer: Color(0xFF134E4A),
      tertiary: Color(0xFF38BDF8),
      tertiaryContainer: Color(0xFF075985),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFF8FAFC), // Crisp Slate Daylight
    lightSurface: Color(0xFFFFFFFF),  // Pure White Surface
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFF2563EB),          // Royal Blue
      primaryContainer: Color(0xFFDBEAFE),
      secondary: Color(0xFF0D9488),        // Dark Teal
      secondaryContainer: Color(0xFFCCFBF1),
      tertiary: Color(0xFF0284C7),
      tertiaryContainer: Color(0xFFE0F2FE),
      error: Color(0xFFD32F2F),
    ),
  );

  // 8. Neon Purple (Cyberpunk Obsidian & Violet)
  static const neonPurple = NexaPalette(
    preset: ThemePreset.neonPurple,
    name: 'Neon Purple',
    description: 'Cyberpunk obsidian night with electric fuchsia and neon violet.',
    isOledBlack: false,
    darkScaffold: Color(0xFF0F071A), // Cyber Obsidian
    darkSurface: Color(0xFF1D1133),  // Neon Void Surface
    darkCard: Color(0xFF2C194D),
    darkScheme: FlexSchemeColor(
      primary: Color(0xFFD946EF),          // Electric Fuchsia
      primaryContainer: Color(0xFF581163),
      secondary: Color(0xFFA855F7),        // Neon Violet
      secondaryContainer: Color(0xFF451368),
      tertiary: Color(0xFFC084FC),         // Amethyst Pulse
      tertiaryContainer: Color(0xFF581C87),
      error: Color(0xFFFF5252),
    ),
    lightScaffold: Color(0xFFFAF5FF), // Soft Lavender Light
    lightSurface: Color(0xFFF3E8FF),  // Lavender Surface
    lightCard: Color(0xFFFFFFFF),
    lightScheme: FlexSchemeColor(
      primary: Color(0xFF9333EA),          // Deep Purple
      primaryContainer: Color(0xFFF3E8FF),
      secondary: Color(0xFFA21CAF),        // Deep Fuchsia
      secondaryContainer: Color(0xFFFAE8FF),
      tertiary: Color(0xFF7E22CE),
      tertiaryContainer: Color(0xFFF3E8FF),
      error: Color(0xFFD32F2F),
    ),
  );

  /// Map of all 8 preset palettes.
  static const Map<ThemePreset, NexaPalette> presets = {
    ThemePreset.midnightBlack: midnightBlack,
    ThemePreset.deepSpace: deepSpace,
    ThemePreset.sakura: sakura,
    ThemePreset.oceanBlue: oceanBlue,
    ThemePreset.forestGreen: forestGreen,
    ThemePreset.lava: lava,
    ThemePreset.daylight: daylight,
    ThemePreset.neonPurple: neonPurple,
  };

  /// List of built-in presets (excluding custom).
  static const List<NexaPalette> all = [
    midnightBlack,
    deepSpace,
    sakura,
    oceanBlue,
    forestGreen,
    lava,
    daylight,
    neonPurple,
  ];

  /// Get palette by preset enum with fallback to Midnight Black.
  static NexaPalette getPalette(ThemePreset preset) {
    return presets[preset] ?? midnightBlack;
  }
}
