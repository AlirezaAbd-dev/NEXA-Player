import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/standby_mode_screen.dart';
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
                id: 'standby_test_track',
                title: 'Starlight Voyage',
                artist: 'Cosmic Echo',
                album: 'Celestial Horizon',
                duration: Duration(minutes: 4, seconds: 12),
              ),
          status: PlaybackStatus.playing,
          position: const Duration(minutes: 1, seconds: 30),
          duration: const Duration(minutes: 4, seconds: 12),
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
  late FakePlayerNotifier fakePlayer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    if (!getIt.isRegistered<IStorageService>()) {
      getIt.registerSingleton<IStorageService>(storage);
    }
    fakePlayer = FakePlayerNotifier();
  });

  tearDown(() async {
    if (getIt.isRegistered<IStorageService>()) {
      await getIt.unregister<IStorageService>();
    }
  });

  Widget buildTestWidget({Widget? child}) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
        playerNotifierProvider.overrideWith((ref) => fakePlayer),
      ],
      child: MaterialApp(
        home: child ?? const StandbyModeScreen(),
      ),
    );
  }

  group('StandbyModeScreen', () {
    testWidgets('renders clock, standby badge, turntable, and controls',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STANDBY'), findsOneWidget);
      expect(find.text('Starlight Voyage'), findsWidgets);
      expect(find.byIcon(Icons.close_fullscreen_rounded), findsOneWidget);
      expect(find.byIcon(Icons.skip_previous_rounded), findsWidgets);
      expect(find.byIcon(Icons.skip_next_rounded), findsWidgets);
    });

    testWidgets('cycling dimming level changes icon and maintains screen',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump(const Duration(milliseconds: 100));

      final dimButton = find.byTooltip('Cycle Dim Level');
      expect(dimButton, findsOneWidget);

      // Cycle to Bedside dim
      await tester.tap(dimButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.brightness_medium_rounded), findsOneWidget);

      // Cycle to Ultra dim
      await tester.tap(dimButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.brightness_3_rounded), findsOneWidget);

      // Cycle back to full
      await tester.tap(dimButton);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byIcon(Icons.brightness_high_rounded), findsOneWidget);
    });

    testWidgets('tapping exit button calls pop safely', (tester) async {
      bool popped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            playerNotifierProvider.overrideWith((ref) => fakePlayer),
          ],
          child: MaterialApp(
            home: StandbyModeScreen(onExit: () => popped = true),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final exitBtn = find.byTooltip('Exit Standby Mode');
      expect(exitBtn, findsOneWidget);

      await tester.tap(exitBtn);
      await tester.pump(const Duration(milliseconds: 500));

      expect(popped, isTrue);
    });
  });
}
