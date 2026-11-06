/// Persistent storage keys for NEXA Player.
///
/// All keys are prefixed with `nexa_` to avoid namespace collisions.
abstract final class StorageKeys {
  StorageKeys._();

  // Theme & Appearance (F0.10 - F0.13)
  static const String themePreset = 'nexa_theme_preset';
  static const String themeMode = 'nexa_theme_mode';
  static const String customPrimaryColor = 'nexa_custom_primary_color';
  static const String customSurfaceColor = 'nexa_custom_surface_color';
  static const String customBackgroundColor = 'nexa_custom_background_color';
  static const String glassBlurIntensity = 'nexa_glass_blur_intensity';
  static const String glassOpacityIntensity = 'nexa_glass_opacity_intensity';

  // Playback & Queue State
  static const String volume = 'nexa_player_volume';
  static const String isMuted = 'nexa_player_is_muted';
  static const String repeatMode = 'nexa_player_repeat_mode';
  static const String shuffleEnabled = 'nexa_player_shuffle_enabled';
  static const String lastTrackId = 'nexa_player_last_track_id';
  static const String lastPositionMs = 'nexa_player_last_position_ms';

  // Audio Engine & Equalizer
  static const String equalizerEnabled = 'nexa_eq_enabled';
  static const String equalizerPreset = 'nexa_eq_preset';
  static const String bassBoost = 'nexa_eq_bass_boost';
  static const String virtualizer = 'nexa_eq_virtualizer';
  static const String crossfadeDurationMs = 'nexa_audio_crossfade_ms';

  // Library & App State
  static const String onboardingCompleted = 'nexa_onboarding_completed';
  static const String libraryScanFolders = 'nexa_library_scan_folders';
  static const String lastScanTimestamp = 'nexa_last_scan_timestamp';
  static const String sortOrder = 'nexa_library_sort_order';
  static const String sortAscending = 'nexa_library_sort_ascending';
}
