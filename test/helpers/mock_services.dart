import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/services/logging/logging_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

/// In-memory fake implementation of [IStorageService] for fast, deterministic unit testing.
class FakeStorageService implements IStorageService {
  final Map<String, Object> _storage = {};
  bool simulateFailure = false;
  String failureMessage = 'Simulated storage failure';

  FakeStorageService([Map<String, Object>? initialValues]) {
    if (initialValues != null) {
      _storage.addAll(initialValues);
    }
  }

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    if (simulateFailure) {
      return Result.failure(StorageFailure(failureMessage));
    }
    _storage[key] = value;
    return const Result.success(null);
  }

  @override
  Result<String?, StorageFailure> getString(String key) {
    if (simulateFailure) {
      return Result.failure(StorageFailure(failureMessage));
    }
    final value = _storage[key];
    if (value == null) return const Result.success(null);
    if (value is String) return Result.success(value);
    return Result.failure(StorageFailure('Key "$key" contains non-string value: $value'));
  }

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    if (simulateFailure) {
      return Result.failure(StorageFailure(failureMessage));
    }
    _storage[key] = value;
    return const Result.success(null);
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) {
    if (simulateFailure) {
      return Result.failure(StorageFailure(failureMessage));
    }
    final value = _storage[key];
    if (value == null) return const Result.success(null);
    if (value is bool) return Result.success(value);
    return Result.failure(StorageFailure('Key "$key" contains non-bool value: $value'));
  }

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    if (simulateFailure) {
      return Result.failure(StorageFailure(failureMessage));
    }
    _storage.remove(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    if (simulateFailure) {
      return Result.failure(StorageFailure(failureMessage));
    }
    _storage.clear();
    return const Result.success(null);
  }

  // Inspection & verification helpers
  bool containsKey(String key) => _storage.containsKey(key);
  Object? getRaw(String key) => _storage[key];
  int get count => _storage.length;
  void reset() {
    _storage.clear();
    simulateFailure = false;
  }
}

/// Record of a logged message.
class TestLogEntry {
  final String level;
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  TestLogEntry({
    required this.level,
    required this.message,
    this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}

/// In-memory fake logging service capturing all log calls for assertions.
class FakeLoggingService implements ILoggingService {
  final List<TestLogEntry> logs = [];

  @override
  void debug(String message) {
    logs.add(TestLogEntry(level: 'DEBUG', message: message));
  }

  @override
  void info(String message) {
    logs.add(TestLogEntry(level: 'INFO', message: message));
  }

  @override
  void warning(String message) {
    logs.add(TestLogEntry(level: 'WARNING', message: message));
  }

  @override
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    logs.add(TestLogEntry(level: 'ERROR', message: message, error: error, stackTrace: stackTrace));
  }

  bool hasMessage(String query) => logs.any((l) => l.message.contains(query));
  List<TestLogEntry> get errors => logs.where((l) => l.level == 'ERROR').toList();
  void clear() => logs.clear();
}

/// Mocktail mock for [IStorageService].
class MockStorageService extends Mock implements IStorageService {}

/// Mocktail mock for [ILoggingService].
class MockLoggingService extends Mock implements ILoggingService {}
