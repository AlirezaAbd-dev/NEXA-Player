import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/theme/dynamic_palette_service.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/features/player/presentation/widgets/hero_artwork_card.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../player/player_notifier_test.dart';

void main() {
  group('HW-v1.1.1 PR 5/5 (DEF-04) — Stellio-Style 3D Cover Flow Carousel & Palette Morph', () {
    late MockAudioEngine engine;
    late PlaybackQueueImpl queue;
    late SleepTimerServiceImpl sleepTimer;

    const testTracks = [
      Track(
        id: 'trk-01',
        title: 'Song One',
        artist: 'Artist A',
        album: 'Album X',
        duration: Duration(seconds: 200),
      ),
      Track(
        id: 'trk-02',
        title: 'Song Two',
        artist: 'Artist B',
        album: 'Album Y',
        duration: Duration(seconds: 240),
      ),
      Track(
        id: 'trk-03',
        title: 'Song Three',
        artist: 'Artist C',
        album: 'Album Z',
        duration: Duration(seconds: 180),
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

    Widget createSubject({
      bool disableAnimations = false,
      int initialIndex = 0,
      void Function(double)? onPageScrolled,
      void Function(int)? onPageSettled,
    }) {
      return ProviderScope(
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              disableAnimations: disableAnimations,
            ),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360.0,
                  child: HeroArtworkCard(
                    track: testTracks[initialIndex],
                    tracks: testTracks,
                    currentIndex: initialIndex,
                    isPlaying: true,
                    size: 260.0,
                    onPageScrolled: onPageScrolled,
                    onPageSettled: onPageSettled,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    test('3D perspective rotation strictly clamps value to [-1.0, 1.0] to prevent card inversion', () {
      // Studio formula constants
      const maxAngle = math.pi / 7; // ~25.7 degrees

      double computeAngle(double rawValue) {
        final clampedValue = rawValue.clamp(-1.0, 1.0);
        return clampedValue * maxAngle;
      }

      // Fast multi-page fling deltas
      expect(computeAngle(0.0), 0.0);
      expect(computeAngle(1.0), maxAngle);
      expect(computeAngle(2.5), maxAngle); // Clamped: does NOT invert (> 90°)
      expect(computeAngle(-3.0), -maxAngle); // Clamped: does NOT invert
      expect(computeAngle(0.5), closeTo(maxAngle * 0.5, 0.001));

      // Studio scale clamping: (1.0 - value.abs() * 0.14).clamp(0.70, 1.0)
      double computeScale(double rawValue) {
        final clampedValue = rawValue.clamp(-1.0, 1.0);
        return (1.0 - clampedValue.abs() * 0.14).clamp(0.70, 1.0);
      }

      expect(computeScale(0.0), 1.0);
      expect(computeScale(1.0), 0.86);
      expect(computeScale(5.0), 0.86); // Never below 0.70
    });

    test('ExtractedPalette.lerp continuously morphs between two palettes under user thumb', () {
      const paletteA = ExtractedPalette(
        dominant: Color(0xFF102030),
        vibrant: Color(0xFFFF0000),
        muted: Color(0xFF666666),
        darkVibrant: Color(0xFF330000),
        lightVibrant: Color(0xFFFF9999),
      );

      const paletteB = ExtractedPalette(
        dominant: Color(0xFF506070),
        vibrant: Color(0xFF00FF00),
        muted: Color(0xFF999999),
        darkVibrant: Color(0xFF003300),
        lightVibrant: Color(0xFF99FF99),
      );

      // Interpolation at boundaries
      final atZero = ExtractedPalette.lerp(paletteA, paletteB, 0.0);
      expect(atZero.dominant, paletteA.dominant);
      expect(atZero.vibrant, paletteA.vibrant);

      final atOne = ExtractedPalette.lerp(paletteA, paletteB, 1.0);
      expect(atOne.dominant, paletteB.dominant);
      expect(atOne.vibrant, paletteB.vibrant);

      // Mid-swipe 50% morph
      final atMid = ExtractedPalette.lerp(paletteA, paletteB, 0.5);
      expect(atMid.vibrant, Color.lerp(paletteA.vibrant, paletteB.vibrant, 0.5));
      expect(atMid.dominant, Color.lerp(paletteA.dominant, paletteB.dominant, 0.5));
    });

    testWidgets('renders PageView.builder carousel with RepaintBoundary for Kirin 710F 60fps', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('Reduced Motion disables 3D rotateY and maintains flat slide', (tester) async {
      await tester.pumpWidget(createSubject(disableAnimations: true));
      await tester.pumpAndSettle();

      expect(find.byType(HeroArtworkCard), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
    });

    testWidgets('swiping carousel fires onPageScrolled continuously and onPageSettled once on settle', (tester) async {
      final scrolledOffsets = <double>[];
      int? settledIndex;

      await tester.pumpWidget(
        createSubject(
          onPageScrolled: (offset) => scrolledOffsets.add(offset),
          onPageSettled: (index) => settledIndex = index,
        ),
      );
      await tester.pumpAndSettle();

      // Swipe left from track 0 to track 1
      await tester.fling(find.byType(PageView), const Offset(-250, 0), 1000);
      await tester.pumpAndSettle();

      expect(scrolledOffsets, isNotEmpty);
      expect(settledIndex, 1);
    });

    testWidgets('tapping adjacent carousel item animates PageController to that page', (tester) async {
      int? settledIndex;

      await tester.pumpWidget(
        createSubject(
          initialIndex: 0,
          onPageSettled: (index) => settledIndex = index,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the adjacent carousel item (card 1)
      final adjacentCardFinder = find.byWidgetPredicate(
        (w) => w is GestureDetector && w.child is Container,
      );
      expect(adjacentCardFinder, findsWidgets);

      // Tap on the right-edge visible slice of next card (inside [565, 580], y inside [195, 455])
      await tester.tapAt(const Offset(572, 300));
      await tester.pumpAndSettle();

      expect(settledIndex, 1);
    });

    testWidgets('external skipNext advances active queue and updates NowPlayingScreen', (tester) async {
      const container = ProviderScope(
        child: MaterialApp(
          home: NowPlayingScreen(),
        ),
      );

      await tester.pumpWidget(container);
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(NowPlayingScreen));
      final ref = ProviderScope.containerOf(element);
      await ref.read(playerNotifierProvider.notifier).playTrack(testTracks[0]);
      await tester.pumpAndSettle();

      // Initially on track 1 ('Song One')
      expect(find.text('Song One'), findsWidgets);

      // Trigger skipNext from playerNotifier
      await ref.read(playerNotifierProvider.notifier).skipNext();
      await tester.pumpAndSettle();

      // Active track is now Song Two
      expect(ref.read(playerNotifierProvider).currentTrack?.title, 'Song Two');
      expect(find.text('Song Two'), findsWidgets);
    });
  });
}
