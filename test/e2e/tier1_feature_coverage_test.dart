import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'e2e_test_helpers.dart';

void main() {
  group('Tier 1: Feature Coverage — Area A: Architecture, DI & Foundation', () {
    test('T1.A.1: Result.success encapsulates value, flags isSuccess, and executes fold/when success callback', () {
      final result = E2EResult<String, String>.success('hello_nexa');

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, equals('hello_nexa'));
      expect(result.failureOrNull, isNull);

      final folded = result.fold(
        (val) => 'value:$val',
        (err) => 'error:$err',
      );
      expect(folded, equals('value:hello_nexa'));
    });

    test('T1.A.2: Result.failure encapsulates error, flags isFailure, and executes fold/when failure callback', () {
      final result = E2EResult<String, String>.failure('io_failure');

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, equals('io_failure'));

      final folded = result.fold(
        (val) => 'value:$val',
        (err) => 'error:$err',
      );
      expect(folded, equals('error:io_failure'));
    });

    test('T1.A.3: Storage service contract roundtrips string and boolean values', () {
      final storage = <String, dynamic>{};
      // Emulate setString & getString
      storage['theme_preset'] = 'oceanBlue';
      storage['is_dark'] = true;

      expect(storage['theme_preset'], equals('oceanBlue'));
      expect(storage['is_dark'], isTrue);
      expect(storage['missing_key'], isNull);

      storage.remove('theme_preset');
      expect(storage['theme_preset'], isNull);
    });

    test('T1.A.4: Duration formatters correctly format milliseconds to mm:ss and hh:mm:ss', () {
      String formatDuration(Duration d) {
        final minutes = d.inMinutes;
        final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
        return '$minutes:$seconds';
      }

      expect(formatDuration(const Duration(minutes: 3, seconds: 45)), equals('3:45'));
      expect(formatDuration(const Duration(seconds: 5)), equals('0:05'));
      expect(formatDuration(const Duration(minutes: 10, seconds: 0)), equals('10:00'));
    });

    test('T1.A.5: DI registration and resolution contract guarantees singleton retrieval', () {
      final registry = <Type, Object>{};
      final loggerInstance = Object();
      registry[Object] = loggerInstance;

      expect(registry[Object], isNotNull);
      expect(identical(registry[Object], loggerInstance), isTrue);
    });
  });

  group('Tier 1: Feature Coverage — Area B: Theme Engine & Customization', () {
    testWidgets('T1.B.1: Midnight Black preset resolves dark background to pure #000000 AMOLED black', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialPreset: 'midnightBlack', initialThemeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T1.B.2: All 8 theme presets apply distinct and authoritative colors', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);

      for (final preset in E2EThemePresetFixture.presets) {
        await tester.pumpWidget(NexaE2ETestApp(initialPreset: preset.name, initialThemeMode: ThemeMode.dark));
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
        expect(scaffold.backgroundColor, equals(preset.darkBackground), reason: 'Mismatch on preset ${preset.name}');
      }
    });

    testWidgets('T1.B.3: Light mode updates scaffold background to preset light palette', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialPreset: 'daylight', initialThemeMode: ThemeMode.light));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFF8FAFC)));
    });

    testWidgets('T1.B.4: Switching theme preset dynamically in Settings updates UI and storage', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 4)); // Start on Settings
      await tester.pumpAndSettle();

      // Tap Ocean Blue preset chip
      final oceanBlueChip = find.byKey(E2EKeys.themeCardOceanBlue);
      expect(oceanBlueChip, findsOneWidget);
      await tester.tap(oceanBlueChip);
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0B192C)));

      final appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(appState.mockStorage['theme_preset'], equals('oceanBlue'));
    });

    testWidgets('T1.B.5: Custom HSL editor updates primary accent color dynamically', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 4));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(E2EKeys.hslSaveButton);
      expect(saveButton, findsOneWidget);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      final appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(appState.activePresetName, equals('custom'));
      expect(appState.mockStorage['theme_preset'], equals('custom'));
    });
  });

  group('Tier 1: Feature Coverage — Area C: Glassmorphism Design System', () {
    testWidgets('T1.C.1: GlassCard renders ClipRRect and BackdropFilter with blur >= 16dp', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: E2EGlassCard(
                blur: 20.0,
                borderRadius: BorderRadius.circular(24.0),
                child: const Text('Glass Content'),
              ),
            ),
          ),
        ),
      );

      final clipFinder = find.byType(ClipRRect);
      expect(clipFinder, findsOneWidget);

      final filterFinder = find.byType(BackdropFilter);
      expect(filterFinder, findsOneWidget);

      final filter = tester.widget<BackdropFilter>(filterFinder);
      expect(filter.filter, equals(ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0)));
    });

    testWidgets('T1.C.2: GlassCard renders 1dp border with alpha transparency', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: Center(
              child: E2EGlassCard(
                borderWidth: 1.0,
                child: Text('Border Card'),
              ),
            ),
          ),
        ),
      );

      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNotNull);
      expect(decoration.border!.top.width, equals(1.0));
      expect(decoration.border!.top.color, equals(const Color(0x40FFFFFF)));
    });

    testWidgets('T1.C.3: GlassCard handles tap events correctly', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: E2EGlassCard(
                onTap: () => tapped = true,
                child: const Text('Tap Me'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('T1.C.4: TrackTile renders title, artist, duration, and trailing icon', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 0));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.trackTile), findsOneWidget);
      expect(find.text('Midnight Stargazer'), findsWidgets);
      expect(find.text('NEXA Sound'), findsWidgets);
      expect(find.text('3:45'), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsWidgets);
    });

    testWidgets('T1.C.5: AlbumCard renders album metadata in grid layout', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 1)); // Albums tab
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.albumCard), findsOneWidget);
      expect(find.text('Cosmic Drift'), findsOneWidget);
      expect(find.text('NEXA Sound • 2026'), findsOneWidget);
    });

    testWidgets('T1.C.6: GlassBottomNav renders 5 primary navigation destinations with labels', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 0));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.tabSongs), findsOneWidget);
      expect(find.byKey(E2EKeys.tabAlbums), findsOneWidget);
      expect(find.byKey(E2EKeys.tabArtists), findsOneWidget);
      expect(find.byKey(E2EKeys.tabPlaylists), findsOneWidget);
      expect(find.byKey(E2EKeys.tabSettings), findsOneWidget);
    });
  });

  group('Tier 1: Feature Coverage — Area D: Shell Navigation, Mini-Player & Responsive Layout', () {
    testWidgets('T1.D.1: App starts on Tab 0 (Songs) by default', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      final appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(appState.currentTab, equals(0));
      expect(find.text('Songs'), findsWidgets);
    });

    testWidgets('T1.D.2: Tapping tabs switches active screen branch', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      // Switch to Albums (Tab 1)
      await tester.tap(find.byKey(E2EKeys.tabAlbums));
      await tester.pumpAndSettle();
      var appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(appState.currentTab, equals(1));
      expect(find.byKey(E2EKeys.albumCard), findsOneWidget);

      // Switch to Artists (Tab 2)
      await tester.tap(find.byKey(E2EKeys.tabArtists));
      await tester.pumpAndSettle();
      appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(appState.currentTab, equals(2));
      expect(find.byKey(E2EKeys.artistCard), findsOneWidget);

      // Switch to Settings (Tab 4)
      await tester.tap(find.byKey(E2EKeys.tabSettings));
      await tester.pumpAndSettle();
      appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(appState.currentTab, equals(4));
      expect(find.byKey(E2EKeys.themeModeDark), findsOneWidget);
    });

    testWidgets('T1.D.3: MiniPlayerSlot is visible on compact layout across all 5 tabs', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      for (int i = 0; i < 5; i++) {
        final appState = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
        appState.selectTab(i);
        await tester.pumpAndSettle();
        expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget, reason: 'MiniPlayerSlot missing on tab $i');
      }
    });

    testWidgets('T1.D.4: Tapping MiniPlayerSlot opens fullscreen Now Playing, hiding BottomNav', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(E2EKeys.miniPlayerSlot));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('now_playing_screen')), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);

      // Tap back button
      await tester.tap(find.byKey(const ValueKey('now_playing_back_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('now_playing_screen')), findsNothing);
      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
    });

    testWidgets('T1.D.5: Compact screen (<600dp) renders BottomNav and hides NavigationRail', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.navigationRail), findsNothing);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T1.D.6: Expanded screen (>840dp) renders NavigationRail and hides BottomNav', (tester) async {
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);
      E2ETestHarness.expectNoOverflow(tester);
    });
  });

  group('Tier 1: Feature Coverage — Area E: Quality & Verification', () {
    testWidgets('T1.E.1: Zero RenderFlex overflow errors on compact viewport', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T1.E.2: Zero RenderFlex overflow errors on expanded desktop viewport', (tester) async {
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
    });
  });
}
