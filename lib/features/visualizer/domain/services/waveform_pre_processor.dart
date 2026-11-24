import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

/// Service that analyzes audio files in a background isolate, computes normalized
/// amplitude profiles, and caches them in SQLite (with key-value fallback) for
/// zero-latency seeking & rendering.
abstract interface class IWaveformPreProcessor {
  /// Analyzes an audio file at [filePath] or returns cached amplitude array.
  Future<List<double>> getOrAnalyzeWaveform({
    required String trackId,
    required String filePath,
    int sampleCount = 64,
  });

  /// Clears cached waveform for [trackId].
  Future<void> invalidate(String trackId);
}

class WaveformPreProcessorImpl implements IWaveformPreProcessor {
  WaveformPreProcessorImpl(this._storage, {IAppDatabase? database})
      : _database = database;

  final IStorageService _storage;
  final IAppDatabase? _database;
  static const String _storagePrefix = 'nexa_wf_cache_';

  @override
  Future<List<double>> getOrAnalyzeWaveform({
    required String trackId,
    required String filePath,
    int sampleCount = 64,
  }) async {
    // 1. Check SQLite cache first when available and count matches
    final dbCached = _readFromDatabase(trackId, sampleCount);
    if (dbCached != null && dbCached.isNotEmpty) {
      return dbCached;
    }

    // 2. Check legacy key-value cache for backwards compatibility
    final cacheKey = '$_storagePrefix$trackId';
    final cached = _storage.getString(cacheKey);
    if (cached.isSuccess &&
        cached.valueOrNull != null &&
        cached.valueOrNull!.isNotEmpty) {
      try {
        final decoded = (jsonDecode(cached.valueOrNull!) as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList();
        if (decoded.isNotEmpty) {
          _writeToDatabase(trackId, decoded);
          return decoded;
        }
      } catch (_) {}
    }

    // 3. Extract amplitude envelope off the UI isolate
    final amplitudes = await Isolate.run(
      () => _extractAmplitudesSync(filePath, trackId, sampleCount),
    );

    // 4. Persist to SQLite + storage cache
    _writeToDatabase(trackId, amplitudes);
    await _storage.setString(cacheKey, jsonEncode(amplitudes));
    return amplitudes;
  }

  @override
  Future<void> invalidate(String trackId) async {
    final db = _database;
    if (db != null && !db.isClosed) {
      try {
        db.execute(
          'DELETE FROM ${DatabaseSchema.tableTrackWaveforms} '
          'WHERE ${DatabaseSchema.colTrackId} = ?;',
          [trackId],
        );
      } catch (_) {}
    }
    await _storage.remove('$_storagePrefix$trackId');
  }

  List<double>? _readFromDatabase(String trackId, int expectedSampleCount) {
    final db = _database;
    if (db == null || db.isClosed) return null;
    try {
      final rows = db.select(
        'SELECT sample_count, amplitudes_json '
        'FROM ${DatabaseSchema.tableTrackWaveforms} '
        'WHERE ${DatabaseSchema.colTrackId} = ? LIMIT 1;',
        [trackId],
      );
      if (rows.isEmpty) return null;
      final row = rows.first;
      final storedCount = row['sample_count'] as int?;
      final rawJson = row['amplitudes_json'] as String?;
      if (rawJson == null || rawJson.isEmpty) return null;
      final decoded = (jsonDecode(rawJson) as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
      if (storedCount != null &&
          storedCount != expectedSampleCount &&
          decoded.length != expectedSampleCount) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  void _writeToDatabase(String trackId, List<double> amplitudes) {
    final db = _database;
    if (db == null || db.isClosed) return;
    try {
      db.execute(
        'INSERT OR REPLACE INTO ${DatabaseSchema.tableTrackWaveforms} '
        '(${DatabaseSchema.colTrackId}, sample_count, amplitudes_json, ${DatabaseSchema.colUpdatedAt}) '
        'VALUES (?, ?, ?, ?);',
        [
          trackId,
          amplitudes.length,
          jsonEncode(amplitudes),
          DateTime.now().millisecondsSinceEpoch,
        ],
      );
    } catch (_) {}
  }

  /// Extracts [sampleCount] amplitude values evenly distributed across the
  /// audio payload in a worker isolate, skipping ID3/container headers.
  static List<double> _extractAmplitudesSync(
    String filePath,
    String trackId,
    int sampleCount,
  ) {
    final safeCount = math.max(1, sampleCount);
    final file = File(filePath);
    if (filePath.isNotEmpty && file.existsSync()) {
      RandomAccessFile? raf;
      try {
        final totalLen = file.lengthSync();
        if (totalLen > 1024) {
          raf = file.openSync(mode: FileMode.read);
          final header = raf.readSync(math.min(128, totalLen));
          int payloadStart = 0;
          bool isPcm16Wav = false;

          // Parse RIFF/WAVE PCM chunk if present
          if (header.length >= 44 &&
              header[0] == 0x52 &&
              header[1] == 0x49 &&
              header[2] == 0x46 &&
              header[3] == 0x46 &&
              header[8] == 0x57 &&
              header[9] == 0x41 &&
              header[10] == 0x56 &&
              header[11] == 0x45) {
            final bitsPerSample = header[34] | (header[35] << 8);
            final audioFormat = header[20] | (header[21] << 8);
            isPcm16Wav = audioFormat == 1 && bitsPerSample == 16;
            payloadStart = _findWaveDataOffset(raf, totalLen) ?? 44;
          } else if (header.length >= 10 &&
              header[0] == 0x49 &&
              header[1] == 0x44 &&
              header[2] == 0x33) {
            // Skip ID3v2 tag + embedded album artwork completely
            final id3Size = ((header[6] & 0x7F) << 21) |
                ((header[7] & 0x7F) << 14) |
                ((header[8] & 0x7F) << 7) |
                (header[9] & 0x7F);
            payloadStart = math.min(totalLen - 512, 10 + id3Size).clamp(0, totalLen);
          }

          final payloadEnd = math
              .max(payloadStart + safeCount * 16, totalLen - 128)
              .clamp(payloadStart, totalLen);
          final payloadLen = payloadEnd - payloadStart;

          if (payloadLen >= safeCount * 8) {
            final rawEnergies = List<double>.filled(safeCount, 0.0);
            const windowBytes = 2048;

            for (int i = 0; i < safeCount; i++) {
              final bucketStart = payloadStart + ((payloadLen * i) ~/ safeCount);
              final bucketEnd = payloadStart + ((payloadLen * (i + 1)) ~/ safeCount);
              final span = math.max(1, bucketEnd - bucketStart);
              final readOffset = span > windowBytes
                  ? bucketStart + ((span - windowBytes) ~/ 2)
                  : bucketStart;
              final toRead = math.min(windowBytes, totalLen - readOffset);
              if (toRead <= 0) continue;

              raf.setPositionSync(readOffset);
              final chunk = raf.readSync(toRead);
              rawEnergies[i] = isPcm16Wav
                  ? _computePcm16Rms(chunk)
                  : _computeCompressedWindowEnergy(chunk);
            }

            // Dynamic normalization preserves intros, drops, and choruses
            double minE = rawEnergies.first;
            double maxE = rawEnergies.first;
            for (final e in rawEnergies) {
              if (e < minE) minE = e;
              if (e > maxE) maxE = e;
            }
            final range = maxE - minE;
            if (range > 1e-5) {
              return rawEnergies
                  .map((e) => (0.14 + ((e - minE) / range) * 0.86).clamp(0.12, 1.0))
                  .toList();
            }
            return rawEnergies.map((e) => e.clamp(0.18, 0.95)).toList();
          }
        }
      } catch (_) {
      } finally {
        try {
          raf?.closeSync();
        } catch (_) {}
      }
    }

    // Deterministic fallback for virtual/missing demo paths
    final seed = trackId.codeUnits.fold(0, (a, b) => a + b);
    final rnd = math.Random(seed);
    return List.generate(safeCount, (i) {
      final normalizedPos = i / safeCount;
      final envelope = math.sin(normalizedPos * math.pi);
      final raw = 0.20 + (rnd.nextDouble() * 0.75 * envelope);
      return raw.clamp(0.12, 1.0);
    });
  }

  static int? _findWaveDataOffset(RandomAccessFile raf, int totalLen) {
    try {
      int pos = 12;
      final chunkHeader = Uint8List(8);
      while (pos + 8 <= totalLen) {
        raf.setPositionSync(pos);
        if (raf.readIntoSync(chunkHeader) < 8) break;
        final id = String.fromCharCodes(chunkHeader.sublist(0, 4));
        final size = chunkHeader[4] |
            (chunkHeader[5] << 8) |
            (chunkHeader[6] << 16) |
            (chunkHeader[7] << 24);
        if (id == 'data') return pos + 8;
        if (size <= 0) break;
        pos += 8 + size + (size.isOdd ? 1 : 0);
      }
    } catch (_) {}
    return null;
  }

  static double _computePcm16Rms(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return 0.0;
    double sumSq = 0.0;
    for (int i = 0; i < sampleCount; i++) {
      final lo = bytes[2 * i];
      final hi = bytes[2 * i + 1];
      int sample = lo | (hi << 8);
      if (sample >= 0x8000) sample -= 0x10000;
      final norm = sample / 32768.0;
      sumSq += norm * norm;
    }
    return math.sqrt(sumSq / sampleCount);
  }

  static double _computeCompressedWindowEnergy(Uint8List bytes) {
    if (bytes.length < 4) return 0.2;
    int deltaSum = 0;
    for (int i = 1; i < bytes.length; i++) {
      deltaSum += (bytes[i] - bytes[i - 1]).abs();
    }
    return deltaSum / (bytes.length - 1);
  }
}
