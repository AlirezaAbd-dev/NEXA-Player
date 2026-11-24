import 'dart:math' as math;
import 'dart:typed_data';

/// Acoustic FFT processor that converts raw Android `Visualizer` FFT pairs
/// or linear spectrum bins into logarithmically spaced octave bands across
/// `32 Hz -> 16 kHz` with dB compression, ballistic smoothing, peak hold,
/// and deterministic `300ms` silence decay.
class FftSpectrumProcessor {
  FftSpectrumProcessor({
    this.bandCount = 64,
    this.sampleRate = 44100,
    this.minFreqHz = 32.0,
    this.maxFreqHz = 16000.0,
    this.smoothing = 0.65,
    this.sensitivity = 1.0,
  })  : assert(bandCount > 0),
        _smoothed = List<double>.filled(bandCount, 0.0),
        _peaks = List<double>.filled(bandCount, 0.0);

  final int bandCount;
  final int sampleRate;
  final double minFreqHz;
  final double maxFreqHz;
  double smoothing;
  double sensitivity;

  final List<double> _smoothed;
  final List<double> _peaks;
  double _silenceElapsedMs = 0.0;

  static const double _noiseFloor = 1e-4;
  static const double _minDb = -55.0;
  static const double _maxSilenceMs = 300.0;

  /// Current smoothed band magnitudes (`0.0 .. 1.0`).
  List<double> get smoothedBands => List<double>.unmodifiable(_smoothed);

  /// Current decaying peak-hold markers (`0.0 .. 1.0`).
  List<double> get peakHolds => List<double>.unmodifiable(_peaks);

  /// Average sub-bass energy (`20–80 Hz`, lowest octave bands) normalized `0.0 .. 1.0`.
  double get subBassEnergy {
    if (_smoothed.isEmpty) return 0.0;
    final subCount = math.max(1, (bandCount * 0.10).round().clamp(1, 6));
    double sum = 0.0;
    for (int i = 0; i < subCount; i++) {
      sum += _smoothed[i];
    }
    return _sanitizeUnit(sum / subCount);
  }

  /// Logarithmic center frequencies (`Hz`) for each band across `[minFreqHz, maxFreqHz]`.
  List<double> get bandCenterFrequencies {
    final nyquist = sampleRate > 0 ? sampleRate / 2.0 : 22050.0;
    final effectiveMax = math.min(maxFreqHz, nyquist).clamp(minFreqHz + 1.0, nyquist);
    final ratio = effectiveMax / minFreqHz;
    return List<double>.generate(bandCount, (i) {
      final f0 = minFreqHz * math.pow(ratio, i / bandCount);
      final f1 = minFreqHz * math.pow(ratio, (i + 1) / bandCount);
      return math.sqrt(f0 * f1);
    });
  }

  /// Maps raw Android `Visualizer.onFftDataCapture` byte array into [bandCount]
  /// smoothed logarithmic bands.
  List<double> processAndroidFftBytes(
    Uint8List rawBytes, {
    required bool isPlaying,
    int? captureSize,
    double dtMs = 16.7,
  }) {
    if (!isPlaying || rawBytes.length < 4) {
      return decayToSilence(dtMs);
    }

    final n = captureSize != null && captureSize >= 4 ? captureSize : rawBytes.length;
    final pairCount = rawBytes.length ~/ 2;
    if (pairCount <= 1) {
      return decayToSilence(dtMs);
    }

    // Android FFT format: [Re0, Re(n/2), Re1, Im1, Re2, Im2, ...]
    final linearMags = List<double>.filled(pairCount, 0.0);
    final dc = rawBytes[0].toSigned(8).abs() / 128.0;
    linearMags[0] = _sanitizeNonNegative(dc * 0.25);

    double rmsSq = 0.0;
    for (int k = 1; k < pairCount; k++) {
      final re = rawBytes[2 * k].toSigned(8) / 128.0;
      final im = rawBytes[2 * k + 1].toSigned(8) / 128.0;
      final mag = math.sqrt(re * re + im * im);
      final safeMag = _sanitizeNonNegative(mag);
      linearMags[k] = safeMag;
      rmsSq += safeMag * safeMag;
    }

    final rms = math.sqrt(rmsSq / math.max(1, pairCount - 1));
    if (rms < _noiseFloor) {
      return decayToSilence(dtMs);
    }

    return processLinearMagnitudes(
      linearMags,
      isPlaying: true,
      captureSize: n,
      dtMs: dtMs,
    );
  }

