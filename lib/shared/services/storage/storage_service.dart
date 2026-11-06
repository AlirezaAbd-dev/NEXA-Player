import 'package:nexa_player/core/utils/result.dart';

/// Failure type specific to storage read/write/clear operations.
class StorageFailure extends Failure {
  const StorageFailure(super.message, [super.cause, super.stackTrace]);

  factory StorageFailure.read(String key, [Object? cause, StackTrace? stackTrace]) =>
      StorageFailure('Failed to read key: "$key"', cause, stackTrace);

  factory StorageFailure.write(String key, [Object? cause, StackTrace? stackTrace]) =>
      StorageFailure('Failed to write key: "$key"', cause, stackTrace);

  factory StorageFailure.delete(String key, [Object? cause, StackTrace? stackTrace]) =>
      StorageFailure('Failed to delete key: "$key"', cause, stackTrace);

  factory StorageFailure.clear([Object? cause, StackTrace? stackTrace]) =>
      StorageFailure('Failed to clear storage', cause, stackTrace);
}

/// Abstract interface contract for key-value persistence.
abstract interface class IStorageService {
  /// Stores a string [value] associated with [key].
  Future<Result<void, StorageFailure>> setString(String key, String value);

  /// Synchronously retrieves the string associated with [key], or `null` if not found.
  Result<String?, StorageFailure> getString(String key);

  /// Stores a boolean [value] associated with [key].
  Future<Result<void, StorageFailure>> setBool(String key, bool value);

  /// Synchronously retrieves the boolean associated with [key], or `null` if not found.
  Result<bool?, StorageFailure> getBool(String key);

  /// Removes the entry associated with [key].
  Future<Result<void, StorageFailure>> remove(String key);

  /// Clears all stored key-value pairs.
  Future<Result<void, StorageFailure>> clear();
}
