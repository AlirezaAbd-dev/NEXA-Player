import 'package:equatable/equatable.dart';
import '../../../../shared/models/track.dart';
import '../../../library/domain/repositories/albums_repository.dart';
import '../../../library/domain/repositories/artists_repository.dart';
import '../../../library/domain/repositories/folders_repository.dart';
import '../../../library/domain/repositories/tracks_repository.dart';
import '../../../playlists/domain/repositories/playlists_repository.dart';
import '../entities/queue_context.dart';

/// Result returned when advancing across library collections.
class QueueListTransitionResult extends Equatable {
  const QueueListTransitionResult({
    required this.context,
    required this.tracks,
    required this.initialIndex,
  });

  /// Metadata describing the destination list.
  final QueueContext context;

  /// Tracks contained inside the destination list.
  final List<Track> tracks;

  /// Entry index (`0` for forward transition, `tracks.length - 1` for backward).
  final int initialIndex;

  @override
  List<Object?> get props => [context, tracks, initialIndex];
}

/// Resolves neighboring collections (folders, albums, artists, playlists) when
/// cross-list repeat modes reach the boundary of the active queue.
abstract interface class IQueueListNavigator {
  /// Returns the next non-empty list after [current], or wraps to the first
  /// list when [wrapToFirst] is `true`. Returns `null` when playback should stop.
  Future<QueueListTransitionResult?> nextList(
    QueueContext current, {
    required bool wrapToFirst,
  });

  /// Returns the previous non-empty list before [current], or wraps to the last
  /// list when [wrapToLast] is `true`. Returns `null` if unavailable.
  Future<QueueListTransitionResult?> previousList(
    QueueContext current, {
    required bool wrapToLast,
  });
}

/// Default library-backed [IQueueListNavigator] navigating folders (depth-first
/// non-empty audio directories), albums, artists, playlists, and all songs.
class LibraryQueueListNavigator implements IQueueListNavigator {
  const LibraryQueueListNavigator({
    IFoldersRepository? foldersRepository,
    ITracksRepository? tracksRepository,
    IAlbumsRepository? albumsRepository,
    IArtistsRepository? artistsRepository,
    IPlaylistsRepository? playlistsRepository,
  })  : _foldersRepository = foldersRepository,
        _tracksRepository = tracksRepository,
        _albumsRepository = albumsRepository,
        _artistsRepository = artistsRepository,
        _playlistsRepository = playlistsRepository;

  final IFoldersRepository? _foldersRepository;
  final ITracksRepository? _tracksRepository;
  final IAlbumsRepository? _albumsRepository;
  final IArtistsRepository? _artistsRepository;
  final IPlaylistsRepository? _playlistsRepository;

  @override
  Future<QueueListTransitionResult?> nextList(
    QueueContext current, {
    required bool wrapToFirst,
  }) {
    return _navigate(current, forward: true, wrap: wrapToFirst);
  }

  @override
  Future<QueueListTransitionResult?> previousList(
    QueueContext current, {
    required bool wrapToLast,
  }) {
    return _navigate(current, forward: false, wrap: wrapToLast);
  }

  Future<QueueListTransitionResult?> _navigate(
    QueueContext current, {
    required bool forward,
    required bool wrap,
  }) async {
    switch (current.collectionType) {
      case QueueCollectionType.folder:
        return _navigateFolders(current, forward: forward, wrap: wrap);
      case QueueCollectionType.album:
        return _navigateAlbums(current, forward: forward, wrap: wrap);
      case QueueCollectionType.artist:
        return _navigateArtists(current, forward: forward, wrap: wrap);
      case QueueCollectionType.playlist:
        return _navigatePlaylists(current, forward: forward, wrap: wrap);
      case QueueCollectionType.allSongs:
        if (!wrap || _tracksRepository == null) return null;
        final res = await _tracksRepository.getAllTracks();
        final tracks = res.valueOrNull ?? const <Track>[];
        if (tracks.isEmpty) return null;
        return QueueListTransitionResult(
          context: current,
          tracks: tracks,
          initialIndex: forward ? 0 : tracks.length - 1,
        );
      case QueueCollectionType.custom:
        return null;
    }
  }

