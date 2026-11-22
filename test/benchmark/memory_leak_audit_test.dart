import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/cloud/cloud.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Benchmark: Memory Leak & Stream Subscription Audits', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await configureDependencies();
    });

    tearDown(() async {
      await resetDependencies();
    });
    test('Rapid StreamController subscription & cancellation (1,000 cycles)', () async {
      final eq = PureDartEqualizerService();
      final stopwatch = Stopwatch()..start();
      const cycles = 1000;

      for (var i = 0; i < cycles; i++) {
        final sub = eq.stateStream.listen((state) {});
        await eq.setBandGain(0, (i % 12).toDouble());
        await sub.cancel();
      }
      stopwatch.stop();

      // ignore: avoid_print
      print('🚀 [Benchmark] 1,000 Stream Subscription/Cancel cycles in ${stopwatch.elapsedMilliseconds}ms '
          '(${(stopwatch.elapsedMicroseconds / cycles).toStringAsFixed(1)} µs/cycle)');

      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('ProviderContainer repeated lifecycle creation and disposal (100 cycles)', () {
      final stopwatch = Stopwatch()..start();
      const cycles = 100;

      for (var i = 0; i < cycles; i++) {
        final container = ProviderContainer();
        // Read a collection of core providers
        final isLossless = container.read(cloudSettingsProvider).losslessStreaming;
        expect(isLossless, isTrue);
        container.dispose();
      }
      stopwatch.stop();

      // ignore: avoid_print
      print('🚀 [Benchmark] 100 ProviderContainer lifecycle allocations in ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Rapid creation and teardown of network streaming components', () async {
      const cycles = 50;
      final stopwatch = Stopwatch()..start();

      for (var i = 0; i < cycles; i++) {
        final discovery = UpnpSsdpDiscoveryService(enableMockFallbacks: false, broadcastPackets: false);
        final controller = DlnaAvTransportController();

        await discovery.startDiscovery();
        await discovery.stopDiscovery();
        await discovery.dispose();
        await controller.dispose();
      }
      stopwatch.stop();

      // ignore: avoid_print
      print('🚀 [Benchmark] 50 Network Services creation & disposal cycles in ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
