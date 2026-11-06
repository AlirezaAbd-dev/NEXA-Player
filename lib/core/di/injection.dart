import 'package:get_it/get_it.dart';
import 'package:nexa_player/shared/services/logging/logging_service.dart';
import 'package:nexa_player/shared/services/logging/talker_logging_service.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Configures core application dependencies in [getIt].
///
/// Accepts optional [sharedPreferences] and [talker] for hermetic testing.
Future<void> configureDependencies({
  SharedPreferences? sharedPreferences,
  Talker? talker,
}) async {
  // 1. SharedPreferences instance
  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingleton<SharedPreferences>(prefs);
  }

  // 2. Talker instance
  final talkerInstance = talker ?? Talker();
  if (!getIt.isRegistered<Talker>()) {
    getIt.registerSingleton<Talker>(talkerInstance);
  }

  // 3. ILoggingService
  if (!getIt.isRegistered<ILoggingService>()) {
    getIt.registerSingleton<ILoggingService>(
      TalkerLoggingService(talker: getIt<Talker>()),
    );
  }

  // 4. IStorageService
  if (!getIt.isRegistered<IStorageService>()) {
    getIt.registerSingleton<IStorageService>(
      SharedPreferencesStorageService(getIt<SharedPreferences>()),
    );
  }
}

/// Clears all registrations in [getIt]. Used for test isolation.
Future<void> resetDependencies() async {
  await getIt.reset();
}
