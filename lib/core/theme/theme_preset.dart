/// The 8 authoritative preset themes for NEXA Player plus custom HSL theme.
enum ThemePreset {
  midnightBlack,
  deepSpace,
  sakura,
  oceanBlue,
  forestGreen,
  lava,
  daylight,
  neonPurple,
  custom;

  /// User-facing display name.
  String get displayName => switch (this) {
        midnightBlack => 'Midnight Black',
        deepSpace => 'Deep Space',
        sakura => 'Sakura',
        oceanBlue => 'Ocean Blue',
        forestGreen => 'Forest Green',
        lava => 'Lava',
        daylight => 'Daylight',
        neonPurple => 'Neon Purple',
        custom => 'Custom HSL',
      };

  /// Whether this preset uses pure AMOLED pitch black (#000000).
  bool get isOledBlack => this == midnightBlack;

  /// Serialization key matching StorageKeys and E2E test strings.
  String get storageValue => name;

  /// Parse from storage string with safe fallback to midnightBlack.
  static ThemePreset fromString(String? value) {
    if (value == null || value.trim().isEmpty) {
      return ThemePreset.midnightBlack;
    }
    final normalized = value.trim().toLowerCase();
    for (final preset in ThemePreset.values) {
      if (preset.name.toLowerCase() == normalized) {
        return preset;
      }
    }
    return ThemePreset.midnightBlack;
  }
}
