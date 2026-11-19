import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/visualizer/domain/services/waveform_pre_processor.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late SharedPreferencesStorageService storage;
  late WaveformPreProcessorImpl preProcessor;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    preProcessor = WaveformPreProcessorImpl(storage);
  });

  group('WaveformPreProcessorImpl Tests', () {
    test('generates procedural waveform when file does not exist and saves to cache', () async {
      final amps = await preProcessor.getOrAnalyzeWaveform(
        trackId: 'trk-101',
        filePath: '/non/existent/path/song.mp3',
        sampleCount: 40,
      );

      expect(amps.length, equals(40));
      expect(amps.every((a) => a >= 0.08 && a <= 1.0), isTrue);

      // Verify that value was stored in persistent cache
      final cached = storage.getString('nexa_wf_cache_trk-101');
      expect(cached.isSuccess, isTrue);
      expect(cached.valueOrNull, isNotNull);
      expect(cached.valueOrNull!.contains('['), isTrue);
    });

    test('retrieves directly from cache on subsequent calls without recomputing', () async {
      // Seed storage cache directly
      await storage.setString('nexa_wf_cache_trk-cached', '[0.12, 0.45, 0.78, 0.99]');

      final amps = await preProcessor.getOrAnalyzeWaveform(
        trackId: 'trk-cached',
        filePath: '/some/path.mp3',
      );

      expect(amps, equals([0.12, 0.45, 0.78, 0.99]));
    });

    test('invalidate clears cached waveform from storage', () async {
      await storage.setString('nexa_wf_cache_trk-del', '[0.5, 0.5]');

      await preProcessor.invalidate('trk-del');

      final cached = storage.getString('nexa_wf_cache_trk-del');
      expect(cached.valueOrNull, isNull);
    });
  });
}
