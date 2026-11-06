import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'custom_theme_data.dart';
import 'theme_preset.dart';

/// Immutable state containing active theme preset, brightness mode,
/// and custom HSL palette parameters.
class ThemeState extends Equatable {
  const ThemeState({
    this.preset = ThemePreset.midnightBlack,
    this.themeMode = ThemeMode.system,
    this.customTheme,
  });

  /// The active theme preset.
  final ThemePreset preset;

  /// The active brightness mode (system, light, or dark).
  final ThemeMode themeMode;

  /// Custom HSL theme configuration, non-null when [preset] is [ThemePreset.custom].
  final CustomThemeData? customTheme;

  /// Canonical initial default state: AMOLED Midnight Black with System ThemeMode.
  static const ThemeState initial = ThemeState(
    preset: ThemePreset.midnightBlack,
    themeMode: ThemeMode.system,
    customTheme: null,
  );

  /// Whether the user is currently using a custom HSL theme.
  bool get isCustom => preset == ThemePreset.custom;

  /// Convenience accessor for custom primary color (if defined).
  Color? get customPrimary => customTheme?.primaryColor;

  /// Convenience accessor for custom surface color (if defined).
  Color? get customSurface => customTheme?.surfaceColor;

  /// Convenience accessor for custom background color (if defined).
  Color? get customBackground => customTheme?.scaffoldBackgroundColor;

  /// Resolves whether the current theme should render dark given [platformBrightness].
  bool isDark(Brightness platformBrightness) {
    return switch (themeMode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformBrightness == Brightness.dark,
    };
  }

  /// Returns a copy of this state with specified fields updated.
  ThemeState copyWith({
    ThemePreset? preset,
    ThemeMode? themeMode,
    CustomThemeData? customTheme,
    bool clearCustomTheme = false,
  }) {
    return ThemeState(
      preset: preset ?? this.preset,
      themeMode: themeMode ?? this.themeMode,
      customTheme: clearCustomTheme ? null : (customTheme ?? this.customTheme),
    );
  }

  @override
  List<Object?> get props => [preset, themeMode, customTheme];

  @override
  String toString() =>
      'ThemeState(preset: ${preset.name}, themeMode: ${themeMode.name}, customTheme: $customTheme)';
}
