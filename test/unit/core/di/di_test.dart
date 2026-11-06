import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/shared/services/logging/logging_service.dart';
import 'package:nexa_player/shared/services/logging/talker_logging_service.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';
import '../../../helpers/mock_services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetDependencies();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Dependency Injection (GetIt)', () {
    test('registers all expected services on configureDependencies', () async {
      await configureDependencies();

      expect(getIt.isRegistered<SharedPreferences>(), isTrue);
      expect(getIt.isRegistered<Talker>(), isTrue);
      expect(getIt.isRegistered<ILoggingService>(), isTrue);
      expect(getIt.isRegistered<IStorageService>(), isTrue);
    });

    test('resolves singleton instances with correct concrete types', () async {
      await configureDependencies();

      final loggingService = getIt<ILoggingService>();
      final storageService = getIt<IStorageService>();

      expect(loggingService, isA<TalkerLoggingService>());
      expect(storageService, isA<SharedPreferencesStorageService>());

      // Verifies singleton identity
      expect(identical(getIt<ILoggingService>(), loggingService), isTrue);
      expect(identical(getIt<IStorageService>(), storageService), isTrue);
    });

    test('supports custom instance injection for testing', () async {
      final customTalker = Talker();
      SharedPreferences.setMockInitialValues({'injected': true});
      final customPrefs = await SharedPreferences.getInstance();

      await configureDependencies(
        sharedPreferences: customPrefs,
        talker: customTalker,
      );

      expect(identical(getIt<Talker>(), customTalker), isTrue);
      expect(identical(getIt<SharedPreferences>(), customPrefs), isTrue);
    });

    test('calling configureDependencies multiple times is idempotent', () async {
      await configureDependencies();
      // Should not throw duplicate registration errors
      await configureDependencies();

      expect(getIt.isRegistered<ILoggingService>(), isTrue);
    });

    test('resetDependencies cleans up all registrations', () async {
      await configureDependencies();
      expect(getIt.isRegistered<ILoggingService>(), isTrue);

      await resetDependencies();
      expect(getIt.isRegistered<ILoggingService>(), isFalse);
      expect(getIt.isRegistered<IStorageService>(), isFalse);
    });

    test('allows overriding registration with FakeStorageService for test isolation', () async {
      final fakeStorage = FakeStorageService({'theme': 'sakura'});
      getIt.registerSingleton<IStorageService>(fakeStorage);

      final resolved = getIt<IStorageService>();
      expect(resolved, equals(fakeStorage));
      expect(resolved.getString('theme').valueOrNull, equals('sakura'));
    });
  });

  group('Riverpod Service Provider Bridge', () {
    test('providers resolve registered singletons from DI', () async {
      await configureDependencies();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final talker = container.read(talkerProvider);
      final logging = container.read(loggingServiceProvider);
      final storage = container.read(storageServiceProvider);

      expect(identical(talker, getIt<Talker>()), isTrue);
      expect(identical(logging, getIt<ILoggingService>()), isTrue);
      expect(identical(storage, getIt<IStorageService>()), isTrue);
    });

    test('providers can be overridden in ProviderContainer without GetIt', () {
      final fakeLogging = FakeLoggingService();
      final fakeStorage = FakeStorageService({'key': 'mock_value'});
      final container = ProviderContainer(
        overrides: [
          loggingServiceProvider.overrideWithValue(fakeLogging),
          storageServiceProvider.overrideWithValue(fakeStorage),
        ],
      );
      addTearDown(container.dispose);

      expect(identical(container.read(loggingServiceProvider), fakeLogging), isTrue);
      expect(identical(container.read(storageServiceProvider), fakeStorage), isTrue);
      expect(container.read(storageServiceProvider).getString('key').valueOrNull, equals('mock_value'));
    });
  });
}
