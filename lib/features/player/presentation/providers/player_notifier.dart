import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../../library/domain/repositories/tracks_repository.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/entities/queue_context.dart';
import '../../domain/services/audio_engine.dart';
import '../../domain/services/playback_queue.dart';
import '../../domain/services/queue_list_navigator.dart';
import '../../domain/services/sleep_timer_service.dart';

/// State notifier managing playback lifecycle, queue interactions,
/// engine synchronization, Stellio 5-mode repeat, and state persistence.
class PlayerNotifier extends StateNotifier<PlaybackState> {
  PlayerNotifier({
    required IAudioEngine engine,
    required IPlaybackQueue queue,
    required ISleepTimerService sleepTimer,
    ITracksRepository? tracksRepository,
    IQueueListNavigator? listNavigator,
    IStorageService? storageService,
  })  : _engine = engine,
        _queue = queue,
        _sleepTimer = sleepTimer,
        _tracksRepository = tracksRepository,
        _listNavigator = listNavigator,
        _storageService = storageService,
        super(_buildInitialState(queue, storageService)) {
    _syncInitialQueueModes();
    _bindStreams();
  }

  static PlaybackState _buildInitialState(
    IPlaybackQueue queue,
    IStorageService? storageService,
  ) {
    final storedRepeat =
        storageService?.getString(StorageKeys.repeatMode).valueOrNull;
    final initialRepeat = storedRepeat != null
        ? NexaRepeatMode.fromStorage(storedRepeat)
        : queue.state.repeatMode;
    final storedShuffle =
        storageService?.getBool(StorageKeys.shuffleEnabled).valueOrNull ??
            queue.state.isShuffled;
    return PlaybackState(
      repeatMode: initialRepeat,
      isShuffled: storedShuffle,
      playbackMode:
          initialRepeat.toLegacyPlaybackMode(isShuffled: storedShuffle),
      queueVersion: queue.state.queueVersion,
    );
  }

  final IAudioEngine _engine;
  final IPlaybackQueue _queue;
  final ISleepTimerService _sleepTimer;
  final ITracksRepository? _tracksRepository;
  final IQueueListNavigator? _listNavigator;
  final IStorageService? _storageService;
  final List<StreamSubscription> _subscriptions = [];
  int _loadEpoch = 0;

  void _syncInitialQueueModes() {
    if (_queue.state.repeatMode != state.repeatMode) {
      _queue.setRepeatMode(state.repeatMode);
    }
    if (_queue.state.isShuffled != state.isShuffled) {
      _queue.setShuffle(state.isShuffled);
    }
  }

  void _bindStreams() {
    _subscriptions.add(
      _engine.statusStream.listen((status) {
        state = state.copyWith(status: status);
        if (status == PlaybackStatus.completed) {
          skipNext();
        }
      }),
    );

    _subscriptions.add(
      _engine.positionStream.listen((pos) {
        state = state.copyWith(position: pos);
      }),
    );

    _subscriptions.add(
      _engine.durationStream.listen((dur) {
        state = state.copyWith(duration: dur);
      }),
    );

    _subscriptions.add(
      _engine.bufferedPositionStream.listen((buf) {
        state = state.copyWith(bufferedPosition: buf);
      }),
    );

    _subscriptions.add(
      _engine.volumeStream.listen((vol) {
        state = state.copyWith(volume: vol);
      }),
    );

    _subscriptions.add(
      _engine.speedStream.listen((spd) {
        state = state.copyWith(speed: spd);
      }),
    );

    _subscriptions.add(
      _queue.queueStream.listen((qState) {
        state = state.copyWith(
          currentTrack: qState.currentTrack,
          playbackMode: qState.mode,
          repeatMode: qState.repeatMode,
          isShuffled: qState.isShuffled,
          queueVersion: qState.queueVersion,
          clearCurrentTrack: qState.currentTrack == null,
        );
      }),
    );
  }

