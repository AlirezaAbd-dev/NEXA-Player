import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/albums_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/queue_list_navigator.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

class _FakeAudioEngine implements IAudioEngine {
  final _statusController = StreamController<PlaybackStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _position = Duration.zero;
  Track? loadedTrack;
  final List<String> loadHistory = [];
  int seekCalls = 0;

  @override
  PlaybackStatus get status => _status;
  @override
  Duration get position => _position;
  @override
  Duration get duration => loadedTrack?.duration ?? Duration.zero;
  @override
  double get volume => 1.0;
  @override
  double get speed => 1.0;

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

  void emitCompleted() {
    _status = PlaybackStatus.completed;
    _statusController.add(_status);
  }

  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
    loadedTrack = track;
    loadHistory.add(track.id);
    _position = Duration.zero;
    _status = autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> play() async {
    _status = PlaybackStatus.playing;
    _statusController.add(_status);
  }

  @override
  Future<void> pause() async {
    _status = PlaybackStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> stop() async {
    _status = PlaybackStatus.idle;
    _statusController.add(_status);
  }

  @override
  Future<void> seek(Duration position) async {
    seekCalls++;
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async => _volumeController.add(volume);

  @override
  Future<void> setSpeed(double speed) async => _speedController.add(speed);

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

class _FakeSleepTimer implements ISleepTimerService {
  final _remainingController = StreamController<Duration?>.broadcast();

  @override
  bool get isActive => false;
  @override
  Duration? get remainingTime => null;
  @override
  Stream<Duration?> get remainingStream => _remainingController.stream;
  @override
  void start(
    Duration duration, {
    bool fadeOut = true,
    void Function()? onCompleted,
  }) {}
  @override
  void cancel() {}
  @override
  void dispose() {
    _remainingController.close();
  }
}

class _InMemoryStorageService implements IStorageService {
  final Map<String, String> _strings = {};
  final Map<String, bool> _bools = {};

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _strings[key] = value;
    return const Success(null);
  }

  @override
  Result<String?, StorageFailure> getString(String key) =>
      Success(_strings[key]);

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    _bools[key] = value;
    return const Success(null);
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) => Success(_bools[key]);

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    _strings.remove(key);
    _bools.remove(key);
    return const Success(null);
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _strings.clear();
    _bools.clear();
    return const Success(null);
  }
}

class _FakeFoldersRepo implements IFoldersRepository {
  _FakeFoldersRepo(this.tree);
  List<FolderNode> tree;

  @override
  Future<Result<List<FolderNode>, DatabaseFailure>> getFoldersTree(
    List<String> rootPaths,
  ) async =>
      Success(tree);
}

class _FakeAlbumsRepo implements IAlbumsRepository {
  _FakeAlbumsRepo(this.albums, this.tracksByAlbum);
  List<Album> albums;
  Map<String, List<Track>> tracksByAlbum;

  @override
  Future<Result<List<Album>, DatabaseFailure>> getAllAlbums({
    AlbumSortBy sortBy = AlbumSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async =>
      Success(albums);

  @override
  Future<Result<Album?, DatabaseFailure>> getAlbumById(String id) async =>
      Success(
        albums.cast<Album?>().firstWhere(
              (a) => a?.id == id,
              orElse: () => null,
            ),
      );

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForAlbum(
    String albumId,
  ) async =>
      Success(tracksByAlbum[albumId] ?? const []);
}

class _FakeTracksRepo implements ITracksRepository {
  _FakeTracksRepo(List<Track> all) : _byId = {for (final t in all) t.id: t};
  final Map<String, Track> _byId;

  @override
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async =>
      Success(_byId.values.toList());

  @override
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id) async =>
      Success(_byId[id]);

  @override
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId) async =>
      const Success(null);

  @override
  Future<Result<void, DatabaseFailure>> incrementPlayCount(String trackId) async =>
      const Success(null);

  @override
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId) async =>
      const Success(null);

  @override
  Future<Result<void, DatabaseFailure>> insertTrack(Track track) async =>
      const Success(null);

  @override
  Future<Result<void, DatabaseFailure>> insertTracks(List<Track> tracks) async =>
      const Success(null);
}

