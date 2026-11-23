import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/app/shell/scaffold_with_nav_bar.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/desktop_studio_dock.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:go_router/go_router.dart';
import '../../helpers/mock_services.dart';

class FakeNavigationShell implements StatefulNavigationShell {
  @override
  int get currentIndex => 0;

  int? navigatedIndex;

  @override
  void goBranch(int index, {bool initialLocation = false}) {
    navigatedIndex = index;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePlayerNotifierForDesktop extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  FakePlayerNotifierForDesktop()
      : super(const PlaybackState(
          currentTrack: Track(
            id: 'desktop_test_1',
            title: 'Studio Masterpiece',
            artist: 'Audiophile Guild',
            album: 'High Fidelity',
            duration: Duration(minutes: 5, seconds: 12),
          ),
          status: PlaybackStatus.playing,
          position: Duration(minutes: 2),
          duration: Duration(minutes: 5, seconds: 12),
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
  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeNavigationShell fakeShell;
  late FakePlayerNotifierForDesktop fakePlayer;
  late PlaybackQueueImpl fakeQueue;

  setUp(() {
    fakeShell = FakeNavigationShell();
    fakePlayer = FakePlayerNotifierForDesktop();
    fakeQueue = PlaybackQueueImpl();
    fakeQueue.setQueue([
      const Track(
        id: 'q1',
        title: 'Track One',
        artist: 'Artist One',
        album: 'Album',
        duration: Duration(minutes: 3),
      ),
      const Track(
        id: 'q2',
        title: 'Track Two',
        artist: 'Artist Two',
        album: 'Album',
        duration: Duration(minutes: 4),
      ),
    ], initialIndex: 0);
  });

  tearDown(() {
    fakeQueue.dispose();
  });

  Widget buildShellWidget(Size size) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(FakeStorageService()),
        loggingServiceProvider.overrideWithValue(FakeLoggingService()),
        playerNotifierProvider.overrideWith((ref) => fakePlayer),
        playbackQueueProvider.overrideWithValue(fakeQueue),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ScaffoldWithNavBar(navigationShell: fakeShell),
        ),
      ),
    );
  }

  group('Desktop Studio Layout & Shortcuts Tests', () {
    testWidgets('mobile viewport (<800dp) renders bottom nav without studio dock',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShellWidget(const Size(400, 800)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('glass_bottom_nav')), findsOneWidget);
      expect(find.byKey(const ValueKey('navigation_rail')), findsNothing);
      expect(find.byKey(DesktopStudioDockKeys.root), findsNothing);
    });

    testWidgets('tablet viewport (800dp - 1199dp) renders navigation rail without studio dock',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShellWidget(const Size(900, 800)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('navigation_rail')), findsOneWidget);
      expect(find.byKey(const ValueKey('glass_bottom_nav')), findsNothing);
      expect(find.byKey(DesktopStudioDockKeys.root), findsNothing);
    });

    testWidgets('wide desktop viewport (>=1200dp) renders 3-zone layout with DesktopStudioDock',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShellWidget(const Size(1300, 800)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('navigation_rail')), findsOneWidget);
      expect(find.byKey(DesktopStudioDockKeys.root), findsOneWidget);
      expect(find.text('STUDIO INSPECTOR'), findsOneWidget);
      expect(find.text('10-Band Parametric EQ'), findsOneWidget);
      expect(find.text('UP NEXT QUEUE'), findsOneWidget);
      expect(find.text('Studio Masterpiece'), findsWidgets);
    });

    testWidgets('spacebar hardware keyboard shortcut toggles play/pause',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShellWidget(const Size(1300, 800)));
      await tester.pumpAndSettle();

      // Send spacebar key event
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();

      // Initially playing, so space should pause
      expect(fakePlayer.pauseCalled, isTrue);
    });
  });
}