  Future<QueueListTransitionResult?> _navigateFolders(
    QueueContext current, {
    required bool forward,
    required bool wrap,
  }) async {
    final foldersRepo = _foldersRepository;
    final tracksRepo = _tracksRepository;
    if (foldersRepo == null) return null;

    final treeResult = await foldersRepo.getFoldersTree(const []);
    final roots = treeResult.valueOrNull ?? const <FolderNode>[];
    if (roots.isEmpty) return null;

    final orderedFolders = <FolderNode>[];
    void collectAudioFolders(List<FolderNode> nodes) {
      for (final node in nodes) {
        if (node.files.isNotEmpty) {
          orderedFolders.add(node);
        }
        if (node.subFolders.isNotEmpty) {
          collectAudioFolders(node.subFolders);
        }
      }
    }

    collectAudioFolders(roots);
    if (orderedFolders.isEmpty) return null;

    return _stepCollection<FolderNode>(
      items: orderedFolders,
      currentId: current.collectionId,
      idOf: (f) => f.path,
      forward: forward,
      wrap: wrap,
      resolveTracks: (folder) async {
        final tracks = <Track>[];
        for (final file in folder.files) {
          Track? resolved;
          if (file.trackId != null && tracksRepo != null) {
            final res = await tracksRepo.getTrackById(file.trackId!);
            resolved = res.valueOrNull;
          }
          tracks.add(
            resolved ??
                Track(
                  id: file.trackId ?? file.path,
                  title: _fileBaseName(file.name),
                  artist: folder.name,
                  album: folder.name,
                  duration: Duration.zero,
                  filePath: file.path,
                  fileSize: file.fileSize,
                ),
          );
        }
        return tracks;
      },
      buildContext: (folder) =>
          QueueContext.folder(folder.path, title: folder.name),
    );
  }

  Future<QueueListTransitionResult?> _navigateAlbums(
    QueueContext current, {
    required bool forward,
    required bool wrap,
  }) async {
    final albumsRepo = _albumsRepository;
    if (albumsRepo == null) return null;
    final albums = (await albumsRepo.getAllAlbums()).valueOrNull ?? const [];
    if (albums.isEmpty) return null;

    return _stepCollection(
      items: albums,
      currentId: current.collectionId,
      idOf: (a) => a.id,
      forward: forward,
      wrap: wrap,
      resolveTracks: (a) async =>
          (await albumsRepo.getTracksForAlbum(a.id)).valueOrNull ?? const [],
      buildContext: (a) => QueueContext.album(a.id, title: a.title),
    );
  }

  Future<QueueListTransitionResult?> _navigateArtists(
    QueueContext current, {
    required bool forward,
    required bool wrap,
  }) async {
    final artistsRepo = _artistsRepository;
    if (artistsRepo == null) return null;
    final artists = (await artistsRepo.getAllArtists()).valueOrNull ?? const [];
    if (artists.isEmpty) return null;

    return _stepCollection(
      items: artists,
      currentId: current.collectionId,
      idOf: (a) => a.id,
      forward: forward,
      wrap: wrap,
      resolveTracks: (a) async =>
          (await artistsRepo.getTracksForArtist(a.id)).valueOrNull ?? const [],
      buildContext: (a) => QueueContext.artist(a.id, title: a.name),
    );
  }

  Future<QueueListTransitionResult?> _navigatePlaylists(
    QueueContext current, {
    required bool forward,
    required bool wrap,
  }) async {
    final playlistsRepo = _playlistsRepository;
    if (playlistsRepo == null) return null;
    final playlists =
        (await playlistsRepo.getAllPlaylists()).valueOrNull ?? const [];
    if (playlists.isEmpty) return null;

    return _stepCollection(
      items: playlists,
      currentId: current.collectionId,
      idOf: (pl) => pl.id,
      forward: forward,
      wrap: wrap,
      resolveTracks: (pl) async =>
          (await playlistsRepo.getTracksForPlaylist(pl.id)).valueOrNull ??
          const [],
      buildContext: (pl) => QueueContext.playlist(pl.id, title: pl.name),
    );
  }

  Future<QueueListTransitionResult?> _stepCollection<T>({
    required List<T> items,
    required String currentId,
    required String Function(T item) idOf,
    required bool forward,
    required bool wrap,
    required Future<List<Track>> Function(T item) resolveTracks,
    required QueueContext Function(T item) buildContext,
  }) async {
    if (items.isEmpty) return null;

    final currentIdx = items.indexWhere((item) => idOf(item) == currentId);
    final step = forward ? 1 : -1;

    // If the active list isn't in the list, start from boundary if wrapping or index 0.
    int candidate = currentIdx == -1
        ? (forward ? 0 : items.length - 1)
        : currentIdx + step;

    var wrappedOnce = false;
    var visited = 0;

    while (visited < items.length) {
      if (candidate < 0 || candidate >= items.length) {
        if (!wrap || wrappedOnce) {
          return null;
        }
        wrappedOnce = true;
        candidate = forward ? 0 : items.length - 1;
      }

      // When only 1 item exists in stopOnLast mode, the out-of-bounds guard above returns null.
      // When wrap is true and only 1 item exists, returning it wraps back to start/end cleanly.
      final item = items[candidate];
      final tracks = await resolveTracks(item);
      if (tracks.isNotEmpty) {
        return QueueListTransitionResult(
          context: buildContext(item),
          tracks: tracks,
          initialIndex: forward ? 0 : tracks.length - 1,
        );
      }

      candidate += step;
      visited++;
    }

    return null;
  }

  String _fileBaseName(String filename) {
    final dot = filename.lastIndexOf('.');
    return dot > 0 ? filename.substring(0, dot) : filename;
  }
}
