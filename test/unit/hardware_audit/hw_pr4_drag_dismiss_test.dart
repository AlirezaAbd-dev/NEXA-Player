import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/features/player/presentation/widgets/waveform_visualizer.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../player/player_notifier_test.dart';

void main() {
  group('HW-v1.1.1 PR 4/5 (DEF-03) — Interactive Drag-Down Dismiss & Route Guards', () {
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

    Widget createTestApp() {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  key: const ValueKey('open_player_button'),
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        opaque: false,
                        barrierColor: Colors.black54,
                        pageBuilder: (context, anim, secAnim) =>
                            const NowPlayingScreen(),
                      ),
                    );
                  },
                  child: const Text('Open Player'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('AppRoutes.player GoRoute uses CustomTransitionPage with opaque=false & barrierColor=Colors.black54', (tester) async {
      await tester.pumpWidget(createTestApp());
      final context = tester.element(find.byKey(const ValueKey('open_player_button')));

      final routes = appRouter.configuration.routes;
      final playerRoute = routes
          .whereType<GoRoute>()
          .firstWhere((r) => r.path == AppRoutes.player);

      expect(playerRoute, isNotNull);
      expect(playerRoute.pageBuilder, isNotNull);

      final mockState = GoRouterState(
        appRouter.configuration,
        uri: Uri.parse(AppRoutes.player),
        matchedLocation: AppRoutes.player,
        fullPath: AppRoutes.player,
        pathParameters: const <String, String>{},
        pageKey: const ValueKey('mock_player_page'),
      );

      final page = playerRoute.pageBuilder!(context, mockState);
      expect(page, isA<CustomTransitionPage<void>>());
      final transitionPage = page as CustomTransitionPage<void>;
      expect(transitionPage.opaque, isFalse);
      expect(transitionPage.barrierColor, equals(Colors.black54));
    });

    testWidgets('Top grabber handle pill (36x4dp) is present on NowPlayingScreen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();

      final grabber = find.byKey(const ValueKey('now_playing_grabber_pill'));
      expect(grabber, findsOneWidget);

      final size = tester.getSize(grabber);
      expect(size.width, equals(36.0));
      expect(size.height, equals(4.0));
    });

    testWidgets('Dragging down > 150dp on top grabber pill pops NowPlayingScreen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      // Drag down 180dp from grabber pill
      await tester.drag(
        find.byKey(const ValueKey('now_playing_grabber_pill')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();

      // Screen popped
      expect(find.byType(NowPlayingScreen), findsNothing);
    });

    testWidgets('Dragging down > 150dp on central artwork pops NowPlayingScreen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      // Drag down 180dp from artwork area
      await tester.drag(
        find.byKey(const ValueKey('now_playing_pull_down_artwork')),
        const Offset(0, 180),
      );
      await tester.pumpAndSettle();

      // Screen popped
      expect(find.byType(NowPlayingScreen), findsNothing);
    });

    testWidgets('Dragging down < 150dp with low velocity springs back without popping', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      // Drag down 60dp with small drag
      await tester.drag(
        find.byKey(const ValueKey('now_playing_pull_down_artwork')),
        const Offset(0, 60),
      );
      await tester.pump();

      // Screen remains visible
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      // Allow snap-back animation to finish
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });

    testWidgets('Downward fling > 800 dp/s pops NowPlayingScreen even with small distance', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      // Fling down at 1200 dp/s
      await tester.fling(
        find.byKey(const ValueKey('now_playing_pull_down_header')),
        const Offset(0, 80),
        1200.0,
      );
      await tester.pumpAndSettle();

      // Screen popped due to high velocity
      expect(find.byType(NowPlayingScreen), findsNothing);
    });

    testWidgets('Left edge rail vertical drag adjusts speed and does NOT pop route', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      final leftRail = find.byKey(const ValueKey('now_playing_left_edge_rail'));
      expect(leftRail, findsOneWidget);

      // Drag upward on left rail (speed up)
      await tester.drag(leftRail, const Offset(0, -60));
      await tester.pumpAndSettle();

      // Screen is still open
      expect(find.byType(NowPlayingScreen), findsOneWidget);
      // Speed HUD appeared
      expect(find.textContaining('Speed:'), findsOneWidget);
    });

    testWidgets('Right edge rail vertical drag adjusts volume and does NOT pop route', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      final rightRail = find.byKey(const ValueKey('now_playing_right_edge_rail'));
      expect(rightRail, findsOneWidget);

      // Drag upward on right rail (volume up)
      await tester.drag(rightRail, const Offset(0, -60));
      await tester.pumpAndSettle();

      // Screen is still open
      expect(find.byType(NowPlayingScreen), findsOneWidget);
      // Volume HUD appeared
      expect(find.textContaining('Volume:'), findsOneWidget);
    });

    testWidgets('Dragging on WaveformVisualizer does NOT dismiss NowPlayingScreen', (tester) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('open_player_button')));
      await tester.pumpAndSettle();
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      final visualizer = find.byType(WaveformVisualizer);
      expect(visualizer, findsOneWidget);

      // Drag horizontally and downward on visualizer
      await tester.drag(visualizer, const Offset(50, 40));
      await tester.pumpAndSettle();

      // Screen is still open
      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });
  });
}