  /// Atomically replaces the active queue with [tracks], purging any previous
  /// `playNext` entries, and begins playing [tracks[initialIndex]].
  Future<void> playQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    PlaybackMode? mode,
    NexaRepeatMode? repeatMode,
    QueueContext? queueContext,
  }) async {
    if (tracks.isEmpty) return;
    final clampedIndex = initialIndex.clamp(0, tracks.length - 1);
    _queue.setQueue(
      tracks,
      initialIndex: clampedIndex,
      mode: mode,
      repeatMode: repeatMode,
      queueContext: queueContext,
    );
    final activeTrack = _queue.state.currentTrack ?? tracks[clampedIndex];
    await _loadAndPlay(activeTrack);
  }

  /// Plays [track]. If [queue] is provided, atomically replaces the active queue
  /// with [initialIndex]. If [queue] is omitted and [track] is not already the
  /// active track in queue, atomically replaces the queue with `[track]` so
  /// stale `playNext` entries never desync UI/Next from the active audio.
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? initialIndex,
    QueueContext? queueContext,
  }) async {
    if (queue != null && queue.isNotEmpty) {
      final index = initialIndex ?? queue.indexWhere((t) => t.id == track.id);
      final resolvedIndex = index >= 0 ? index.clamp(0, queue.length - 1) : 0;
      _queue.setQueue(
        queue,
        initialIndex: resolvedIndex,
        queueContext: queueContext,
      );
    } else if (_queue.state.isEmpty || _queue.state.currentTrack?.id != track.id) {
      _queue.setQueue([track], initialIndex: 0, queueContext: queueContext);
    }

    final activeTrack = _queue.state.currentTrack ?? track;
    await _loadAndPlay(activeTrack);
  }

  Future<void> _loadAndPlay(Track track) async {
    final epoch = ++_loadEpoch;
    state = state.copyWith(
      currentTrack: track,
      queueVersion: _queue.state.queueVersion,
      status: PlaybackStatus.loading,
    );

    await _engine.load(track, autoPlay: true);
    if (epoch != _loadEpoch) return;
    state = state.copyWith(
      status: _engine.status,
      queueVersion: _queue.state.queueVersion,
    );
  }

  /// Toggles playback between playing and paused.
  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Resumes playback.
  Future<void> play() async {
    if (state.currentTrack == null && _queue.state.isNotEmpty) {
      final current = _queue.state.currentTrack ?? _queue.state.tracks.first;
      await _loadAndPlay(current);
      return;
    }
    await _engine.play();
    state = state.copyWith(status: _engine.status);
  }

  /// Pauses playback.
  Future<void> pause() async {
    await _engine.pause();
    state = state.copyWith(status: _engine.status);
  }

  /// Stops playback.
  Future<void> stop() async {
    ++_loadEpoch;
    await _engine.stop();
    state = state.copyWith(status: _engine.status);
  }

  /// Seeks to [position].
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  /// Advances to the next track in the queue or transitions to the next
  /// list when a Stellio cross-list repeat mode reaches the queue boundary.
  Future<void> skipNext() async {
    final nextTrack = _queue.next();
    if (nextTrack != null) {
      await _loadAndPlay(nextTrack);
      return;
    }

    final activeRepeat = _queue.state.repeatMode;
    final ctx = _queue.state.queueContext;
    if (activeRepeat.jumpsToNextList && _listNavigator != null && ctx != null) {
      final transition = await _listNavigator.nextList(
        ctx,
        wrapToFirst: activeRepeat == NexaRepeatMode.nextListRepeatFirst,
      );
      if (transition != null && transition.tracks.isNotEmpty) {
        _queue.setQueue(
          transition.tracks,
          initialIndex: transition.initialIndex,
          queueContext: transition.context,
        );
        final next = _queue.state.currentTrack ??
            transition.tracks[transition.initialIndex];
        await _loadAndPlay(next);
        return;
      }
    }

    await stop();
  }

  /// Skips directly to the track at [index] in the active queue and plays it.
  Future<void> skipToIndex(int index) async {
    final targetTrack = _queue.skipToIndex(index);
    if (targetTrack != null) {
      await _loadAndPlay(targetTrack);
    }
  }

  /// Inserts [track] immediately following the currently active track in queue.
  void addNext(Track track) {
    _queue.addNext(track);
  }

  /// Appends [track] to the end of the active queue.
  void addTrack(Track track) {
    _queue.addTrack(track);
  }

  /// Returns to previous track or previous list (in cross-list modes), or
  /// restarts current track if elapsed > 3s.
  Future<void> skipPrevious() async {
    if (state.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }

    final prevTrack = _queue.previous();
    if (prevTrack != null) {
      await _loadAndPlay(prevTrack);
      return;
    }

    final activeRepeat = _queue.state.repeatMode;
    final ctx = _queue.state.queueContext;
    if (activeRepeat.jumpsToNextList && _listNavigator != null && ctx != null) {
      final transition = await _listNavigator.previousList(
        ctx,
        wrapToLast: activeRepeat == NexaRepeatMode.nextListRepeatFirst,
      );
      if (transition != null && transition.tracks.isNotEmpty) {
        _queue.setQueue(
          transition.tracks,
          initialIndex: transition.initialIndex,
          queueContext: transition.context,
        );
        final prev = _queue.state.currentTrack ??
            transition.tracks[transition.initialIndex];
        await _loadAndPlay(prev);
        return;
      }
    }

    await seek(Duration.zero);
  }

  /// Updates queue progression mode (legacy enum support).
  void setPlaybackMode(PlaybackMode mode) {
    _queue.setMode(mode);
    final updated = _queue.state;
    state = state.copyWith(
      playbackMode: updated.mode,
      repeatMode: updated.repeatMode,
      isShuffled: updated.isShuffled,
    );
    unawaited(
      _storageService?.setString(
        StorageKeys.repeatMode,
        updated.repeatMode.storageValue,
      ),
    );
    unawaited(
      _storageService?.setBool(
        StorageKeys.shuffleEnabled,
        updated.isShuffled,
      ),
    );
  }

  /// Toggles shuffle independently without altering the active 5-mode repeat setting.
  void toggleShuffle() {
    final nextShuffle = !state.isShuffled;
    _queue.setShuffle(nextShuffle);
    final updated = _queue.state;
    state = state.copyWith(
      isShuffled: updated.isShuffled,
      repeatMode: updated.repeatMode,
      playbackMode: updated.mode,
    );
    unawaited(
      _storageService?.setBool(
        StorageKeys.shuffleEnabled,
        updated.isShuffled,
      ),
    );
  }

  /// Directly selects a Stellio 5-mode repeat setting and persists it cleanly
  /// without disturbing active shuffle state or re-triggering track playback.
  void setRepeatMode(NexaRepeatMode repeatMode) {
    _queue.setRepeatMode(repeatMode);
    final updated = _queue.state;
    state = state.copyWith(
      repeatMode: updated.repeatMode,
      isShuffled: updated.isShuffled,
      playbackMode: updated.mode,
    );
    unawaited(
      _storageService?.setString(
        StorageKeys.repeatMode,
        repeatMode.storageValue,
      ),
    );
  }

  /// Cycles sequentially through all 5 Stellio repeat modes:
  /// stopOnLastTrack -> repeatList -> repeatSelectedTrack -> nextListStopOnLast -> nextListRepeatFirst.
  void cycleRepeatMode() {
    setRepeatMode(state.repeatMode.nextMode);
  }

  /// Updates playback volume.
  Future<void> setVolume(double volume) async {
    await _engine.setVolume(volume);
  }

  /// Updates playback speed.
  Future<void> setSpeed(double speed) async {
    await _engine.setSpeed(speed);
  }

  /// Toggles favorite status on [track], persisting to repository.
  Future<void> toggleFavorite([Track? targetTrack]) async {
    final track = targetTrack ?? state.currentTrack;
    if (track == null) return;

    final updatedTrack = Track(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      artworkUri: track.artworkUri,
      filePath: track.filePath,
      trackNumber: track.trackNumber,
      discNumber: track.discNumber,
      year: track.year,
      genre: track.genre,
      isFavorite: !track.isFavorite,
      playCount: track.playCount,
      bitrate: track.bitrate,
      fileSize: track.fileSize,
      dateAdded: track.dateAdded,
      dateModified: track.dateModified,
      albumId: track.albumId,
      artistId: track.artistId,
      genreId: track.genreId,
    );

    if (_tracksRepository != null) {
      await _tracksRepository.toggleFavorite(track.id);
    }

    if (state.currentTrack?.id == track.id) {
      state = state.copyWith(currentTrack: updatedTrack);
    }
  }

  /// Activates a sleep timer for [duration] which pauses playback when reached.
  void startSleepTimer(Duration duration) {
    _sleepTimer.start(
      duration,
      fadeOut: true,
      onCompleted: () => pause(),
    );
  }

  /// Cancels active sleep timer.
  void cancelSleepTimer() {
    _sleepTimer.cancel();
  }

  @override
  void dispose() {
    for (final s in _subscriptions) {
      s.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
