import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../features/scanner/data/pure_dart_audio_metadata_reader.dart';
import '../../../shared/models/track.dart';
import '../../../shared/services/database/app_database.dart';
import '../../../shared/services/database/database_schema.dart';
import '../../utils/audio_quality_formatter.dart';

/// Hydrates accurate audio bitrate, sample rate, bit depth, channels, and codec
/// for tracks that were previously scanned with missing/`0` telemetry (e.g. Android 10
/// MediaStore upgrades), persisting hydrated specs back into SQLite off the UI thread.
abstract interface class IAudioTelemetryService {
  /// Hydrates telemetry for a single [track], returning an enriched copy if updated.
  Future<Track> hydrateTrackTelemetry(Track track);

  /// Runs a lightweight asynchronous background pass over tracks in SQLite that have
  /// missing/`<= 0` bitrate or missing sample rate/codec.
  Future<int> backfillMissingTelemetry({int batchLimit = 60});
}

class AudioTelemetryService implements IAudioTelemetryService {
  AudioTelemetryService({
    IAppDatabase? database,
    Future<Map<String, dynamic>?> Function(Track track)? nativeExtractor,
  })  : _database = database,
        _nativeExtractor = nativeExtractor ?? _defaultNativeExtractor;

  final IAppDatabase? _database;
  final Future<Map<String, dynamic>?> Function(Track track) _nativeExtractor;
  final Map<String, Future<Track>> _inFlight = {};

  static const MethodChannel _channel =
      MethodChannel('com.nexa.player/media_store');

  static Future<Map<String, dynamic>?> _defaultNativeExtractor(
    Track track,
  ) async {
    if (kIsWeb || !Platform.isAndroid || track.filePath == null) return null;
    try {
      final raw = await _channel.invokeMapMethod<String, dynamic>(
        'extractAudioTelemetry',
        {
          'filePath': track.filePath,
          'fileSize': track.fileSize ?? 0,
          'durationMs': track.duration.inMilliseconds,
        },
      );
      return raw;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Track> hydrateTrackTelemetry(Track track) {
    final hasBitrate = (AudioQualityFormatter.normalizeKbps(track.bitrate) ?? 0) > 0;
    final hasCodec = track.codec != null && track.codec!.isNotEmpty;
    final hasSampleRate = (track.sampleRate ?? 0) > 0;
    if (hasBitrate && hasCodec && hasSampleRate) {
      return Future.value(track);
    }

    final existing = _inFlight[track.id];
    if (existing != null) return existing;

    final future = _hydrateInternal(track).whenComplete(() {
      _inFlight.remove(track.id);
    });
    _inFlight[track.id] = future;
    return future;
  }

  Future<Track> _hydrateInternal(Track track) async {
    int? bitrate = AudioQualityFormatter.normalizeKbps(track.bitrate);
    int? sampleRate = track.sampleRate;
    int? bitDepth = track.bitDepth;
    int? channels = track.channels;
    String? codec = track.codec;

    final nativeData = await _nativeExtractor(track);
    if (nativeData != null) {
      bitrate = AudioQualityFormatter.normalizeKbps(
            (nativeData['bitrate'] as num?)?.toInt(),
          ) ??
          bitrate;
      sampleRate = (nativeData['sample_rate'] as num?)?.toInt() ?? sampleRate;
      bitDepth = (nativeData['bit_depth'] as num?)?.toInt() ?? bitDepth;
      channels = (nativeData['channels'] as num?)?.toInt() ?? channels;
      codec = (nativeData['codec'] as String?) ?? codec;
    }

    // Pure-Dart fallback off UI isolate for desktop or when native returned partial info
    final filePath = track.filePath;
    if ((bitrate == null || sampleRate == null || codec == null) &&
        filePath != null &&
        filePath.isNotEmpty) {
      final file = File(filePath);
      if (await file.exists()) {
        try {
          final size = await file.length();
          if (size >= 12 && size <= 32 * 1024 * 1024) {
            final meta = await compute(_isolateExtractMeta, filePath);
            if (meta != null) {
              bitrate ??= AudioQualityFormatter.normalizeKbps(meta.bitrate);
              sampleRate ??= meta.sampleRate;
              bitDepth ??= meta.bitDepth;
              channels ??= meta.channels;
              codec ??= meta.codec;
            }
          }
          bitrate ??= AudioQualityFormatter.resolveEffectiveKbps(
            fileSize: size,
            duration: track.duration,
          );
        } catch (_) {}
      }
    }

    bitrate ??= AudioQualityFormatter.resolveTrackKbps(track);
    codec ??= AudioQualityFormatter.inferCodec(track);

    final updated = track.copyWith(
      bitrate: bitrate ?? track.bitrate,
      sampleRate: sampleRate ?? track.sampleRate,
      bitDepth: bitDepth ?? track.bitDepth,
      channels: channels ?? track.channels,
      codec: codec ?? track.codec,
    );

    if (_database != null && updated != track) {
      try {
        _database.execute('''
          UPDATE ${DatabaseSchema.tableTracks}
          SET ${DatabaseSchema.colBitrate} = COALESCE(?, ${DatabaseSchema.colBitrate}),
              ${DatabaseSchema.colSampleRate} = COALESCE(?, ${DatabaseSchema.colSampleRate}),
              ${DatabaseSchema.colBitDepth} = COALESCE(?, ${DatabaseSchema.colBitDepth}),
              ${DatabaseSchema.colChannels} = COALESCE(?, ${DatabaseSchema.colChannels}),
              ${DatabaseSchema.colCodec} = COALESCE(?, ${DatabaseSchema.colCodec})
          WHERE ${DatabaseSchema.colId} = ?;
        ''', [
          updated.bitrate,
          updated.sampleRate,
          updated.bitDepth,
          updated.channels,
          updated.codec,
          updated.id,
        ]);
      } catch (_) {}
    }

    return updated;
  }

  static Future<dynamic> _isolateExtractMeta(String path) async {
    try {
      return await const PureDartAudioMetadataReader().extract(File(path));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> backfillMissingTelemetry({int batchLimit = 60}) async {
    final db = _database;
    if (db == null || db.isClosed) return 0;

    final rows = db.select('''
      SELECT * FROM ${DatabaseSchema.tableTracks}
      WHERE ${DatabaseSchema.colBitrate} IS NULL
         OR ${DatabaseSchema.colBitrate} <= 0
         OR ${DatabaseSchema.colSampleRate} IS NULL
         OR ${DatabaseSchema.colCodec} IS NULL
      LIMIT ?;
    ''', [batchLimit]);

    var updatedCount = 0;
    for (final row in rows) {
      final track = Track.fromMap(row);
      final hydrated = await hydrateTrackTelemetry(track);
      if (hydrated != track) {
        updatedCount++;
      }
      // Yield back to UI event loop between files for 60fps pacing
      await Future<void>.delayed(Duration.zero);
    }
    return updatedCount;
  }
}
