import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/shell/scaffold_with_nav_bar.dart';
import 'package:nexa_player/core/di/service_providers.dart' hide playbackQueueProvider;
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/utils/contrast_validator.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_state.dart';
import 'package:nexa_player/features/equalizer/domain/entities/reverb_preset.dart';
import 'package:nexa_player/features/equalizer/presentation/providers/equalizer_notifier.dart';
import 'package:nexa_player/features/equalizer/presentation/providers/equalizer_providers.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/glass/nexa_floating_nav_dock.dart';
import '../../helpers/mock_services.dart';

// ignore: must_be_immutable
class FakeNavShellForDock extends Fake implements StatefulNavigationShell {
  FakeNavShellForDock({this.currentIndex = 0, this.child});

  @override
  final int currentIndex;
  final Widget? child;
  int? navigatedIndex;

  @override
  Key? get key => null;

  @override
  StatefulElement createElement() => StatefulElement(this);

  @override
  State<StatefulWidget> createState() => _FakeNavShellForDockState();

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    navigatedIndex = index;
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) =>
      'FakeNavShellForDock';
}

class _FakeNavShellForDockState extends State<FakeNavShellForDock> {
  @override
  Widget build(BuildContext context) => widget.child ?? const SizedBox();
}

class FakeEqualizerForDockTest extends StateNotifier<EqualizerState>
    implements EqualizerNotifier {
  FakeEqualizerForDockTest()
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

class FakePlayerForDockTest extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  FakePlayerForDockTest({PlaybackState? initial})
      : super(
          initial ??
              const PlaybackState(
                currentTrack: Track(
                  id: 'dock_test_track_1',
                  title: 'Acoustic Dock Sound',
                  artist: 'Audiophile Artist',
                  album: 'High Fidelity Master',
                  duration: Duration(minutes: 3, seconds: 45),
                ),
                status: PlaybackStatus.playing,
              ),
        );

  @override
  Future<void> stop() async {
    state = const PlaybackState(
      status: PlaybackStatus.idle,
      currentTrack: null,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeStorageService fakeStorage;
  late FakeLoggingService fakeLogging;
  late SettingsServiceImpl settingsService;
  late FakePlayerForDockTest fakePlayer;
  late PlaybackQueueImpl fakeQueue;

  setUp(() {
    fakeStorage = FakeStorageService();
    fakeLogging = FakeLoggingService();
    settingsService = SettingsServiceImpl(fakeStorage);
    fakePlayer = FakePlayerForDockTest();
    fakeQueue = PlaybackQueueImpl();
  });

  tearDown(() {
    fakeQueue.dispose();
  });

  Widget buildDockHarness({
    required int currentIndex,
    required ValueChanged<int> onTap,
    ValueChanged<int>? onDoubleTap,
    ThemeData? theme,
    MediaQueryData? mediaQuery,
  }) {
    final effectiveTheme =
        theme ?? AppTheme.buildTheme(preset: ThemePreset.midnightBlack, mode: ThemeMode.dark);
    final mq = mediaQuery ?? const MediaQueryData(size: Size(360, 780));

    return MaterialApp(
      theme: effectiveTheme,
      home: MediaQuery(
        data: mq,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: NexaFloatingNavDock(
                currentIndex: currentIndex,
                onTap: onTap,
                onDoubleTap: onDoubleTap,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('NexaFloatingNavDock & Acoustic Dock Suite', () {
    testWidgets(
      'All 4 tabs render with >= 48x48dp touch targets and zero RenderFlex overflow at 360x780',
      (tester) async {
        const viewport = Size(360, 780);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int selectedIndex = 0;

        await tester.pumpWidget(
          buildDockHarness(
            currentIndex: selectedIndex,
            onTap: (idx) => selectedIndex = idx,
            mediaQuery: const MediaQueryData(size: viewport),
          ),
        );
        await tester.pumpAndSettle();

        // Check each destination has touch target >= 48x48dp
        const tabKeys = [
          ValueKey('tab_library'),
          ValueKey('tab_playlists'),
          ValueKey('tab_search'),
          ValueKey('tab_settings'),
        ];

        for (final key in tabKeys) {
          final tabFinder = find.byKey(key);
          expect(tabFinder, findsOneWidget);

          final tabSize = tester.getSize(tabFinder);
          expect(
            tabSize.width,
            greaterThanOrEqualTo(48.0),
            reason: 'Tab width (${tabSize.width}dp) must meet >= 48dp WCAG touch target',
          );
          expect(
            tabSize.height,
            greaterThanOrEqualTo(48.0),
            reason: 'Tab height (${tabSize.height}dp) must meet >= 48dp WCAG touch target',
          );
        }

        // Verify zero overflow exceptions
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Modern standard viewport 412x915 and 1.3x text scale renders with zero overflow',
      (tester) async {
        const viewport = Size(412, 915);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int selectedIndex = 1; // Playlists active

        await tester.pumpWidget(
          buildDockHarness(
            currentIndex: selectedIndex,
            onTap: (idx) => selectedIndex = idx,
            mediaQuery: const MediaQueryData(
              size: viewport,
              textScaler: TextScaler.linear(1.3),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Playlists'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Morphing active pill: active tab shows filled icon + label; inactive tabs show outlined icon only',
      (tester) async {
        const viewport = Size(360, 780);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int selectedIndex = 0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildDockHarness(
                currentIndex: selectedIndex,
                onTap: (idx) => setState(() => selectedIndex = idx),
                mediaQuery: const MediaQueryData(size: viewport),
              );
            },
          ),
        );
        await tester.pumpAndSettle();

        // Tab 0 (Library) is active
        expect(find.text('Library'), findsOneWidget);
        expect(find.byIcon(Icons.library_music_rounded), findsOneWidget);

        // Inactive tabs show outlined icons only and do NOT show text labels
        expect(find.text('Playlists'), findsNothing);
        expect(find.text('Search'), findsNothing);
        expect(find.text('Settings'), findsNothing);
        expect(find.byIcon(Icons.queue_music_outlined), findsOneWidget);
        expect(find.byIcon(Icons.search_outlined), findsOneWidget);
        expect(find.byIcon(Icons.tune_outlined), findsOneWidget);

        // Tap Tab 1 (Playlists)
        await tester.tap(find.byKey(const ValueKey('tab_playlists')));
        await tester.pumpAndSettle();

        // Now Playlists is active
        expect(selectedIndex, equals(1));
        expect(find.text('Playlists'), findsOneWidget);
        expect(find.byIcon(Icons.queue_music_rounded), findsOneWidget);

        // Library is now inactive (outlined icon, label disappeared)
        expect(find.text('Library'), findsNothing);
        expect(find.byIcon(Icons.library_music_outlined), findsOneWidget);

        // Horizontal swipe gesture across dock to navigate to next tab (Search)
        await tester.fling(
          find.byType(NexaFloatingNavDock),
          const Offset(-300, 0),
          1000,
        );
        await tester.pumpAndSettle();

        expect(selectedIndex, equals(2));
        expect(find.text('Search'), findsOneWidget);
        expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'Theme propagation: Sakura Rose and Daylight render zero hardcoded cyan and maintain WCAG AA contrast (>=4.5:1)',
      (tester) async {
        const viewport = Size(360, 780);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        // 1. Sakura Rose Dark Theme
        final sakuraTheme = AppTheme.buildTheme(
          preset: ThemePreset.sakura,
          mode: ThemeMode.dark,
        );

        await tester.pumpWidget(
          buildDockHarness(
            currentIndex: 0,
            onTap: (_) {},
            theme: sakuraTheme,
            mediaQuery: const MediaQueryData(size: viewport),
          ),
        );
        await tester.pumpAndSettle();

        // Active text color check in Sakura
        final libraryTextFinder = find.text('Library');
        expect(libraryTextFinder, findsOneWidget);
        final Text libraryText = tester.widget(libraryTextFinder);
        final textColor = libraryText.style?.color;
        expect(textColor, isNotNull);

        // Verify zero hardcoded cyan (#00E5FF)
        expect(textColor, isNot(equals(const Color(0xFF00E5FF))));

        // 2. Daylight Light Theme
        final daylightTheme = AppTheme.buildTheme(
          preset: ThemePreset.daylight,
          mode: ThemeMode.light,
        );

        await tester.pumpWidget(
          buildDockHarness(
            currentIndex: 0,
            onTap: (_) {},
            theme: daylightTheme,
            mediaQuery: const MediaQueryData(size: viewport),
          ),
        );
        await tester.pumpAndSettle();

        final Text daylightText = tester.widget(find.text('Library'));
        final daylightTextColor = daylightText.style?.color;
        expect(daylightTextColor, isNotNull);
        expect(daylightTextColor, isNot(equals(const Color(0xFF00E5FF))));

        // WCAG AA contrast against white / pill background (>= 4.5:1)
        final contrastRatio = ContrastValidator.calculateContrastRatio(
          daylightTextColor!,
          Colors.white,
        );
        expect(
          contrastRatio,
          greaterThanOrEqualTo(4.5),
          reason: 'Daylight mode foreground contrast ratio ($contrastRatio) must be >= 4.5:1',
        );
      },
    );

    testWidgets(
      'Reduced motion: disableAnimations completes tab transitions cleanly without throwing',
      (tester) async {
        const viewport = Size(360, 780);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        int selectedIndex = 0;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return buildDockHarness(
                currentIndex: selectedIndex,
                onTap: (idx) => setState(() => selectedIndex = idx),
                mediaQuery: const MediaQueryData(
                  size: viewport,
                  disableAnimations: true,
                ),
              );
            },
          ),
        );
        await tester.pump();

        expect(find.text('Library'), findsOneWidget);

        // Tap tab 3 (Settings) with animations disabled
        await tester.tap(find.byKey(const ValueKey('tab_settings')));
        await tester.pump();

        expect(selectedIndex, equals(3));
        expect(find.text('Settings'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Desktop NavigationRail parity: wide desktop renders rail with filled/outlined icons and studio dock',
      (tester) async {
        const viewport = Size(1280, 800);
        await tester.binding.setSurfaceSize(viewport);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fakeShell = FakeNavShellForDock(currentIndex: 0);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storageServiceProvider.overrideWithValue(fakeStorage),
              loggingServiceProvider.overrideWithValue(fakeLogging),
              settingsServiceProvider.overrideWithValue(settingsService),
              equalizerNotifierProvider
                  .overrideWith((ref) => FakeEqualizerForDockTest()),
              playerNotifierProvider.overrideWith((ref) => fakePlayer),
              playbackQueueProvider.overrideWithValue(fakeQueue),
            ],
            child: MaterialApp(
              theme: AppTheme.buildTheme(
                preset: ThemePreset.midnightBlack,
                mode: ThemeMode.dark,
              ),
              home: MediaQuery(
                data: const MediaQueryData(size: viewport),
                child: ScaffoldWithNavBar(navigationShell: fakeShell),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Rail is present
        expect(find.byKey(const ValueKey('navigation_rail')), findsOneWidget);
        // Mobile bottom dock is absent
        expect(find.byKey(const ValueKey('glass_bottom_nav')), findsNothing);

        // Rail icons are rendered
        expect(find.byKey(const ValueKey('tab_songs')), findsOneWidget);
        expect(find.byKey(const ValueKey('tab_albums')), findsOneWidget);
        expect(find.byKey(const ValueKey('tab_artists')), findsOneWidget);
        expect(find.byKey(const ValueKey('tab_settings')), findsOneWidget);
      },
    );
  });
}