  /// Maps raw FFT bin magnitudes (e.g. `0 .. captureSize/2`) logarithmically
  /// across `32 Hz -> 16 kHz` into [bandCount] smoothed bands.
  List<double> processLinearMagnitudes(
    List<double> linearMags, {
    required bool isPlaying,
    required int captureSize,
    double dtMs = 16.7,
  }) {
    if (!isPlaying || linearMags.isEmpty || captureSize <= 0) {
      return decayToSilence(dtMs);
    }

    double rmsSq = 0.0;
    int validCount = 0;
    for (final m in linearMags) {
      final s = _sanitizeNonNegative(m);
      rmsSq += s * s;
      validCount++;
    }
    if (validCount == 0 || math.sqrt(rmsSq / validCount) < _noiseFloor) {
      return decayToSilence(dtMs);
    }

    _silenceElapsedMs = 0.0;

    final nyquist = sampleRate > 0 ? sampleRate / 2.0 : 22050.0;
    final effectiveMax = math.min(maxFreqHz, nyquist).clamp(minFreqHz + 1.0, nyquist);
    final ratio = effectiveMax / minFreqHz;
    final maxBinIndex = linearMags.length - 1;
    final binsPerHz = captureSize / math.max(8000, sampleRate);

    final targets = List<double>.filled(bandCount, 0.0);
    for (int b = 0; b < bandCount; b++) {
      final fLow = minFreqHz * math.pow(ratio, b / bandCount);
      final fHigh = minFreqHz * math.pow(ratio, (b + 1) / bandCount);

      final binLow = (fLow * binsPerHz).clamp(0.0, maxBinIndex.toDouble());
      final binHigh = (fHigh * binsPerHz).clamp(binLow, maxBinIndex.toDouble());

      double rawEnergy = 0.0;
      final lowIdx = binLow.floor();
      final highIdx = binHigh.ceil().clamp(lowIdx, maxBinIndex);

      if (highIdx - lowIdx <= 1) {
        // Fractional linear interpolation for narrow sub-bass octave bands.
        final centerBin = ((binLow + binHigh) * 0.5).clamp(0.0, maxBinIndex.toDouble());
        final i0 = centerBin.floor().clamp(0, maxBinIndex);
        final i1 = math.min(i0 + 1, maxBinIndex);
        final frac = centerBin - i0;
        final v0 = _sanitizeNonNegative(linearMags[i0]);
        final v1 = _sanitizeNonNegative(linearMags[i1]);
        rawEnergy = v0 * (1.0 - frac) + v1 * frac;
      } else {
        double sumSq = 0.0;
        int nBins = 0;
        for (int k = lowIdx; k <= highIdx; k++) {
          final v = _sanitizeNonNegative(linearMags[k]);
          sumSq += v * v;
          nBins++;
        }
        rawEnergy = nBins > 0 ? math.sqrt(sumSq / nBins) : 0.0;
      }

      // dB compression [-55 dB .. 0 dB] -> [0.0 .. 1.0]
      final db = 20.0 * (math.log(rawEnergy + 1e-6) / math.ln10);
      final normalizedDb = ((db - _minDb) / (-_minDb)).clamp(0.0, 1.0);
      targets[b] = _sanitizeUnit(normalizedDb * sensitivity);
    }

    return _applyBallistics(targets, dtMs);
  }

