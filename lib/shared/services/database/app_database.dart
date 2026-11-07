import 'dart:io';

import 'package:nexa_player/core/utils/failure.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

export 'package:sqlite3/sqlite3.dart' show ResultSet, Row, SqliteException;

/// Domain failure type representing SQLite and database operational errors.
class DatabaseFailure extends Failure {
  const DatabaseFailure(
    super.message, [
    super.cause,
    super.stackTrace,
    this.extendedResultCode,
    this.sql,
  ]);

  /// SQLite extended result code (e.g. 19 for SQLITE_CONSTRAINT), if available.
  final int? extendedResultCode;

  /// The SQL statement that triggered the failure, if available.
  final String? sql;

  /// Constructs a [DatabaseFailure] wrapping a native [SqliteException].
  factory DatabaseFailure.fromSqliteException(
    SqliteException exception, [
    StackTrace? stackTrace,
  ]) {
    final buffer = StringBuffer(exception.message);
    if (exception.explanation != null) {
      buffer.write(': ${exception.explanation}');
    }
    return DatabaseFailure(
      buffer.toString(),
      exception,
      stackTrace,
      exception.extendedResultCode,
      exception.causingStatement,
    );
  }

  /// Failure thrown when database operations are attempted on a closed database.
  factory DatabaseFailure.closed([StackTrace? stackTrace]) =>
      DatabaseFailure('Database connection is closed', null, stackTrace);

  /// Failure thrown when an atomic transaction fails and is rolled back.
  factory DatabaseFailure.transaction(
    String message, [
    Object? cause,
    StackTrace? stackTrace,
  ]) =>
      DatabaseFailure('Transaction error: $message', cause, stackTrace);

  @override
  List<Object?> get props => [message, cause, extendedResultCode, sql];
}

/// Abstract contract for SQLite database operations in NEXA Player.
abstract interface class IAppDatabase {
  /// Direct access to the underlying raw [Database] instance from `package:sqlite3`.
  Database get rawDatabase;

  /// Returns `true` if the database connection has been closed.
  bool get isClosed;

  /// Executes a SQL DDL/DML statement (e.g. CREATE, INSERT, UPDATE, DELETE)
  /// with optional positional [parameters].
  ///
  /// Throws [DatabaseFailure] on failure or if the database is closed.
  void execute(String sql, [List<Object?> parameters = const []]);

  /// Executes a SQL query (e.g. SELECT) with optional positional [parameters]
  /// and buffers the resulting rows into a [ResultSet].
  ///
  /// Throws [DatabaseFailure] on query failure or if the database is closed.
  ResultSet select(String sql, [List<Object?> parameters = const []]);

  /// Executes [action] atomically within a database transaction.
  ///
  /// Automatically manages `BEGIN TRANSACTION` / `COMMIT`, and executes
  /// `ROLLBACK` if [action] throws an exception.
  ///
  /// Supports nested calls safely via SQLite `SAVEPOINT`s.
  /// Throws [DatabaseFailure] if transaction execution fails.
  void transaction(void Function() action);

  /// Closes the database connection and releases all native resources.
  void close();
}

/// Production SQLite database engine implementing [IAppDatabase].
///
/// Supports hermetic in-memory execution for unit tests and WAL-mode file-based
/// persistence for mobile/desktop runtimes.
class AppDatabase implements IAppDatabase {
  /// Default SQLite database file name stored in application documents directory.
  static const String defaultDatabaseName = 'nexa_player.db';

  final Database _rawDatabase;
  bool _isClosed = false;
  int _transactionDepth = 0;

  /// Internal constructor wrapping an opened [Database].
  AppDatabase._(this._rawDatabase);

  /// Synchronous in-memory constructor for unit and integration testing.
  ///
  /// Opens a transient SQLite database in memory using [sqlite3.openInMemory].
  /// If [initializeSchema] is `true` (default), all tables, indexes, and pragmas
  /// are automatically configured.
  factory AppDatabase.inMemory({bool initializeSchema = true}) {
    final rawDb = sqlite3.openInMemory();
    try {
      if (initializeSchema) {
        DatabaseSchema.initializeDatabase(rawDb, isInMemory: true);
      } else {
        DatabaseSchema.configurePragmas(rawDb, isInMemory: true);
      }
      return AppDatabase._(rawDb);
    } catch (e, st) {
      rawDb.dispose();
      if (e is DatabaseFailure) rethrow;
      if (e is SqliteException) throw DatabaseFailure.fromSqliteException(e, st);
      throw DatabaseFailure('Failed to initialize in-memory database: $e', e, st);
    }
  }

