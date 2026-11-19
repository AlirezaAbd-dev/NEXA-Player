/// Centralized route definitions and path constants for NEXA Player.
abstract final class AppRoutes {
  static const String songs = '/songs';
  static const String albums = '/albums';
  static const String artists = '/artists';
  static const String playlists = '/playlists';
  static const String folders = '/folders';
  static const String settings = '/settings';

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
  static const String player = '/player';
  static const String equalizer = '/equalizer';
  static const String ringtoneTrimmer = '/ringtone-trimmer';
  static const String lyrics = '/lyrics';
  static const String search = '/search';
}
