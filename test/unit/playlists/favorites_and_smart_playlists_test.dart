import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/services/library/library_sync_bus.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_tracks_repository.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_smart_playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:path/path.dart' as p;

class _FakeEngine implements IAudioEngine {
  final _statusCtrl = StreamController<PlaybackStatus>.broadcast();
  final _posCtrl = StreamController<Duration>.broadcast();
  final _durCtrl = StreamController<Duration>.broadcast();
  final _bufCtrl = StreamController<Duration>.broadcast();
  final _volCtrl = StreamController<double>.broadcast();
  final _spdCtrl = StreamController<double>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _pos = Duration.zero;
  Duration _dur = Duration.zero;

  @override
  PlaybackStatus get status => _status;
  @override
  Duration get position => _pos;
  @override
  Duration get duration => _dur;
  @override
  double get volume => 1.0;
  @override
  double get speed => 1.0;
  @override
  Stream<PlaybackStatus> get statusStream => _statusCtrl.stream;
  @override
  Stream<Duration> get positionStream => _posCtrl.stream;
  @override
  Stream<Duration> get durationStream => _durCtrl.stream;
  @override
  Stream<Duration> get bufferedPositionStream => _bufCtrl.stream;
  @override
  Stream<double> get volumeStream => _volCtrl.stream;
  @override
  Stream<double> get speedStream => _spdCtrl.stream;

  void emitPosition(Duration pos) {
    _pos = pos;
    _posCtrl.add(pos);
  }

  void emitCompleted() {
    _status = PlaybackStatus.completed;
    _statusCtrl.add(_status);
  }

  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
    _dur = track.duration;
    _pos = Duration.zero;
    _durCtrl.add(_dur);
    _status = autoPlay ? PlaybackStatus.playing : PlaybackStatus.paused;
    _statusCtrl.add(_status);
  }

  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSpeed(double speed) async {}
  @override
  Future<void> setLoopMode(bool loop) async {}

  @override
  Future<void> dispose() async {
    await _statusCtrl.close();
    await _posCtrl.close();
    await _durCtrl.close();
    await _bufCtrl.close();
    await _volCtrl.close();
    await _spdCtrl.close();
  }
}

class _FakeTimer implements ISleepTimerService {
  final _ctrl = StreamController<Duration?>.broadcast();
  @override
  bool get isActive => false;
  @override
  Duration? get remainingTime => null;
  @override
  Stream<Duration?> get remainingStream => _ctrl.stream;
  @override
  void start(Duration duration, {bool fadeOut = true, void Function()? onCompleted}) {}
  @override
  void cancel() {}
  @override
  void dispose() => _ctrl.close();
}

Track _makeTrack(int i, {int? dateAddedMs, bool fav = false}) {
  return Track(
    id: 'trk-$i',
    title: 'Song $i',
    artist: 'Artist $i',
    album: 'Album ${(i % 5) + 1}',
    duration: const Duration(minutes: 3),
    filePath: '/music/song_$i.mp3',
    dateAdded: DateTime.fromMillisecondsSinceEpoch(dateAddedMs ?? (1000000 + i * 1000)),
    isFavorite: fav,
  );
}

