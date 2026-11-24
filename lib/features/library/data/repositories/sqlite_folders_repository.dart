import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:path/path.dart' as p;

class _MutableDirNode {
  _MutableDirNode({required this.path, required this.name});

  final String path;
  final String name;
  final Map<String, _MutableDirNode> children = {};
  final List<FileNode> files = [];

  bool get hasAnyAudio =>
      files.isNotEmpty || children.values.any((c) => c.hasAnyAudio);

  FolderNode toImmutable() {
    final sortedSubs = children.values
        .where((c) => c.hasAnyAudio)
        .map((c) => c.toImmutable())
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final sortedFiles = List<FileNode>.from(files)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return FolderNode(
      path: path,
      name: name.isNotEmpty ? name : path,
      subFolders: sortedSubs,
      files: sortedFiles,
    );
  }
}

/// SQLite-backed implementation of [IFoldersRepository].
///
/// Builds a strict hierarchical directory tree of audio-containing folders where
/// every node holds ONLY its direct subfolders and direct audio files.
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
        'ORDER BY ${DatabaseSchema.colTrackFilePath} COLLATE NOCASE ASC',
      );

      final virtualRoot = _MutableDirNode(path: '/', name: '/');

      for (final row in rows) {
        final rawFilePath = row[DatabaseSchema.colTrackFilePath] as String?;
        if (rawFilePath == null || rawFilePath.isEmpty) continue;

        final normalizedFilePath = rawFilePath.replaceAll(r'\', '/');
        final dirPath = p.posix.dirname(normalizedFilePath);
        final fileName = p.posix.basename(normalizedFilePath);
        final trackId = row[DatabaseSchema.colId] as String?;
        final fileSize = (row[DatabaseSchema.colFileSize] as int?) ?? 0;

        final segments = dirPath
            .split('/')
            .where((s) => s.isNotEmpty)
            .toList();

        var cursor = virtualRoot;
        var builtPath = dirPath.startsWith('/') ? '' : '';

        for (final seg in segments) {
          builtPath = dirPath.startsWith('/')
              ? '$builtPath/$seg'
              : (builtPath.isEmpty ? seg : '$builtPath/$seg');
          cursor = cursor.children.putIfAbsent(
            seg,
            () => _MutableDirNode(path: builtPath, name: seg),
          );
        }

        cursor.files.add(FileNode(
          path: rawFilePath,
          name: fileName,
          trackId: trackId,
          fileSize: fileSize,
        ));
      }

      if (!virtualRoot.hasAnyAudio) {
        return const Result.success([]);
      }

      // Unwrap OS storage mount prefixes (e.g. '/', '/storage', '/storage/emulated/0',
      // or '/home/music' when empty) so the root screen displays meaningful audio folders.
      List<FolderNode> unwrapEmptyAncestors(FolderNode node) {
        if (node.files.isNotEmpty || node.subFolders.isEmpty) {
          return [node];
        }
        final expanded = <FolderNode>[];
        for (final sub in node.subFolders) {
          expanded.addAll(unwrapEmptyAncestors(sub));
        }
        return expanded;
      }

      final rawRoot = virtualRoot.toImmutable();
      var roots = <FolderNode>[];

      if (rawRoot.files.isNotEmpty) {
        // Songs sit directly at storage root; return subFolders and a root node if needed
        roots = [rawRoot];
      } else {
        for (final child in rawRoot.subFolders) {
          roots.addAll(unwrapEmptyAncestors(child));
        }
      }

      // Filter by optional rootPaths if requested
      if (rootPaths.isNotEmpty) {
        final normalizedRoots =
            rootPaths.map((r) => r.replaceAll(r'\', '/')).toSet();
        final matched = <FolderNode>[];
        for (final rootPath in normalizedRoots) {
          final found = rawRoot.findByPath(rootPath);
          if (found != null) {
            matched.add(found);
          }
        }
        if (matched.isNotEmpty) {
          roots = matched;
        }
      }

      roots.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
      return Result.success(roots);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to construct folders tree: $e',
        e,
        st,
      ));
    }
  }
}
