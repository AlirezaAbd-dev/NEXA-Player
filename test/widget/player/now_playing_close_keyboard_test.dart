import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/app/shell/scaffold_with_nav_bar.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/inputs/nexa_search_bar.dart';

class _TestPlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _TestPlayerNotifier(super.state);

  @override
  Future<void> playQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    PlaybackMode? mode,
    NexaRepeatMode? repeatMode,
    QueueContext? queueContext,
  }) async {}

  @override
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? initialIndex,
    QueueContext? queueContext,
  }) async {}

  @override
  Future<void> skipNext() async {}

  @override
  Future<void> skipPrevious() async {}

  @override
  Future<void> skipToIndex(int index) async {}

  @override
  void refreshTrack(Track updatedTrack) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleTrack = Track(
    id: 'trk-kbd-1',
    title: 'Keyboard Isolation Track',
    artist: 'Test Artist',
    album: 'Test Album',
    duration: Duration(minutes: 3, seconds: 30),
  );

  late int textInputShowCount;
  late GoRouter testRouter;

  void installTextInputSpy() {
    textInputShowCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, (call) async {
      if (call.method == 'TextInput.show') {
        textInputShowCount++;
      }
      return null;
    });
  }

  bool hasEditableTextFocus() {
    final focus = FocusManager.instance.primaryFocus;
    final ctx = focus?.context;
    if (ctx == null) return false;
    return ctx.widget is EditableText ||
        focus?.debugLabel == 'EditableText' ||
        ctx.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  Widget buildTestApp() {
    final rootKey = GlobalKey<NavigatorState>(debugLabel: 'test_root');
    testRouter = GoRouter(
      navigatorKey: rootKey,
      initialLocation: AppRoutes.songs,
      observers: [FocusDismissNavigatorObserver()],
      routes: [
        StatefulShellRoute(
          builder: (context, state, navigationShell) {
            return ScaffoldWithNavBar(navigationShell: navigationShell);
          },
          navigatorContainerBuilder: buildStatefulShellNavigatorContainer,
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.songs,
                  builder: (context, state) => const Scaffold(
                    body: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            NexaSearchBar(
                              key: ValueKey('songs_tab_search_bar'),
                              hintText: 'Filter songs...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.albums,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.artists,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.folders,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.playlists,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.search,
                  builder: (context, state) => const Scaffold(
                    body: SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            NexaSearchBar(
                              key: ValueKey('search_tab_search_bar'),
                              hintText: 'Global search...',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: AppRoutes.settings,
                  builder: (context, state) => const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          parentNavigatorKey: rootKey,
          path: AppRoutes.player,
          pageBuilder: (context, state) => CustomTransitionPage<void>(
            key: state.pageKey,
            opaque: false,
            barrierColor: Colors.black54,
            child: const NowPlayingScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        playerNotifierProvider.overrideWith(
          (ref) => _TestPlayerNotifier(
            const PlaybackState(
              currentTrack: sampleTrack,
              status: PlaybackStatus.paused,
              position: Duration(seconds: 30),
              duration: Duration(minutes: 3, seconds: 30),
            ),
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.buildTheme(
          preset: ThemePreset.midnightBlack,
          mode: ThemeMode.dark,
        ),
        routerConfig: testRouter,
      ),
    );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.textInput, null);
  });

  Future<void> setMobileViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('Task #14b NowPlaying close keyboard & focus regression', () {
    testWidgets(
      'Closing NowPlaying via Back/Minimize button emits zero TextInput.show calls after search field use',
      (tester) async {
        await setMobileViewport(tester);
        installTextInputSpy();

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Tap search TextField -> shows keyboard
        final songsField = find.descendant(
          of: find.byKey(const ValueKey('songs_tab_search_bar')),
          matching: find.byType(TextField),
        );
        await tester.tap(songsField);
        await tester.pump();
        expect(textInputShowCount, greaterThan(0));

        // Simulate dismissing IME without full route change, then open NowPlaying
        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await tester.pump();
        textInputShowCount = 0;

        testRouter.push(AppRoutes.player);
        await tester.pumpAndSettle();
        expect(find.byType(NowPlayingScreen), findsOneWidget);
        expect(textInputShowCount, 0);

        // Close NowPlaying via top-left Back/Minimize button
        await tester.tap(find.byTooltip('Minimize'));
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsNothing);
        expect(textInputShowCount, 0);
        expect(hasEditableTextFocus(), isFalse);
      },
    );

    testWidgets(
      'Closing NowPlaying via pull-down dismiss emits zero TextInput.show calls',
      (tester) async {
        await setMobileViewport(tester);
        installTextInputSpy();

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        final songsField = find.descendant(
          of: find.byKey(const ValueKey('songs_tab_search_bar')),
          matching: find.byType(TextField),
        );
        await tester.tap(songsField);
        await tester.pump();
        expect(textInputShowCount, greaterThan(0));

        await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
        await tester.pump();
        textInputShowCount = 0;

        testRouter.push(AppRoutes.player);
        await tester.pumpAndSettle();
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        // Pull down header beyond 150dp dismiss threshold
        await tester.drag(
          find.byKey(const ValueKey('now_playing_pull_down_header')),
          const Offset(0, 260),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsNothing);
        expect(textInputShowCount, 0);
        expect(hasEditableTextFocus(), isFalse);
      },
    );

    testWidgets(
      'Switching from Search tab to Library tab then opening and closing NowPlaying emits zero TextInput.show calls',
      (tester) async {
        await setMobileViewport(tester);
        installTextInputSpy();

        await tester.pumpWidget(buildTestApp());
        await tester.pumpAndSettle();

        // Switch to Search tab & tap global search input
        await tester.tap(find.byKey(const ValueKey('tab_search')));
        await tester.pumpAndSettle();

        final globalSearchField = find.descendant(
          of: find.byKey(const ValueKey('search_tab_search_bar')),
          matching: find.byType(TextField),
        );
        await tester.tap(globalSearchField);
        await tester.pump();
        expect(textInputShowCount, greaterThan(0));
        expect(hasEditableTextFocus(), isTrue);

        // Switch to Library tab (must unfocus active Search input & isolate inactive branch)
        await tester.tap(find.byKey(const ValueKey('tab_library')));
        await tester.pumpAndSettle();

        textInputShowCount = 0;

        // Open NowPlaying via MiniPlayer tap
        await tester.tap(find.byKey(const ValueKey('mini_player_slot')));
        await tester.pumpAndSettle();
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        // Close NowPlaying
        await tester.tap(find.byTooltip('Minimize'));
        await tester.pumpAndSettle();

        expect(find.byType(NowPlayingScreen), findsNothing);
        expect(textInputShowCount, 0);
        expect(hasEditableTextFocus(), isFalse);
      },
    );
  });
}
