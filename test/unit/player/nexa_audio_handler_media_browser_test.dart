import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/player/data/services/nexa_audio_handler.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart' as domain;
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/search/domain/models/search_result.dart';
import 'package:nexa_player/features/search/domain/models/search_result_category.dart';
import 'package:nexa_player/features/search/domain/repositories/search_repository.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/database_failure.dart';

class FakeAudioEngine implements IAudioEngine {
  final _statusController = StreamController<domain.PlaybackStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();

  domain.PlaybackStatus _status = domain.PlaybackStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  Track? loadedTrack;
  bool playCalled = false;
  bool pauseCalled = false;
  bool stopCalled = false;
  Duration? seekPosition;

  @override
  Stream<domain.PlaybackStatus> get statusStream => _statusController.stream;
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
  domain.PlaybackStatus get status => _status;
  @override
  Duration get position => _position;
  @override
  Duration get duration => _duration;
  @override
  double get volume => 1.0;
  @override
  double get speed => 1.0;

  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
    loadedTrack = track;
    _duration = track.duration;
    if (autoPlay) {
      await play();
    }
  }

  @override
  Future<void> play() async {
    playCalled = true;
    _status = domain.PlaybackStatus.playing;
    _statusController.add(_status);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    _status = domain.PlaybackStatus.paused;
    _statusController.add(_status);
  }

  @override
  Future<void> stop() async {
    stopCalled = true;
    _status = domain.PlaybackStatus.idle;
    _statusController.add(_status);
  }

  @override
  Future<void> seek(Duration position) async {
    seekPosition = position;
    _position = position;
    _positionController.add(position);
  }

  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
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
  List<Track> tracks = [];
  final List<String> favoriteToggles = [];

  @override
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async {
    return Result.success(tracks);
  }

  @override
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id) async {
    final match = tracks.where((t) => t.id == id).firstOrNull;
    return Result.success(match);
  }

  @override
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId) async {
    favoriteToggles.add(trackId);
    return const Result.success(null);
  }

  @override
  Future<Result<void, DatabaseFailure>> incrementPlayCount(String trackId) async =>
      const Result.success(null);
  @override
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId) async =>
      const Result.success(null);
  @override
  Future<Result<void, DatabaseFailure>> insertTrack(Track track) async =>
      const Result.success(null);
  @override
  Future<Result<void, DatabaseFailure>> insertTracks(List<Track> tracks) async =>
      const Result.success(null);
}

class FakePlaylistsRepository implements IPlaylistsRepository {
  List<Playlist> playlists = [];
  Map<String, List<Track>> playlistTracks = {};

  @override
  Future<Result<List<Playlist>, DatabaseFailure>> getAllPlaylists() async {
    return Result.success(playlists);
  }

  @override
  Future<Result<Playlist?, DatabaseFailure>> getPlaylistById(String id) async {
    return Result.success(playlists.where((p) => p.id == id).firstOrNull);
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForPlaylist(
      String playlistId) async {
    return Result.success(playlistTracks[playlistId] ?? []);
  }

  @override
  Future<Result<Playlist, DatabaseFailure>> createPlaylist(String name,
      {String? description}) async {
    final now = DateTime.now();
    final p = Playlist(
      id: 'p_${playlists.length + 1}',
      name: name,
      trackCount: 0,
      createdAt: now,
      updatedAt: now,
    );
    playlists.add(p);
    return Result.success(p);
  }

  @override
  Future<Result<void, DatabaseFailure>> deletePlaylist(String playlistId) async =>
      const Result.success(null);
  @override
  Future<Result<void, DatabaseFailure>> addTrackToPlaylist(
          String playlistId, String trackId) async =>
      const Result.success(null);
  @override
  Future<Result<void, DatabaseFailure>> removeTrackFromPlaylist(
          String playlistId, String trackId) async =>
      const Result.success(null);
  @override
  Future<Result<void, DatabaseFailure>> reorderPlaylistTracks(
          String playlistId, int oldIndex, int newIndex) async =>
      const Result.success(null);
}

class FakeSearchRepository implements ISearchRepository {
  List<Track> searchTracks = [];