Track _trk(String id, String title, {String album = 'Album'}) => Track(
      id: id,
      title: title,
      artist: 'Artist',
      album: album,
      duration: const Duration(minutes: 3),
      filePath: '/storage/emulated/0/Music/$id.mp3',
    );

void main() {
  group('Stellio 5-Mode Repeat & Cross-List Engine', () {
    late _FakeAudioEngine engine;
    late PlaybackQueueImpl queue;
    late _FakeSleepTimer sleepTimer;
    late _InMemoryStorageService storage;

    final f1Tracks = [_trk('f1-1', 'Folder1 One'), _trk('f1-2', 'Folder1 Two')];
    final f2Tracks = [_trk('f2-1', 'Folder2 One'), _trk('f2-2', 'Folder2 Two')];

    final alb1Tracks = [
      _trk('a1-1', 'Alb1 One', album: 'Album 1'),
      _trk('a1-2', 'Alb1 Two', album: 'Album 1'),
    ];
    final alb2Tracks = [_trk('a2-1', 'Alb2 One', album: 'Album 2')];

    late _FakeTracksRepo tracksRepo;
    late _FakeFoldersRepo foldersRepo;
    late _FakeAlbumsRepo albumsRepo;
    late LibraryQueueListNavigator navigator;
    late PlayerNotifier notifier;

    setUp(() {
      engine = _FakeAudioEngine();
      queue = PlaybackQueueImpl(random: Random(7));
      sleepTimer = _FakeSleepTimer();
      storage = _InMemoryStorageService();
      tracksRepo = _FakeTracksRepo([
        ...f1Tracks,
        ...f2Tracks,
        ...alb1Tracks,
        ...alb2Tracks,
      ]);

      // Tree includes an empty subfolder between Folder1 and Folder2 to verify skipping empty lists
      foldersRepo = _FakeFoldersRepo([
        FolderNode(
          name: 'Music',
          path: '/music',
          files: const [],
          subFolders: [
            FolderNode(
              name: 'Folder1',
              path: '/music/Folder1',
              files: f1Tracks
                  .map((t) => FileNode(name: '${t.title}.mp3', path: t.filePath!, trackId: t.id))
                  .toList(),
            ),
            const FolderNode(
              name: 'EmptyFolder',
              path: '/music/EmptyFolder',
              files: [],
            ),
            FolderNode(
              name: 'Folder2',
              path: '/music/Folder2',
              files: f2Tracks
                  .map((t) => FileNode(name: '${t.title}.mp3', path: t.filePath!, trackId: t.id))
                  .toList(),
            ),
          ],
        ),
      ]);

      albumsRepo = _FakeAlbumsRepo(
        const [
          Album(id: 'alb-1', title: 'Album 1', artist: 'Artist', trackCount: 2),
          Album(id: 'alb-empty', title: 'Empty Album', artist: 'Artist', trackCount: 0),
          Album(id: 'alb-2', title: 'Album 2', artist: 'Artist', trackCount: 1),
        ],
        {
          'alb-1': alb1Tracks,
          'alb-empty': const [],
          'alb-2': alb2Tracks,
        },
      );

      navigator = LibraryQueueListNavigator(
        foldersRepository: foldersRepo,
        tracksRepository: tracksRepo,
        albumsRepository: albumsRepo,
      );

      notifier = PlayerNotifier(
        engine: engine,
        queue: queue,
        sleepTimer: sleepTimer,
        tracksRepository: tracksRepo,
        listNavigator: navigator,
        storageService: storage,
      );
    });

    tearDown(() async {
      notifier.dispose();
      queue.dispose();
      sleepTimer.dispose();
      await engine.dispose();
    });

    test('Mode 1 (stopOnLastTrack): stops cleanly at end of Folder 1 without jumping lists', () async {
      notifier.setRepeatMode(NexaRepeatMode.stopOnLastTrack);
      await notifier.playQueue(
        f1Tracks,
        initialIndex: 1,
        queueContext: const QueueContext.folder('/music/Folder1', title: 'Folder1'),
      );
      expect(notifier.state.currentTrack?.id, 'f1-2');

      engine.emitCompleted();
      await Future<void>.delayed(Duration.zero);

      expect(notifier.state.status, PlaybackStatus.idle);
      expect(notifier.state.currentTrack?.id, 'f1-2');
      expect(queue.state.queueContext?.collectionId, '/music/Folder1');
    });

    test('Mode 2 (repeatList): loops Folder 1 indefinitely forward and backward', () async {
      notifier.setRepeatMode(NexaRepeatMode.repeatList);
      await notifier.playQueue(
        f1Tracks,
        initialIndex: 1,
        queueContext: const QueueContext.folder('/music/Folder1', title: 'Folder1'),
      );

      await notifier.skipNext();
      expect(notifier.state.currentTrack?.id, 'f1-1');

      await notifier.skipPrevious();
      expect(notifier.state.currentTrack?.id, 'f1-2');
      expect(queue.state.queueContext?.collectionId, '/music/Folder1');
    });

    test('Mode 3 (repeatSelectedTrack): repeats active track continuously on completion and manual skip', () async {
      notifier.setRepeatMode(NexaRepeatMode.repeatSelectedTrack);
      await notifier.playQueue(
        f1Tracks,
        initialIndex: 0,
        queueContext: const QueueContext.folder('/music/Folder1', title: 'Folder1'),
      );

      engine.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(notifier.state.currentTrack?.id, 'f1-1');

      await notifier.skipNext();
      expect(notifier.state.currentTrack?.id, 'f1-1');
    });

    test('Mode 4 (nextListStopOnLast): jumps Folder1 -> skips EmptyFolder -> Folder2, then stops on last track', () async {
      notifier.setRepeatMode(NexaRepeatMode.nextListStopOnLast);
      await notifier.playQueue(
        f1Tracks,
        initialIndex: 1,
        queueContext: const QueueContext.folder('/music/Folder1', title: 'Folder1'),
      );

      // End of Folder 1 -> jumps to index 0 of Folder 2
      engine.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.currentTrack?.id, 'f2-1');
      expect(queue.state.queueContext?.collectionId, '/music/Folder2');

      // Manual Previous at track 0 of Folder 2 -> jumps back to last track of Folder 1
      await notifier.skipPrevious();
      expect(notifier.state.currentTrack?.id, 'f1-2');
      expect(queue.state.queueContext?.collectionId, '/music/Folder1');

      // Manual Previous at track 0 of Folder 1 does NOT wrap to last folder; seeks to 0
      await notifier.skipPrevious();
      expect(notifier.state.currentTrack?.id, 'f1-1');
      await notifier.skipPrevious();
      expect(notifier.state.currentTrack?.id, 'f1-1');
      expect(queue.state.queueContext?.collectionId, '/music/Folder1');

      // Advance forward to Folder 2 last track -> natural end MUST stop playback
      await notifier.skipNext(); // f1-2
      await notifier.skipNext(); // jumps to f2-1
      await notifier.skipNext(); // f2-2
      expect(notifier.state.currentTrack?.id, 'f2-2');

      engine.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.status, PlaybackStatus.idle);
    });

    test('Mode 5 (nextListRepeatFirst): jumps Album1 -> skips EmptyAlbum -> Album2 -> wraps back to Album1', () async {
      notifier.setRepeatMode(NexaRepeatMode.nextListRepeatFirst);
      await notifier.playQueue(
        alb1Tracks,
        initialIndex: 1,
        queueContext: const QueueContext.album('alb-1', title: 'Album 1'),
      );

      // End of Album 1 -> Album 2 track 0
      await notifier.skipNext();
      expect(notifier.state.currentTrack?.id, 'a2-1');
      expect(queue.state.queueContext?.collectionId, 'alb-2');

      // End of Album 2 -> wraps to Album 1 track 0
      engine.emitCompleted();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(notifier.state.currentTrack?.id, 'a1-1');
      expect(queue.state.queueContext?.collectionId, 'alb-1');

      // Previous on Album 1 track 0 wraps backward to last track of Album 2
      await notifier.skipPrevious();
      expect(notifier.state.currentTrack?.id, 'a2-1');
      expect(queue.state.queueContext?.collectionId, 'alb-2');
    });

    test('Single-list edge case behaves predictably for nextListStopOnLast vs nextListRepeatFirst', () async {
      final singleFolderRepo = _FakeFoldersRepo([
        FolderNode(
          name: 'OnlyFolder',
          path: '/music/OnlyFolder',
          files: f1Tracks
              .map((t) => FileNode(name: '${t.title}.mp3', path: t.filePath!, trackId: t.id))
              .toList(),
        ),
      ]);
      final singleNav = LibraryQueueListNavigator(
        foldersRepository: singleFolderRepo,
        tracksRepository: tracksRepo,
      );
      final singleNotifier = PlayerNotifier(
        engine: engine,
        queue: queue,
        sleepTimer: sleepTimer,
        tracksRepository: tracksRepo,
        listNavigator: singleNav,
        storageService: storage,
      );
      addTearDown(singleNotifier.dispose);

      // nextListStopOnLast stops on last track of single list
      singleNotifier.setRepeatMode(NexaRepeatMode.nextListStopOnLast);
      await singleNotifier.playQueue(
        f1Tracks,
        initialIndex: 1,
        queueContext: const QueueContext.folder('/music/OnlyFolder', title: 'OnlyFolder'),
      );
      await singleNotifier.skipNext();
      expect(singleNotifier.state.status, PlaybackStatus.idle);

      // nextListRepeatFirst wraps to index 0 of that single list
      singleNotifier.setRepeatMode(NexaRepeatMode.nextListRepeatFirst);
      await singleNotifier.playQueue(
        f1Tracks,
        initialIndex: 1,
        queueContext: const QueueContext.folder('/music/OnlyFolder', title: 'OnlyFolder'),
      );
      await singleNotifier.skipNext();
      expect(singleNotifier.state.currentTrack?.id, 'f1-1');
      expect(singleNotifier.state.status, PlaybackStatus.playing);
    });

    test('Decouples isShuffled from NexaRepeatMode across cycling & toggles', () async {
      await notifier.playQueue(f1Tracks, initialIndex: 0);
      notifier.toggleShuffle();
      expect(notifier.state.isShuffled, isTrue);
      final shuffledIdsBefore = List<String>.from(queue.state.tracks.map((t) => t.id));

      for (final expected in [
        NexaRepeatMode.repeatList,
        NexaRepeatMode.repeatSelectedTrack,
        NexaRepeatMode.nextListStopOnLast,
        NexaRepeatMode.nextListRepeatFirst,
        NexaRepeatMode.stopOnLastTrack,
      ]) {
        notifier.cycleRepeatMode();
        expect(notifier.state.repeatMode, expected);
        expect(notifier.state.isShuffled, isTrue);
        expect(queue.state.tracks.map((t) => t.id).toList(), shuffledIdsBefore);
      }

      notifier.setRepeatMode(NexaRepeatMode.nextListRepeatFirst);
      notifier.toggleShuffle();
      expect(notifier.state.isShuffled, isFalse);
      expect(notifier.state.repeatMode, NexaRepeatMode.nextListRepeatFirst);
    });

    test('Persists selected NexaRepeatMode via IStorageService across PlayerNotifier restarts', () {
      notifier.setRepeatMode(NexaRepeatMode.nextListRepeatFirst);
      expect(
        storage.getString(StorageKeys.repeatMode).valueOrNull,
        NexaRepeatMode.nextListRepeatFirst.storageValue,
      );

      final freshQueue = PlaybackQueueImpl();
      addTearDown(freshQueue.dispose);
      final restoredNotifier = PlayerNotifier(
        engine: engine,
        queue: freshQueue,
        sleepTimer: sleepTimer,
        tracksRepository: tracksRepo,
        listNavigator: navigator,
        storageService: storage,
      );
      addTearDown(restoredNotifier.dispose);

      expect(restoredNotifier.state.repeatMode, NexaRepeatMode.nextListRepeatFirst);
      expect(freshQueue.state.repeatMode, NexaRepeatMode.nextListRepeatFirst);
    });
  });
}
