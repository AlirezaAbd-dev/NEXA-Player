import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import '../design_system/nexa_surface_tokens.dart';
import 'color_palettes.dart';
import 'theme_preset.dart';

/// Central ThemeData builder for NEXA Player.
///
/// Integrates Material 3 and FlexColorScheme 8.0.2 to construct beautiful,
/// high-fidelity, contrast-compliant theme data for all presets and custom HSL themes.
abstract final class AppTheme {
  AppTheme._();

  /// Builds a [ThemeData] instance according to preset, mode, and optional custom colors.
  static ThemeData buildTheme({
    required ThemePreset preset,
    required ThemeMode mode,
    Brightness systemBrightness = Brightness.dark,
    Color? customPrimary,
    Color? customSurface,
    Color? customBackground,
    String? fontFamily,
  }) {
    final effectiveBrightness = switch (mode) {
      ThemeMode.dark => Brightness.dark,
      ThemeMode.light => Brightness.light,
      ThemeMode.system => systemBrightness,
    };

    return effectiveBrightness == Brightness.dark
        ? dark(
            preset: preset,
            customPrimary: customPrimary,
            customSurface: customSurface,
            customBackground: customBackground,
            fontFamily: fontFamily,
          )
        : light(
            preset: preset,
            customPrimary: customPrimary,
            customSurface: customSurface,
            customBackground: customBackground,
            fontFamily: fontFamily,
          );
  }

  /// Builds light [ThemeData] for a preset or custom palette.
  static ThemeData light({
    ThemePreset preset = ThemePreset.daylight,
    Color? customPrimary,
    Color? customSurface,
    Color? customBackground,
    String? fontFamily,
  }) {
    if (preset == ThemePreset.custom && customPrimary != null) {
      return _buildCustomTheme(
        primary: customPrimary,
        surface: customSurface ?? const Color(0xFFFFFFFF),
        background: customBackground ?? const Color(0xFFF8FAFC),
        brightness: Brightness.light,
        fontFamily: fontFamily,
      );
    }

    final palette = AppColorPalettes.getPalette(preset);
    final surfaceTokens = NexaSurfaceTokens.light(
      accent: palette.lightScheme.primary,
      seedTint: customPrimary,
    );

    return FlexThemeData.light(
      colors: palette.lightScheme,
      scaffoldBackground: palette.lightScaffold,
      surface: palette.lightSurface,
      appBarElevation: 0.0,
      useMaterial3: true,
      fontFamily: fontFamily,
      subThemesData: _subThemesData(),
      visualDensity: VisualDensity.standard,
    ).copyWith(
      cardColor: palette.lightCard,
      scaffoldBackgroundColor: palette.lightScaffold,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.lightScheme.primary;
          }
          return const Color(0x30000000);
        }),
      ),
      extensions: [surfaceTokens],
    );
  }

  /// Builds dark [ThemeData] for a preset or custom palette.
  static ThemeData dark({
    ThemePreset preset = ThemePreset.obsidian,
    Color? customPrimary,
    Color? customSurface,
    Color? customBackground,
    String? fontFamily,
  }) {
    if (preset == ThemePreset.custom && customPrimary != null) {
      return _buildCustomTheme(
        primary: customPrimary,
        surface: customSurface ?? const Color(0xFF131B2E),
        background: customBackground ?? const Color(0xFF0B0F19),
        brightness: Brightness.dark,
        fontFamily: fontFamily,
      );
    }

    final palette = AppColorPalettes.getPalette(preset);
    final surfaceTokens = palette.isOledBlack
        ? NexaSurfaceTokens.pureBlack(accent: palette.darkScheme.primary)
        : NexaSurfaceTokens.dark(
            accent: palette.darkScheme.primary,
            seedTint: customPrimary,
          );

    return FlexThemeData.dark(
      colors: palette.darkScheme,
      scaffoldBackground: palette.darkScaffold,
      surface: palette.darkSurface,
      darkIsTrueBlack: palette.isOledBlack,
      appBarElevation: 0.0,
      useMaterial3: true,
      fontFamily: fontFamily,
      subThemesData: _subThemesData(),
      visualDensity: VisualDensity.standard,
    ).copyWith(
      cardColor: palette.darkCard,
      scaffoldBackgroundColor: palette.darkScaffold,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.white70;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return palette.darkScheme.primary;
          }
          return const Color(0x30FFFFFF);
        }),
      ),
      extensions: [surfaceTokens],
    );
  }

  /// Shared FlexSubThemesData for Glassmorphism harmony (radii and elevations).
  static FlexSubThemesData _subThemesData() => const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: false,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        alignedDropdown: true,
        navigationBarOpacity: 0.85,
        navigationBarMutedUnselectedIcon: true,
        appBarScrolledUnderElevation: 0.0,
        bottomNavigationBarElevation: 0.0,
        navigationBarElevation: 0.0,
        bottomSheetRadius: 24.0,
        dialogRadius: 20.0,
        cardRadius: 16.0,
        defaultRadius: 12.0,
      );

  /// Builds custom ThemeData from custom HSL colors.
  static ThemeData _buildCustomTheme({
    required Color primary,
    required Color surface,
    required Color background,
    required Brightness brightness,
    String? fontFamily,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = FlexSchemeColor.from(
      primary: primary,
      brightness: brightness,
    );
    final surfaceTokens = isDark
        ? NexaSurfaceTokens.dark(accent: primary, seedTint: primary)
        : NexaSurfaceTokens.light(accent: primary, seedTint: primary);

    final switchTheme = SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return Colors.white;
        }
        return Colors.white70;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return isDark ? const Color(0x30FFFFFF) : const Color(0x30000000);
      }),
    );

    return isDark
        ? FlexThemeData.dark(
            colors: scheme,
            scaffoldBackground: background,
            surface: surface,
            appBarElevation: 0.0,
            useMaterial3: true,
            fontFamily: fontFamily,
            subThemesData: _subThemesData(),
            visualDensity: VisualDensity.standard,
          ).copyWith(
            scaffoldBackgroundColor: background,
            cardColor: surface,
            switchTheme: switchTheme,
            extensions: [surfaceTokens],
          )
        : FlexThemeData.light(
            colors: scheme,
            scaffoldBackground: background,
            surface: surface,
            appBarElevation: 0.0,
            useMaterial3: true,
            fontFamily: fontFamily,
            subThemesData: _subThemesData(),
            visualDensity: VisualDensity.standard,
          ).copyWith(
            scaffoldBackgroundColor: background,
            cardColor: surface,
            switchTheme: switchTheme,
            extensions: [surfaceTokens],
          );
  }
}
