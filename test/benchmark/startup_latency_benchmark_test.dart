import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Performance Benchmark: App Startup & Cold Bootstrap', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await resetDependencies();
    });

    test('Dependency injection container bootstrap completes under 400ms', () async {
      final stopwatch = Stopwatch()..start();
      await configureDependencies();
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('🚀 [Benchmark] DI Container Initialization: ${elapsedMs}ms');

      // Assert cold bootstrap of full get_it registry is ultra-fast (< 400ms on uncompiled JIT)
      expect(elapsedMs, lessThan(400),
          reason: 'Dependency injection container took too long to configure');
      expect(getIt.isRegistered<IAppDatabase>(), isTrue);
    });

    test('Database schema verification and query latency completes under 50ms', () async {
      await configureDependencies();
      final db = getIt<IAppDatabase>();

      final stopwatch = Stopwatch()..start();
      final tracks = db.select('SELECT * FROM tracks');
      final albums = db.select('SELECT * FROM albums');
      final artists = db.select('SELECT * FROM artists');
      stopwatch.stop();

      final elapsedMs = stopwatch.elapsedMilliseconds;
      // ignore: avoid_print
      print('🚀 [Benchmark] Initial SQLite Cold Queries: ${elapsedMs}ms '
          '(Tracks: ${tracks.length}, Albums: ${albums.length}, Artists: ${artists.length})');

      expect(elapsedMs, lessThan(50),
          reason: 'Initial database queries exceeded latency budget');
    });

    test('Repeated cold-restart cycle benchmark (10 iterations)', () async {
      final latencies = <int>[];

      for (var i = 0; i < 10; i++) {
        await resetDependencies();
        final stopwatch = Stopwatch()..start();
        await configureDependencies();
        stopwatch.stop();
        latencies.add(stopwatch.elapsedMilliseconds);
      }

      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      // ignore: avoid_print
      print('🚀 [Benchmark] Average DI Re-initialization over 10 cycles: ${avgLatency.toStringAsFixed(1)}ms');

      expect(avgLatency, lessThan(100),
          reason: 'Average restart latency across cycles exceeded 100ms');
    });
  });
}
