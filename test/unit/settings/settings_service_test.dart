import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/domain/models/audio_settings.dart';
import 'package:nexa_player/features/settings/domain/models/control_settings.dart';
import 'package:nexa_player/features/settings/domain/models/album_art_settings.dart';
import 'package:nexa_player/features/settings/domain/models/metadata_lyrics_settings.dart';
import 'package:nexa_player/features/settings/domain/models/power_saving_settings.dart';
import 'package:nexa_player/features/settings/domain/models/notification_settings.dart';
import 'package:nexa_player/features/settings/domain/models/privacy_settings.dart';
import '../../helpers/mock_services.dart';

void main() {
  late FakeStorageService fakeStorage;
  late SettingsServiceImpl settingsService;

  setUp(() {
    fakeStorage = FakeStorageService();
    settingsService = SettingsServiceImpl(fakeStorage);
  });

  group('SettingsServiceImpl - Defaults & Persistence', () {
    test('returns default AudioSettings when empty', () async {
      final audio = await settingsService.getAudioSettings();
      expect(audio.gaplessPlayback, isTrue);
      expect(audio.crossfadeEnabled, isFalse);
      expect(audio.crossfadeDurationSeconds, equals(3));
      expect(audio.audioBufferSize, equals('medium'));
      expect(audio.dvcEnabled, isTrue);
    });

    test('saves and retrieves modified AudioSettings', () async {
      const customAudio = AudioSettings(
        gaplessPlayback: false,
        crossfadeEnabled: true,
        crossfadeDurationSeconds: 8,
        audioBufferSize: 'high',
        sampleRate: '96',
        bitDepth: '32_float',
        dvcEnabled: false,
      );

      await settingsService.saveAudioSettings(customAudio);
      final retrieved = await settingsService.getAudioSettings();

      expect(retrieved.gaplessPlayback, isFalse);
      expect(retrieved.crossfadeEnabled, isTrue);
      expect(retrieved.crossfadeDurationSeconds, equals(8));
      expect(retrieved.audioBufferSize, equals('high'));
      expect(retrieved.sampleRate, equals('96'));
      expect(retrieved.bitDepth, equals('32_float'));
      expect(retrieved.dvcEnabled, isFalse);
    });

    test('saves and retrieves modified ControlSettings', () async {
      const customControl = ControlSettings(
        resumeAfterCall: false,
        audioFocusPolicy: 'ignore',
        headsetUnpluggedAction: 'stop',
        carMode: true,
        defaultSleepTimerMinutes: 60,
      );

      await settingsService.saveControlSettings(customControl);
      final retrieved = await settingsService.getControlSettings();

      expect(retrieved.resumeAfterCall, isFalse);
      expect(retrieved.audioFocusPolicy, equals('ignore'));
      expect(retrieved.headsetUnpluggedAction, equals('stop'));
      expect(retrieved.carMode, isTrue);
      expect(retrieved.defaultSleepTimerMinutes, equals(60));
    });

    test('saves and retrieves modified AlbumArtSettings', () async {
      const customArt = AlbumArtSettings(
        downloadMissingCovers: false,
        onlyViaWifi: false,
        downloadQuality: 'original',
        blurBackground: 'high',
      );

      await settingsService.saveAlbumArtSettings(customArt);
      final retrieved = await settingsService.getAlbumArtSettings();

      expect(retrieved.downloadMissingCovers, isFalse);
      expect(retrieved.onlyViaWifi, isFalse);
      expect(retrieved.downloadQuality, equals('original'));
      expect(retrieved.blurBackground, equals('high'));
    });

    test('saves and retrieves modified MetadataLyricsSettings', () async {
      const customMeta = MetadataLyricsSettings(
        translateMetadata: true,
        translationProvider: 'deepl',
        lyricsFontSize: 28.0,
        lyricsHighlightColorHex: '0xFFFFD600',
      );

      await settingsService.saveMetadataLyricsSettings(customMeta);
      final retrieved = await settingsService.getMetadataLyricsSettings();

      expect(retrieved.translateMetadata, isTrue);
      expect(retrieved.translationProvider, equals('deepl'));
      expect(retrieved.lyricsFontSize, equals(28.0));
      expect(retrieved.lyricsHighlightColorHex, equals('0xFFFFD600'));
    });

    test('saves and retrieves modified PowerSavingSettings', () async {
      const customPower = PowerSavingSettings(
        powerSavingMode: 'on',
        reduceAnimations: true,
        lowBatteryThresholdPercent: 20,
      );

      await settingsService.savePowerSavingSettings(customPower);
      final retrieved = await settingsService.getPowerSavingSettings();

      expect(retrieved.powerSavingMode, equals('on'));
      expect(retrieved.reduceAnimations, isTrue);
      expect(retrieved.lowBatteryThresholdPercent, equals(20));
    });

    test('saves and retrieves modified NotificationSettings', () async {
      const customNotif = NotificationSettings(
        showPlaybackNotification: false,
        widgetFormat: '4x2',
        androidAuto: false,
      );

      await settingsService.saveNotificationSettings(customNotif);
      final retrieved = await settingsService.getNotificationSettings();

      expect(retrieved.showPlaybackNotification, isFalse);
      expect(retrieved.widgetFormat, equals('4x2'));
      expect(retrieved.androidAuto, isFalse);
    });

    test('saves and retrieves modified PrivacySettings', () async {
      const customPrivacy = PrivacySettings(
        crashReporting: true,
        analytics: true,
      );

      await settingsService.savePrivacySettings(customPrivacy);
      final retrieved = await settingsService.getPrivacySettings();

      expect(retrieved.crashReporting, isTrue);
      expect(retrieved.analytics, isTrue);
    });
  });

  group('SettingsServiceImpl - Export & Import JSON Backup', () {
    test('exports full valid JSON configuration', () async {
      await settingsService.saveAudioSettings(
        const AudioSettings(sampleRate: '192', bitDepth: '24'),
      );
      await settingsService.saveControlSettings(
        const ControlSettings(carMode: true),
      );

      final exported = await settingsService.exportSettingsJson();
      expect(exported, isNotEmpty);

      final decoded = jsonDecode(exported) as Map<String, dynamic>;
      expect(decoded['version'], equals(1));
      expect(decoded['app'], equals('NEXA Player'));
      expect(decoded['audio'], isA<Map<String, dynamic>>());
      expect(decoded['audio']['sampleRate'], equals('192'));
      expect(decoded['control']['carMode'], isTrue);
    });

    test('imports settings from valid JSON', () async {
      final jsonPayload = jsonEncode({
        'version': 1,
        'audio': {
          'gaplessPlayback': false,
          'crossfadeEnabled': true,
          'crossfadeDurationSeconds': 7,
          'sampleRate': '96',
        },
        'control': {
          'carMode': true,
          'defaultSleepTimerMinutes': 45,
        },
      });

      final result = await settingsService.importSettingsJson(jsonPayload);
      expect(result.isSuccess, isTrue);

      final audio = await settingsService.getAudioSettings();
      expect(audio.gaplessPlayback, isFalse);
      expect(audio.crossfadeEnabled, isTrue);
      expect(audio.crossfadeDurationSeconds, equals(7));
      expect(audio.sampleRate, equals('96'));

      final control = await settingsService.getControlSettings();
      expect(control.carMode, isTrue);
      expect(control.defaultSleepTimerMinutes, equals(45));
    });

    test('returns failure on malformed JSON import', () async {
      final result = await settingsService.importSettingsJson('invalid-json{{{');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Failed to parse settings JSON'));
    });

    test('resets all settings back to factory defaults', () async {
      await settingsService.saveAudioSettings(
        const AudioSettings(gaplessPlayback: false, crossfadeDurationSeconds: 12),
      );
      await settingsService.saveControlSettings(
        const ControlSettings(carMode: true),
      );

      await settingsService.resetAllSettingsToDefaults();

      final audio = await settingsService.getAudioSettings();
      expect(audio.gaplessPlayback, isTrue);
      expect(audio.crossfadeDurationSeconds, equals(3));

      final control = await settingsService.getControlSettings();
      expect(control.carMode, isFalse);
    });
  });

  group('SettingsServiceImpl - Settings Search', () {
    test('returns empty results on empty query', () {
      final results = settingsService.searchSettings('');
      expect(results, isEmpty);
    });

    test('finds crossfade setting by keyword', () {
      final results = settingsService.searchSettings('crossfade');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.title.contains('Crossfade')), isTrue);
      expect(results.first.category, equals('Audio Settings'));
    });

    test('finds car mode setting by keyword', () {
      final results = settingsService.searchSettings('car');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.title == 'Car Mode'), isTrue);
      expect(results.firstWhere((r) => r.title == 'Car Mode').category,
          equals('Control Settings'));
    });

    test('finds lyrics settings by keyword', () {
      final results = settingsService.searchSettings('lyrics');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.category == 'Lyrics & Metadata'), isTrue);
    });
  });
}
