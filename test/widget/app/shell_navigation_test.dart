import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/app/app.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('Shell Navigation & Responsive Layout Tests', () {
    testWidgets('renders shell scaffold, bottom nav, and persistent mini-player slot', (tester) async {
      tester.view.physicalSize = const Size(400 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: NexaPlayerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initial tab is Songs
      expect(find.byKey(const ValueKey('shell_scaffold')), findsOneWidget);
      expect(find.byKey(const ValueKey('mini_player_slot')), findsOneWidget);
      expect(find.byKey(const ValueKey('glass_bottom_nav')), findsOneWidget);
      expect(find.text('Starboy'), findsWidgets);

      // 2. Tap Albums tab
      await tester.tap(find.byKey(const ValueKey('tab_albums')));
      await tester.pumpAndSettle();
      expect(find.text('Random Access Memories'), findsOneWidget);

      // 3. Tap Artists tab
      await tester.tap(find.byKey(const ValueKey('tab_artists')));
      await tester.pumpAndSettle();
      expect(find.text('Daft Punk'), findsOneWidget);

      // 4. Tap Playlists tab
      await tester.tap(find.byKey(const ValueKey('tab_playlists')));
      await tester.pumpAndSettle();
      expect(find.text('Smart Playlists'), findsOneWidget);

      // 5. Tap Settings tab
      await tester.tap(find.byKey(const ValueKey('tab_settings')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('theme_settings_tile')), findsOneWidget);

      // 6. Tap Theme Settings tile and verify subroute pushes
      await tester.tap(find.byKey(const ValueKey('theme_settings_tile')));
      await tester.pumpAndSettle();
      expect(find.text('Midnight Black'), findsWidgets);
    });

    testWidgets('mini player play/pause button toggles state without navigating away', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: NexaPlayerApp(),
        ),
      );
      await tester.pumpAndSettle();

      final playPauseFinder = find.byKey(const ValueKey('mini_player_play_pause'));
      expect(playPauseFinder, findsOneWidget);

      // Initially playing, so shows pause icon
      expect(find.byIcon(Icons.pause_circle_filled_rounded), findsOneWidget);

      // Tap to toggle
      await tester.tap(playPauseFinder);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.play_circle_fill_rounded), findsOneWidget);
    });

    testWidgets('responsive layout renders navigation rail on wide desktop viewports', (tester) async {
      tester.view.physicalSize = const Size(1200 * 2.0, 800 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: NexaPlayerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('navigation_rail')), findsOneWidget);
      expect(find.byKey(const ValueKey('glass_bottom_nav')), findsNothing);
      expect(find.byKey(const ValueKey('mini_player_slot')), findsOneWidget);
    });
  });
}
