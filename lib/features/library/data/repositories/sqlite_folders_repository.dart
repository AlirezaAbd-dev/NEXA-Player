import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:path/path.dart' as p;

/// SQLite-backed implementation of [IFoldersRepository].
class SqliteFoldersRepository implements IFoldersRepository {
  SqliteFoldersRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<FolderNode>, DatabaseFailure>> getFoldersTree(
    List<String> rootPaths,
  ) async {
    try {
      final rows = database.select(
        'SELECT ${DatabaseSchema.colId}, ${DatabaseSchema.colTrackFilePath}, '
        '${DatabaseSchema.colTitle}, ${DatabaseSchema.colFileSize} '
        'FROM ${DatabaseSchema.tableTracks} '
        'ORDER BY ${DatabaseSchema.colTrackFilePath} ASC',
      );

      final foldersMap = <String, List<FileNode>>{};

      for (final row in rows) {
        final filePath = row[DatabaseSchema.colTrackFilePath] as String?;
        if (filePath == null) continue;

        final dirPath = p.dirname(filePath);
        final fileName = p.basename(filePath);
        final trackId = row[DatabaseSchema.colId] as String?;
        final fileSize = (row[DatabaseSchema.colFileSize] as int?) ?? 0;

        foldersMap.putIfAbsent(dirPath, () => []).add(FileNode(
              path: filePath,
              name: fileName,
              trackId: trackId,
              fileSize: fileSize,
            ));
      }

      final rootNodes = <FolderNode>[];

      for (final entry in foldersMap.entries) {
        final dirPath = entry.key;
        final files = entry.value;
        final dirName = p.basename(dirPath);

        rootNodes.add(FolderNode(
          path: dirPath,
          name: dirName.isNotEmpty ? dirName : dirPath,
          files: files,
        ));
      }

      // Sort folders by path alphabetically
      rootNodes.sort((a, b) => a.path.compareTo(b.path));

      return Result.success(rootNodes);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to construct folders tree: $e',
        e,
        st,
      ));
    }
  }
}
