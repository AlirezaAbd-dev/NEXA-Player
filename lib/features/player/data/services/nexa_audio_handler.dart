import 'dart:async';
import 'package:audio_service/audio_service.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/models/track.dart';
import '../../../library/domain/repositories/tracks_repository.dart';
import '../../../playlists/domain/repositories/playlists_repository.dart';
import '../../../search/domain/repositories/search_repository.dart';
import '../../domain/entities/playback_state.dart' as domain;
import '../../domain/services/audio_engine.dart';
import '../../domain/services/playback_queue.dart';

/// Background audio handler integrating NEXA Player with the platform OS media session,
/// lock screen controls, headset events, notification tray, and Android Auto MediaBrowser.
class NexaAudioHandler extends BaseAudioHandler with SeekHandler {
  NexaAudioHandler({
    required IAudioEngine engine,
    required IPlaybackQueue queue,
    ITracksRepository? tracksRepository,
    IPlaylistsRepository? playlistsRepository,
    ISearchRepository? searchRepository,
  })  : _engine = engine,
        _queue = queue,
        _tracksRepository = tracksRepository,
        _playlistsRepository = playlistsRepository,
        _searchRepository = searchRepository {
    _bindStreams();
  }

  final IAudioEngine _engine;
  final IPlaybackQueue _queue;
  final ITracksRepository? _tracksRepository;
  final IPlaylistsRepository? _playlistsRepository;
  final ISearchRepository? _searchRepository;

  final List<StreamSubscription> _subscriptions = [];

  ITracksRepository? get _effectiveTracksRepo =>
      _tracksRepository ??
      (getIt.isRegistered<ITracksRepository>()
          ? getIt<ITracksRepository>()
          : null);

  IPlaylistsRepository? get _effectivePlaylistsRepo =>
      _playlistsRepository ??
      (getIt.isRegistered<IPlaylistsRepository>()
          ? getIt<IPlaylistsRepository>()
          : null);

  ISearchRepository? get _effectiveSearchRepo =>
      _searchRepository ??
      (getIt.isRegistered<ISearchRepository>()
          ? getIt<ISearchRepository>()
          : null);

  void _bindStreams() {
    _subscriptions.add(
      _engine.statusStream.listen((_) => _syncPlaybackState()),
    );
    _subscriptions.add(
      _engine.positionStream.listen((_) => _syncPlaybackState()),
    );
    _subscriptions.add(
      _queue.queueStream.listen((queueState) {
        final current = queueState.currentTrack;
        if (current != null) {
          mediaItem.add(_toMediaItem(current));
        }
        _syncPlaybackState();
      }),
    );
  }

