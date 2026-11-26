import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/artwork/artwork_resolution_service.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../../library/domain/repositories/tracks_repository.dart';
import '../../../playlists/domain/repositories/playlists_repository.dart';
import '../../../search/domain/repositories/search_repository.dart';
import '../../domain/entities/playback_state.dart' as domain;
import '../../domain/services/audio_engine.dart';
import '../../domain/services/playback_queue.dart';

/// Shared production configuration for Android/iOS OS media notification and lockscreen controls.
const AudioServiceConfig nexaAudioServiceConfig = AudioServiceConfig(
  androidResumeOnClick: true,
  androidNotificationChannelId: 'com.nexa.player.channel.audio',
  androidNotificationChannelName: 'NEXA Playback Controls',
  androidNotificationChannelDescription:
      'Album cover, track controls, and interactive seek bar',
  androidNotificationIcon: 'drawable/ic_stat_nexa',
  androidShowNotificationBadge: false,
  androidNotificationClickStartsActivity: true,
  androidNotificationOngoing: false,
  androidStopForegroundOnPause: true,
  artDownscaleWidth: 512,
  artDownscaleHeight: 512,
  preloadArtwork: true,
);

/// Background audio handler integrating NEXA Player with the platform OS media session,
/// lock screen controls, headset events, notification tray, interactive seekbar, and
/// Android Auto MediaBrowser.
class NexaAudioHandler extends BaseAudioHandler with SeekHandler {
  NexaAudioHandler({
    required IAudioEngine engine,
    required IPlaybackQueue queue,
    ITracksRepository? tracksRepository,
    IPlaylistsRepository? playlistsRepository,
    ISearchRepository? searchRepository,
    IArtworkResolutionService? artworkResolver,
    IStorageService? storageService,
  })  : _engine = engine,
        _queue = queue,
        _tracksRepository = tracksRepository,
        _playlistsRepository = playlistsRepository,
        _searchRepository = searchRepository,
        _artworkResolver = artworkResolver,
        _storageService = storageService {
    _bindStreams();
  }

  final IAudioEngine _engine;
  final IPlaybackQueue _queue;
  final ITracksRepository? _tracksRepository;
  final IPlaylistsRepository? _playlistsRepository;
  final ISearchRepository? _searchRepository;
  final IArtworkResolutionService? _artworkResolver;
  final IStorageService? _storageService;

