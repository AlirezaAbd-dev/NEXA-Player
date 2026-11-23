import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/app/shell/mini_player_slot.dart';
import 'package:nexa_player/app/shell/scaffold_with_nav_bar.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/di/service_providers.dart' hide playbackQueueProvider;
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_state.dart';
import 'package:nexa_player/features/equalizer/domain/entities/reverb_preset.dart';
import 'package:nexa_player/features/equalizer/presentation/providers/equalizer_notifier.dart';
import 'package:nexa_player/features/equalizer/presentation/providers/equalizer_providers.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/desktop_studio_dock.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/presentation/screens/settings_hub_screen.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../../helpers/mock_services.dart';

// ignore: must_be_immutable
class FakeNavigationShellWithChild extends Fake implements StatefulNavigationShell {
  FakeNavigationShellWithChild({this.child, this.currentIndex = 0});

  final Widget? child;

  @override
  Key? get key => null;

  @override
  StatefulElement createElement() => StatefulElement(this);

  @override
  State<StatefulWidget> createState() => _FakeNavigationShellWithChildState();

  @override
  final int currentIndex;

  int? navigatedIndex;

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    navigatedIndex = index;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeNavigationShellWithChild';
}

class _FakeNavigationShellWithChildState
    extends State<FakeNavigationShellWithChild> {
  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox();
}

