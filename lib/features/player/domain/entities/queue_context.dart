import 'package:equatable/equatable.dart';

/// Identifies the type of library container backing the current playback queue.
enum QueueCollectionType {
  allSongs,
  folder,
  album,
  artist,
  playlist,
  custom,
}

/// Metadata identifying which library list (folder, album, artist, playlist)
/// originated the active queue so cross-list repeat modes know what comes next.
class QueueContext extends Equatable {
  const QueueContext({
    required this.collectionType,
    required this.collectionId,
    this.collectionTitle,
  });

  const QueueContext.allSongs({String title = 'Songs'})
      : collectionType = QueueCollectionType.allSongs,
        collectionId = 'all',
        collectionTitle = title;

  const QueueContext.folder(String folderPath, {String? title})
      : collectionType = QueueCollectionType.folder,
        collectionId = folderPath,
        collectionTitle = title;

  const QueueContext.album(String albumId, {String? title})
      : collectionType = QueueCollectionType.album,
        collectionId = albumId,
        collectionTitle = title;

  const QueueContext.artist(String artistId, {String? title})
      : collectionType = QueueCollectionType.artist,
        collectionId = artistId,
        collectionTitle = title;

  const QueueContext.playlist(String playlistId, {String? title})
      : collectionType = QueueCollectionType.playlist,
        collectionId = playlistId,
        collectionTitle = title;

  /// The category of list being played.
  final QueueCollectionType collectionType;

  /// Canonical identifier for the list (folder path, albumId, artistId, playlistId).
  final String collectionId;

  /// Optional display title of the list for UI badges / diagnostics.
  final String? collectionTitle;

  @override
  List<Object?> get props => [collectionType, collectionId, collectionTitle];
}
