import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/features/player/data/services/nexa_audio_handler.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart'
    as domain;
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAudioEngine implements IAudioEngine {
  final _statusController = StreamController<domain.PlaybackStatus>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration>.broadcast();
  final _bufferedController = StreamController<Duration>.broadcast();
  final _volumeController = StreamController<double>.broadcast();
  final _speedController = StreamController<double>.broadcast();

  domain.PlaybackStatus _status = domain.PlaybackStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final double _speed = 1.0;

  Duration? lastSeekPosition;
  bool playCalled = false;
  bool pauseCalled = false;

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
  double get speed => _speed;

  void emitDuration(Duration dur) {
    _duration = dur;
    _durationController.add(dur);
  }

  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
    _duration = track.duration;
    _durationController.add(_duration);
    if (autoPlay) {
      await play();
    } else {
      _status = domain.PlaybackStatus.paused;
      _statusController.add(_status);
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
    _status = domain.PlaybackStatus.idle;
    _position = Duration.zero;
    _statusController.add(_status);
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
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

class _FakeArtworkResolver implements IArtworkResolutionService {
  _FakeArtworkResolver(this.resolvedPath);
  final String resolvedPath;

  @override
  Future<String?> resolveTrackArtwork(
    Track track, {
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
    int? mediaStoreAlbumId,
    int maxSize = 512,
  }) async {
    return resolvedPath;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAudioEngine engine;
  late PlaybackQueueImpl queue;
  late SharedPreferencesStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    engine = _FakeAudioEngine();
    queue = PlaybackQueueImpl();
  });

  tearDown(() async {
    await engine.dispose();
    queue.dispose();
  });

  group('NexaAudioHandler Notification & Lockscreen Player Tests', () {
    test('configures Android media notification channel & valid ongoing/pause flags', () {
      expect(
        nexaAudioServiceConfig.androidNotificationChannelId,
        equals('com.nexa.player.channel.audio'),
      );
      expect(
        nexaAudioServiceConfig.androidNotificationIcon,
        equals('drawable/ic_stat_nexa'),
      );
      expect(nexaAudioServiceConfig.androidStopForegroundOnPause, isFalse);
      expect(nexaAudioServiceConfig.preloadArtwork, isTrue);
      expect(nexaAudioServiceConfig.artDownscaleWidth, equals(512));
      expect(nexaAudioServiceConfig.artDownscaleHeight, equals(512));
    });

    test('publishes MediaItem with non-null duration, artUri & Persian/UTF-8 metadata', () async {
      final tmpDir = Directory.systemTemp.createTempSync('nexa_art_notif_');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final artFile = File('${tmpDir.path}/cover.jpg')..writeAsBytesSync([1, 2, 3]);

      final handler = NexaAudioHandler(
        engine: engine,
        queue: queue,
        storageService: storage,
      );
      addTearDown(handler.dispose);

      final track = Track(
        id: 'trk-fa-1',
        title: 'پر پرواز',
        artist: 'شادمهر عقیلی',
        album: 'آلبوم برگزیده',
        duration: const Duration(minutes: 4, seconds: 12),
        artworkUri: artFile.path,
      );

      queue.setQueue([track], initialIndex: 0);
      await engine.load(track, autoPlay: true);
      await Future<void>.delayed(Duration.zero);

      final item = handler.mediaItem.valueOrNull;
      expect(item, isNotNull);
      expect(item!.title, equals('پر پرواز'));
      expect(item.artist, equals('شادمهر عقیلی'));
      expect(item.album, equals('آلبوم برگزیده'));
      expect(item.duration, equals(const Duration(minutes: 4, seconds: 12)));
      expect(item.artUri, equals(Uri.file(artFile.path)));
    });

    test('lazily resolves missing artworkUri and updates MediaItem when available', () async {
      final resolver = _FakeArtworkResolver('/cache/resolved_cover.jpg');
      final handler = NexaAudioHandler(
        engine: engine,
        queue: queue,
        artworkResolver: resolver,
        storageService: storage,
      );
      addTearDown(handler.dispose);

      const track = Track(
        id: 'trk-lazy-art',
        title: 'Track Without Initial Art',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        artworkUri: null,
      );

      queue.setQueue([track], initialIndex: 0);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      final item = handler.mediaItem.valueOrNull;
      expect(item, isNotNull);
      expect(item!.artUri, equals(Uri.file('/cache/resolved_cover.jpg')));
    });

    test('PlaybackState exposes MediaAction.seek and transport controls; seek() updates state position immediately', () async {
      await storage.setString(
        StorageKeys.notificationActions,
        jsonEncode(['previous', 'play_pause', 'next', 'favorite']),
      );

      final handler = NexaAudioHandler(
        engine: engine,
        queue: queue,
        storageService: storage,
      );
      addTearDown(handler.dispose);

      const t1 = Track(
        id: 't1',
        title: 'First Song',
        artist: 'Artist 1',
        duration: Duration(minutes: 3),
      );
      const t2 = Track(
        id: 't2',
        title: 'Second Song',
        artist: 'Artist 2',
        duration: Duration(minutes: 4),
      );

      queue.setQueue([t1, t2], initialIndex: 0);
      await engine.load(t1, autoPlay: true);
      await Future<void>.delayed(Duration.zero);

      final statePlaying = handler.playbackState.value;
      expect(statePlaying.playing, isTrue);
      expect(statePlaying.systemActions, contains(MediaAction.seek));
      expect(
        statePlaying.controls.map((c) => c.action),
        containsAll([MediaAction.skipToPrevious, MediaAction.pause, MediaAction.skipToNext]),
      );
      expect(
        statePlaying.controls.any((c) => c.androidIcon == 'drawable/ic_stat_nexa'),
        isTrue,
      );

      // Interactive seekbar drag updates engine & re-emits position synchronously
      await handler.seek(const Duration(seconds: 42));
      expect(engine.lastSeekPosition, equals(const Duration(seconds: 42)));
      expect(
        handler.playbackState.value.updatePosition,
        equals(const Duration(seconds: 42)),
      );

      // Pause & verify Play button replaces Pause while remaining seekable
      await handler.pause();
      expect(engine.pauseCalled, isTrue);
      expect(handler.playbackState.value.playing, isFalse);
      expect(
        handler.playbackState.value.controls.map((c) => c.action),
        contains(MediaAction.play),
      );
      expect(handler.playbackState.value.systemActions, contains(MediaAction.seek));
    });

    test('next, previous, play, pause delegate to PlayerNotifier callbacks when bound', () async {
      final handler = NexaAudioHandler(
        engine: engine,
        queue: queue,
        storageService: storage,
      );
      addTearDown(handler.dispose);

      int nextCalls = 0;
      int prevCalls = 0;
      int favCalls = 0;
      handler.bindTransportCallbacks(
        onSkipNext: () async => nextCalls++,
        onSkipPrevious: () async => prevCalls++,
        onToggleFavorite: () async => favCalls++,
      );

      await handler.skipToNext();
      await handler.skipToPrevious();
      await handler.customAction('toggleFavorite');

      expect(nextCalls, equals(1));
      expect(prevCalls, equals(1));
      expect(favCalls, equals(1));
    });
  });
}