class FakeEqualizerNotifierForTest extends StateNotifier<EqualizerState>
    implements EqualizerNotifier {
  FakeEqualizerNotifierForTest()
      : super(const EqualizerState(
          isEnabled: false,
          preamp: 0.0,
          bands: [],
          bassBoost: 0.0,
          virtualizer: 0.0,
          reverb: ReverbPreset.none,
          activePresetId: null,
          presets: [],
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlayerNotifierForLayout extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  FakePlayerNotifierForLayout({PlaybackState? initial})
      : super(
          initial ??
              const PlaybackState(
                currentTrack: Track(
                  id: 'occlusion_test_track_1',
                  title: 'Acoustic Transparency',
                  artist: 'Audiophile Reference Master',
                  album: 'High Fidelity Vol. 1',
                  duration: Duration(minutes: 4, seconds: 30),
                ),
                status: PlaybackStatus.playing,
                position: Duration(minutes: 1),
                duration: Duration(minutes: 4, seconds: 30),
              ),
        );

  @override
  Future<void> stop() async {
    state = const PlaybackState(
      status: PlaybackStatus.idle,
      currentTrack: null,
    );
  }

  void setTrack(Track? track) {
    state = state.copyWith(currentTrack: track);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeStorageService fakeStorage;
  late FakeLoggingService fakeLogging;
  late SettingsServiceImpl settingsService;
  late FakePlayerNotifierForLayout fakePlayer;
  late PlaybackQueueImpl fakeQueue;

  setUp(() {
    fakeStorage = FakeStorageService();
    fakeLogging = FakeLoggingService();
    settingsService = SettingsServiceImpl(fakeStorage);
    fakePlayer = FakePlayerNotifierForLayout();
    fakeQueue = PlaybackQueueImpl();
  });

  tearDown(() {
    fakeQueue.dispose();
  });

  Widget buildShellWithChild({
    required Widget child,
    required Size size,
    int initialBranch = 0,
    FakePlayerNotifierForLayout? playerNotifier,
  }) {
    final shell = FakeNavigationShellWithChild(
      currentIndex: initialBranch,
      child: child,
    );

    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(fakeStorage),
        loggingServiceProvider.overrideWithValue(fakeLogging),
        settingsServiceProvider.overrideWithValue(settingsService),
        equalizerNotifierProvider
            .overrideWith((ref) => FakeEqualizerNotifierForTest()),
        playerNotifierProvider
            .overrideWith((ref) => playerNotifier ?? fakePlayer),
        playbackQueueProvider.overrideWithValue(fakeQueue),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ScaffoldWithNavBar(navigationShell: shell),
        ),
      ),
    );
  }

  group('Dynamic Bottom Insets & Zero Visual Occlusion Suite', () {
    testWidgets(
      'Mobile 360x780: scrollable list achieves zero occlusion against floating mini-player',
      (tester) async {
        const viewportSize = Size(360, 780);
        await tester.binding.setSurfaceSize(viewportSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int? tappedIndex;

        // Long list of 40 items using nexaScrollPadding
        final scrollableTestList = Builder(
          builder: (context) {
            return ListView.builder(
              key: const ValueKey('test_scrollable_list'),
              padding: nexaScrollPadding(context, horizontal: 16.0, top: 16.0),
              itemCount: 40,
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey('test_item_$index'),
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => tappedIndex = index,
                    child: Text('Audiophile Track Entry $index'),
                  ),
                );
              },
            );
          },
        );

        await tester.pumpWidget(
          buildShellWithChild(child: scrollableTestList, size: viewportSize),
        );
        await tester.pumpAndSettle();

        // 1. Both mini-player and bottom navigation bar are visible
        expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsOneWidget);
        expect(find.byKey(const ValueKey('glass_bottom_nav')), findsOneWidget);

        // 2. Scroll until the last item (index 39) is fully visible
        final lastItemFinder = find.byKey(const ValueKey('test_item_39'));
        await tester.scrollUntilVisible(
          lastItemFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(lastItemFinder, findsOneWidget);

        // 3. ZERO OCCLUSION ASSERTION:
        // The bottom-most pixel of the last item MUST be at or above the top-most pixel of the mini-player pill.
        final lastItemBottomY = tester.getBottomRight(lastItemFinder).dy;
        final miniPlayerTopY =
            tester.getTopLeft(find.byKey(MiniPlayerKeys.miniPlayerSlot)).dy;

        expect(
          lastItemBottomY,
          lessThanOrEqualTo(miniPlayerTopY),
          reason:
              'Last item bottom ($lastItemBottomY) must be completely clear of mini-player top ($miniPlayerTopY)',
        );

        // 4. TAP-THROUGH ASSERTION:
        // Tapping the last item must directly trigger the onPressed callback without overlay interception.
        await tester.tap(lastItemFinder);
        await tester.pumpAndSettle();

        expect(tappedIndex, equals(39));
      },
    );

    testWidgets(
      'Mobile 412x915: zero occlusion and unclipped layout in modern standard viewport',
      (tester) async {
        const viewportSize = Size(412, 915);
        await tester.binding.setSurfaceSize(viewportSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int? tappedIndex;

        final scrollableTestList = Builder(
          builder: (context) {
            return ListView.builder(
              key: const ValueKey('test_scrollable_list_412'),
              padding: nexaScrollPadding(context, horizontal: 16.0, top: 16.0),
              itemCount: 40,
              itemBuilder: (context, index) {
                return Container(
                  key: ValueKey('test_item_412_$index'),
                  height: 48,
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ElevatedButton(
                    onPressed: () => tappedIndex = index,
                    child: Text('Hi-Res Entry $index'),
                  ),
                );
              },
            );
          },
        );

        await tester.pumpWidget(
          buildShellWithChild(child: scrollableTestList, size: viewportSize),
        );
        await tester.pumpAndSettle();

        final lastItemFinder = find.byKey(const ValueKey('test_item_412_39'));
        await tester.scrollUntilVisible(
          lastItemFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        final lastItemBottomY = tester.getBottomRight(lastItemFinder).dy;
        final miniPlayerTopY =
            tester.getTopLeft(find.byKey(MiniPlayerKeys.miniPlayerSlot)).dy;

        expect(
          lastItemBottomY,
          lessThanOrEqualTo(miniPlayerTopY),
          reason:
              'Last item bottom ($lastItemBottomY) must be above mini-player top ($miniPlayerTopY) at 412x915',
        );

        await tester.tap(lastItemFinder);
        await tester.pumpAndSettle();

        expect(tappedIndex, equals(39));
      },
    );

    testWidgets(
      'Dynamic collapse: when track stops, mini-player disappears and bottom chrome shrinks',
      (tester) async {
        const viewportSize = Size(360, 780);
        await tester.binding.setSurfaceSize(viewportSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        double observedBottomPadding = 0.0;

        final probeWidget = Builder(
          builder: (context) {
            observedBottomPadding = MediaQuery.paddingOf(context).bottom;
            return const Center(child: Text('Dynamic Inset Probe'));
          },
        );

        await tester.pumpWidget(
          buildShellWithChild(child: probeWidget, size: viewportSize),
        );
        await tester.pumpAndSettle();

        // When active track is playing, mini-player is present and inset is 146.0dp (76 + 66 + 4)
        expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsOneWidget);
        expect(observedBottomPadding, equals(146.0));

        // Stop playback and clear current track
        fakePlayer.stop();
        await tester.pumpAndSettle();

        // Mini-player slot must collapse (finds nothing)
        expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsNothing);
        // Bottom nav is still present, so bottom inset shrinks to 76.0dp
        expect(find.byKey(const ValueKey('glass_bottom_nav')), findsOneWidget);
        expect(observedBottomPadding, equals(76.0));
      },
    );

    testWidgets(
      'Desktop 1280x800: bottom chrome collapses completely to 0dp in studio layout',
      (tester) async {
        const viewportSize = Size(1280, 800);
        await tester.binding.setSurfaceSize(viewportSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        double observedBottomPadding = -1.0;

        final probeWidget = Builder(
          builder: (context) {
            observedBottomPadding = MediaQuery.paddingOf(context).bottom;
            return const Center(child: Text('Desktop Inset Probe'));
          },
        );

        await tester.pumpWidget(
          buildShellWithChild(child: probeWidget, size: viewportSize),
        );
        await tester.pumpAndSettle();

        // Mobile bottom nav must be absent
        expect(find.byKey(const ValueKey('glass_bottom_nav')), findsNothing);
        // Navigation rail and studio dock must be active
        expect(find.byKey(const ValueKey('navigation_rail')), findsOneWidget);
        expect(find.byKey(DesktopStudioDockKeys.root), findsOneWidget);

        // Dynamic bottom chrome inset must be 0.0dp on desktop
        expect(observedBottomPadding, equals(0.0));
      },
    );

    testWidgets(
      'SettingsHubScreen audit: entire settings hierarchy scrolls completely above floating bottom chrome',
      (tester) async {
        const viewportSize = Size(360, 780);
        await tester.binding.setSurfaceSize(viewportSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          buildShellWithChild(
            child: const SettingsHubScreen(),
            size: viewportSize,
          ),
        );
        await tester.pumpAndSettle();

        // Locate Settings screen
        expect(find.text('Settings'), findsWidgets);
        expect(find.text('AUDIO PIPELINE STATUS'), findsOneWidget);
        expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsOneWidget);

        // Scroll down to the last tile in SettingsHubScreen ("About NEXA")
        final aboutTileFinder = find.text('About NEXA');
        await tester.scrollUntilVisible(
          aboutTileFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        expect(aboutTileFinder, findsOneWidget);

        final aboutTileBottomY = tester.getBottomRight(aboutTileFinder).dy;
        final miniPlayerTopY =
            tester.getTopLeft(find.byKey(MiniPlayerKeys.miniPlayerSlot)).dy;

        expect(
          aboutTileBottomY,
          lessThanOrEqualTo(miniPlayerTopY),
          reason:
              'About NEXA tile bottom ($aboutTileBottomY) must be completely clear of floating mini-player top ($miniPlayerTopY)',
        );
      },
    );

    testWidgets(
      'Sub-screen route honesty: auto-hides bottom nav on sub-routes, reclaiming bottom space',
      (tester) async {
        const viewportSize = Size(360, 780);
        await tester.binding.setSurfaceSize(viewportSize);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        double observedBottomPadding = -1.0;

        final router = GoRouter(
          initialLocation: AppRoutes.audioSettings,
          routes: [
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => ScaffoldWithNavBar(
                navigationShell: navigationShell,
              ),
              branches: [
                StatefulShellBranch(
                  routes: [
                    GoRoute(
                      path: AppRoutes.audioSettings,
                      builder: (context, state) => Builder(
                        builder: (context) {
                          observedBottomPadding =
                              MediaQuery.paddingOf(context).bottom;
                          return const Center(child: Text('Audio Subscreen'));
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(fakeStorage),
              loggingServiceProvider.overrideWithValue(fakeLogging),
              settingsServiceProvider.overrideWithValue(settingsService),
              equalizerNotifierProvider
                  .overrideWith((ref) => FakeEqualizerNotifierForTest()),
              playerNotifierProvider.overrideWith((ref) => fakePlayer),
              playbackQueueProvider.overrideWithValue(fakeQueue),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              builder: (context, child) => MediaQuery(
                data: const MediaQueryData(size: Size(360, 780)),
                child: child!,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Mobile bottom nav MUST be hidden on pushed subroutes
        expect(find.byKey(const ValueKey('glass_bottom_nav')), findsNothing);

        // 2. Since track is active, mini-player is visible
        expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsOneWidget);

        // 3. Bottom inset is only mini-player height (66.0dp), saving 80dp
        expect(observedBottomPadding, equals(66.0));

        // 4. When track stops, bottom inset collapses to 0.0dp
        fakePlayer.stop();
        await tester.pumpAndSettle();

        expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsNothing);
        expect(observedBottomPadding, equals(0.0));
      },
    );
  });
}
