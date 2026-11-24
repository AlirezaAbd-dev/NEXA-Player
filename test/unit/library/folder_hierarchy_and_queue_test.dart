import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_folders_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_tracks_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/folders_tab_screen.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

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
  }

  void simulateTrackCompleted() {
    _status = PlaybackStatus.completed;
    if (!_statusController.isClosed) {
      _statusController.add(PlaybackStatus.completed);
    }
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
    if (!_statusController.isClosed) _statusController.add(_status);
  }

  @override
  Future<void> seek(Duration position) async {
    _position = position;
    if (!_positionController.isClosed) _positionController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async => _volume = volume;
  @override
  Future<void> setSpeed(double speed) async => _speed = speed;
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

class _MapTracksRepo implements ITracksRepository {
  _MapTracksRepo(this.tracksById);
  final Map<String, Track> tracksById;

  @override
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id) async {
    return Result.success(tracksById[id]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Task #2 — Hierarchical Folder Tree & Folder-as-Queue Playback', () {
    late AppDatabase db;
    late SqliteTracksRepository tracksRepo;
    late SqliteFoldersRepository foldersRepo;

    setUp(() {
      db = AppDatabase.inMemory();
      tracksRepo = SqliteTracksRepository(db);
      foldersRepo = SqliteFoldersRepository(db);
    });

    tearDown(() {
      db.close();
    });

    test('Root returns folders only; entering /Music returns ONLY direct subfolders + direct songs (excluding /Music/Sub/deep.mp3)', () async {
      final tracks = [
        const Track(
          id: 'trk-root',
          title: 'Root Track',
          artist: 'Artist',
          duration: Duration(minutes: 3),
          filePath: '/storage/emulated/0/Music/root.mp3',
        ),
        const Track(
          id: 'trk-deep',
          title: 'Deep Track',
          artist: 'Artist',
          duration: Duration(minutes: 4),
          filePath: '/storage/emulated/0/Music/Sub/deep.mp3',
        ),
        const Track(
          id: 'trk-other',
          title: 'Podcast Episode',
          artist: 'Host',
          duration: Duration(minutes: 10),
          filePath: '/storage/emulated/0/Podcasts/ep1.mp3',
        ),
      ];
      await tracksRepo.insertTracks(tracks);

      final result = await foldersRepo.getFoldersTree(const []);
      expect(result.isSuccess, isTrue);
      final roots = result.valueOrNull!;

      // Top-level roots should contain 'Music' and 'Podcasts' (no deep 'Sub' leaked to root!)
      expect(roots.map((n) => n.name).toList(), containsAll(['Music', 'Podcasts']));
      expect(roots.any((n) => n.name == 'Sub'), isFalse);

      final musicNode = roots.firstWhere((n) => n.name == 'Music');
      expect(musicNode.directTrackCount, 1);
      expect(musicNode.recursiveTrackCount, 2);
      expect(musicNode.files.map((f) => f.name).toList(), ['root.mp3']);
      expect(musicNode.subFolders.map((s) => s.name).toList(), ['Sub']);

      final subNode = musicNode.subFolders.first;
      expect(subNode.files.map((f) => f.name).toList(), ['deep.mp3']);
    });

    testWidgets('Vertical scroll on FoldersTabScreen does NOT auto-open any folder, whereas tap opens cleanly and plays folder queue', (tester) async {
      final engine = _TestAudioEngine();
      final queue = PlaybackQueueImpl();
      final sleepTimer = SleepTimerServiceImpl();

      // Build 5 tracks inside Folder A plus extra folders to ensure vertical scrolling works
      final folderATracks = List.generate(
        5,
        (i) => Track(
          id: 'fa_$i',
          title: 'Folder A Song ${i + 1}',
          artist: 'Artist A',
          album: 'Folder A',
          duration: const Duration(minutes: 3),
          filePath: '/storage/emulated/0/Music/Alpha/track_${i + 1}.mp3',
        ),
      );
      final trackMap = {for (final t in folderATracks) t.id: t};
      final fakeTracksRepo = _MapTracksRepo(trackMap);

      final notifier = PlayerNotifier(
        engine: engine,
        queue: queue,
        sleepTimer: sleepTimer,
        tracksRepository: fakeTracksRepo,
      );

      final manyFolders = [
        FolderNode(
          path: '/storage/emulated/0/Music/Alpha',
          name: 'Alpha',
          files: folderATracks
              .asMap()
              .entries
              .map((e) => FileNode(
                    path: e.value.filePath!,
                    name: 'track_${e.key + 1}.mp3',
                    trackId: e.value.id,
                  ))
              .toList(),
        ),
        for (var i = 0; i < 15; i++)
          FolderNode(
            path: '/storage/emulated/0/Music/ExtraFolder_$i',
            name: 'ExtraFolder_$i',
            files: [
              FileNode(
                path: '/storage/emulated/0/Music/ExtraFolder_$i/song_$i.mp3',
                name: 'song_$i.mp3',
                trackId: 'extra_$i',
              ),
            ],
          ),
      ];

      addTearDown(() async {
        await engine.dispose();
        queue.dispose();
        sleepTimer.dispose();
      });

      await tester.binding.setSurfaceSize(const Size(360, 780));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foldersTreeProvider(const []).overrideWith((ref) => Future.value(manyFolders)),
            tracksRepositoryProvider.overrideWithValue(fakeTracksRepo),
            playbackQueueProvider.overrideWithValue(queue),
            playerNotifierProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: FoldersTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Root shows folders only (track_1.mp3 is NOT visible yet)
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('track_1.mp3'), findsNothing);

      // Drag/scroll vertically inside list -> MUST NOT open any folder!
      await tester.drag(find.byKey(Phase2Keys.foldersTreeView), const Offset(0, -350));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('folder_contents_list')), findsNothing);
      expect(find.text('track_1.mp3'), findsNothing);

      // Scroll back to top cleanly
      await tester.drag(find.byKey(Phase2Keys.foldersTreeView), const Offset(0, 400));
      await tester.pumpAndSettle();

      // Intentionally tap 'Alpha' -> opens folder contents
      await tester.tap(find.text('Alpha'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('folder_contents_list')), findsOneWidget);
      expect(find.text('track_2.mp3'), findsOneWidget);

      // Tap track #2 in 5-track folder -> loads all 5 tracks at index 1
      await tester.tap(find.text('track_2.mp3'));
      await tester.pumpAndSettle();

      expect(queue.state.tracks.length, 5);
      expect(queue.state.currentIndex, 1);
      expect(notifier.state.currentTrack?.id, 'fa_1');
      expect(engine.loadedTrack?.id, 'fa_1');

      // Completing track #2 automatically advances to track #3 ('fa_2')
      engine.simulateTrackCompleted();
      await tester.pumpAndSettle();

      expect(queue.state.currentIndex, 2);
      expect(notifier.state.currentTrack?.id, 'fa_2');
      expect(engine.loadedTrack?.id, 'fa_2');
    });
  });
}
