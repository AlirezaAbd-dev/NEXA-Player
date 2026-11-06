import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/services/logging/logging_service.dart';
import 'package:nexa_player/shared/services/logging/talker_logging_service.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../helpers/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ---------------------------------------------------------------------------
  // ATTACK SURFACE 1: Result Monad Stress, Nested Folds & Exception Containment
  // ---------------------------------------------------------------------------
  group('Adversarial Challenge: Result Monad & Exception Containment', () {
    test('deeply nested Result folds and transformations (10 levels)', () {
      // Construct a 10-level nested Result
      Result<dynamic, Failure> current = const Result<int, Failure>.success(1);
      for (int i = 0; i < 9; i++) {
        current = Result<Result<dynamic, Failure>, Failure>.success(current);
      }

      // Unwind 10 levels of nesting via fold
      dynamic unwrap(dynamic res) {
        if (res is Result<dynamic, Failure>) {
          return res.fold((val) => unwrap(val), (fail) => fail);
        }
        return res;
      }

      final unwound = unwrap(current);
      expect(unwound, equals(1));
    });

    test('deep chain of 500 flatMap calls executes without stack overflow', () {
      Result<int, Failure> chain = const Result<int, Failure>.success(0);
      for (int i = 0; i < 500; i++) {
        chain = chain.flatMap((val) => Result<int, Failure>.success(val + 1));
      }

      expect(chain.isSuccess, isTrue);
      expect(chain.valueOrNull, equals(500));
    });

    test('chain of 500 flatMaps short-circuits at step 250 and preserves failure identity', () {
      const targetFailure = UnexpectedFailure('Halt at 250');
      Result<int, Failure> chain = const Result<int, Failure>.success(0);

      var computationsExecuted = 0;
      for (int i = 0; i < 500; i++) {
        chain = chain.flatMap((val) {
          computationsExecuted++;
          if (val == 250) {
            return const Result<int, Failure>.failure(targetFailure);
          }
          return Result<int, Failure>.success(val + 1);
        });
      }

      expect(chain.isFailure, isTrue);
      expect(chain.failureOrNull, equals(targetFailure));
      // Once failure happens at val == 250 (which is iteration 251), subsequent 249 flatMaps must NOT call transform
      expect(computationsExecuted, equals(251));
    });

    test('500 sequential map transformations execute without error', () {
      Result<int, Failure> chain = const Result<int, Failure>.success(0);
      for (int i = 0; i < 500; i++) {
        chain = chain.map((val) => val + 2);
      }
      expect(chain.valueOrNull, equals(1000));
    });

    test('Result.guard captures all standard Dart Error types without escaping', () {
      // 1. ArgumentError
      final r1 = Result.guard(() => throw ArgumentError('Bad argument'));
      expect(r1.isFailure, isTrue);
      expect(r1.failureOrNull, isA<UnexpectedFailure>());
      expect(r1.failureOrNull?.cause, isA<ArgumentError>());

      // 2. StateError
      final r2 = Result.guard(() => throw StateError('Bad state'));
      expect(r2.isFailure, isTrue);
      expect(r2.failureOrNull?.cause, isA<StateError>());

      // 3. RangeError
      final r3 = Result.guard(() => throw RangeError.index(10, [1, 2]));
      expect(r3.isFailure, isTrue);
      expect(r3.failureOrNull?.cause, isA<RangeError>());

      // 4. TypeError
      final r4 = Result.guard(() {
        const dynamic invalid = 'string';
        return (invalid as int) + 5;
      });
      expect(r4.isFailure, isTrue);
      expect(r4.failureOrNull?.cause, isA<TypeError>());

      // 5. UnsupportedError
      final r5 = Result.guard(() => throw UnsupportedError('Not supported'));
      expect(r5.isFailure, isTrue);
      expect(r5.failureOrNull?.cause, isA<UnsupportedError>());

      // 6. ConcurrentModificationError
      final r6 = Result.guard(() {
        final list = [1, 2, 3];
        for (final item in list) {
          list.add(item);
        }
      });
      expect(r6.isFailure, isTrue);
      expect(r6.failureOrNull?.cause, isA<ConcurrentModificationError>());
    });

    test('Result.guard catches non-Exception, non-Error objects (e.g., primitives)', () {
      final rString = Result.guard(() => throw 'raw string throw');
      expect(rString.isFailure, isTrue);
      expect(rString.failureOrNull, isA<UnexpectedFailure>());
      expect(rString.failureOrNull?.cause, equals('raw string throw'));

      final rInt = Result.guard(() => throw 404);
      expect(rInt.isFailure, isTrue);
      expect(rInt.failureOrNull?.cause, equals(404));
    });

    test('Result.guard preserves domain Failure subclass directly without wrapping in UnexpectedFailure', () {
      const domainFailure = StorageFailure('Disk full');
      final res = Result.guard(() => throw domainFailure);
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<StorageFailure>());
      expect(res.failureOrNull, same(domainFailure));
    });

    test('Result.guardAsync catches synchronous throw within async closure', () async {
      final res = await Result.guardAsync<int>(() {
        throw const FormatException('Sync format exception inside async');
      });
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<UnexpectedFailure>());
      expect(res.failureOrNull?.cause, isA<FormatException>());
    });

    test('Result.guardAsync catches asynchronous future rejection', () async {
      final res = await Result.guardAsync<String>(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        throw Exception('Async I/O rejection');
      });
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, isA<UnexpectedFailure>());
      expect(res.failureOrNull?.message, contains('Async I/O rejection'));
    });

    test('Result.guardAsync preserves domain Failure thrown asynchronously', () async {
      const domainFailure = ValidationFailure('Invalid audio bitrate');
      final res = await Result.guardAsync<int>(() async {
        await Future.delayed(const Duration(milliseconds: 5));
        throw domainFailure;
      });
      expect(res.isFailure, isTrue);
      expect(res.failureOrNull, same(domainFailure));
    });

    test('Result handles null value edge cases correctly', () {
      const Result<String?, Failure> nullSuccess = Result.success(null);
      expect(nullSuccess.isSuccess, isTrue);
      expect(nullSuccess.isFailure, isFalse);
      expect(nullSuccess.valueOrNull, isNull);
      expect(nullSuccess.failureOrNull, isNull);

      // getOrElse on null success should return null, NOT fallback
      final orElseValue = nullSuccess.getOrElse((_) => 'fallback');
      expect(orElseValue, isNull);

      // getOrThrow on null success should return null without throwing
      expect(nullSuccess.getOrThrow(), isNull);
    });

    test('Result nested in another Result handles failure correctly', () {
      // Outer is success, inner is failure
      const innerFailure = UnexpectedFailure('Inner fail');
      const Result<Result<int, Failure>, Failure> nested =
          Result.success(Result.failure(innerFailure));

      expect(nested.isSuccess, isTrue);
      expect(nested.valueOrNull?.isFailure, isTrue);
      expect(nested.valueOrNull?.failureOrNull, equals(innerFailure));
    });
  });

  // ---------------------------------------------------------------------------
  // ATTACK SURFACE 2: Storage Service Concurrency, Stress & High-Load Operations
  // ---------------------------------------------------------------------------
  group('Adversarial Challenge: Storage Service Concurrency & Stress', () {
    late SharedPreferences prefs;
    late IStorageService storage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      storage = SharedPreferencesStorageService(prefs);
    });

    test('100 concurrent setString operations on distinct keys persist correctly', () async {
      final futures = <Future<Result<void, StorageFailure>>>[];
      for (int i = 0; i < 100; i++) {
        futures.add(storage.setString('key_$i', 'val_$i'));
      }

      final results = await Future.wait(futures);
      expect(results.every((r) => r.isSuccess), isTrue);

      // Verify all 100 values read back correctly
      for (int i = 0; i < 100; i++) {
        final getRes = storage.getString('key_$i');
        expect(getRes.isSuccess, isTrue);
        expect(getRes.valueOrNull, equals('val_$i'));
      }
    });

    test('100 concurrent setString operations on the SAME key resolve cleanly without error', () async {
      final futures = <Future<Result<void, StorageFailure>>>[];
      for (int i = 0; i < 100; i++) {
        futures.add(storage.setString('hotspot_key', 'value_$i'));
      }

      final results = await Future.wait(futures);
      // All writes must succeed
      expect(results.every((r) => r.isSuccess), isTrue);

      // Value must be one of the written values
      final finalVal = storage.getString('hotspot_key');
      expect(finalVal.isSuccess, isTrue);
      expect(finalVal.valueOrNull, startsWith('value_'));
    });

    test('interleaved concurrent reads and writes maintain integrity', () async {
      await storage.setString('shared_counter', '0');

      final operations = <Future<dynamic>>[];
      for (int i = 1; i <= 50; i++) {
        // Read
        operations.add(Future(() => storage.getString('shared_counter')));
        // Write
        operations.add(storage.setString('shared_counter', '$i'));
      }

      final results = await Future.wait(operations);
      // Verify no exceptions were thrown
      expect(results.length, equals(100));

      final finalValue = storage.getString('shared_counter');
      expect(finalValue.isSuccess, isTrue);
      expect(int.parse(finalValue.valueOrNull!), inInclusiveRange(1, 50));
    });

    test('concurrent clear() during active writes completes gracefully', () async {
      final writes = <Future<Result<void, StorageFailure>>>[];
      for (int i = 0; i < 30; i++) {
        writes.add(storage.setString('item_$i', 'data_$i'));
      }

      final clearFuture = storage.clear();
      final allResults = await Future.wait<dynamic>([...writes, clearFuture]);

      expect(allResults.every((r) => (r as Result).isSuccess), isTrue);
    });

    test('handles very large string payload (1 Megabyte) without memory failure', () async {
      final largeString = 'X' * 1024 * 1024; // 1MB string
      final setResult = await storage.setString('large_payload', largeString);
      expect(setResult.isSuccess, isTrue);

      final getResult = storage.getString('large_payload');
      expect(getResult.isSuccess, isTrue);
      expect(getResult.valueOrNull?.length, equals(1024 * 1024));
    });

    test('handles boundary and special character keys/values', () async {
      final trickyPairs = {
        '': 'empty_key',
        '   ': 'whitespace_key',
        'key:with:colons': 'val:with:colons',
        'key/with/slashes': 'val/with/slashes',
        'key\nwith\nnewlines': 'val\nwith\nnewlines',
        'emoji_key_🎵_🚀': 'emoji_val_🎧_🔥',
        'unicode_فارسی': 'متن_فارسی_تست',
        'json_val': '{"theme":"midnightBlack","accent":4282339765,"custom":true}',
        'null_char_\u0000_key': 'null_char_\u0000_val',
      };

      for (final entry in trickyPairs.entries) {
        final setRes = await storage.setString(entry.key, entry.value);
        expect(setRes.isSuccess, isTrue, reason: 'Failed to set key: ${entry.key}');

        final getRes = storage.getString(entry.key);
        expect(getRes.isSuccess, isTrue, reason: 'Failed to get key: ${entry.key}');
        expect(getRes.valueOrNull, equals(entry.value));
      }
    });

    test('type corruption in SharedPreferences returns StorageFailure safely', () async {
      // Direct raw write of incompatible type into SharedPreferences
      await prefs.setStringList('list_key', ['a', 'b', 'c']);

      // Attempt to read as string
      final strRes = storage.getString('list_key');
      expect(strRes.isFailure, isTrue);
      expect(strRes.failureOrNull, isA<StorageFailure>());
      expect(strRes.failureOrNull?.message, contains('list_key'));

      // Attempt to read as bool
      final boolRes = storage.getBool('list_key');
      expect(boolRes.isFailure, isTrue);
      expect(boolRes.failureOrNull, isA<StorageFailure>());
      expect(boolRes.failureOrNull?.message, contains('list_key'));
    });
  });

  // ---------------------------------------------------------------------------
  // ATTACK SURFACE 3: Behavioral Parity (FakeStorageService vs Real SharedPreferencesStorageService)
  // ---------------------------------------------------------------------------
  group('Adversarial Challenge: FakeStorageService vs SharedPreferencesStorageService Parity', () {
    late SharedPreferences realPrefs;
    late IStorageService realService;
    late IStorageService fakeService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      realPrefs = await SharedPreferences.getInstance();
      realService = SharedPreferencesStorageService(realPrefs);
      fakeService = FakeStorageService();
    });

    test('both implementations yield identical results across full CRUD sequence', () async {
      final services = [realService, fakeService];

      for (final s in services) {
        // 1. Initial missing key
        expect(s.getString('non_existent').valueOrNull, isNull);
        expect(s.getBool('non_existent').valueOrNull, isNull);

        // 2. Set and Get String
        final setStrRes = await s.setString('test_str', 'nexa_val');
        expect(setStrRes.isSuccess, isTrue);
        expect(s.getString('test_str').valueOrNull, equals('nexa_val'));

        // 3. Set and Get Bool
        final setBoolRes = await s.setBool('test_bool', true);
        expect(setBoolRes.isSuccess, isTrue);
        expect(s.getBool('test_bool').valueOrNull, isTrue);

        // 4. Overwrite String
        await s.setString('test_str', 'overwritten');
        expect(s.getString('test_str').valueOrNull, equals('overwritten'));

        // 5. Overwrite Bool
        await s.setBool('test_bool', false);
        expect(s.getBool('test_bool').valueOrNull, isFalse);

        // 6. Remove existing key
        final removeRes = await s.remove('test_str');
        expect(removeRes.isSuccess, isTrue);
        expect(s.getString('test_str').valueOrNull, isNull);

        // 7. Remove non-existent key returns success
        final removeMissing = await s.remove('non_existent_key');
        expect(removeMissing.isSuccess, isTrue);

        // 8. Clear wipes all
        final clearRes = await s.clear();
        expect(clearRes.isSuccess, isTrue);
        expect(s.getBool('test_bool').valueOrNull, isNull);
      }
    });

    test('both implementations produce StorageFailure on type mismatch', () async {
      // In real SharedPreferences: write an int
      await realPrefs.setInt('mismatch_key', 999);
      final realResult = realService.getString('mismatch_key');
      expect(realResult.isFailure, isTrue);
      expect(realResult.failureOrNull, isA<StorageFailure>());

      // In FakeStorageService: initialize with an int
      final fakeWithInt = FakeStorageService({'mismatch_key': 999});
      final fakeResult = fakeWithInt.getString('mismatch_key');
      expect(fakeResult.isFailure, isTrue);
      expect(fakeResult.failureOrNull, isA<StorageFailure>());
    });

    test('FakeStorageService simulateFailure flag cleanly rejects all operations', () async {
      final fake = FakeStorageService({'key': 'val'});
      fake.simulateFailure = true;
      fake.failureMessage = 'Disk I/O Error';

      expect((await fake.setString('k', 'v')).isFailure, isTrue);
      expect(fake.getString('key').isFailure, isTrue);
      expect((await fake.setBool('k', true)).isFailure, isTrue);
      expect(fake.getBool('key').isFailure, isTrue);
      expect((await fake.remove('key')).isFailure, isTrue);
      expect((await fake.clear()).isFailure, isTrue);

      // Verify failure message
      expect(fake.getString('key').failureOrNull?.message, equals('Disk I/O Error'));
    });
  });

  // ---------------------------------------------------------------------------
  // ATTACK SURFACE 4: DI Lifecycle, Concurrent Init & GetIt Re-initialization
  // ---------------------------------------------------------------------------
  group('Adversarial Challenge: DI Lifecycle & Re-initialization', () {
    setUp(() async {
      await resetDependencies();
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() async {
      await resetDependencies();
    });

    test('100 consecutive configureDependencies -> resolve -> resetDependencies cycles', () async {
      for (int i = 0; i < 100; i++) {
        await configureDependencies();

        expect(getIt.isRegistered<SharedPreferences>(), isTrue);
        expect(getIt.isRegistered<Talker>(), isTrue);
        expect(getIt.isRegistered<ILoggingService>(), isTrue);
        expect(getIt.isRegistered<IStorageService>(), isTrue);

        final storage = getIt<IStorageService>();
        final logging = getIt<ILoggingService>();
        expect(storage, isA<SharedPreferencesStorageService>());
        expect(logging, isA<TalkerLoggingService>());

        await resetDependencies();

        expect(getIt.isRegistered<SharedPreferences>(), isFalse);
        expect(getIt.isRegistered<Talker>(), isFalse);
        expect(getIt.isRegistered<ILoggingService>(), isFalse);
        expect(getIt.isRegistered<IStorageService>(), isFalse);
      }
    });

    test('20 concurrent configureDependencies calls do not crash or throw duplicate registration', () async {
      // Fire 20 configureDependencies simultaneously
      final inits = List.generate(20, (_) => configureDependencies());
      await Future.wait(inits);

      expect(getIt.isRegistered<ILoggingService>(), isTrue);
      expect(getIt.isRegistered<IStorageService>(), isTrue);
      expect(getIt.isRegistered<Talker>(), isTrue);
      expect(getIt.isRegistered<SharedPreferences>(), isTrue);

      // Resolving must succeed and return a single valid instance
      final s1 = getIt<IStorageService>();
      final s2 = getIt<IStorageService>();
      expect(identical(s1, s2), isTrue);
    });

    test('calling resetDependencies multiple times consecutively is safe', () async {
      await configureDependencies();
      await resetDependencies();
      await resetDependencies();
      await resetDependencies();

      expect(getIt.isRegistered<IStorageService>(), isFalse);
    });

    test('attempting to resolve unconfigured dependencies throws GetIt error cleanly', () {
      expect(() => getIt<IStorageService>(), throwsA(isA<StateError>()));
      expect(() => getIt<ILoggingService>(), throwsA(isA<StateError>()));
    });

    test('Riverpod container reflects newly configured DI instances after reset', () async {
      // 1. Initial configuration
      final prefs1 = await SharedPreferences.getInstance();
      await prefs1.setString('session', 'session_1');
      await configureDependencies(sharedPreferences: prefs1);

      var container = ProviderContainer();
      expect(container.read(storageServiceProvider).getString('session').valueOrNull, equals('session_1'));
      container.dispose();

      // 2. Reset dependencies
      await resetDependencies();

      // 3. Second configuration with new mock data
      SharedPreferences.setMockInitialValues({'session': 'session_2'});
      final prefs2 = await SharedPreferences.getInstance();
      await configureDependencies(sharedPreferences: prefs2);

      // Fresh container resolves session_2
      container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(storageServiceProvider).getString('session').valueOrNull, equals('session_2'));
    });
  });
}
