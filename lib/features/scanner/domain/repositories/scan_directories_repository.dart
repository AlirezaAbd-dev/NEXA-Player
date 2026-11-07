import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/scan_directory.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Repository contract managing scan directory inclusions and exclusions.
abstract interface class IScanDirectoriesRepository {
  /// Fetches all configured scan directories.
  Future<Result<List<ScanDirectory>, DatabaseFailure>> getDirectories();

  /// Adds a new scan directory path.
  Future<Result<ScanDirectory, DatabaseFailure>> addDirectory(String path);

  /// Removes a scan directory by its path or ID.
  Future<Result<void, DatabaseFailure>> removeDirectory(String path);

  /// Toggles active status of a scan directory.
  Future<Result<void, DatabaseFailure>> toggleActive(String id, bool isActive);

  /// Updates last scanned timestamp and file count.
  Future<Result<void, DatabaseFailure>> updateLastScanned(
    String id,
    DateTime scannedAt,
    int fileCount,
  );
}
