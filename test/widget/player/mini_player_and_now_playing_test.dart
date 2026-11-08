import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/app/shell/mini_player_slot.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/features/player/presentation/widgets/queue_bottom_sheet.dart';
import 'package:nexa_player/features/player/presentation/widgets/sleep_timer_bottom_sheet.dart';
import 'package:nexa_player/features/player/presentation/widgets/waveform_visualizer.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unit/player/player_notifier_test.dart';

void main() {
  group('MiniPlayerSlot & NowPlayingScreen Widget Tests', () {
    late MockAudioEngine engine;
    late PlaybackQueueImpl queue;
    late SleepTimerServiceImpl sleepTimer;

    const testTracks = [
      Track(
        id: 'trk-101',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: Duration(seconds: 230),
      ),
      Track(
        id: 'trk-102',
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: Duration(seconds: 248),
      ),
    ];

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      engine = MockAudioEngine();
      queue = PlaybackQueueImpl();
      sleepTimer = SleepTimerServiceImpl();

      if (getIt.isRegistered<MockAudioEngine>()) {
        getIt.unregister<MockAudioEngine>();
      }
      await configureDependencies(
        audioEngine: engine,
        playbackQueue: queue,
        sleepTimerService: sleepTimer,
        seedDemoData: false,
      );

      queue.setQueue(testTracks, initialIndex: 0);
    });

    tearDown(() {
      engine.dispose();
      queue.dispose();
      sleepTimer.dispose();
      getIt.reset();
    });

    testWidgets('MiniPlayerSlot displays track title, artist and play/pause icon', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MiniPlayerSlot(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Starboy'), findsOneWidget);
      expect(find.byType(MiniPlayerSlot), findsOneWidget);

      final playPauseBtn = find.byKey(const ValueKey('mini_player_play_pause'));
      expect(playPauseBtn, findsOneWidget);
      await tester.tap(playPauseBtn);
      await tester.pump();
    });

    testWidgets('NowPlayingScreen displays hero artwork, metadata, seekbar and controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NowPlayingScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Starboy'), findsWidgets);
      expect(find.byType(WaveformVisualizer), findsOneWidget);
      expect(find.byTooltip('Play'), findsWidgets);
      expect(find.byTooltip('Next'), findsOneWidget);
      expect(find.byTooltip('Previous'), findsOneWidget);
      expect(find.byTooltip('Shuffle'), findsOneWidget);
      expect(find.byTooltip('Repeat'), findsOneWidget);
      expect(find.byTooltip('Favorite'), findsOneWidget);

      // Tap Play/Pause button
      final playBtn = find.byTooltip('Play').first;
      await tester.tap(playBtn);
      await tester.pump();

      // Tap Shuffle
      final shuffleBtn = find.byTooltip('Shuffle');
      await tester.tap(shuffleBtn);
      await tester.pump();

      // Tap Repeat
      final repeatBtn = find.byTooltip('Repeat');
      await tester.tap(repeatBtn);
      await tester.pump();

      // Tap Favorite
      final favBtn = find.byTooltip('Favorite');
      await tester.tap(favBtn);
      await tester.pump();
    });

    testWidgets('Tapping Queue icon opens QueueBottomSheet with reorderable tracks', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NowPlayingScreen(),
          ),
        ),
      );
      await tester.pump();

      final queueBtn = find.byTooltip('Queue');
      expect(queueBtn, findsOneWidget);
      await tester.tap(queueBtn);
      await tester.pumpAndSettle();

      expect(find.text('Up Next Queue'), findsOneWidget);
      expect(find.byType(QueueBottomSheet), findsOneWidget);
      expect(find.text('Get Lucky'), findsOneWidget);
    });

    testWidgets('Tapping Sleep Timer icon opens SleepTimerBottomSheet with options', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: NowPlayingScreen(),
          ),
        ),
      );
      await tester.pump();

      final timerBtn = find.byTooltip('Sleep Timer').first;
      expect(timerBtn, findsOneWidget);
      await tester.tap(timerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Sleep Timer'), findsOneWidget);
      expect(find.byType(SleepTimerBottomSheet), findsOneWidget);
      expect(find.text('15 Minutes'), findsOneWidget);
      expect(find.text('30 Minutes'), findsOneWidget);
    });
  });
}
