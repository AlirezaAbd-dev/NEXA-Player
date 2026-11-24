import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/services/audio/audio_telemetry_service.dart';
import 'package:nexa_player/core/utils/audio_quality_formatter.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:path/path.dart' as p;

/// Builds a minimal ID3v2 + MPEG1 Layer III frame at 192 kbps / 44100 Hz / Stereo.
Uint8List _buildMp3WithFrame({
  required int bitrateIndex,
  int sampleRateIndex = 0, // 44100 Hz
  int channelMode = 0, // Stereo
  int totalBytes = 4096,
}) {
  const id3 = [0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00];
  // Byte 0: 0xFF
  // Byte 1: 111 11(MPEG1) 01(Layer III) 1(no CRC) = 0xFB
  // Byte 2: bitrateIdx(4) | srIdx(2) | pad(0) | priv(0)
  // Byte 3: channelMode(2) | modeExt(0) | copy(0) | orig(0) | emph(0)
  final b2 = ((bitrateIndex & 0x0F) << 4) | ((sampleRateIndex & 0x03) << 2);
  final b3 = (channelMode & 0x03) << 6;
  final out = Uint8List(totalBytes);
  out.setRange(0, id3.length, id3);
  out[10] = 0xFF;
  out[11] = 0xFB;
  out[12] = b2;
  out[13] = b3;
  return out;
}

/// Builds a minimal FLAC header encoding sampleRate, channels, bitDepth, totalSamples.
Uint8List _buildFlacBytes({
  required int sampleRate,
  required int channels,
  required int bitDepth,
  required int totalSamples,
  int fileLength = 1060000,
}) {
  final out = Uint8List(fileLength);
  out[0] = 0x66;
  out[1] = 0x4C;
  out[2] = 0x61;
  out[3] = 0x43;
  out[4] = 0x80; // last block = STREAMINFO
  out[7] = 34;

  // bytes 18..20 hold sampleRate (20 bits), channels-1 (3 bits), bitDepth-1 top bit (1 bit)
  final sr = sampleRate & 0xFFFFF;
  final ch = (channels - 1) & 0x07;
  final bd = (bitDepth - 1) & 0x1F;
  out[18] = (sr >> 12) & 0xFF;
  out[19] = (sr >> 4) & 0xFF;
  out[20] = ((sr & 0x0F) << 4) | (ch << 1) | ((bd >> 4) & 0x01);
  out[21] = ((bd & 0x0F) << 4) | ((totalSamples >> 32) & 0x0F);
  out[22] = (totalSamples >> 24) & 0xFF;
  out[23] = (totalSamples >> 16) & 0xFF;
  out[24] = (totalSamples >> 8) & 0xFF;
  out[25] = totalSamples & 0xFF;
  return out;
}

