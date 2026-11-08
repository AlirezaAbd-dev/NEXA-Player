import 'dart:async';
import 'package:audio_service/audio_service.dart';
import '../../../../shared/models/track.dart';
import '../../domain/entities/playback_state.dart' as domain;
import '../../domain/services/audio_engine.dart';
import '../../domain/services/playback_queue.dart';

/// Background audio handler integrating NEXA Player with the platform OS media session,
/// lock screen controls, headset events, and notification tray.
class NexaAudioHandler extends BaseAudioHandler with SeekHandler {
  NexaAudioHandler({
    required IAudioEngine engine,
    required IPlaybackQueue queue,
  })  : _engine = engine,
        _queue = queue {
    _bindStreams();
  }

  final IAudioEngine _engine;
  final IPlaybackQueue _queue;
  final List<StreamSubscription> _subscriptions = [];

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

  MediaItem _toMediaItem(Track track) {
    return MediaItem(
      id: track.id,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      artUri: track.artworkUri != null ? Uri.tryParse(track.artworkUri!) : null,
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
    // If playing for more than 3 seconds, restart current track first
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

  /// Cleans up subscriptions and resources.
  Future<void> dispose() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }
}