  final List<StreamSubscription> _subscriptions = [];
  Duration _lastSyncedPosition = Duration.zero;
  DateTime _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);
  domain.PlaybackStatus? _lastSyncedStatus;
  String? _lastMediaItemKey;

  Future<void> Function()? _onSkipNextRequested;
  Future<void> Function()? _onSkipPreviousRequested;
  Future<void> Function()? _onPlayRequested;
  Future<void> Function()? _onPauseRequested;
  Future<void> Function()? _onStopRequested;
  Future<void> Function(Duration position)? _onSeekRequested;
  Future<void> Function()? _onToggleFavoriteRequested;

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

  IArtworkResolutionService? get _effectiveArtworkResolver =>
      _artworkResolver ??
      (getIt.isRegistered<IArtworkResolutionService>()
          ? getIt<IArtworkResolutionService>()
          : null);

  IStorageService? get _effectiveStorage =>
      _storageService ??
      (getIt.isRegistered<IStorageService>()
          ? getIt<IStorageService>()
          : null);

  /// Binds higher-level coordinator callbacks (e.g. `PlayerNotifier`) so
  /// notification/lockscreen transport controls respect Stellio repeat modes,
  /// play counts, and Riverpod UI state.
  void bindTransportCallbacks({
    Future<void> Function()? onPlay,
    Future<void> Function()? onPause,
    Future<void> Function()? onStop,
    Future<void> Function(Duration position)? onSeek,
    Future<void> Function()? onSkipNext,
    Future<void> Function()? onSkipPrevious,
    Future<void> Function()? onToggleFavorite,
  }) {
    _onPlayRequested = onPlay;
    _onPauseRequested = onPause;
    _onStopRequested = onStop;
    _onSeekRequested = onSeek;
    _onSkipNextRequested = onSkipNext;
    _onSkipPreviousRequested = onSkipPrevious;
    _onToggleFavoriteRequested = onToggleFavorite;
  }

  /// Immediately updates the published OS `MediaItem` & notification controls
  /// for [track] (e.g. after metadata edit, telemetry hydration, or favorite toggle).
  void updateMediaTrack(Track track) {
    _publishMediaItem(track);
    _syncPlaybackState(force: true);
  }

  void _bindStreams() {
    _subscriptions.add(
      _engine.statusStream.listen((_) => _syncPlaybackState(force: true)),
    );
    _subscriptions.add(
      _engine.speedStream.listen((_) => _syncPlaybackState(force: true)),
    );
    _subscriptions.add(
      _engine.durationStream.listen((dur) {
        final current = _queue.state.currentTrack;
        if (current != null && dur > Duration.zero && current.duration != dur) {
          _publishMediaItem(current.copyWith(duration: dur));
          _syncPlaybackState(force: true);
        }
      }),
    );
    _subscriptions.add(
      _engine.positionStream.listen((pos) {
        // Avoid excessive IPC floods while correcting any seek/buffer drift > 1s.
        final now = DateTime.now();
        final expectedDelta =
            (now.difference(_lastSyncTime).inMilliseconds * _engine.speed)
                .round();
        final actualDelta = (pos - _lastSyncedPosition).inMilliseconds;
        if ((actualDelta - expectedDelta).abs() > 1000) {
          _syncPlaybackState(force: true, explicitPosition: pos);
        }
      }),
    );
    _subscriptions.add(
      _queue.queueStream.listen((queueState) {
        final current = queueState.currentTrack;
        if (current != null) {
          _publishMediaItem(current);
        }
        _syncPlaybackState(force: true);
      }),
    );
  }

  void _publishMediaItem(Track track) {
    final resolvedDuration =
        _engine.duration > Duration.zero ? _engine.duration : track.duration;
    final enrichedTrack = track.copyWith(duration: resolvedDuration);
    final item = _toMediaItem(enrichedTrack);
    final itemKey =
        '${item.id}|${item.title}|${item.artist}|${item.album}|${item.duration?.inMilliseconds}|${item.artUri}';
    if (_lastMediaItemKey != itemKey) {
      _lastMediaItemKey = itemKey;
      mediaItem.add(item);
    }

    // Lazily resolve local album artwork URI for SystemUI/lockscreen tinting if missing.
    if (item.artUri == null) {
      final resolver = _effectiveArtworkResolver;
      if (resolver != null) {
        unawaited(
          resolver.resolveTrackArtwork(enrichedTrack).then((path) {
            if (path == null || path.isEmpty) return;
            final current = _queue.state.currentTrack;
            if (current == null || current.id != enrichedTrack.id) return;
            final updatedItem = _toMediaItem(
              enrichedTrack.copyWith(artworkUri: path),
            );
            _lastMediaItemKey =
                '${updatedItem.id}|${updatedItem.title}|${updatedItem.artist}|${updatedItem.album}|${updatedItem.duration?.inMilliseconds}|${updatedItem.artUri}';
            mediaItem.add(updatedItem);
          }).catchError((_) {}),
        );
      }
    }
  }

  Uri? _resolveArtUri(String? artworkUri) {
    if (artworkUri == null || artworkUri.isEmpty) return null;
    if (artworkUri.startsWith('http://') ||
        artworkUri.startsWith('https://') ||
        artworkUri.startsWith('content://')) {
      return Uri.tryParse(artworkUri);
    }
    if (artworkUri.startsWith('file://')) {
      final path = artworkUri.substring('file://'.length);
      if (File(path).existsSync()) {
        return Uri.tryParse(artworkUri);
      }
      return Uri.tryParse(artworkUri);
    }
    return Uri.file(artworkUri);
  }

  MediaItem _toMediaItem(Track track, {bool playable = true}) {
    final effectiveTitle =
        track.title.trim().isNotEmpty ? track.title : 'Unknown Track';
    final effectiveArtist =
        track.artist.trim().isNotEmpty ? track.artist : 'Unknown Artist';
    final effectiveAlbum =
        track.album.trim().isNotEmpty ? track.album : 'NEXA Player';
    return MediaItem(
      id: track.id,
      title: effectiveTitle,
      artist: effectiveArtist,
      album: effectiveAlbum,
      duration: track.duration > Duration.zero ? track.duration : null,
      artUri: _resolveArtUri(track.artworkUri),
      playable: playable,
      extras: {
        'filePath': track.filePath,
        'year': track.year,
        'genre': track.genre,
        'isFavorite': track.isFavorite,
      },
    );
  }

  bool _includeFavoriteControl() {
    final raw =
        _effectiveStorage?.getString(StorageKeys.notificationActions).valueOrNull;
    if (raw == null || raw.isEmpty) return false;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).contains('favorite');
      }
    } catch (_) {}
    return raw.split(',').map((s) => s.trim()).contains('favorite');
  }

  void _syncPlaybackState({
    bool force = false,
    Duration? explicitPosition,
  }) {
    final status = _engine.status;
    if (!force && status == _lastSyncedStatus) {
      return;
    }

    final isPlaying = status == domain.PlaybackStatus.playing;
    final isBuffering = status == domain.PlaybackStatus.buffering ||
        status == domain.PlaybackStatus.loading;
    final currentTrack = _queue.state.currentTrack;
    final pos = explicitPosition ?? _engine.position;
    final maxDur = _engine.duration > Duration.zero
        ? _engine.duration
        : (currentTrack?.duration ?? Duration.zero);
    final clampedPos = (maxDur > Duration.zero && pos > maxDur)
        ? maxDur
        : (pos < Duration.zero ? Duration.zero : pos);

    final showFavorite = _includeFavoriteControl();
    final isFavorite = currentTrack?.isFavorite ?? false;

    final controls = <MediaControl>[
      MediaControl.skipToPrevious,
      if (isPlaying) MediaControl.pause else MediaControl.play,
      MediaControl.skipToNext,
      if (showFavorite)
        MediaControl.custom(
          androidIcon: 'drawable/ic_stat_nexa',
          label: isFavorite ? 'Unfavorite' : 'Favorite',
          name: 'toggleFavorite',
        ),
    ];

    final AudioProcessingState processingState;
    if (isBuffering) {
      processingState = AudioProcessingState.buffering;
    } else if (status == domain.PlaybackStatus.completed) {
      processingState = AudioProcessingState.completed;
    } else if (status == domain.PlaybackStatus.idle && currentTrack == null) {
      processingState = AudioProcessingState.idle;
    } else if (status == domain.PlaybackStatus.error) {
      processingState = AudioProcessingState.error;
    } else {
      processingState = AudioProcessingState.ready;
    }

    final AudioServiceRepeatMode mappedRepeat;
    switch (_queue.state.repeatMode) {
      case domain.NexaRepeatMode.stopOnLastTrack:
        mappedRepeat = AudioServiceRepeatMode.none;
        break;
      case domain.NexaRepeatMode.repeatSelectedTrack:
        mappedRepeat = AudioServiceRepeatMode.one;
        break;
      case domain.NexaRepeatMode.repeatList:
      case domain.NexaRepeatMode.nextListStopOnLast:
      case domain.NexaRepeatMode.nextListRepeatFirst:
        mappedRepeat = AudioServiceRepeatMode.all;
        break;
    }

    _lastSyncedStatus = status;
    _lastSyncedPosition = clampedPos;
    _lastSyncTime = DateTime.now();

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
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: processingState,
        playing: isPlaying,
        updatePosition: clampedPos,
        bufferedPosition: clampedPos,
        speed: isPlaying ? _engine.speed : 0.0,
        queueIndex: _queue.state.currentIndex,
        repeatMode: mappedRepeat,
        shuffleMode: _queue.state.isShuffled
            ? AudioServiceShuffleMode.all
            : AudioServiceShuffleMode.none,
      ),
    );
  }

  @override
  Future<void> play() async {
    if (_onPlayRequested != null) {
      await _onPlayRequested!();
    } else {
      await _engine.play();
    }
    _syncPlaybackState(force: true);
  }

  @override
  Future<void> pause() async {
    if (_onPauseRequested != null) {
      await _onPauseRequested!();
    } else {
      await _engine.pause();
    }
    _syncPlaybackState(force: true);
  }

  @override
  Future<void> stop() async {
    if (_onStopRequested != null) {
      await _onStopRequested!();
    } else {
      await _engine.stop();
    }
    _syncPlaybackState(force: true, explicitPosition: Duration.zero);
    await super.stop();
  }

  @override
  Future<void> onNotificationDeleted() async {
    // Allow dismissing notification when paused without discarding active track/position;
    // pressing Play later re-promotes foreground service and shows notification again.
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) async {
    final maxDur = _engine.duration > Duration.zero
        ? _engine.duration
        : (_queue.state.currentTrack?.duration ?? Duration.zero);
    final clamped = position < Duration.zero
        ? Duration.zero
        : (maxDur > Duration.zero && position > maxDur ? maxDur : position);

    if (_onSeekRequested != null) {
      await _onSeekRequested!(clamped);
    } else {
      await _engine.seek(clamped);
    }
    _syncPlaybackState(force: true, explicitPosition: clamped);
  }

  @override
  Future<void> skipToNext() async {
    if (_onSkipNextRequested != null) {
      await _onSkipNextRequested!();
      return;
    }
    final track = _queue.next();
    if (track != null) {
      await _engine.load(track, autoPlay: true);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    if (_onSkipPreviousRequested != null) {
      await _onSkipPreviousRequested!();
      return;
    }
    if (_engine.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
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
    _syncPlaybackState(force: true);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    if (shuffleMode == AudioServiceShuffleMode.all ||
        shuffleMode == AudioServiceShuffleMode.group) {
      _queue.setMode(domain.PlaybackMode.shuffle);
    } else {
      _queue.setMode(domain.PlaybackMode.ordered);
    }
    _syncPlaybackState(force: true);
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
      return playlists
          .map((p) => MediaItem(
                id: 'playlist/${p.id}',
                title: p.name,
                album: 'Playlist (${p.trackCount} tracks)',
                artist: 'NEXA Playlist',
                playable: false,
              ))
          .toList();
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
    for (final track in _queue.state.tracks) {
      if (track.id == mediaId) {
        return _toMediaItem(track);
      }
    }

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

    final trackIndex = _queue.state.tracks.indexWhere((t) => t.id == mediaId);
    if (trackIndex >= 0) {
      final track = _queue.skipToIndex(trackIndex);
      if (track != null) {
        await _engine.load(track, autoPlay: true);
      }
      return;
    }

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

    final tracksRepo = _effectiveTracksRepo;
    if (tracksRepo != null) {
      final res = await tracksRepo.getAllTracks();
      final tracks = res.valueOrNull ?? [];
      final matches = tracks.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.artist.toLowerCase().contains(q) ||
            t.album.toLowerCase().contains(q);
      }).toList();

      return matches.map((t) => _toMediaItem(t, playable: true)).toList();
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
        if (_onToggleFavoriteRequested != null) {
          await _onToggleFavoriteRequested!();
          return;
        }
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
        _syncPlaybackState(force: true);
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
