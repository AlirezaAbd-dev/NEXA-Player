import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/track.dart';
import '../../../library/domain/repositories/tracks_repository.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/services/audio_engine.dart';
import '../../domain/services/playback_queue.dart';
import '../../domain/services/sleep_timer_service.dart';

/// State notifier managing playback lifecycle, queue interactions,
/// engine synchronization, and track state persistence.
class PlayerNotifier extends StateNotifier<PlaybackState> {
  PlayerNotifier({
    required IAudioEngine engine,
    required IPlaybackQueue queue,
    required ISleepTimerService sleepTimer,
    ITracksRepository? tracksRepository,
  })  : _engine = engine,
        _queue = queue,
        _sleepTimer = sleepTimer,
        _tracksRepository = tracksRepository,
        super(const PlaybackState()) {
    _bindStreams();
  }

  final IAudioEngine _engine;
  final IPlaybackQueue _queue;
  final ISleepTimerService _sleepTimer;
  final ITracksRepository? _tracksRepository;
  final List<StreamSubscription> _subscriptions = [];

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
        );
      }),
    );
  }

  /// Plays [track]. If [queue] is provided, sets active queue with [initialIndex].
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? initialIndex,
  }) async {
    if (queue != null && queue.isNotEmpty) {
      final index = initialIndex ?? queue.indexWhere((t) => t.id == track.id);
      _queue.setQueue(queue, initialIndex: index != -1 ? index : 0);
    } else if (_queue.state.isEmpty) {
      _queue.setQueue([track], initialIndex: 0);
    }

    state = state.copyWith(
      currentTrack: track,
      status: PlaybackStatus.loading,
    );

    await _engine.load(track, autoPlay: true);
    state = state.copyWith(status: _engine.status);
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
      await playTrack(current);
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
    await _engine.stop();
    state = state.copyWith(status: _engine.status);
  }

  /// Seeks to [position].
  Future<void> seek(Duration position) async {
    await _engine.seek(position);
  }

  /// Advances to the next track in the queue.
  Future<void> skipNext() async {
    final nextTrack = _queue.next();
    if (nextTrack != null) {
      await playTrack(nextTrack);
    } else {
      await stop();
    }
  }

  /// Returns to previous track or restarts current track if elapsed > 3s.
  Future<void> skipPrevious() async {
    if (state.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return;
    }

    final prevTrack = _queue.previous();
    if (prevTrack != null) {
      await playTrack(prevTrack);
    } else {
      await seek(Duration.zero);
    }
  }

  /// Updates queue progression mode.
  void setPlaybackMode(PlaybackMode mode) {
    _queue.setMode(mode);
    state = state.copyWith(playbackMode: mode);
  }

  /// Toggles between shuffle and ordered sequence.
  void toggleShuffle() {
    if (state.playbackMode == PlaybackMode.shuffle) {
      setPlaybackMode(PlaybackMode.ordered);
    } else {
      setPlaybackMode(PlaybackMode.shuffle);
    }
  }

  /// Cycles repetition modes: ordered -> repeatAll -> repeatOne -> ordered.
  void cycleRepeatMode() {
    switch (state.playbackMode) {
      case PlaybackMode.ordered:
        setPlaybackMode(PlaybackMode.repeatAll);
        break;
      case PlaybackMode.repeatAll:
        setPlaybackMode(PlaybackMode.repeatOne);
        break;
      case PlaybackMode.repeatOne:
        setPlaybackMode(PlaybackMode.ordered);
        break;
      case PlaybackMode.shuffle:
        setPlaybackMode(PlaybackMode.repeatAll);
        break;
    }
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
