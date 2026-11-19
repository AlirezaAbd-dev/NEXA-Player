import 'dart:convert';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import '../../domain/models/audio_settings.dart';
import '../../domain/models/control_settings.dart';
import '../../domain/models/album_art_settings.dart';
import '../../domain/models/metadata_lyrics_settings.dart';
import '../../domain/models/power_saving_settings.dart';
import '../../domain/models/notification_settings.dart';
import '../../domain/models/privacy_settings.dart';
import '../../domain/models/setting_search_item.dart';
import '../../domain/services/settings_service.dart';

class SettingsServiceImpl implements ISettingsService {
  SettingsServiceImpl(this._storage);

  final IStorageService _storage;

  static const String _keyAudioJson = 'nexa_settings_audio_json';
  static const String _keyControlJson = 'nexa_settings_control_json';
  static const String _keyAlbumArtJson = 'nexa_settings_album_art_json';
  static const String _keyMetadataJson = 'nexa_settings_metadata_json';
  static const String _keyPowerSavingJson = 'nexa_settings_power_saving_json';
  static const String _keyNotificationJson = 'nexa_settings_notification_json';
  static const String _keyPrivacyJson = 'nexa_settings_privacy_json';

  @override
  Future<AudioSettings> getAudioSettings() async {
    final raw = _storage.getString(_keyAudioJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return AudioSettings.fromJson(map);
      } catch (_) {}
    }
    return const AudioSettings();
  }

  @override
  Future<void> saveAudioSettings(AudioSettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyAudioJson, encoded);
    // Also sync crossfade to legacy/player key
    await _storage.setString(
      StorageKeys.crossfadeDurationMs,
      (settings.crossfadeDurationSeconds * 1000).toString(),
    );
  }

  @override
  Future<ControlSettings> getControlSettings() async {
    final raw = _storage.getString(_keyControlJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return ControlSettings.fromJson(map);
      } catch (_) {}
    }
    return const ControlSettings();
  }

  @override
  Future<void> saveControlSettings(ControlSettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyControlJson, encoded);
  }

  @override
  Future<AlbumArtSettings> getAlbumArtSettings() async {
    final raw = _storage.getString(_keyAlbumArtJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return AlbumArtSettings.fromJson(map);
      } catch (_) {}
    }
    return const AlbumArtSettings();
  }

  @override
  Future<void> saveAlbumArtSettings(AlbumArtSettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyAlbumArtJson, encoded);
  }

  @override
  Future<MetadataLyricsSettings> getMetadataLyricsSettings() async {
    final raw = _storage.getString(_keyMetadataJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return MetadataLyricsSettings.fromJson(map);
      } catch (_) {}
    }
    return const MetadataLyricsSettings();
  }

  @override
  Future<void> saveMetadataLyricsSettings(
    MetadataLyricsSettings settings,
  ) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyMetadataJson, encoded);
  }

  @override
  Future<PowerSavingSettings> getPowerSavingSettings() async {
    final raw = _storage.getString(_keyPowerSavingJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return PowerSavingSettings.fromJson(map);
      } catch (_) {}
    }
    return const PowerSavingSettings();
  }

  @override
  Future<void> savePowerSavingSettings(PowerSavingSettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyPowerSavingJson, encoded);
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    final raw = _storage.getString(_keyNotificationJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return NotificationSettings.fromJson(map);
      } catch (_) {}
    }
    return const NotificationSettings();
  }

  @override
  Future<void> saveNotificationSettings(
    NotificationSettings settings,
  ) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyNotificationJson, encoded);
  }

  @override
  Future<PrivacySettings> getPrivacySettings() async {
    final raw = _storage.getString(_keyPrivacyJson);
    if (raw.isSuccess &&
        raw.valueOrNull != null &&
        raw.valueOrNull!.isNotEmpty) {
      try {
        final map = jsonDecode(raw.valueOrNull!) as Map<String, dynamic>;
        return PrivacySettings.fromJson(map);
      } catch (_) {}
    }
    return const PrivacySettings();
  }

  @override
  Future<void> savePrivacySettings(PrivacySettings settings) async {
    final encoded = jsonEncode(settings.toJson());
    await _storage.setString(_keyPrivacyJson, encoded);
  }

  @override
  Future<String> exportSettingsJson() async {
    final audio = await getAudioSettings();
    final control = await getControlSettings();
    final albumArt = await getAlbumArtSettings();
    final metadata = await getMetadataLyricsSettings();
    final powerSaving = await getPowerSavingSettings();
    final notification = await getNotificationSettings();
    final privacy = await getPrivacySettings();

    final exportMap = <String, dynamic>{
      'version': 1,
      'app': 'NEXA Player',
      'exportedAt': DateTime.now().toIso8601String(),
      'audio': audio.toJson(),
      'control': control.toJson(),
      'albumArt': albumArt.toJson(),
      'metadata': metadata.toJson(),
      'powerSaving': powerSaving.toJson(),
      'notification': notification.toJson(),
      'privacy': privacy.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(exportMap);
  }

  @override
  Future<Result<void, Failure>> importSettingsJson(String jsonString) async {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is! Map<String, dynamic>) {
        return const Result.failure(
          ValidationFailure('Invalid settings JSON: Expected a JSON object'),
        );
      }

      if (decoded.containsKey('audio') &&
          decoded['audio'] is Map<String, dynamic>) {
        await saveAudioSettings(
          AudioSettings.fromJson(decoded['audio'] as Map<String, dynamic>),
        );
      }
      if (decoded.containsKey('control') &&
          decoded['control'] is Map<String, dynamic>) {
        await saveControlSettings(
          ControlSettings.fromJson(decoded['control'] as Map<String, dynamic>),
        );
      }
      if (decoded.containsKey('albumArt') &&
          decoded['albumArt'] is Map<String, dynamic>) {
        await saveAlbumArtSettings(
          AlbumArtSettings.fromJson(
            decoded['albumArt'] as Map<String, dynamic>,
          ),
        );
      }
      if (decoded.containsKey('metadata') &&
          decoded['metadata'] is Map<String, dynamic>) {
        await saveMetadataLyricsSettings(
          MetadataLyricsSettings.fromJson(
            decoded['metadata'] as Map<String, dynamic>,
          ),
        );
      }
      if (decoded.containsKey('powerSaving') &&
          decoded['powerSaving'] is Map<String, dynamic>) {
        await savePowerSavingSettings(
          PowerSavingSettings.fromJson(
            decoded['powerSaving'] as Map<String, dynamic>,
          ),
        );
      }
      if (decoded.containsKey('notification') &&
          decoded['notification'] is Map<String, dynamic>) {
        await saveNotificationSettings(
          NotificationSettings.fromJson(
            decoded['notification'] as Map<String, dynamic>,
          ),
        );
      }
      if (decoded.containsKey('privacy') &&
          decoded['privacy'] is Map<String, dynamic>) {
        await savePrivacySettings(
          PrivacySettings.fromJson(decoded['privacy'] as Map<String, dynamic>),
        );
      }

      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        ValidationFailure('Failed to parse settings JSON: $e', e, st),
      );
    }
  }

  @override
  Future<void> resetAllSettingsToDefaults() async {
    await saveAudioSettings(const AudioSettings());
    await saveControlSettings(const ControlSettings());
    await saveAlbumArtSettings(const AlbumArtSettings());
    await saveMetadataLyricsSettings(const MetadataLyricsSettings());
    await savePowerSavingSettings(const PowerSavingSettings());
    await saveNotificationSettings(const NotificationSettings());
    await savePrivacySettings(const PrivacySettings());
  }

  @override
  List<SettingSearchItem> searchSettings(String query) {
    if (query.trim().isEmpty) return const [];
    return _allSettingsCatalog.where((item) => item.matches(query)).toList();
  }

  static const List<SettingSearchItem> _allSettingsCatalog = [
    // Audio Settings
    SettingSearchItem(
      title: 'Gapless Playback',
      subtitle: 'Remove silence between consecutive tracks',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['gapless', 'silence', 'continuous', 'transition', 'audio'],
    ),
    SettingSearchItem(
      title: 'Crossfade on Track Change',
      subtitle: 'Smooth transition crossfade between songs',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['crossfade', 'blend', 'transition', 'fade', 'overlap'],
    ),
    SettingSearchItem(
      title: 'Crossfade Length',
      subtitle: 'Duration slider from 1 to 12 seconds',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['duration', 'seconds', 'crossfade', 'slider'],
    ),
    SettingSearchItem(
      title: 'Fading on Play / Pause',
      subtitle: 'Gradual volume ramp when playing or pausing audio',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['fade in', 'fade out', 'ramp', 'pause', 'play'],
    ),
    SettingSearchItem(
      title: 'Audio Buffer Size',
      subtitle: 'Buffer latency: Low (50ms), Medium (100ms), High (200ms)',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['buffer', 'latency', 'dropouts', 'underrun'],
    ),
    SettingSearchItem(
      title: 'Audio Output Routing',
      subtitle:
          'Direct routing to Auto, Speaker, Headset, Bluetooth, or USB DAC',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['output', 'routing', 'dac', 'usb', 'bluetooth', 'speaker'],
    ),
    SettingSearchItem(
      title: 'Sample Rate',
      subtitle: 'Hardware clock: Auto, 44.1, 48, 88.2, 96, or 192 kHz',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['sample rate', 'khz', 'resample', 'high res', 'audiophile'],
    ),
    SettingSearchItem(
      title: 'Bit Depth Output',
      subtitle: 'Studio depth: 16-bit, 24-bit, or 32-bit float',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['bit depth', '24 bit', '32 bit float', 'precision', 'hires'],
    ),
    SettingSearchItem(
      title: 'Dithering',
      subtitle: 'Noise shaping: Off, Triangular, or Shaped psychoacoustic',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['dither', 'quantization', 'noise shaping', 'triangular'],
    ),
    SettingSearchItem(
      title: 'Hi-Res Audio Mode',
      subtitle: 'Bypass standard OS mixer for bit-perfect output',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['hires', 'bit-perfect', 'exclusive', 'dac', 'lossless'],
    ),
    SettingSearchItem(
      title: 'ReplayGain Normalization',
      subtitle: 'Loudness correction: Off, Track, Album, or Smart RG',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['replaygain', 'loudness', 'normalize', 'volume', 'smart'],
    ),
    SettingSearchItem(
      title: 'ReplayGain Preamp',
      subtitle: 'Gain bias from -12 dB to +12 dB',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['preamp', 'gain', 'db', 'decibels', 'boost'],
    ),
    SettingSearchItem(
      title: 'Direct Volume Control (DVC)',
      subtitle: 'Hardware volume bypass for optimal dynamic range',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['dvc', 'direct volume', 'hardware', 'dynamic range'],
    ),
    SettingSearchItem(
      title: 'Stereo Widening',
      subtitle: 'Off, Software spatializer, or Hardware expander',
      category: 'Audio Settings',
      route: AppRoutes.audioSettings,
      keywords: ['stereo', 'spatial', 'widening', 'soundstage', 'surround'],
    ),

    // Control Settings
    SettingSearchItem(
      title: 'Resume After Call',
      subtitle: 'Auto-resume music playback when phone call terminates',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['call', 'phone', 'resume', 'telephony', 'ring'],
    ),
    SettingSearchItem(
      title: 'Audio Focus Policy',
      subtitle:
          'Handle incoming alerts and navigation speech without abrupt cutoffs',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['focus', 'ducking', 'alert', 'notification interrupt'],
    ),
    SettingSearchItem(
      title: 'Headset Unplugged Behavior',
      subtitle: 'Action on headphone removal: Pause, Stop, or Nothing',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['headset', 'unplug', 'disconnect', 'pause'],
    ),
    SettingSearchItem(
      title: 'On Bluetooth Connected',
      subtitle: 'Auto-play or resume when Bluetooth receiver connects',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['bluetooth', 'car', 'connect', 'autoplay'],
    ),
    SettingSearchItem(
      title: 'Volume Buttons Action',
      subtitle: 'Volume, skip tracks on long press, or fast seek',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['volume buttons', 'hardware keys', 'skip track'],
    ),
    SettingSearchItem(
      title: 'Shake For Next Track',
      subtitle: 'Accelerometer shake gesture to advance to the next track',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['shake', 'gesture', 'accelerometer', 'next'],
    ),
    SettingSearchItem(
      title: 'Car Mode',
      subtitle: 'High-contrast landscape mode with oversized touch targets',
      category: 'Control Settings',
      route: AppRoutes.controlSettings,
      keywords: ['car', 'driving', 'auto', 'dashboard', 'large buttons'],
    ),

    // Album Art
    SettingSearchItem(
      title: 'Download Missing Covers',
      subtitle: 'Fetch high-resolution album artwork from online providers',
      category: 'Album Art',
      route: AppRoutes.albumArtSettings,
      keywords: ['cover', 'artwork', 'download', 'art', 'image'],
    ),
    SettingSearchItem(
      title: 'Wi-Fi Only Downloads',
      subtitle: 'Restrict artwork downloads to unmetered connections',
      category: 'Album Art',
      route: AppRoutes.albumArtSettings,
      keywords: ['wifi', 'cellular', 'data saver', 'metered'],
    ),
    SettingSearchItem(
      title: 'Cover Download Quality',
      subtitle: 'Resolution: Low, Medium, High, or Original source',
      category: 'Album Art',
      route: AppRoutes.albumArtSettings,
      keywords: ['quality', 'resolution', 'high res', 'cover size'],
    ),
    SettingSearchItem(
      title: 'Clear Covers Cache',
      subtitle: 'Free storage space by clearing local artwork cache',
      category: 'Album Art',
      route: AppRoutes.albumArtSettings,
      keywords: ['clear cache', 'storage', 'delete art', 'disk'],
    ),
    SettingSearchItem(
      title: 'Embedded Art Priority',
      subtitle: 'Choose whether ID3 tag artwork overrides downloaded art',
      category: 'Album Art',
      route: AppRoutes.albumArtSettings,
      keywords: ['embedded', 'id3', 'tag', 'priority', 'source'],
    ),
    SettingSearchItem(
      title: 'Blurred Art Background',
      subtitle: 'Intensity of blurred album art backdrop in player view',
      category: 'Album Art',
      route: AppRoutes.albumArtSettings,
      keywords: ['blur', 'background', 'backdrop', 'glass', 'visual'],
    ),

    // Scanner
    SettingSearchItem(
      title: 'Media Scan Folders',
      subtitle: 'Manage included and excluded music directories',
      category: 'Media Scanner',
      route: AppRoutes.scannerSettings,
      keywords: ['scanner', 'folder', 'directories', 'music paths', 'scan'],
    ),
    SettingSearchItem(
      title: 'Skip Short Audio Files',
      subtitle: 'Ignore ringtones and sound effects under minimum duration',
      category: 'Media Scanner',
      route: AppRoutes.scannerSettings,
      keywords: ['short audio', 'ringtone', 'filter', 'duration'],
    ),
    SettingSearchItem(
      title: 'Skip .nomedia Directories',
      subtitle: 'Respect Android standard .nomedia exclusion markers',
      category: 'Media Scanner',
      route: AppRoutes.scannerSettings,
      keywords: ['nomedia', 'hidden', 'exclude', 'system'],
    ),

    // Themes & Appearance
    SettingSearchItem(
      title: 'Theme Presets',
      subtitle:
          'Obsidian, Tokyo Neon, Cyberpunk, Velvet, Sakura, Amber, Emerald, Daylight',
      category: 'Theme & Appearance',
      route: AppRoutes.themePicker,
      keywords: ['theme', 'palette', 'dark mode', 'obsidian', 'color', 'neon'],
    ),
    SettingSearchItem(
      title: 'Custom Theme Editor',
      subtitle: 'Interactive live HSL color editor for background and accents',
      category: 'Theme & Appearance',
      route: AppRoutes.customTheme,
      keywords: ['custom theme', 'color picker', 'hsl', 'accent', 'editor'],
    ),
    SettingSearchItem(
      title: 'Design System Widget Showcase',
      subtitle:
          'Interactive gallery of all glass buttons, cards, faders, sliders',
      category: 'Theme & Appearance',
      route: AppRoutes.designSystem,
      keywords: ['design system', 'showcase', 'widgets', 'lab', 'components'],
    ),

    // Equalizer & DSP
    SettingSearchItem(
      title: 'Equalizer & DSP Engine',
      subtitle: '10-Band Parametric EQ, Z-Bass, Reverb, Presets',
      category: 'Equalizer & DSP',
      route: AppRoutes.equalizer,
      keywords: [
        'equalizer',
        'eq',
        'bass boost',
        'reverb',
        'dsp',
        'faders',
        'bands'
      ],
    ),

    // Metadata & Lyrics
    SettingSearchItem(
      title: 'Auto-Fetch Synchronized Lyrics',
      subtitle: 'Query LRCLIB online for synchronized karaoke lyrics',
      category: 'Lyrics & Metadata',
      route: AppRoutes.metadataSettings,
      keywords: ['lyrics', 'lrc', 'karaoke', 'synced lyrics', 'lrclib'],
    ),
    SettingSearchItem(
      title: 'Lyrics Font Size',
      subtitle: 'Adjust readability of synchronized lyrics lines',
      category: 'Lyrics & Metadata',
      route: AppRoutes.metadataSettings,
      keywords: ['lyrics font', 'text size', 'karaoke scale'],
    ),
    SettingSearchItem(
      title: 'Lyrics Highlight Color',
      subtitle: 'Active singing line glow color',
      category: 'Lyrics & Metadata',
      route: AppRoutes.metadataSettings,
      keywords: ['highlight color', 'lyrics glow', 'active line'],
    ),
    SettingSearchItem(
      title: 'Tag Writeback to File',
      subtitle:
          'Save edited artist, title, album tags directly into audio files',
      category: 'Lyrics & Metadata',
      route: AppRoutes.metadataSettings,
      keywords: ['tag editor', 'writeback', 'id3', 'save file'],
    ),

    // Power Saving
    SettingSearchItem(
      title: 'Power Saving Mode',
      subtitle: 'Reduce CPU utilization and frame rate when battery is low',
      category: 'Power Saving',
      route: AppRoutes.powerSavingSettings,
      keywords: ['power', 'battery', 'energy', 'save', 'cpu'],
    ),
    SettingSearchItem(
      title: 'Wake Lock',
      subtitle: 'Prevent Android CPU deep-sleep during music playback',
      category: 'Power Saving',
      route: AppRoutes.powerSavingSettings,
      keywords: [
        'wake lock',
        'cpu sleep',
        'keep awake',
        'background playback'
      ],
    ),

    // Notifications & Widgets
    SettingSearchItem(
      title: 'Playback Notification Actions',
      subtitle: 'Customize 5 media notification button slots',
      category: 'Notifications & Widgets',
      route: AppRoutes.notificationSettings,
      keywords: [
        'notification',
        'status bar',
        'actions',
        'buttons',
        'media style'
      ],
    ),
    SettingSearchItem(
      title: 'Android Auto & CarPlay',
      subtitle: 'Enable dashboard automotive media browsing',
      category: 'Notifications & Widgets',
      route: AppRoutes.notificationSettings,
      keywords: ['android auto', 'carplay', 'vehicle', 'automotive'],
    ),

    // Privacy & Backup
    SettingSearchItem(
      title: 'Export Settings Backup',
      subtitle: 'Save complete JSON backup of all configurations',
      category: 'Privacy & Storage',
      route: AppRoutes.privacySettings,
      keywords: ['export', 'backup', 'json', 'save settings', 'share'],
    ),
    SettingSearchItem(
      title: 'Import Settings Restore',
      subtitle: 'Restore application configuration from a JSON file or text',
      category: 'Privacy & Storage',
      route: AppRoutes.privacySettings,
      keywords: ['import', 'restore', 'load settings', 'json'],
    ),
    SettingSearchItem(
      title: 'Clear Playback & Search History',
      subtitle: 'Reset recently played songs and search queries',
      category: 'Privacy & Storage',
      route: AppRoutes.privacySettings,
      keywords: ['clear history', 'recent searches', 'privacy', 'reset'],
    ),

    // Visualizer & Spectrum Engine
    SettingSearchItem(
      title: 'Visualizer Style',
      subtitle: 'Bars, Circle, Wave, Spectrogram, VU Meter',
      category: 'Visualizer & Spectrum',
      route: AppRoutes.visualizerSettings,
      keywords: ['visualizer', 'spectrum', 'fft', 'bars', 'vu meter', 'circle', 'wave'],
    ),
    SettingSearchItem(
      title: 'Visualizer Color Accent',
      subtitle: 'Neon Cyan, Electric Orchid, Cyber Gold, Hot Pink, Emerald Neon, Amber Flame',
      category: 'Visualizer & Spectrum',
      route: AppRoutes.visualizerSettings,
      keywords: ['color', 'accent', 'visualizer', 'neon', 'glow', 'spectrum'],
    ),
    SettingSearchItem(
      title: 'Visualizer Sensitivity',
      subtitle: 'Magnitude dynamic gain from 0.5x to 2.5x',
      category: 'Visualizer & Spectrum',
      route: AppRoutes.visualizerSettings,
      keywords: ['sensitivity', 'gain', 'amplitude', 'visualizer', 'fft'],
    ),
    SettingSearchItem(
      title: 'Visualizer Frame Rate (FPS)',
      subtitle: 'Cap animation rate: 30, 60, or 120 FPS',
      category: 'Visualizer & Spectrum',
      route: AppRoutes.visualizerSettings,
      keywords: ['fps', 'framerate', 'smoothness', '120hz', '60fps'],
    ),

    // About
    SettingSearchItem(
      title: 'About NEXA Player',
      subtitle: 'Version 1.0.0 "Obsidian", changelog, developer info, licenses',
      category: 'About NEXA',
      route: AppRoutes.aboutSettings,
      keywords: [
        'about',
        'version',
        'license',
        'credits',
        'developer',
        'changelog'
      ],
    ),
  ];
}
