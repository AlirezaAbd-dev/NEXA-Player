import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/auto/presentation/screens/wear_companion_screen.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeWearPlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  FakeWearPlayerNotifier()
      : super(const PlaybackState(
          currentTrack: Track(
            id: 'wear_track_1',
            title: 'Midnight Echo',
            artist: 'Luna Waves',
            album: 'Nocturne',
            duration: Duration(minutes: 3, seconds: 30),
            isFavorite: true,
          ),
          status: PlaybackStatus.playing,
          position: Duration(minutes: 1, seconds: 0),
          duration: Duration(minutes: 3, seconds: 30),
        ));

  bool playCalled = false;
  bool pauseCalled = false;
  bool skipNextCalled = false;
  bool skipPreviousCalled = false;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IStorageService storage;
  late FakeWearPlayerNotifier fakePlayer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    if (!getIt.isRegistered<IStorageService>()) {
      getIt.registerSingleton<IStorageService>(storage);
    }
    fakePlayer = FakeWearPlayerNotifier();
  });

  tearDown(() async {
    if (getIt.isRegistered<IStorageService>()) {
      await getIt.unregister<IStorageService>();
    }
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        playerNotifierProvider.overrideWith((ref) => fakePlayer),
      ],
      child: const MaterialApp(
        home: WearCompanionScreen(),
      ),
    );
  }

  group('WearCompanionScreen Tests', () {
    testWidgets('renders Wear OS smartwatch enclosure and track metadata',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Wear OS Smartwatch Hub'), findsOneWidget);
      expect(find.text('Midnight Echo'), findsOneWidget);
      expect(find.text('Luna Waves'), findsOneWidget);
      expect(find.text('10:42'), findsOneWidget);
      expect(find.byTooltip('Previous'), findsOneWidget);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Next'), findsOneWidget);
      expect(find.text('Wear OS Remote MediaSession'), findsOneWidget);
      expect(find.text('CIRCULAR (450px)'), findsOneWidget);
    });

    testWidgets('toggles bezel shape between round and square', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final toggleButton = find.byTooltip('Switch to Square Bezel');
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to Round Bezel'), findsOneWidget);
      expect(find.text('SQUARE (390px)'), findsOneWidget);

      await tester.tap(find.byTooltip('Switch to Round Bezel'));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Switch to Square Bezel'), findsOneWidget);
      expect(find.text('CIRCULAR (450px)'), findsOneWidget);
    });

    testWidgets('play/pause button controls player state', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Pause'));
      await tester.pumpAndSettle();

      expect(fakePlayer.pauseCalled, isTrue);
    });

    testWidgets('skip buttons trigger previous and next track actions',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Previous'));
      await tester.tap(find.byTooltip('Next'));
      await tester.pumpAndSettle();

      expect(fakePlayer.skipPreviousCalled, isTrue);
      expect(fakePlayer.skipNextCalled, isTrue);
    });
  });
}
