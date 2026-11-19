import 'package:nexa_player/core/utils/result.dart';
import '../models/audio_settings.dart';
import '../models/control_settings.dart';
import '../models/album_art_settings.dart';
import '../models/metadata_lyrics_settings.dart';
import '../models/power_saving_settings.dart';
import '../models/notification_settings.dart';
import '../models/privacy_settings.dart';
import '../models/setting_search_item.dart';

/// Contract for persistent settings storage, queries, and JSON backup/restore.
abstract interface class ISettingsService {
  Future<AudioSettings> getAudioSettings();
  Future<void> saveAudioSettings(AudioSettings settings);

  Future<ControlSettings> getControlSettings();
  Future<void> saveControlSettings(ControlSettings settings);

  Future<AlbumArtSettings> getAlbumArtSettings();
  Future<void> saveAlbumArtSettings(AlbumArtSettings settings);

  Future<MetadataLyricsSettings> getMetadataLyricsSettings();
  Future<void> saveMetadataLyricsSettings(MetadataLyricsSettings settings);

  Future<PowerSavingSettings> getPowerSavingSettings();
  Future<void> savePowerSavingSettings(PowerSavingSettings settings);

  Future<NotificationSettings> getNotificationSettings();
  Future<void> saveNotificationSettings(NotificationSettings settings);

  Future<PrivacySettings> getPrivacySettings();
  Future<void> savePrivacySettings(PrivacySettings settings);

  /// Exports all application settings as an indented JSON configuration string.
  Future<String> exportSettingsJson();

  /// Validates and imports settings from a JSON configuration string.
  Future<Result<void, Failure>> importSettingsJson(String jsonString);

  /// Resets all settings to their initial factory default state.
  Future<void> resetAllSettingsToDefaults();

  /// Searches all setting items using fuzzy/substring keyword matching.
  List<SettingSearchItem> searchSettings(String query);
}
