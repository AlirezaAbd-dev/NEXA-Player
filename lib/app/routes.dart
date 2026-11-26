/// Centralized route definitions and path constants for NEXA Player.
abstract final class AppRoutes {
  static const String songs = '/songs';
  static const String albums = '/albums';
  static const String artists = '/artists';
  static const String playlists = '/playlists';
  static const String folders = '/folders';
  static const String settings = '/settings';
  static const String albumDetail = '/album-detail';
  static const String artistDetail = '/artist-detail';
  static const String playlistDetail = '/playlist-detail';

  // Subroutes
  static const String themePicker = '/settings/theme';
  static const String customTheme = '/settings/theme/custom';
  static const String designSystem = '/settings/design-system';
  static const String scannerSettings = '/settings/scanner';
  static const String audioSettings = '/settings/audio';
  static const String controlSettings = '/settings/controls';
  static const String albumArtSettings = '/settings/album-art';
  static const String metadataSettings = '/settings/metadata';
  static const String powerSavingSettings = '/settings/power-saving';
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String visualizerSettings = '/settings/visualizer';
  static const String aboutSettings = '/settings/about';
  static const String appearanceSettings = '/settings/appearance';
  static const String autoSettings = '/settings/auto';
  static const String player = '/player';
  static const String equalizer = '/equalizer';
  static const String ringtoneTrimmer = '/ringtone-trimmer';
  static const String lyrics = '/lyrics';
  static const String search = '/search';
  static const String nowPlaying = '/player';
  static const String widgets = '/widgets';
  static const String standby = '/standby';
  static const String lockscreen = '/lockscreen';
  static const String carMode = '/car-mode';
  static const String wear = '/wear';

  // Cloud & Network Streaming (Phase 14)
  static const String cloud = '/cloud';
  static const String cloudBrowse = '/cloud/browse';
  static const String cloudRadio = '/cloud/radio';
}

/// Convenience alias for [AppRoutes].
typedef Routes = AppRoutes;
