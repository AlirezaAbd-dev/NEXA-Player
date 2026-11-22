import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/visualizer/domain/services/fft_engine.dart';

void main() {
  group('Performance Benchmark: Audio DSP & FFT Processing', () {
    test('FFT spectral magnitude calculation throughput across 1,000 blocks', () {
      final engine = FftEngine(size: 64);
      final random = math.Random(42);
      final buffer = List<double>.generate(64, (_) => (random.nextDouble() * 2.0) - 1.0);

      final stopwatch = Stopwatch()..start();
      const iterations = 1000;

      for (var i = 0; i < iterations; i++) {
        final mags = engine.computeMagnitudes(buffer, sensitivity: 1.2);
        expect(mags.length, 32);
      }
      stopwatch.stop();

      final totalUs = stopwatch.elapsedMicroseconds;
      final avgUsPerBlock = totalUs / iterations;
      // ignore: avoid_print
      print('🚀 [Benchmark] 64-Point Hanning Real-FFT: ${avgUsPerBlock.toStringAsFixed(2)} µs per block '
          '($iterations blocks processed in ${stopwatch.elapsedMilliseconds}ms)');

      // Must complete in less than 200 µs (0.2 ms) per block (well under the 16.6 ms 60 FPS frame window)
      expect(avgUsPerBlock, lessThan(200.0),
          reason: 'FFT transformation took longer than 0.2ms per block');
    });

    test('Higher-order 256-point FFT throughput benchmark', () {
      final engine = FftEngine(size: 256);
      final random = math.Random(1337);
      final buffer = List<double>.generate(256, (_) => (random.nextDouble() * 2.0) - 1.0);

      final stopwatch = Stopwatch()..start();
      const iterations = 500;

      for (var i = 0; i < iterations; i++) {
        final mags = engine.computeMagnitudes(buffer, sensitivity: 1.0);
        expect(mags.length, 128);
      }
      stopwatch.stop();

      final avgUsPerBlock = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print('🚀 [Benchmark] 256-Point Hi-Res FFT: ${avgUsPerBlock.toStringAsFixed(2)} µs per block');

      expect(avgUsPerBlock, lessThan(500.0));
    });

    test('Equalizer preset calculation and band modulation throughput (10,000 updates)', () async {
      final eq = PureDartEqualizerService();
      final stopwatch = Stopwatch()..start();
      const iterations = 10000;

      for (var i = 0; i < iterations; i++) {
        final gain = ((i % 24) - 12).toDouble();
        await eq.setBandGain(i % 10, gain);
      }
      stopwatch.stop();

      final avgUs = stopwatch.elapsedMicroseconds / iterations;
      // ignore: avoid_print
      print('🚀 [Benchmark] 10-Band EQ Modulation: ${avgUs.toStringAsFixed(2)} µs per parameter update');

      expect(avgUs, lessThan(50.0),
          reason: 'Equalizer parameter update was slower than 50 µs');
    });
  });
}