void main() {
  group('AudioQualityFormatter & API 29 Fallback Tests', () {
    test('normalizes both bps (320000) and kbps (320) without dividing kbps by 1000', () {
      expect(AudioQualityFormatter.normalizeKbps(320000), 320);
      expect(AudioQualityFormatter.normalizeKbps(320), 320);
      expect(AudioQualityFormatter.normalizeKbps(192), 192);
      expect(AudioQualityFormatter.normalizeKbps(128), 128);
      expect(AudioQualityFormatter.normalizeKbps(1411), 1411);
      expect(AudioQualityFormatter.normalizeKbps(1411200), 1411);
      expect(AudioQualityFormatter.normalizeKbps(0), isNull);
      expect(AudioQualityFormatter.normalizeKbps(-128), isNull);
    });

    test('computes API 29 fallback average bitrate cleanly from fileSize and duration', () {
      // 7.2 MB (7,200,000 bytes) over 180 seconds = 320 kbps
      final kbps = AudioQualityFormatter.resolveEffectiveKbps(
        bitrate: 0,
        fileSize: 7200000,
        duration: const Duration(seconds: 180),
      );
      expect(kbps, 320);

      // ~35.5 MB FLAC over 100 seconds = 2840 kbps
      final flacKbps = AudioQualityFormatter.resolveEffectiveKbps(
        bitrate: null,
        fileSize: 35500000,
        duration: const Duration(seconds: 100),
      );
      expect(flacKbps, 2840);
    });

    test('never renders "0 KBPS" in any formatter output even when bitrate/size are 0 or null', () {
      const zeroFlac = Track(
        id: 'trk-0-flac',
        title: 'Unknown Rate FLAC',
        artist: 'Artist',
        duration: Duration.zero,
        bitrate: 0,
        fileSize: 0,
        filePath: '/music/lossless.flac',
      );
      final badge = AudioQualityFormatter.formatNowPlayingBadge(zeroFlac);
      final signal = AudioQualityFormatter.formatSignalChainFormat(zeroFlac);

      expect(badge.toUpperCase(), isNot(contains('0 KBPS')));
      expect(signal.toUpperCase(), isNot(contains('0 KBPS')));
      expect(badge, equals('FLAC • STEREO'));
      expect(signal, equals('FLAC'));

      const zeroNoPath = Track(
        id: 'trk-0-none',
        title: 'Plain',
        artist: 'Artist',
        duration: Duration.zero,
        bitrate: 0,
      );
      expect(
        AudioQualityFormatter.formatNowPlayingBadge(zeroNoPath),
        equals('STEREO'),
      );
    });

    test('formats Hi-Res FLAC, MP3, AAC, OPUS cleanly with commas & tabular precision', () {
      const flac = Track(
        id: 't1',
        title: 'Master',
        artist: 'Artist',
        duration: Duration(minutes: 4),
        bitrate: 2840,
        sampleRate: 96000,
        bitDepth: 24,
        channels: 2,
        codec: 'FLAC',
        filePath: '/music/master.flac',
      );
      expect(
        AudioQualityFormatter.formatNowPlayingBadge(flac),
        'FLAC · 96 kHz / 24-bit · 2,840 KBPS',
      );
      expect(
        AudioQualityFormatter.formatSignalChainFormat(flac),
        'FLAC · 2,840 kbps',
      );
      expect(
        AudioQualityFormatter.formatSamplePrecision(flac),
        '96 kHz / 24-bit',
      );

      const mp3StoredInKbps = Track(
        id: 't2',
        title: 'Song',
        artist: 'Artist',
        duration: Duration(minutes: 3),
        bitrate: 320,
        filePath: '/music/song.mp3',
      );
      expect(
        AudioQualityFormatter.formatNowPlayingBadge(mp3StoredInKbps),
        '320 KBPS • STEREO',
      );

      const opusMono = Track(
        id: 't3',
        title: 'Voice',
        artist: 'Host',
        duration: Duration(minutes: 5),
        bitrate: 96,
        channels: 1,
        codec: 'OPUS',
        filePath: '/podcasts/ep1.opus',
      );
      expect(
        AudioQualityFormatter.formatNowPlayingBadge(opusMono),
        'OPUS · 96 KBPS • MONO',
      );
    });
  });

  group('PureDartAudioMetadataReader Audio Telemetry Extraction', () {
    const reader = PureDartAudioMetadataReader();

    test('extracts real MPEG frame bitrate (192 kbps), sample rate (44100), and channels', () {
      // Index 11 in MPEG1 Layer III table = 192 kbps
      final bytes = _buildMp3WithFrame(bitrateIndex: 11, sampleRateIndex: 0, channelMode: 0);
      final meta = reader.extractBytes(bytes, 'MP3 Song');
      expect(meta.bitrate, 192);
      expect(meta.sampleRate, 44100);
      expect(meta.channels, 2);
      expect(meta.codec, 'MP3');
    });

    test('extracts real FLAC sample rate, bit depth (24-bit), channels, and computed kbps', () {
      // 96kHz, 2ch, 24-bit, 3 seconds (288000 samples), ~1,065,000 bytes => ~2840 kbps
      final bytes = _buildFlacBytes(
        sampleRate: 96000,
        channels: 2,
        bitDepth: 24,
        totalSamples: 288000,
        fileLength: 1065000,
      );
      final meta = reader.extractBytes(bytes, 'HiRes FLAC');
      expect(meta.sampleRate, 96000);
      expect(meta.bitDepth, 24);
      expect(meta.channels, 2);
      expect(meta.bitrate, 2840);
      expect(meta.codec, 'FLAC');
    });
  });

  group('AudioTelemetryService SQLite Backfill', () {
    test('hydrates existing SQLite tracks with bitrate <= 0 and persists real metrics', () async {
      final dir = Directory.systemTemp.createTempSync('nexa_telemetry_test_');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final mp3File = File(p.join(dir.path, 'legacy_0kbps.mp3'));
      mp3File.writeAsBytesSync(_buildMp3WithFrame(bitrateIndex: 9)); // 128 kbps

      final db = AppDatabase.inMemory();
      addTearDown(db.close);

      db.execute('''
        INSERT INTO ${DatabaseSchema.tableTracks} (
          ${DatabaseSchema.colId}, ${DatabaseSchema.colTitle}, ${DatabaseSchema.colTrackArtist},
          ${DatabaseSchema.colTrackAlbum}, ${DatabaseSchema.colDurationMs}, ${DatabaseSchema.colTrackFilePath},
          ${DatabaseSchema.colBitrate}, ${DatabaseSchema.colFileSize}, ${DatabaseSchema.colDateAdded}
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''', [
        'trk-legacy-0',
        'Legacy Track',
        'Artist',
        'Album',
        180000,
        mp3File.path,
        0,
        mp3File.lengthSync(),
        1000,
      ]);

      final service = AudioTelemetryService(database: db);
      final count = await service.backfillMissingTelemetry();
      expect(count, 1);

      final rows = db.select(
        'SELECT ${DatabaseSchema.colBitrate}, ${DatabaseSchema.colSampleRate}, ${DatabaseSchema.colCodec} FROM ${DatabaseSchema.tableTracks} WHERE ${DatabaseSchema.colId} = ?',
        ['trk-legacy-0'],
      );
      expect(rows.first['bitrate'], 128);
      expect(rows.first['sample_rate'], 44100);
      expect(rows.first['codec'], 'MP3');
    });
  });
}
