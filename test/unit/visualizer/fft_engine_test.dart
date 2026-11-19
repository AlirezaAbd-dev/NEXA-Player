import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/visualizer/domain/services/fft_engine.dart';

void main() {
  group('FftEngine Unit Tests', () {
    test('initializes with default size and computes magnitudes', () {
      final engine = FftEngine(size: 64);
      expect(engine.size, equals(64));

      final emptyResult = engine.computeMagnitudes([]);
      expect(emptyResult.length, equals(32));
      expect(emptyResult.every((m) => m == 0.0), isTrue);
    });

    test('computes normalized magnitudes for synthetic audio samples', () {
      final engine = FftEngine(size: 64);
      final samples = FftEngine.synthesizeTimeDomainSamples(
        sampleCount: 64,
        positionSeconds: 1.5,
        isPlaying: true,
      );

      expect(samples.length, equals(64));
      expect(samples.any((s) => s != 0.0), isTrue);

      final magnitudes = engine.computeMagnitudes(samples);
      expect(magnitudes.length, equals(32));
      for (final m in magnitudes) {
        expect(m, greaterThanOrEqualTo(0.0));
        expect(m, lessThanOrEqualTo(1.0));
      }
    });

    test('sensitivity scaling amplifies magnitudes proportionally', () {
      final engine = FftEngine(size: 64);
      final samples = FftEngine.synthesizeTimeDomainSamples(
        sampleCount: 64,
        positionSeconds: 2.0,
        isPlaying: true,
      );

      final normalMags = engine.computeMagnitudes(samples, sensitivity: 1.0);
      final boostedMags = engine.computeMagnitudes(samples, sensitivity: 2.0);

      expect(normalMags.length, equals(boostedMags.length));
      final normalSum = normalMags.reduce((a, b) => a + b);
      final boostedSum = boostedMags.reduce((a, b) => a + b);
      expect(boostedSum, greaterThanOrEqualTo(normalSum));
    });

    test('synthesizeTimeDomainSamples returns silence when paused', () {
      final silent = FftEngine.synthesizeTimeDomainSamples(
        sampleCount: 64,
        positionSeconds: 5.0,
        isPlaying: false,
      );

      expect(silent.length, equals(64));
      expect(silent.every((s) => s == 0.0), isTrue);
    });

    test('synthesizeTimeDomainSamples respects multipliers', () {
      final standard = FftEngine.synthesizeTimeDomainSamples(
        sampleCount: 64,
        positionSeconds: 1.0,
        isPlaying: true,
        bassMultiplier: 1.0,
      );

      final heavyBass = FftEngine.synthesizeTimeDomainSamples(
        sampleCount: 64,
        positionSeconds: 1.0,
        isPlaying: true,
        bassMultiplier: 2.5,
      );

      expect(standard.length, equals(64));
      expect(heavyBass.length, equals(64));
      // Audio samples should remain clamped between -1.0 and 1.0
      expect(heavyBass.every((s) => s >= -1.0 && s <= 1.0), isTrue);
    });
  });
}