  /// Synthesizes a smooth spectrum reaction directly from a real pre-computed
  /// per-track RMS waveform envelope when OS live FFT capture is unavailable.
  List<double> processWaveformEnvelopeFallback(
    List<double> trackWaveform, {
    required double progress,
    required bool isPlaying,
    double dtMs = 16.7,
  }) {
    if (!isPlaying || trackWaveform.isEmpty) {
      return decayToSilence(dtMs);
    }

    _silenceElapsedMs = 0.0;
    final p = progress.isNaN || progress.isInfinite ? 0.0 : progress.clamp(0.0, 1.0);
    final exactIdx = p * (trackWaveform.length - 1);
    final i0 = exactIdx.floor().clamp(0, trackWaveform.length - 1);
    final i1 = math.min(i0 + 1, trackWaveform.length - 1);
    final frac = exactIdx - i0;
    final envA = _sanitizeUnit(trackWaveform[i0]);
    final envB = _sanitizeUnit(trackWaveform[i1]);
    final envelope = envA * (1.0 - frac) + envB * frac;

    if (envelope < _noiseFloor) {
      return decayToSilence(dtMs);
    }

    final phase = p * math.pi * 24.0;
    final targets = List<double>.filled(bandCount, 0.0);
    for (int b = 0; b < bandCount; b++) {
      final normBand = b / math.max(1, bandCount - 1);
      // Warm acoustic tilt: slightly higher low/mid energy with natural treble roll-off.
      final tilt = 1.05 - normBand * 0.48;
      final neighborIdx = ((i0 + (b % 5) - 2).clamp(0, trackWaveform.length - 1));
      final localVar = _sanitizeUnit(trackWaveform[neighborIdx]);
      final ripple = 0.80 + 0.20 * math.sin(phase + normBand * math.pi * 3.0).abs();
      final val = ((envelope * 0.72 + localVar * 0.28) * tilt * ripple * sensitivity);
      targets[b] = _sanitizeUnit(val);
    }

    return _applyBallistics(targets, dtMs);
  }

  /// Smoothly decays all bands toward `0.0` during pause/silence and guarantees
  /// complete convergence to `0.0` within `300ms`.
  List<double> decayToSilence(double dtMs) {
    final safeDt = dtMs.isNaN || dtMs.isInfinite || dtMs <= 0 ? 16.7 : dtMs;
    _silenceElapsedMs += safeDt;

    if (_silenceElapsedMs >= _maxSilenceMs) {
      for (int i = 0; i < bandCount; i++) {
        _smoothed[i] = 0.0;
        _peaks[i] = 0.0;
      }
      return smoothedBands;
    }

    final progress = (_silenceElapsedMs / _maxSilenceMs).clamp(0.0, 1.0);
    final stepDecay = math.pow(0.008, safeDt / _maxSilenceMs).toDouble();
    final remainingCap = 1.0 - progress;

    for (int i = 0; i < bandCount; i++) {
      final next = (_smoothed[i] * stepDecay).clamp(0.0, remainingCap);
      _smoothed[i] = next < 0.003 ? 0.0 : _sanitizeUnit(next);
      final nextPeak = (_peaks[i] * stepDecay).clamp(0.0, remainingCap);
      _peaks[i] = nextPeak < 0.003 ? 0.0 : _sanitizeUnit(nextPeak);
    }
    return smoothedBands;
  }

  /// Resets all smoothed and peak states immediately to `0.0`.
  void reset() {
    _silenceElapsedMs = 0.0;
    for (int i = 0; i < bandCount; i++) {
      _smoothed[i] = 0.0;
      _peaks[i] = 0.0;
    }
  }

  List<double> _applyBallistics(List<double> targets, double dtMs) {
    final safeDt = dtMs.isNaN || dtMs.isInfinite || dtMs <= 0 ? 16.7 : dtMs;
    final clampedSmoothing = smoothing.clamp(0.0, 0.95);
    // Attack responds rapidly (~75%), decay scales with smoothing setting.
    final attackAlpha = (1.0 - clampedSmoothing * 0.45).clamp(0.35, 1.0);
    final decayTimeConstant = 0.04 + clampedSmoothing * 0.18;
    final decayAlpha = (1.0 - math.exp(-(safeDt / 1000.0) / decayTimeConstant)).clamp(0.08, 1.0);
    final peakDecay = math.pow(0.92, safeDt / 16.7).toDouble();

    for (int i = 0; i < bandCount; i++) {
      final target = _sanitizeUnit(targets[i]);
      final current = _smoothed[i];
      final alpha = target >= current ? attackAlpha : decayAlpha;
      final next = current + (target - current) * alpha;
      _smoothed[i] = _sanitizeUnit(next);

      if (_smoothed[i] >= _peaks[i]) {
        _peaks[i] = _smoothed[i];
      } else {
        _peaks[i] = _sanitizeUnit(math.max(_smoothed[i], _peaks[i] * peakDecay));
      }
    }
    return smoothedBands;
  }

  static double _sanitizeNonNegative(double value) {
    if (value.isNaN || value.isInfinite || value < 0.0) return 0.0;
    return value;
  }

  static double _sanitizeUnit(double value) {
    if (value.isNaN || value.isInfinite) return 0.0;
    return value.clamp(0.0, 1.0);
  }
}
