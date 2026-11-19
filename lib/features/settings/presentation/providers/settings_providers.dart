import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/service_providers.dart';
export 'package:nexa_player/core/di/service_providers.dart' show settingsServiceProvider;
import '../../domain/models/audio_settings.dart';
import '../../domain/models/control_settings.dart';
import '../../domain/models/album_art_settings.dart';
import '../../domain/models/metadata_lyrics_settings.dart';
import '../../domain/models/power_saving_settings.dart';
import '../../domain/models/notification_settings.dart';
import '../../domain/models/privacy_settings.dart';
import '../../domain/models/setting_search_item.dart';
import '../../domain/services/settings_service.dart';

/// Reactive notifier for Audio Engine Settings.
class AudioSettingsNotifier extends StateNotifier<AudioSettings> {
  AudioSettingsNotifier(this._service) : super(const AudioSettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getAudioSettings();
    state = s;
  }

  Future<void> update(AudioSettings updated) async {
    state = updated;
    await _service.saveAudioSettings(updated);
  }
}

final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return AudioSettingsNotifier(service);
});

/// Reactive notifier for Control Settings.
class ControlSettingsNotifier extends StateNotifier<ControlSettings> {
  ControlSettingsNotifier(this._service) : super(const ControlSettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getControlSettings();
    state = s;
  }

  Future<void> update(ControlSettings updated) async {
    state = updated;
    await _service.saveControlSettings(updated);
  }
}

final controlSettingsProvider =
    StateNotifierProvider<ControlSettingsNotifier, ControlSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return ControlSettingsNotifier(service);
});

/// Reactive notifier for Album Art Settings.
class AlbumArtSettingsNotifier extends StateNotifier<AlbumArtSettings> {
  AlbumArtSettingsNotifier(this._service) : super(const AlbumArtSettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getAlbumArtSettings();
    state = s;
  }

  Future<void> update(AlbumArtSettings updated) async {
    state = updated;
    await _service.saveAlbumArtSettings(updated);
  }
}

final albumArtSettingsProvider =
    StateNotifierProvider<AlbumArtSettingsNotifier, AlbumArtSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return AlbumArtSettingsNotifier(service);
});

/// Reactive notifier for Lyrics & Metadata Settings.
class MetadataLyricsSettingsNotifier
    extends StateNotifier<MetadataLyricsSettings> {
  MetadataLyricsSettingsNotifier(this._service)
      : super(const MetadataLyricsSettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getMetadataLyricsSettings();
    state = s;
  }

  Future<void> update(MetadataLyricsSettings updated) async {
    state = updated;
    await _service.saveMetadataLyricsSettings(updated);
  }
}

final metadataLyricsSettingsProvider = StateNotifierProvider<
    MetadataLyricsSettingsNotifier, MetadataLyricsSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return MetadataLyricsSettingsNotifier(service);
});

/// Reactive notifier for Power Saving Settings.
class PowerSavingSettingsNotifier extends StateNotifier<PowerSavingSettings> {
  PowerSavingSettingsNotifier(this._service)
      : super(const PowerSavingSettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getPowerSavingSettings();
    state = s;
  }

  Future<void> update(PowerSavingSettings updated) async {
    state = updated;
    await _service.savePowerSavingSettings(updated);
  }
}

final powerSavingSettingsProvider =
    StateNotifierProvider<PowerSavingSettingsNotifier, PowerSavingSettings>(
        (ref) {
  final service = ref.watch(settingsServiceProvider);
  return PowerSavingSettingsNotifier(service);
});

/// Reactive notifier for Notification & Widget Settings.
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier(this._service)
      : super(const NotificationSettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getNotificationSettings();
    state = s;
  }

  Future<void> update(NotificationSettings updated) async {
    state = updated;
    await _service.saveNotificationSettings(updated);
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsNotifier, NotificationSettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return NotificationSettingsNotifier(service);
});

/// Reactive notifier for Privacy Settings.
class PrivacySettingsNotifier extends StateNotifier<PrivacySettings> {
  PrivacySettingsNotifier(this._service) : super(const PrivacySettings()) {
    _load();
  }

  final ISettingsService _service;

  Future<void> _load() async {
    final s = await _service.getPrivacySettings();
    state = s;
  }

  Future<void> update(PrivacySettings updated) async {
    state = updated;
    await _service.savePrivacySettings(updated);
  }
}

final privacySettingsProvider =
    StateNotifierProvider<PrivacySettingsNotifier, PrivacySettings>((ref) {
  final service = ref.watch(settingsServiceProvider);
  return PrivacySettingsNotifier(service);
});

/// Settings in-hub search query state.
final settingsSearchQueryProvider = StateProvider<String>((ref) => '');

/// Computed search results filtering catalog by active query.
final settingsSearchResultsProvider =
    Provider<List<SettingSearchItem>>((ref) {
  final query = ref.watch(settingsSearchQueryProvider);
  final service = ref.watch(settingsServiceProvider);
  return service.searchSettings(query);
});