  MediaItem _toMediaItem(Track track, {bool playable = true}) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      artUri: track.artworkUri != null ? Uri.tryParse(track.artworkUri!) : null,
      playable: playable,
      extras: {
        'filePath': track.filePath,
        'year': track.year,
        'genre': track.genre,
        'isFavorite': track.isFavorite,
      },
    );
  }

  void _syncPlaybackState() {
    final status = _engine.status;
    final isPlaying = status == domain.PlaybackStatus.playing;
    final isBuffering = status == domain.PlaybackStatus.buffering ||
        status == domain.PlaybackStatus.loading;

    final controls = [
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      MediaControl.stop,
    ];

    playbackState.add(
      PlaybackState(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
          MediaAction.playFromMediaId,
          MediaAction.playFromSearch,
          MediaAction.setRating,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: isBuffering
            ? AudioProcessingState.buffering
            : status == domain.PlaybackStatus.completed
                ? AudioProcessingState.completed
                : AudioProcessingState.ready,
        playing: isPlaying,
        updatePosition: _engine.position,
        bufferedPosition: _engine.position,
        speed: _engine.speed,
        queueIndex: _queue.state.currentIndex,
      ),
    );
  }

  @override
  Future<void> play() => _engine.play();

  @override
  Future<void> pause() => _engine.pause();

  @override
  Future<void> stop() async {
    await _engine.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _engine.seek(position);

  @override
  Future<void> skipToNext() async {
    final track = _queue.next();
    if (track != null) {
      await _engine.load(track, autoPlay: true);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_engine.position > const Duration(seconds: 3)) {
      await _engine.seek(Duration.zero);
      return;
    }

    final track = _queue.previous();
    if (track != null) {
      await _engine.load(track, autoPlay: true);
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    final track = _queue.skipToIndex(index);
    if (track != null) {
      await _engine.load(track, autoPlay: true);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    switch (repeatMode) {
      case AudioServiceRepeatMode.none:
        _queue.setMode(domain.PlaybackMode.ordered);
        break;
      case AudioServiceRepeatMode.one:
        _queue.setMode(domain.PlaybackMode.repeatOne);
        break;
      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        _queue.setMode(domain.PlaybackMode.repeatAll);
        break;
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.all ||
        shuffleMode == AudioServiceShuffleMode.group) {
      _queue.setMode(domain.PlaybackMode.shuffle);
    } else {
      _queue.setMode(domain.PlaybackMode.ordered);
    }
  }

  // ===========================================================================
  // Android Auto MediaBrowser Hierarchy
  // ===========================================================================

  static const String rootMediaId = 'root';
  static const String rootSongsId = 'root/songs';
  static const String rootFavoritesId = 'root/favorites';
  static const String rootPlaylistsId = 'root/playlists';
  static const String rootQueueId = 'root/queue';

  @override
  Future<List<MediaItem>> getChildren(
    String parentMediaId, [
    Map<String, dynamic>? options,
  ]) async {
    // 1. Top-Level MediaBrowser Root Hierarchy for Android Auto & Wear OS
    if (parentMediaId == AudioService.browsableRootId ||
        parentMediaId == rootMediaId) {
      return const [
        MediaItem(
          id: rootSongsId,
          title: 'All Tracks',
          album: 'NEXA High-Res Engine',
          artist: 'Browse complete music library',
          playable: false,
        ),
        MediaItem(
          id: rootFavoritesId,
          title: 'Favorites',
          album: 'NEXA High-Res Engine',
          artist: 'Starred favorite songs',
          playable: false,
        ),
        MediaItem(
          id: rootPlaylistsId,
          title: 'Playlists',
          album: 'NEXA High-Res Engine',
          artist: 'Custom playlists',
          playable: false,
        ),
        MediaItem(
          id: rootQueueId,
          title: 'Up Next Queue',
          album: 'NEXA High-Res Engine',
          artist: 'Active playback queue',
          playable: false,
        ),
      ];
    }

    // 2. All Songs List
    if (parentMediaId == rootSongsId) {
      final repo = _effectiveTracksRepo;
      if (repo == null) return const [];
      final res = await repo.getAllTracks();
      final tracks = res.valueOrNull ?? [];
      return tracks.map((t) => _toMediaItem(t, playable: true)).toList();
    }

    // 3. Favorites List
    if (parentMediaId == rootFavoritesId) {
      final repo = _effectiveTracksRepo;
      if (repo == null) return const [];
      final res = await repo.getAllTracks();
      final tracks = res.valueOrNull ?? [];
      final favs = tracks.where((t) => t.isFavorite).toList();
      return favs.map((t) => _toMediaItem(t, playable: true)).toList();
    }

    // 4. Playlists Overview
    if (parentMediaId == rootPlaylistsId) {
      final repo = _effectivePlaylistsRepo;
      if (repo == null) return const [];
      final res = await repo.getAllPlaylists();
      final playlists = res.valueOrNull ?? [];
      return playlists.map((p) => MediaItem(
        id: 'playlist/${p.id}',
        title: p.name,
        album: 'Playlist (${p.trackCount} tracks)',
        artist: 'NEXA Playlist',
        playable: false,
      )).toList();
    }

    // 5. Tracks inside a specific Playlist
    if (parentMediaId.startsWith('playlist/')) {
      final playlistId = parentMediaId.substring('playlist/'.length);
      final repo = _effectivePlaylistsRepo;
      if (repo == null) return const [];
      final res = await repo.getTracksForPlaylist(playlistId);
      final tracks = res.valueOrNull ?? [];
      return tracks.map((t) => _toMediaItem(t, playable: true)).toList();
    }

    // 6. Active Playback Queue
    if (parentMediaId == rootQueueId) {
      return _queue.state.tracks
          .map((t) => _toMediaItem(t, playable: true))
          .toList();
    }

    return const [];
  }

  @override
  Future<MediaItem?> getMediaItem(String mediaId) async {
    // Check if item is in active queue
    for (final track in _queue.state.tracks) {
      if (track.id == mediaId) {
        return _toMediaItem(track);
      }
    }

    // Otherwise check tracks repository
    final repo = _effectiveTracksRepo;
    if (repo != null) {
      final res = await repo.getTrackById(mediaId);
      final track = res.valueOrNull;
      if (track != null) {
        return _toMediaItem(track);
      }
    }

    return null;
  }

  @override
  Future<void> playFromMediaId(
    String mediaId, [
    Map<String, dynamic>? extras,
  ]) async {
    // 1. Play entire Favorites
    if (mediaId == rootFavoritesId) {
      final repo = _effectiveTracksRepo;
      if (repo != null) {
        final res = await repo.getAllTracks();
        final favs = (res.valueOrNull ?? []).where((t) => t.isFavorite).toList();
        if (favs.isNotEmpty) {
          _queue.setQueue(favs, initialIndex: 0);
          await _engine.load(favs.first, autoPlay: true);
        }
      }
      return;
    }

    // 2. Play entire Playlist
    if (mediaId.startsWith('playlist/')) {
      final playlistId = mediaId.substring('playlist/'.length);
      final repo = _effectivePlaylistsRepo;
      if (repo != null) {
        final res = await repo.getTracksForPlaylist(playlistId);
        final tracks = res.valueOrNull ?? [];
        if (tracks.isNotEmpty) {
          _queue.setQueue(tracks, initialIndex: 0);
          await _engine.load(tracks.first, autoPlay: true);
        }
      }
      return;
    }

    // 3. Play specific Track ID
    final trackIndex = _queue.state.tracks.indexWhere((t) => t.id == mediaId);
    if (trackIndex >= 0) {
      final track = _queue.skipToIndex(trackIndex);
      if (track != null) {
        await _engine.load(track, autoPlay: true);
      }
      return;
    }

    // Track is not in current queue; load from repository
    final repo = _effectiveTracksRepo;
    if (repo != null) {
      final res = await repo.getTrackById(mediaId);
      final track = res.valueOrNull;
      if (track != null) {
        _queue.setQueue([track], initialIndex: 0);
        await _engine.load(track, autoPlay: true);
      }
    }
  }

  @override
  Future<List<MediaItem>> search(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];

    final searchRepo = _effectiveSearchRepo;
    if (searchRepo != null) {
      final res = await searchRepo.search(query: q);
      final searchResult = res.valueOrNull;
      if (searchResult != null) {
        return searchResult.tracks
            .map((t) => _toMediaItem(t, playable: true))
            .toList();
      }
    }

    // Fallback search directly in tracks repo
    final tracksRepo = _effectiveTracksRepo;
    if (tracksRepo != null) {
      final res = await tracksRepo.getAllTracks();
      final tracks = res.valueOrNull ?? [];
      final matches = tracks.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q);
      }).toList();

      return matches
          .map((t) => _toMediaItem(t, playable: true))
          .toList();
    }

    return const [];
  }

  @override
  Future<void> playFromSearch(
    String query, [
    Map<String, dynamic>? extras,
  ]) async {
    final matches = await search(query, extras);
    if (matches.isNotEmpty) {
      await playFromMediaId(matches.first.id);
    }
  }

  @override
  Future<dynamic> customAction(
    String name, [
    Map<String, dynamic>? extras,
  ]) async {
    switch (name) {
      case 'toggleFavorite':
        final current = _queue.state.currentTrack;
        if (current != null) {
          final repo = _effectiveTracksRepo;
          if (repo != null) {
            await repo.toggleFavorite(current.id);
          }
        }
        break;
      case 'shuffleQueue':
        final currentMode = _queue.state.mode;
        if (currentMode == domain.PlaybackMode.shuffle) {
          _queue.setMode(domain.PlaybackMode.ordered);
        } else {
          _queue.setMode(domain.PlaybackMode.shuffle);
        }
        break;
    }
  }

  /// Cleans up subscriptions and resources.
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}