  /// Synchronous constructor opening a persistent SQLite database at [path].
  ///
  /// Ensures parent directories exist.
  /// Configures WAL journal mode, NORMAL synchronous mode, and foreign keys.
  /// If [initializeSchema] is `true` (default), creates all tables and indexes.
  factory AppDatabase.openFile(String path, {bool initializeSchema = true}) {
    final file = File(path);
    final parentDir = file.parent;
    if (!parentDir.existsSync()) {
      parentDir.createSync(recursive: true);
    }

    final rawDb = sqlite3.open(path);
    try {
      if (initializeSchema) {
        DatabaseSchema.initializeDatabase(rawDb, isInMemory: false);
      } else {
        DatabaseSchema.configurePragmas(rawDb, isInMemory: false);
      }
      return AppDatabase._(rawDb);
    } catch (e, st) {
      rawDb.dispose();
      if (e is DatabaseFailure) rethrow;
      if (e is SqliteException) throw DatabaseFailure.fromSqliteException(e, st);
      throw DatabaseFailure('Failed to open database file at "$path": $e', e, st);
    }
  }

  /// Constructs an [AppDatabase] wrapping a raw [Database] instance.
  /// Useful for custom mocks and test harnesses.
  factory AppDatabase.fromRaw(
    Database rawDatabase, {
    bool isInMemory = false,
    bool initializeSchema = false,
  }) {
    if (initializeSchema) {
      DatabaseSchema.initializeDatabase(rawDatabase, isInMemory: isInMemory);
    }
    return AppDatabase._(rawDatabase);
  }

  /// Asynchronous factory resolving the database file path on device storage.
  ///
  /// Resolves the application documents directory via [path_provider].
  /// If [inMemory] is `true`, ignores paths and returns [AppDatabase.inMemory].
  /// If [customPath] is provided, opens that exact file.
  /// Otherwise, opens `<app_documents>/[fileName]` (default: `nexa_player.db`).
  static Future<AppDatabase> open({
    String? fileName,
    String? customPath,
    bool inMemory = false,
    bool initializeSchema = true,
  }) async {
    if (inMemory) {
      return AppDatabase.inMemory(initializeSchema: initializeSchema);
    }

    if (customPath != null) {
      return AppDatabase.openFile(
        customPath,
        initializeSchema: initializeSchema,
      );
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(docsDir.path, fileName ?? defaultDatabaseName);
    return AppDatabase.openFile(dbPath, initializeSchema: initializeSchema);
  }

  @override
  Database get rawDatabase {
    _checkNotClosed();
    return _rawDatabase;
  }

  @override
  bool get isClosed => _isClosed;

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {
    _checkNotClosed();
    try {
      _rawDatabase.execute(sql, parameters);
    } on SqliteException catch (e, st) {
      throw DatabaseFailure.fromSqliteException(e, st);
    } catch (e, st) {
      if (e is DatabaseFailure) rethrow;
      throw DatabaseFailure('Failed to execute statement: $e', e, st);
    }
  }

  @override
  ResultSet select(String sql, [List<Object?> parameters = const []]) {
    _checkNotClosed();
    try {
      return _rawDatabase.select(sql, parameters);
    } on SqliteException catch (e, st) {
      throw DatabaseFailure.fromSqliteException(e, st);
    } catch (e, st) {
      if (e is DatabaseFailure) rethrow;
      throw DatabaseFailure('Failed to execute query: $e', e, st);
    }
  }

  @override
  void transaction(void Function() action) {
    runTransaction<void>(action);
  }

  /// Generic transaction helper executing [action] atomically and returning its result.
  ///
  /// Uses SQLite `SAVEPOINT`s for safe nested transaction execution.
  T runTransaction<T>(T Function() action) {
    _checkNotClosed();
    final isOutermost = _transactionDepth == 0;
    final savepointName = 'sp_$_transactionDepth';
    _transactionDepth++;

    try {
      if (isOutermost) {
        _rawDatabase.execute('BEGIN TRANSACTION;');
      } else {
        _rawDatabase.execute('SAVEPOINT $savepointName;');
      }

      final result = action();

      if (isOutermost) {
        _rawDatabase.execute('COMMIT;');
      } else {
        _rawDatabase.execute('RELEASE SAVEPOINT $savepointName;');
      }

      return result;
    } catch (e, st) {
      try {
        if (isOutermost) {
          _rawDatabase.execute('ROLLBACK;');
        } else {
          _rawDatabase.execute('ROLLBACK TO SAVEPOINT $savepointName;');
        }
      } catch (_) {
        // Rollback failure is ignored if native connection already aborted
      }

      if (e is DatabaseFailure) rethrow;
      if (e is SqliteException) throw DatabaseFailure.fromSqliteException(e, st);
      throw DatabaseFailure.transaction(e.toString(), e, st);
    } finally {
      _transactionDepth--;
    }
  }

  @override
  void close() {
    if (_isClosed) return;
    _isClosed = true;
    try {
      _rawDatabase.dispose();
    } on SqliteException catch (e, st) {
      throw DatabaseFailure.fromSqliteException(e, st);
    }
  }

  /// Disposable alias conforming to Flutter / GetIt service disposal conventions.
  void dispose() => close();

  void _checkNotClosed() {
    if (_isClosed) {
      throw DatabaseFailure.closed();
    }
  }
}
