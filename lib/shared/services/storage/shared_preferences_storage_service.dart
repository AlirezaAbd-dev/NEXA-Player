import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete [IStorageService] implementation backed by [SharedPreferences].
class SharedPreferencesStorageService implements IStorageService {
  const SharedPreferencesStorageService(this._prefs);

  final SharedPreferences _prefs;

  @override
  Result<String?, StorageFailure> getString(String key) {
    try {
      final value = _prefs.getString(key);
      return Result.success(value);
    } catch (e, st) {
      return Result.failure(StorageFailure.read(key, e, st));
    }
  }

  @override
  Future<Result<void, StorageFailure>> setString(
    String key,
    String value,
  ) async {
    try {
      final success = await _prefs.setString(key, value);
      if (success) {
        return const Result.success(null);
      }
      return Result.failure(
        StorageFailure.write(key, 'SharedPreferences failed to persist string'),
      );
    } catch (e, st) {
      return Result.failure(StorageFailure.write(key, e, st));
    }
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) {
    try {
      final value = _prefs.getBool(key);
      return Result.success(value);
    } catch (e, st) {
      return Result.failure(StorageFailure.read(key, e, st));
    }
  }

  @override
  Future<Result<void, StorageFailure>> setBool(
    String key,
    bool value,
  ) async {
    try {
      final success = await _prefs.setBool(key, value);
      if (success) {
        return const Result.success(null);
      }
      return Result.failure(
        StorageFailure.write(key, 'SharedPreferences failed to persist bool'),
      );
    } catch (e, st) {
      return Result.failure(StorageFailure.write(key, e, st));
    }
  }

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    try {
      final success = await _prefs.remove(key);
      if (success) {
        return const Result.success(null);
      }
      return Result.failure(
        StorageFailure.delete(key, 'SharedPreferences failed to remove key'),
      );
    } catch (e, st) {
      return Result.failure(StorageFailure.delete(key, e, st));
    }
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    try {
      final success = await _prefs.clear();
      if (success) {
        return const Result.success(null);
      }
      return Result.failure(
        StorageFailure.clear('SharedPreferences failed to clear storage'),
      );
    } catch (e, st) {
      return Result.failure(StorageFailure.clear(e, st));
    }
  }
}
