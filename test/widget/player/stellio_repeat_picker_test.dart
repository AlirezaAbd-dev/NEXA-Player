import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/shared/models/track.dart';

class _TestAudioEngine implements IAudioEngine {
  final _statusCtrl = StreamController<PlaybackStatus>.broadcast();
  final _posCtrl = StreamController<Duration>.broadcast();
  final _durCtrl = StreamController<Duration>.broadcast();
  final _bufCtrl = StreamController<Duration>.broadcast();
  final _volCtrl = StreamController<double>.broadcast();
  final _spdCtrl = StreamController<double>.broadcast();
  PlaybackStatus _status = PlaybackStatus.playing;

  @override
  PlaybackStatus get status => _status;
  @override
  Duration get position => const Duration(seconds: 15);
  @override
  Duration get duration => const Duration(minutes: 3);
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
  @override
  Future<void> load(Track track, {bool autoPlay = true}) async {
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

class _TestSleepTimer implements ISleepTimerService {
  final _ctrl = StreamController<Duration?>.broadcast();
  @override
  bool get isActive => false;
  @override
  Duration? get remainingTime => null;
  @override
  Stream<Duration?> get remainingStream => _ctrl.stream;
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
    _ctrl.close();
  }
}

void main() {
  testWidgets(
      'NowPlayingScreen tap cycles 5 repeat modes with toast pill & long press opens 5-row picker sheet',
      (tester) async {
    final engine = _TestAudioEngine();
    final queue = PlaybackQueueImpl();
    final sleepTimer = _TestSleepTimer();
    final notifier = PlayerNotifier(
      engine: engine,
      queue: queue,
      sleepTimer: sleepTimer,
    );

    const track = Track(
      id: 'trk-ui-1',
      title: 'Test Track',
      artist: 'Test Artist',
      album: 'Test Album',
      duration: Duration(minutes: 3),
      filePath: '/music/test.mp3',
    );
    await notifier.playQueue([track]);

    addTearDown(() async {
      queue.dispose();
      sleepTimer.dispose();
      await engine.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playbackQueueProvider.overrideWithValue(queue),
          playerNotifierProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const NowPlayingScreen(),
        ),
      ),
    );
    await tester.pump();

    final repeatButton = find.byKey(const Key('now_playing_repeat_button'));
    expect(repeatButton, findsOneWidget);

    final expectedSequence = [
      (NexaRepeatMode.repeatList, Icons.repeat_on_rounded),
      (NexaRepeatMode.repeatSelectedTrack, Icons.repeat_one_on_rounded),
      (NexaRepeatMode.nextListStopOnLast, Icons.playlist_play_rounded),
      (NexaRepeatMode.nextListRepeatFirst, Icons.all_inclusive_rounded),
      (NexaRepeatMode.stopOnLastTrack, Icons.repeat_rounded),
    ];

    for (final (expectedMode, expectedIcon) in expectedSequence) {
      await tester.tap(repeatButton);
      await tester.pump();
      expect(notifier.state.repeatMode, expectedMode);
      expect(find.text(expectedMode.shortLabel), findsOneWidget);
      expect(
        find.descendant(of: repeatButton, matching: find.byIcon(expectedIcon)),
        findsOneWidget,
      );
    }

    // Advance clock past 1.6s toast lifetime and verify HUD toast dismisses cleanly
    await tester.pump(const Duration(milliseconds: 1700));
    expect(find.text(NexaRepeatMode.stopOnLastTrack.shortLabel), findsNothing);

    // Long press opens 5-mode picker sheet
    await tester.longPress(repeatButton);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stellio_repeat_picker_sheet')), findsOneWidget);
    for (final mode in NexaRepeatMode.values) {
      expect(find.byKey(Key('repeat_option_${mode.name}')), findsOneWidget);
    }

    // Selecting "Jump to next list: repeat first" updates state cleanly and closes sheet
    await tester.tap(find.byKey(const Key('repeat_option_nextListRepeatFirst')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('stellio_repeat_picker_sheet')), findsNothing);
    expect(notifier.state.repeatMode, NexaRepeatMode.nextListRepeatFirst);
    expect(
      find.descendant(
        of: repeatButton,
        matching: find.byIcon(Icons.all_inclusive_rounded),
      ),
      findsOneWidget,
    );
  });
}
