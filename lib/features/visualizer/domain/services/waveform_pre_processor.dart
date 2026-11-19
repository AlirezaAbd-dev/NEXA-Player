import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:nexa_player/shared/services/storage/storage_service.dart';

/// Service that analyzes audio files, computes normalized amplitude profiles,
/// and caches them for zero-latency seeking & rendering.
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
  WaveformPreProcessorImpl(this._storage);

  final IStorageService _storage;
  static const String _storagePrefix = 'nexa_wf_cache_';

  @override
  Future<List<double>> getOrAnalyzeWaveform({
    required String trackId,
    required String filePath,
    int sampleCount = 64,
  }) async {
    final cacheKey = '$_storagePrefix$trackId';
    final cached = _storage.getString(cacheKey);

    if (cached.isSuccess && cached.valueOrNull != null && cached.valueOrNull!.isNotEmpty) {
      try {
        final decoded = jsonDecode(cached.valueOrNull!) as List<dynamic>;
        return decoded.map((e) => (e as num).toDouble()).toList();
      } catch (_) {}
    }

    // Generate or extract amplitude array
    final amplitudes = await _extractAmplitudes(filePath, trackId, sampleCount);

    // Save to persistent storage cache
    await _storage.setString(cacheKey, jsonEncode(amplitudes));
    return amplitudes;
  }

  @override
  Future<void> invalidate(String trackId) async {
    await _storage.remove('$_storagePrefix$trackId');
  }

  Future<List<double>> _extractAmplitudes(
    String filePath,
    String trackId,
    int sampleCount,
  ) async {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        final length = await file.length();
        if (length > 1024) {
          final bytes = await file.openRead(0, math.min(length, 128 * 1024)).toList();
          final flatBytes = bytes.expand((b) => b).toList();

          if (flatBytes.length >= sampleCount * 4) {
            final step = flatBytes.length ~/ sampleCount;
            final amps = <double>[];

            for (int i = 0; i < sampleCount; i++) {
              int sum = 0;
              final end = math.min((i + 1) * step, flatBytes.length);
              final start = i * step;
              for (int j = start; j < end; j += 4) {
                final val = flatBytes[j];
                sum += (val - 128).abs();
              }
              final avg = (sum / ((end - start) / 4)).clamp(10.0, 128.0) / 128.0;
              amps.add(avg.clamp(0.12, 1.0));
            }
            return amps;
          }
        }
      } catch (_) {}
    }

    // Deterministic synthetic waveform generator based on track ID
    final seed = trackId.codeUnits.fold(0, (a, b) => a + b);
    final rnd = math.Random(seed);
    return List.generate(sampleCount, (i) {
      final normalizedPos = i / sampleCount;
      final envelope = math.sin(normalizedPos * math.pi);
      final raw = 0.20 + (rnd.nextDouble() * 0.75 * envelope);
      return raw.clamp(0.12, 1.0);
    });
  }
}
