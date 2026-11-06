import 'dart:ui';

/// Centralized application constants for NEXA Player.
///
/// Contains design system tokens, responsive layout breakpoints,
/// animation durations, and default playback parameters.
abstract final class AppConstants {
  AppConstants._();

  // App Metadata
  static const String appName = 'NEXA Player';
  static const String appVersion = '1.0.0+1';
  static const String appPackageName = 'com.nexa.player';

  // Responsive Breakpoints (Phone < 600, Tablet 600-840, Desktop > 840)
  static const double phoneBreakpoint = 600.0;
  static const double tabletBreakpoint = 840.0;

  // Glassmorphism Token Defaults (F0.8)
  static const double defaultGlassBlur = 20.0;
  static const double minGlassBlur = 16.0;
  static const double maxGlassBlur = 24.0;
  static const double defaultGlassOpacity = 0.15;
  static const double minGlassOpacity = 0.12;
  static const double maxGlassOpacity = 0.18;
  static const double glassBorderWidth = 1.0;
  static const Color glassBorderColor = Color(0x40FFFFFF); // White at 25% alpha

  // Layout & Navigation Dimensions
  static const double miniPlayerHeight = 64.0;
  static const double bottomNavBarHeight = 72.0;
  static const double appBarHeight = 64.0;
  static const double trackTileHeight = 72.0;
  static const double albumCardDefaultSize = 160.0;
  static const double artistAvatarRadius = 40.0;

  // 8-Step Spacing Scale (F0.9)
  static const double spaceXxs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double spaceXxl = 48.0;
  static const double space3xl = 64.0;

  // Corner Radii Scale
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0;

  // Animation Durations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animPageTransition = Duration(milliseconds: 350);

  // Playback & Audio Defaults
  static const double defaultVolume = 1.0;
  static const Duration defaultSeekStep = Duration(seconds: 10);
  static const Duration minSeekStep = Duration(seconds: 5);
  static const Duration maxSeekStep = Duration(seconds: 30);
  static const Duration defaultCrossfade = Duration.zero;
  static const Duration maxCrossfade = Duration(seconds: 10);

  // Supported Audio Formats
  static const Set<String> supportedAudioExtensions = {
    'mp3',
    'flac',
    'wav',
    'm4a',
    'aac',
    'ogg',
    'opus',
    'wma',
    'alac',
    'aiff',
  };

  // Primary Shell Navigation Routes
  static const String songsRoute = '/songs';
  static const String albumsRoute = '/albums';
  static const String artistsRoute = '/artists';
  static const String playlistsRoute = '/playlists';
  static const String settingsRoute = '/settings';
  static const String nowPlayingRoute = '/player';
  static const String equalizerRoute = '/equalizer';
  static const String designSystemRoute = '/design-system';
}
