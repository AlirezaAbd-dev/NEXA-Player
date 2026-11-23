import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/auto/presentation/providers/auto_providers.dart';
import 'package:nexa_player/features/auto/presentation/screens/car_mode_screen.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  FakePlayerNotifier([Track? initialTrack])
      : super(PlaybackState(
          currentTrack: initialTrack ??
              const Track(
                id: 'car_test_track',
                title: 'Driving Anthem',
                artist: 'Synthwave Cruiser',
                album: 'Highway Dreams',
                duration: Duration(minutes: 3, seconds: 45),
              ),
          status: PlaybackStatus.playing,
          position: const Duration(minutes: 1, seconds: 15),
          duration: const Duration(minutes: 3, seconds: 45),
        ));

  bool playCalled = false;
  bool pauseCalled = false;
  bool skipNextCalled = false;
  bool skipPreviousCalled = false;
  Duration? lastSeekPosition;
  bool toggleFavoriteCalled = false;

  @override
  Future<void> play() async {
    playCalled = true;
    state = state.copyWith(status: PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  @override
  Future<void> skipNext() async {
    skipNextCalled = true;
  }

  @override
  Future<void> skipPrevious() async {
    skipPreviousCalled = true;
  }

  @override
  Future<void> seek(Duration position) async {
    lastSeekPosition = position;
    state = state.copyWith(position: position);
  }

  @override
  Future<void> toggleFavorite([Track? targetTrack]) async {
    toggleFavoriteCalled = true;
    final curr = targetTrack ?? state.currentTrack;
    if (curr != null) {
      state = state.copyWith(
        currentTrack: curr.copyWith(isFavorite: !curr.isFavorite),
      );
    }
  }

  @override
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? initialIndex,
  }) async {
    state = state.copyWith(
      currentTrack: track,
      status: PlaybackStatus.playing,
      position: Duration.zero,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IStorageService storage;
  late FakePlayerNotifier fakePlayer;
  late PlaybackQueueImpl fakeQueue;

  const queueTrack1 = Track(
    id: 'queue_1',
    title: 'Driving Anthem',
    artist: 'Synthwave Cruiser',
    album: 'Highway Dreams',
    duration: Duration(minutes: 3, seconds: 45),
  );
  const queueTrack2 = Track(
    id: 'queue_2',
    title: 'Nightfall Pulse',
    artist: 'Retro Runner',
    album: 'Neon Grid',
    duration: Duration(minutes: 4, seconds: 10),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    if (!getIt.isRegistered<IStorageService>()) {
      getIt.registerSingleton<IStorageService>(storage);
    }
    fakePlayer = FakePlayerNotifier(queueTrack1);
    fakeQueue = PlaybackQueueImpl();
    fakeQueue.setQueue([queueTrack1, queueTrack2], initialIndex: 0);
  });

  tearDown(() async {
    fakeQueue.dispose();
    if (getIt.isRegistered<IStorageService>()) {
      await getIt.unregister<IStorageService>();
    }
  });

  Widget buildTestWidget({
    VoidCallback? onExit,
    Size size = const Size(400, 800),
  }) {
    return ProviderScope(
      overrides: [
        playerNotifierProvider.overrideWith((ref) => fakePlayer),
        playbackQueueProvider.overrideWithValue(fakeQueue),
        autoSettingsProvider.overrideWith(
          (ref) => AutoSettingsNotifier(storage),
        ),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: CarModeScreen(onExit: onExit),
        ),
      ),
    );
  }

  group('CarModeScreen Tests', () {
    testWidgets('renders portrait HUD with track info, badge, and oversized buttons',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('CAR MODE'), findsOneWidget);
      expect(find.text('Driving Anthem'), findsOneWidget);
      expect(find.text('Synthwave Cruiser'), findsOneWidget);
      expect(find.byTooltip('Exit Car Mode'), findsOneWidget);
      expect(find.byTooltip('Previous Track'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Next Track'), findsOneWidget);
      expect(find.byTooltip('Rewind 15s'), findsOneWidget);
      expect(find.byTooltip('Forward 15s'), findsOneWidget);
      expect(find.byTooltip('Queue Drawer'), findsOneWidget);
    });

    testWidgets('calls onExit when exit button is tapped', (tester) async {
      bool exited = false;
      await tester.pumpWidget(buildTestWidget(onExit: () => exited = true));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Exit Car Mode'));
      await tester.pumpAndSettle();

      expect(exited, isTrue);
    });

    testWidgets('play/pause button toggles playback', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();

      expect(fakePlayer.pauseCalled, isTrue);
    });

    testWidgets('skip buttons trigger player skip controls', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Previous Track'));
      await tester.tap(find.byTooltip('Next Track'));
      await tester.pumpAndSettle();

      expect(fakePlayer.skipPreviousCalled, isTrue);
      expect(fakePlayer.skipNextCalled, isTrue);
    });

    testWidgets('rewind 15s and forward 15s trigger seek with delta', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Rewind 15s'));
      await tester.pumpAndSettle();
      expect(fakePlayer.lastSeekPosition?.inSeconds, 60); // 75s - 15s = 60s

      await tester.tap(find.byTooltip('Forward 15s'));
      await tester.pumpAndSettle();
      expect(fakePlayer.lastSeekPosition?.inSeconds, 75); // 60s + 15s = 75s
    });

    testWidgets('opens quick queue drawer and lists tracks', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Queue Drawer'));
      await tester.pumpAndSettle();

      expect(find.text('UP NEXT QUEUE'), findsOneWidget);
      expect(find.text('Nightfall Pulse'), findsOneWidget);
    });

    testWidgets('renders landscape layout when width > height', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestWidget(size: const Size(1280, 800)));
      await tester.pumpAndSettle();

      expect(find.text('CAR MODE'), findsOneWidget);
      expect(find.text('Driving Anthem'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
    });

    testWidgets('blind gestures on canvas trigger skip next and skip previous', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Swipe left on canvas: trigger skipNext
      await tester.drag(find.text('Driving Anthem'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      expect(fakePlayer.skipNextCalled, isTrue);

      // Swipe right on canvas: trigger skipPrevious
      await tester.drag(find.text('Driving Anthem'), const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(fakePlayer.skipPreviousCalled, isTrue);
    });
  });
}