void main() {
  group('Favorites & Smart Playlists End-to-End', () {
    test('toggling favorite persists across DB reopen & updates Favorites list and LibrarySyncBus', () async {
      final dir = await Directory.systemTemp.createTemp('nexa_fav_db_');
      addTearDown(() async {
        if (await dir.exists()) await dir.delete(recursive: true);
      });
      final dbPath = p.join(dir.path, 'library.db');

      final syncBus = LibrarySyncBus();
      var syncEvents = 0;
      final sub = syncBus.stream.listen((_) => syncEvents++);
      addTearDown(sub.cancel);

      var db = await AppDatabase.open(customPath: dbPath);
      var tracksRepo = SqliteTracksRepository(db, syncBus: syncBus);
      var smartRepo = SqliteSmartPlaylistsRepository(db);

      await tracksRepo.insertTracks([
        _makeTrack(1, dateAddedMs: 1000),
        _makeTrack(2, dateAddedMs: 2000),
      ]);

      final engine = _FakeEngine();
      final queue = PlaybackQueueImpl();
      final timer = _FakeTimer();
      final notifier = PlayerNotifier(
        engine: engine,
        queue: queue,
        sleepTimer: timer,
        tracksRepository: tracksRepo,
        syncBus: syncBus,
      );

      final track1 = (await tracksRepo.getTrackById('trk-1')).valueOrNull!;
      await notifier.playQueue([track1]);
      expect(notifier.state.currentTrack?.isFavorite, isFalse);

      await notifier.toggleFavorite();
      expect(notifier.state.currentTrack?.isFavorite, isTrue);
      expect(syncEvents, greaterThanOrEqualTo(1));

      final favs1 = (await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.favorites))
          .valueOrNull!;
      expect(favs1.map((t) => t.id), ['trk-1']);

      // Reopen DB to verify persistence across restarts
      notifier.dispose();
      queue.dispose();
      timer.dispose();
      await engine.dispose();
      db.close();

      db = await AppDatabase.open(customPath: dbPath);
      addTearDown(db.close);
      tracksRepo = SqliteTracksRepository(db, syncBus: syncBus);
      smartRepo = SqliteSmartPlaylistsRepository(db);

      final favsReopened =
          (await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.favorites)).valueOrNull!;
      expect(favsReopened.length, 1);
      expect(favsReopened.first.id, 'trk-1');
      expect(favsReopened.first.isFavorite, isTrue);

      // Toggling again removes it from Favorites cleanly
      await tracksRepo.toggleFavorite('trk-1');
      final favsAfterUntoggle =
          (await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.favorites)).valueOrNull!;
      expect(favsAfterUntoggle, isEmpty);
    });

    test('Recently Added captures latest 30 (and 20) songs in descending date_added order and pushes 36th arrival to #1',
        () async {
      final db = AppDatabase.inMemory();
      addTearDown(db.close);
      final tracksRepo = SqliteTracksRepository(db);
      final smartRepo = SqliteSmartPlaylistsRepository(db);

      final initial35 = List.generate(
        35,
        (i) => _makeTrack(i + 1, dateAddedMs: 1000000 + (i + 1) * 5000),
      );
      await tracksRepo.insertTracks(initial35);

      // Default limit = 30 -> returns trk-35 down to trk-6 (drops trk-1..trk-5)
      final latest30 = (await smartRepo.getTracksForSmartPlaylist(
        SmartPlaylistType.recentlyAdded,
        recentlyAddedLimit: 30,
      ))
          .valueOrNull!;
      expect(latest30.length, 30);
      expect(latest30.first.id, 'trk-35');
      expect(latest30.last.id, 'trk-6');

      // Configurable limit = 20 -> returns trk-35 down to trk-16
      final latest20 = (await smartRepo.getTracksForSmartPlaylist(
        SmartPlaylistType.recentlyAdded,
        recentlyAddedLimit: 20,
      ))
          .valueOrNull!;
      expect(latest20.length, 20);
      expect(latest20.first.id, 'trk-35');
      expect(latest20.last.id, 'trk-16');

      // New 36th song arrives -> jumps to index 0 and drops trk-6
      await tracksRepo.insertTrack(_makeTrack(36, dateAddedMs: 99999999));
      final updated30 = (await smartRepo.getTracksForSmartPlaylist(
        SmartPlaylistType.recentlyAdded,
        recentlyAddedLimit: 30,
      ))
          .valueOrNull!;
      expect(updated30.length, 30);
      expect(updated30.first.id, 'trk-36');
      expect(updated30.any((t) => t.id == 'trk-6'), isFalse);
      expect(updated30.last.id, 'trk-7');
    });

    test('Most Played & Recently Played update accurately after 30s/30% playback events without double-counting',
        () async {
      final db = AppDatabase.inMemory();
      addTearDown(db.close);
      final syncBus = LibrarySyncBus();
      final tracksRepo = SqliteTracksRepository(db, syncBus: syncBus);
      final smartRepo = SqliteSmartPlaylistsRepository(db);

      final t1 = _makeTrack(1, dateAddedMs: 1000);
      final t2 = _makeTrack(2, dateAddedMs: 2000);
      await tracksRepo.insertTracks([t1, t2]);

      final engine = _FakeEngine();
      final queue = PlaybackQueueImpl();
      final timer = _FakeTimer();
      final notifier = PlayerNotifier(
        engine: engine,
        queue: queue,
        sleepTimer: timer,
        tracksRepository: tracksRepo,
        syncBus: syncBus,
      );
      addTearDown(() async {
        notifier.dispose();
        queue.dispose();
        timer.dispose();
        await engine.dispose();
      });

      // Play track 1 past 30s -> counts as 1 play
      await notifier.playQueue([t1, t2], initialIndex: 0);
      engine.emitPosition(const Duration(seconds: 5));
      await Future<void>.delayed(Duration.zero);
      expect(
        (await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.mostPlayed)).valueOrNull,
        isEmpty,
      );

      engine.emitPosition(const Duration(seconds: 35));
      await Future<void>.delayed(Duration.zero);
      engine.emitPosition(const Duration(seconds: 60)); // should not double-count same epoch
      await Future<void>.delayed(Duration.zero);

      final played1 = (await tracksRepo.getTrackById('trk-1')).valueOrNull!;
      expect(played1.playCount, 1);

      // Advance to track 2 and finish it cleanly, then play track 2 a second time
      await notifier.skipNext();
      engine.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      await notifier.playQueue([t2]);
      engine.emitPosition(const Duration(seconds: 31));
      await Future<void>.delayed(Duration.zero);

      final mostPlayed =
          (await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.mostPlayed)).valueOrNull!;
      expect(mostPlayed.map((t) => t.id).toList(), ['trk-2', 'trk-1']);
      expect(mostPlayed.first.playCount, 2);

      final recentPlayed =
          (await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.recentlyPlayed))
              .valueOrNull!;
      expect(recentPlayed.first.id, 'trk-2');
      expect(recentPlayed.last.id, 'trk-1');
    });
  });
}
