import 'package:equatable/equatable.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:path/path.dart' as p;

/// Node representing a directory in the folder tree view.
class FolderNode extends Equatable {
  const FolderNode({
    required this.path,
    required this.name,
    this.subFolders = const [],
    this.files = const [],
  });

  final String path;
  final String name;
  final List<FolderNode> subFolders;
  final List<FileNode> files;

  /// Number of direct child folders inside this folder.
  int get subFolderCount => subFolders.length;

  /// Number of audio files sitting directly inside this folder.
  int get directTrackCount => files.length;

  /// Total number of audio files inside this folder and all descendant subfolders.
  int get recursiveTrackCount =>
      files.length +
      subFolders.fold<int>(0, (sum, sub) => sum + sub.recursiveTrackCount);

  /// Finds the [FolderNode] matching [targetPath] anywhere inside this subtree.
  FolderNode? findByPath(String targetPath) {
    if (path == targetPath) return this;
    for (final sub in subFolders) {
      final match = sub.findByPath(targetPath);
      if (match != null) return match;
    }
    return null;
  }

  @override
  List<Object?> get props => [path, name, subFolders, files];
}

/// Node representing an audio file in the folder tree view.
class FileNode extends Equatable {
  const FileNode({
    required this.path,
    required this.name,
    this.trackId,
    this.fileSize = 0,
    this.track,
  });

  final String path;
  final String name;
  final String? trackId;
  final int fileSize;
  final Track? track;

  /// Track title when indexed, falling back to filename without extension.
  String get displayTitle {
    final t = track?.title.trim();
    if (t != null && t.isNotEmpty) return t;
    return p.basenameWithoutExtension(name);
  }

  /// Artist subtitle when available.
  String get displayArtist => track?.artist.trim() ?? '';

  @override
  List<Object?> get props => [path, name, trackId, fileSize, track];
}

/// Repository contract managing folder-tree navigation over indexed media paths.
abstract interface class IFoldersRepository {
  /// Builds a hierarchical folder tree structure from indexed tracks and directory roots.
  Future<Result<List<FolderNode>, DatabaseFailure>> getFoldersTree(
    List<String> rootPaths,
  );
}
