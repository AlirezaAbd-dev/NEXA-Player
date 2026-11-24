import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/visualizer/domain/services/fft_spectrum_processor.dart';
import 'package:nexa_player/features/visualizer/domain/services/waveform_pre_processor.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/painters/bars_visualizer_painter.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('FftSpectrumProcessor Unit Tests', () {
    test('logarithmic frequency center mapping spans 32 Hz to 16 kHz monotonically', () {
      final processor = FftSpectrumProcessor(
        bandCount: 32,
        sampleRate: 44100,
        minFreqHz: 32.0,
        maxFreqHz: 16000.0,
      );

      final freqs = processor.bandCenterFrequencies;
      expect(freqs.length, equals(32));
      expect(freqs.first, greaterThan(32.0));
      expect(freqs.first, lessThan(45.0));
      expect(freqs.last, lessThanOrEqualTo(16000.0));
      expect(freqs.last, greaterThan(12000.0));

      for (int i = 1; i < freqs.length; i++) {
        expect(freqs[i], greaterThan(freqs[i - 1]));
      }
    });

    test('log binning maps bass and treble energy into matching octave regions', () {
      const captureSize = 1024;
      const sampleRate = 44100;
      const bandCount = 24;

      // Low frequency (~64 Hz -> bin ~1.5) concentrates energy in lower bands
      final bassBins = List<double>.filled(captureSize ~/ 2, 0.0);
      bassBins[1] = 1.0;
      bassBins[2] = 0.8;

      final bassProc = FftSpectrumProcessor(
        bandCount: bandCount,
        sampleRate: sampleRate,
        smoothing: 0.0,
      );
      final bassOut = bassProc.processLinearMagnitudes(
        bassBins,
        isPlaying: true,
        captureSize: captureSize,
      );
      expect(bassOut.length, equals(bandCount));
      final lowThirdAvg =
          bassOut.sublist(0, 6).reduce((a, b) => a + b) / 6;
      final highThirdAvg =
          bassOut.sublist(18, 24).reduce((a, b) => a + b) / 6;
      expect(lowThirdAvg, greaterThan(highThirdAvg));

      // High frequency (~6 kHz -> bin ~139) concentrates energy in upper bands
      final trebleBins = List<double>.filled(captureSize ~/ 2, 0.0);
      trebleBins[139] = 1.0;
      trebleBins[140] = 0.9;

      final trebleProc = FftSpectrumProcessor(
        bandCount: bandCount,
        sampleRate: sampleRate,
        smoothing: 0.0,
      );
      final trebleOut = trebleProc.processLinearMagnitudes(
        trebleBins,
        isPlaying: true,
        captureSize: captureSize,
      );
      final trebleLowAvg =
          trebleOut.sublist(0, 6).reduce((a, b) => a + b) / 6;
      final trebleHighAvg =
          trebleOut.sublist(16, 22).reduce((a, b) => a + b) / 6;
      expect(trebleHighAvg, greaterThan(trebleLowAvg));
    });

    test('decays smoothly to exact 0.0 within 300ms when paused or silent', () {
      final processor = FftSpectrumProcessor(
        bandCount: 16,
        smoothing: 0.75,
        sensitivity: 1.5,
      );

      final raw = Uint8List(1024);
      for (int i = 2; i < raw.length; i += 2) {
        raw[i] = 90;
        raw[i + 1] = 60;
      }

      final active = processor.processAndroidFftBytes(
        raw,
        isPlaying: true,
        captureSize: 1024,
        dtMs: 16.7,
      );
      expect(active.any((v) => v > 0.2), isTrue);

      // Pause playback -> decay ticks over 300ms must reach exact 0.0
      List<double> current = active;
      for (int i = 0; i < 18; i++) {
        current = processor.processAndroidFftBytes(
          raw,
          isPlaying: false,
          captureSize: 1024,
          dtMs: 16.7,
        );
      }

      expect(current.every((v) => v == 0.0), isTrue);
      expect(processor.subBassEnergy, equals(0.0));
    });

    test('safely handles NaN, Infinity, and negative values', () {
      final processor = FftSpectrumProcessor(bandCount: 16);
      final dirty = [
        double.nan,
        double.infinity,
        double.negativeInfinity,
        -12.5,
        0.5,
        double.nan,
        1e308,
        0.0,
      ];

      final result = processor.processLinearMagnitudes(
        dirty,
        isPlaying: true,
        captureSize: 16,
      );
      expect(result.length, equals(16));
      for (final v in result) {
        expect(v.isNaN, isFalse);
        expect(v.isInfinite, isFalse);
        expect(v, inInclusiveRange(0.0, 1.0));
      }

      final envResult = processor.processWaveformEnvelopeFallback(
        [double.nan, 0.4, double.infinity, -1.0],
        progress: double.nan,
        isPlaying: true,
        dtMs: double.infinity,
      );
      for (final v in envResult) {
        expect(v.isNaN, isFalse);
        expect(v.isInfinite, isFalse);
        expect(v, inInclusiveRange(0.0, 1.0));
      }
    });

    test('computeVisualizerBarGeometry fits inside width from 360dp to 1280dp', () {
      for (final width in [360.0, 412.0, 800.0, 1280.0]) {
        for (final count in [8, 24, 32, 64, 128]) {
          final geom = computeVisualizerBarGeometry(width, count);
          expect(geom.barWidth, greaterThan(0.0));
          expect(geom.gap, greaterThanOrEqualTo(0.0));
          final totalSpan = count * geom.barWidth + (count - 1) * geom.gap;
          expect(
            totalSpan,
            lessThanOrEqualTo(width + 1e-6),
            reason: 'Overflowed width=$width for count=$count (span=$totalSpan)',
          );
        }
      }
    });

    test('WaveformPreProcessorImpl computes real PCM dynamics and caches in SQLite', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = SharedPreferencesStorageService(prefs);
      final db = AppDatabase.inMemory();
      addTearDown(db.close);

      final tmpDir = Directory.systemTemp.createTempSync('nexa_wf_test_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final wavFile = File('${tmpDir.path}/dynamic_test.wav');

      // Build a 16-bit PCM mono WAV where second half is significantly louder than first half.
      const totalSamples = 22050;
      const dataSize = totalSamples * 2;
      final byteData = ByteData(44 + dataSize);
      // "RIFF"
      byteData.setUint8(0, 0x52);
      byteData.setUint8(1, 0x49);
      byteData.setUint8(2, 0x46);
      byteData.setUint8(3, 0x46);
      byteData.setUint32(4, 36 + dataSize, Endian.little);
      // "WAVEfmt "
      byteData.setUint8(8, 0x57);
      byteData.setUint8(9, 0x41);
      byteData.setUint8(10, 0x56);
      byteData.setUint8(11, 0x45);
      byteData.setUint8(12, 0x66);
      byteData.setUint8(13, 0x6D);
      byteData.setUint8(14, 0x74);
      byteData.setUint8(15, 0x20);
      byteData.setUint32(16, 16, Endian.little);
      byteData.setUint16(20, 1, Endian.little); // PCM
      byteData.setUint16(22, 1, Endian.little); // Mono
      byteData.setUint32(24, 44100, Endian.little);
      byteData.setUint32(28, 88200, Endian.little);
      byteData.setUint16(32, 2, Endian.little);
      byteData.setUint16(34, 16, Endian.little);
      // "data"
      byteData.setUint8(36, 0x64);
      byteData.setUint8(37, 0x61);
      byteData.setUint8(38, 0x74);
      byteData.setUint8(39, 0x61);
      byteData.setUint32(40, dataSize, Endian.little);

      for (int i = 0; i < totalSamples; i++) {
        final amp = i < totalSamples ~/ 2 ? 1200.0 : 28000.0;
        final sample = (math.sin(i * 0.25) * amp).round();
        byteData.setInt16(44 + i * 2, sample, Endian.little);
      }
      wavFile.writeAsBytesSync(byteData.buffer.asUint8List());

      final preProcessor = WaveformPreProcessorImpl(storage, database: db);
      final wf = await preProcessor.getOrAnalyzeWaveform(
        trackId: 'wav-dyn-1',
        filePath: wavFile.path,
        sampleCount: 56,
      );

      expect(wf.length, equals(56));
      final firstQuarterAvg = wf.sublist(0, 14).reduce((a, b) => a + b) / 14;
      final lastQuarterAvg = wf.sublist(42, 56).reduce((a, b) => a + b) / 14;
      expect(lastQuarterAvg, greaterThan(firstQuarterAvg * 1.5));

      // Verify SQLite cache row exists
      final rows = db.select(
        "SELECT sample_count FROM track_waveforms WHERE track_id = 'wav-dyn-1';",
      );
      expect(rows.length, equals(1));
      expect(rows.first['sample_count'], equals(56));
    });
  });
}
