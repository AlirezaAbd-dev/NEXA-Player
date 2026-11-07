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
  static const String player = '/player';
}
