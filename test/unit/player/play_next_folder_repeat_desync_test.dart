import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/widgets/hero_artwork_card.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/database_failure.dart';

class _TestAudioEngine implements IAudioEngine {
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

  Track? loadedTrack;

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

  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
    loadedTrack = track;
    _duration = track.duration;
    _status = autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused;
    if (!_statusController.isClosed) _statusController.add(_status);
    if (!_durationController.isClosed) _durationController.add(_duration);
  }

  @override
  Future<void> play() async {
    _status = PlaybackStatus.playing;
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  @override
  Future<void> pause() async {
    _status = PlaybackStatus.paused;
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  @override
  Future<void> stop() async {
    _status = PlaybackStatus.idle;
    _position = Duration.zero;
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    if (!_positionController.isClosed) _positionController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed;
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

class _TestTracksRepo implements ITracksRepository {
  @override
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId) async =>
      const Result.success(null);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _TestAudioEngine engine;
  late PlaybackQueueImpl queue;
  late SleepTimerServiceImpl sleepTimer;
  late _TestTracksRepo tracksRepo;
  late PlayerNotifier notifier;

  const songA = Track(
    id: 'song-a',
    title: 'Song A',
    artist: 'Artist A',
    album: 'All Songs',
    duration: Duration(minutes: 3),
    filePath: '/Music/SongA.mp3',
  );
  const songB = Track(
    id: 'song-b',
    title: 'Song B (Play Next)',
    artist: 'Artist B',
    album: 'All Songs',
    duration: Duration(minutes: 4),
    filePath: '/Music/SongB.mp3',
  );
  const folderSongC = Track(
    id: 'folder-c',
    title: 'Folder Song C',
    artist: 'Artist C',
    album: 'Folder X',
    duration: Duration(minutes: 3, seconds: 30),
    filePath: '/Music/FolderX/SongC.mp3',
  );
  const folderSongD = Track(
    id: 'folder-d',
    title: 'Folder Song D',
    artist: 'Artist D',
    album: 'Folder X',
    duration: Duration(minutes: 2, seconds: 45),
    filePath: '/Music/FolderX/SongD.mp3',
  );

  setUp(() {
    engine = _TestAudioEngine();
    queue = PlaybackQueueImpl();
    sleepTimer = SleepTimerServiceImpl();
    tracksRepo = _TestTracksRepo();
    notifier = PlayerNotifier(
      engine: engine,
      queue: queue,
      sleepTimer: sleepTimer,
      tracksRepository: tracksRepo,
    );
  });

  tearDown(() async {
    notifier.dispose();
    await engine.dispose();
    queue.dispose();
    sleepTimer.dispose();
  });

  group('Stale Play Next Queue Corruption & Repeat Audio/UI Desync Tests', () {
    test('Exact user repro: Play Next -> advance -> switch to Folder -> cycleRepeatMode never reverts to stale Song B', () async {
      // 1. Play Song A from All Songs -> swipe-add Song B as Play Next -> advance to Song B
      await notifier.playQueue([songA], initialIndex: 0);
      expect(notifier.state.currentTrack?.id, 'song-a');

      notifier.addNext(songB);
      expect(queue.state.tracks.map((t) => t.id).toList(), ['song-a', 'song-b']);

      await notifier.skipNext();
      expect(notifier.state.currentTrack?.id, 'song-b');
      expect(engine.loadedTrack?.id, 'song-b');

      final versionBeforeFolder = queue.state.queueVersion;

      // 2. Switch to Folder X and tap Folder Song C
      await notifier.playQueue([folderSongC, folderSongD], initialIndex: 0);

      // 3. Assert queue contains ONLY Folder X tracks (Song B is completely gone) and currentTrack == Folder Song C
      expect(queue.state.queueVersion, greaterThan(versionBeforeFolder));
      expect(queue.state.tracks.map((t) => t.id).toList(), ['folder-c', 'folder-d']);
      expect(queue.state.originalTracks.map((t) => t.id).toList(), ['folder-c', 'folder-d']);
      expect(queue.state.currentTrack?.id, 'folder-c');
      expect(notifier.state.currentTrack?.id, 'folder-c');
      expect(engine.loadedTrack?.id, 'folder-c');

      // 4. Tap cycleRepeatMode() 5 times -> assert currentTrack and loadedTrack never flicker to Song B
      for (var i = 0; i < 5; i++) {
        notifier.cycleRepeatMode();
        expect(notifier.state.currentTrack?.id, 'folder-c');
        expect(queue.state.currentTrack?.id, 'folder-c');
        expect(engine.loadedTrack?.id, 'folder-c');
      }

      // Reset repeat mode out of repeatOne so skipNext advances along Folder X
      while (notifier.state.playbackMode != PlaybackMode.ordered) {
        notifier.cycleRepeatMode();
      }

      // 5. Tap skipNext() -> advances strictly to Folder Song D (index 1 of Folder X), NEVER Song B
      await notifier.skipNext();
      expect(notifier.state.currentTrack?.id, 'folder-d');
      expect(engine.loadedTrack?.id, 'folder-d');
    });

    test('Calling playTrack without queue atomically replaces stale queue instead of creating audio/UI split brain', () async {
      await notifier.playQueue([songA], initialIndex: 0);
      notifier.addNext(songB);
      await notifier.skipNext();
      expect(notifier.state.currentTrack?.id, 'song-b');

      // Call playTrack without queue argument (like legacy callers)
      await notifier.playTrack(folderSongC);

      expect(queue.state.tracks.map((t) => t.id).toList(), ['folder-c']);
      expect(queue.state.currentTrack?.id, 'folder-c');
      expect(notifier.state.currentTrack?.id, 'folder-c');
      expect(engine.loadedTrack?.id, 'folder-c');

      notifier.cycleRepeatMode();
      expect(notifier.state.currentTrack?.id, 'folder-c');
      expect(engine.loadedTrack?.id, 'folder-c');
    });

    testWidgets('HeroArtworkCard resets PageController cleanly when queueVersion increments', (tester) async {
      int settledCalls = 0;

      Widget buildCard({
        required List<Track> tracks,
        required int currentIndex,
        required int queueVersion,
      }) {
        return MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: tracks[currentIndex],
                tracks: tracks,
                currentIndex: currentIndex,
                queueVersion: queueVersion,
                onPageSettled: (_) => settledCalls++,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(
        buildCard(tracks: const [songA, songB], currentIndex: 1, queueVersion: 1),
      );
      await tester.pumpAndSettle();
      expect(find.byType(HeroArtworkCard), findsOneWidget);

      // Replace queue cleanly at index 0 with incremented queueVersion
      await tester.pumpWidget(
        buildCard(tracks: const [folderSongC, folderSongD], currentIndex: 0, queueVersion: 2),
      );
      await tester.pumpAndSettle();

      expect(settledCalls, 0);
    });
  });
}
