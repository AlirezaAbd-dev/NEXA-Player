import 'dart:math' as math;
import 'dart:typed_data';
import 'package:fftea/fftea.dart';

/// Engine that performs real-time audio FFT spectral transformations
/// and frequency bin grouping.
class FftEngine {
  FftEngine({this.size = 64}) : _fft = FFT(size) {
    _window = Window.hanning(size);
  }

  final int size;
  final FFT _fft;
  late final Float64List _window;

  /// Computes normalized frequency magnitudes (0.0 .. 1.0) for an input audio sample buffer.
  List<double> computeMagnitudes(List<double> audioSamples, {double sensitivity = 1.0}) {
    if (audioSamples.isEmpty) {
      return List<double>.filled(size ~/ 2, 0.0);
    }

    final input = Float64List(size);
    final count = math.min(size, audioSamples.length);
    for (int i = 0; i < count; i++) {
      input[i] = audioSamples[i] * _window[i];
    }

    final freq = _fft.realFft(input);
    final rawMags = freq.magnitudes();
    final half = size ~/ 2;
    final magnitudes = List<double>.filled(half, 0.0);

    for (int i = 0; i < half; i++) {
      final mag = rawMags[i];
      // Logarithmic scaling for human ear perception
      final logMag = (math.log(1.0 + mag) / 4.0) * sensitivity;
      magnitudes[i] = logMag.clamp(0.0, 1.0);
    }

    return magnitudes;
  }

  /// Synthesizes realistic audio time-domain samples based on position, bass, and playback dynamics.
  static List<double> synthesizeTimeDomainSamples({
    required int sampleCount,
    required double positionSeconds,
    required bool isPlaying,
    double bassMultiplier = 1.0,
    double midMultiplier = 1.0,
    double trebleMultiplier = 1.0,
    double sensitivity = 1.0,
    int seed = 42,
  }) {
    if (!isPlaying) {
      return List<double>.filled(sampleCount, 0.0);
    }

    final samples = List<double>.filled(sampleCount, 0.0);
    final rnd = math.Random(seed + (positionSeconds * 10).toInt());

    // Generate harmonic combination of low, mid, and high frequencies + transient noise
    final t0 = positionSeconds * 2.0 * math.pi;
    for (int i = 0; i < sampleCount; i++) {
      final phase = t0 + (i / sampleCount) * 4.0 * math.pi;
      final low = math.sin(phase * 1.5) * 0.45 * bassMultiplier * sensitivity;
      final mid = math.sin(phase * 4.2 + 0.5) * 0.30 * midMultiplier * sensitivity;
      final high = math.cos(phase * 8.8) * 0.15 * trebleMultiplier * sensitivity;
      final noise = (rnd.nextDouble() - 0.5) * 0.10 * sensitivity;
      samples[i] = (low + mid + high + noise).clamp(-1.0, 1.0);
    }

    return samples;
  }
}
