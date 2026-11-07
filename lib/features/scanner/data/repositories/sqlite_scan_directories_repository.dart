import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/scanner/domain/repositories/scan_directories_repository.dart';
import 'package:nexa_player/shared/models/scan_directory.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// SQLite implementation of [IScanDirectoriesRepository].
class SqliteScanDirectoriesRepository implements IScanDirectoriesRepository {
  SqliteScanDirectoriesRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<ScanDirectory>, DatabaseFailure>> getDirectories() async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableScanDirectories} ORDER BY ${DatabaseSchema.colPath} ASC',
      );
      final list = rows.map((r) => ScanDirectory.fromMap(r)).toList();
      return Result.success(list);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query scan directories: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<ScanDirectory, DatabaseFailure>> addDirectory(String path) async {
    try {
      final id = 'sd_${path.hashCode.abs()}';
      database.execute('''
        INSERT INTO ${DatabaseSchema.tableScanDirectories} (
          ${DatabaseSchema.colId},
          ${DatabaseSchema.colPath},
          ${DatabaseSchema.colIsActive},
          ${DatabaseSchema.colFileCount}
        ) VALUES (?, ?, 1, 0)
        ON CONFLICT(${DatabaseSchema.colPath}) DO NOTHING;
      ''', [id, path]);

      final dir = ScanDirectory(
        id: id,
        path: path,
        isEnabled: true,
        trackCount: 0,
      );
      return Result.success(dir);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to add scan directory: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> removeDirectory(String path) async {
    try {
      database.execute('''
        DELETE FROM ${DatabaseSchema.tableScanDirectories}
        WHERE ${DatabaseSchema.colPath} = ? OR ${DatabaseSchema.colId} = ?;
      ''', [path, path]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to remove scan directory: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> toggleActive(
      String id, bool isActive) async {
    try {
      database.execute('''
        UPDATE ${DatabaseSchema.tableScanDirectories}
        SET ${DatabaseSchema.colIsActive} = ?
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [isActive ? 1 : 0, id]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to toggle scan directory status: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> updateLastScanned(
    String id,
    DateTime scannedAt,
    int fileCount,
  ) async {
    try {
      database.execute('''
        UPDATE ${DatabaseSchema.tableScanDirectories}
        SET ${DatabaseSchema.colLastScanned} = ?,
            ${DatabaseSchema.colFileCount} = ?
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [scannedAt.millisecondsSinceEpoch, fileCount, id]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to update last scanned info: $e',
        e,
        st,
      ));
    }
  }
}