  @override
  Future<Result<SearchResult, DatabaseFailure>> search({
    required String query,
    SearchResultCategory category = SearchResultCategory.all,
    int limitPerCategory = 25,
  }) async {
    final matches = searchTracks
        .where((t) =>
            t.title.toLowerCase().contains(query.toLowerCase()) ||
            t.artist.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Result.success(SearchResult(
      query: query,
      tracks: matches,
    ));
  }

  @override
  Future<List<String>> getRecentSearches() async => const [];
  @override
  Future<void> saveRecentSearch(String query) async {}
  @override
  Future<void> removeRecentSearch(String query) async {}
  @override
  Future<void> clearRecentSearches() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NexaAudioHandler Android Auto MediaBrowser Tests', () {
    late FakeAudioEngine engine;
    late PlaybackQueueImpl queue;
    late FakeTracksRepository tracksRepo;
    late FakePlaylistsRepository playlistsRepo;
    late FakeSearchRepository searchRepo;
    late NexaAudioHandler handler;

    const t1 = Track(
      id: 'track-1',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      isFavorite: true,
    );
    const t2 = Track(
      id: 'track-2',
      title: 'Starboy',
      artist: 'The Weeknd',
      album: 'Starboy',
      duration: Duration(minutes: 3, seconds: 50),
      isFavorite: false,
    );
    const t3 = Track(
      id: 'track-3',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      duration: Duration(minutes: 3, seconds: 20),
      isFavorite: true,
    );

    setUp(() {
      engine = FakeAudioEngine();
      queue = PlaybackQueueImpl();
      tracksRepo = FakeTracksRepository()..tracks = [t1, t2, t3];
      final now = DateTime.now();
      playlistsRepo = FakePlaylistsRepository()
        ..playlists = [
          Playlist(
            id: 'road_trip',
            name: 'Road Trip Essentials',
            trackCount: 2,
            createdAt: now,
            updatedAt: now,
          ),
        ]
        ..playlistTracks = {
          'road_trip': [t1, t2],
        };
      searchRepo = FakeSearchRepository()..searchTracks = [t1, t2, t3];

      handler = NexaAudioHandler(
        engine: engine,
        queue: queue,
        tracksRepository: tracksRepo,
        playlistsRepository: playlistsRepo,
        searchRepository: searchRepo,
      );
    });

    tearDown(() async {
      queue.dispose();
      await engine.dispose();
    });

    test('getChildren for root returns 4 standard MediaBrowser directories',
        () async {
      final items = await handler.getChildren(AudioService.browsableRootId);

      expect(items.length, 4);
      expect(items.map((i) => i.id).toList(), [
        NexaAudioHandler.rootSongsId,
        NexaAudioHandler.rootFavoritesId,
        NexaAudioHandler.rootPlaylistsId,
        NexaAudioHandler.rootQueueId,
      ]);
      expect(items.every((i) => i.playable == false), isTrue);
    });

    test('getChildren for root/songs returns all tracks as playable', () async {
      final items = await handler.getChildren(NexaAudioHandler.rootSongsId);

      expect(items.length, 3);
      expect(items.map((i) => i.id).toList(), ['track-1', 'track-2', 'track-3']);
      expect(items.first.title, 'Midnight City');
      expect(items.every((i) => i.playable == true), isTrue);
    });

    test('getChildren for root/favorites filters only starred tracks', () async {
      final items = await handler.getChildren(NexaAudioHandler.rootFavoritesId);

      expect(items.length, 2);
      expect(items.map((i) => i.id).toList(), ['track-1', 'track-3']);
      expect(items.every((i) => i.playable == true), isTrue);
    });

    test('getChildren for root/playlists returns available playlists', () async {
      final items = await handler.getChildren(NexaAudioHandler.rootPlaylistsId);

      expect(items.length, 1);
      expect(items.first.id, 'playlist/road_trip');
      expect(items.first.title, 'Road Trip Essentials');
    });

    test('getChildren for playlist/ID returns tracks within that playlist',
        () async {
      final items = await handler.getChildren('playlist/road_trip');

      expect(items.length, 2);
      expect(items.map((i) => i.id).toList(), ['track-1', 'track-2']);
    });

    test('getChildren for root/queue returns active playback queue tracks',
        () async {
      queue.setQueue([t2, t3], initialIndex: 0);

      final items = await handler.getChildren(NexaAudioHandler.rootQueueId);

      expect(items.length, 2);
      expect(items.first.id, 'track-2');
      expect(items.last.id, 'track-3');
    });

    test('getMediaItem resolves from queue or repository', () async {
      queue.setQueue([t2], initialIndex: 0);

      // Found in queue
      final itemQueue = await handler.getMediaItem('track-2');
      expect(itemQueue?.title, 'Starboy');

      // Found in repository
      final itemRepo = await handler.getMediaItem('track-1');
      expect(itemRepo?.title, 'Midnight City');

      // Not found
      final itemNull = await handler.getMediaItem('non_existent');
      expect(itemNull, isNull);
    });

    test('playFromMediaId for favorites queues and plays all favorite tracks',
        () async {
      await handler.playFromMediaId(NexaAudioHandler.rootFavoritesId);

      expect(queue.state.tracks.length, 2);
      expect(queue.state.tracks.first.id, 'track-1');
      expect(engine.loadedTrack?.id, 'track-1');
      expect(engine.playCalled, isTrue);
    });

    test('playFromMediaId for playlist queues and plays playlist tracks',
        () async {
      await handler.playFromMediaId('playlist/road_trip');

      expect(queue.state.tracks.length, 2);
      expect(queue.state.tracks.first.id, 'track-1');
      expect(engine.loadedTrack?.id, 'track-1');
      expect(engine.playCalled, isTrue);
    });

    test('playFromMediaId for specific track ID loads and plays it', () async {
      await handler.playFromMediaId('track-2');

      expect(queue.state.tracks.first.id, 'track-2');
      expect(engine.loadedTrack?.id, 'track-2');
      expect(engine.playCalled, isTrue);
    });

    test('search and playFromSearch handle voice queries', () async {
      final results = await handler.search('Starboy');
      expect(results.length, 1);
      expect(results.first.id, 'track-2');

      await handler.playFromSearch('Starboy');
      expect(engine.loadedTrack?.id, 'track-2');
      expect(engine.playCalled, isTrue);
    });

    test('customAction toggleFavorite toggles current track', () async {
      queue.setQueue([t1], initialIndex: 0);

      await handler.customAction('toggleFavorite');
      expect(tracksRepo.favoriteToggles, contains('track-1'));
    });

    test('customAction shuffleQueue toggles playback queue mode', () async {
      expect(queue.state.mode, domain.PlaybackMode.ordered);
      await handler.customAction('shuffleQueue');
      expect(queue.state.mode, domain.PlaybackMode.shuffle);
      await handler.customAction('shuffleQueue');
      expect(queue.state.mode, domain.PlaybackMode.ordered);
    });
  });
}
