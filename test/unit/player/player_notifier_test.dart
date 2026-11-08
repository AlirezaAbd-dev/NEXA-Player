import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/database_failure.dart';

class MockAudioEngine implements IAudioEngine {
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration> get durationStream => _durationController.stream;
  @override
  Stream<Duration> get bufferedPositionStream => _bufferedController.stream;
  @override
  Stream<double> get volumeStream => _volumeController.stream;
  @override
  Stream<double> get speedStream => _speedController.stream;

  @override
  PlaybackStatus get status => _status;
  @override
  Duration get position => _position;
  @override
  Duration get duration => _duration;
  @override
  double get volume => _volume;
  @override
  double get speed => _speed;

  Track? loadedTrack;
  bool playCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  Duration? seekPosition;

  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
    loadedTrack = track;
    _duration = track.duration;
    _status = PlaybackStatus.loading;
    if (!_statusController.isClosed) _statusController.add(PlaybackStatus.loading);
    if (!_durationController.isClosed) _durationController.add(_duration);

    if (autoPlay) {
      await play();
    } else {
      _status = PlaybackStatus.paused;
      if (!_statusController.isClosed) _statusController.add(PlaybackStatus.paused);
    }
  }

  @override
  Future<void> play() async {
    playCalled = true;
    _status = PlaybackStatus.playing;
    if (!_statusController.isClosed) _statusController.add(PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    _status = PlaybackStatus.paused;
    if (!_statusController.isClosed) _statusController.add(PlaybackStatus.paused);
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    _status = PlaybackStatus.idle;
    _position = Duration.zero;
    if (!_statusController.isClosed) _statusController.add(PlaybackStatus.idle);
    if (!_positionController.isClosed) _positionController.add(Duration.zero);
  }

  @override
  Future<void> seek(Duration position) async {
    seekPosition = position;
    _position = position;
    if (!_positionController.isClosed) _positionController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    if (!_volumeController.isClosed) _volumeController.add(volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
    if (!_speedController.isClosed) _speedController.add(speed);
  }

  @override
  Future<void> setLoopMode(bool loop) async {}

  @override
  Future<void> dispose() async {
    await _statusController.close();
    await _positionController.close();
    await _durationController.close();
    await _bufferedController.close();
    await _volumeController.close();
    await _speedController.close();
  }
}

class FakeTracksRepository implements ITracksRepository {
  final Map<String, bool> favorites = {};

  @override
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId) async {
    favorites[trackId] = !(favorites[trackId] ?? false);
    return const Result.success(null);
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async =>
      const Result.success([]);

  @override
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id) async =>
      const Result.success(null);

  @override
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId) async =>
      const Result.success(null);

  @override
  Future<Result<void, DatabaseFailure>> incrementPlayCount(String trackId) async =>
      const Result.success(null);

  @override
  Future<Result<void, DatabaseFailure>> insertTrack(Track track) async =>
      const Result.success(null);

  @override
  Future<Result<void, DatabaseFailure>> insertTracks(List<Track> tracks) async =>
      const Result.success(null);
}

void main() {
  group('PlayerNotifier Tests', () {
    late MockAudioEngine engine;
    late PlaybackQueueImpl queue;
    late SleepTimerServiceImpl sleepTimer;
    late FakeTracksRepository tracksRepo;
    late PlayerNotifier notifier;

    const sampleTrack1 = Track(
      id: 'trk-1',
      title: 'Starboy',
      artist: 'The Weeknd',
      album: 'Starboy',
      duration: Duration(seconds: 230),
    );

    const sampleTrack2 = Track(
      id: 'trk-2',
      title: 'Get Lucky',
      artist: 'Daft Punk',
      album: 'Random Access Memories',
      duration: Duration(seconds: 248),
    );

    setUp(() {
      engine = MockAudioEngine();
      queue = PlaybackQueueImpl();
      sleepTimer = SleepTimerServiceImpl();
      tracksRepo = FakeTracksRepository();

      notifier = PlayerNotifier(
        engine: engine,
        queue: queue,
        sleepTimer: sleepTimer,
        tracksRepository: tracksRepo,
      );
    });

    tearDown(() {
      notifier.dispose();
      engine.dispose();
      queue.dispose();
      sleepTimer.dispose();
    });

    test('initial state has empty track and idle status', () {
      expect(notifier.state.currentTrack, isNull);
      expect(notifier.state.status, PlaybackStatus.idle);
      expect(notifier.state.isPlaying, isFalse);
    });

    test('playTrack loads track, sets queue and updates active state', () async {
      await notifier.playTrack(sampleTrack1, queue: [sampleTrack1, sampleTrack2]);

      expect(notifier.state.currentTrack?.id, 'trk-1');
      expect(engine.loadedTrack?.id, 'trk-1');
      expect(engine.playCalled, isTrue);
      expect(notifier.state.isPlaying, isTrue);
      expect(queue.state.tracks.length, 2);
    });

    test('togglePlayPause alternates between play and pause', () async {
      await notifier.playTrack(sampleTrack1);
      expect(notifier.state.isPlaying, isTrue);

      await notifier.togglePlayPause();
      expect(engine.pauseCalled, isTrue);
      expect(notifier.state.isPaused, isTrue);

      await notifier.togglePlayPause();
      expect(notifier.state.isPlaying, isTrue);
    });

    test('seek updates engine position', () async {
      await notifier.playTrack(sampleTrack1);
      await notifier.seek(const Duration(seconds: 60));

      expect(engine.seekPosition, const Duration(seconds: 60));
      expect(notifier.state.position, const Duration(seconds: 60));
    });

    test('skipNext advances to upcoming track in queue', () async {
      await notifier.playTrack(sampleTrack1, queue: [sampleTrack1, sampleTrack2]);
      await notifier.skipNext();

      expect(notifier.state.currentTrack?.id, 'trk-2');
      expect(engine.loadedTrack?.id, 'trk-2');
    });

    test('toggleShuffle and cycleRepeatMode alter playback modes', () {
      expect(notifier.state.playbackMode, PlaybackMode.ordered);

      notifier.toggleShuffle();
      expect(notifier.state.playbackMode, PlaybackMode.shuffle);

      notifier.toggleShuffle();
      expect(notifier.state.playbackMode, PlaybackMode.ordered);

      notifier.cycleRepeatMode();
      expect(notifier.state.playbackMode, PlaybackMode.repeatAll);

      notifier.cycleRepeatMode();
      expect(notifier.state.playbackMode, PlaybackMode.repeatOne);

      notifier.cycleRepeatMode();
      expect(notifier.state.playbackMode, PlaybackMode.ordered);
    });

    test('toggleFavorite toggles track favorite and invokes repository', () async {
      await notifier.playTrack(sampleTrack1);
      expect(notifier.state.currentTrack?.isFavorite, isFalse);

      await notifier.toggleFavorite();
      expect(notifier.state.currentTrack?.isFavorite, isTrue);
      expect(tracksRepo.favorites['trk-1'], isTrue);

      await notifier.toggleFavorite();
      expect(notifier.state.currentTrack?.isFavorite, isFalse);
      expect(tracksRepo.favorites['trk-1'], isFalse);
    });

    test('startSleepTimer configures countdown and pauses on completion', () async {
      await notifier.playTrack(sampleTrack1);
      expect(notifier.state.isPlaying, isTrue);

      // Start zero-duration timer which fires completion immediately
      notifier.startSleepTimer(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.isPaused, isTrue);
    });
  });
}
