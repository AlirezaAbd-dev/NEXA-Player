import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'e2e_test_helpers.dart';

void main() {
  group('Tier 4: Real-World Application Scenarios', () {
    testWidgets('Scenario 1: Fresh Install & Cold Boot Journey', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);

      // 1. Boot app with clean defaults
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      final state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));

      // 2. Asserts initial tab is Songs (0)
      expect(state.currentTab, equals(0));
      expect(find.text('Songs'), findsWidgets);

      // 3. Asserts default theme is Midnight Black (AMOLED #000000)
      expect(state.activePresetName, equals('midnightBlack'));
      expect(state.activeThemeMode, equals(ThemeMode.dark));
      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));

      // 4. Asserts MiniPlayerSlot and GlassBottomNav are visible
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.navigationRail), findsNothing);

      // 5. Asserts zero layout overflows
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('Scenario 2: Personalization & Theme Customization Journey with Persistence', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);

      // 1. User starts on Songs tab
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 0));
      await tester.pumpAndSettle();

      // 2. User navigates to Settings tab
      await tester.tap(find.byKey(E2EKeys.tabSettings));
      await tester.pumpAndSettle();

      var state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.currentTab, equals(4));

      // 3. User selects Ocean Blue preset
      await tester.tap(find.byKey(E2EKeys.themeCardOceanBlue));
      await tester.pumpAndSettle();

      state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.activePresetName, equals('oceanBlue'));
      expect(state.mockStorage['theme_preset'], equals('oceanBlue'));
      var scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0B192C)));

      // 4. User toggles brightness mode to Light
      await tester.tap(find.byKey(E2EKeys.themeModeLight));
      await tester.pumpAndSettle();

      state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.activeThemeMode, equals(ThemeMode.light));
      expect(state.mockStorage['theme_mode'], equals('light'));
      scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFF0F9FF)));

      // 5. User navigates back to Songs tab
      await tester.tap(find.byKey(E2EKeys.tabSongs));
      await tester.pumpAndSettle();
      expect(state.currentTab, equals(0));

      // 6. Simulate app restart with persisted state
      final savedPreset = state.mockStorage['theme_preset'] as String;
      final savedMode = state.mockStorage['theme_mode'] == 'light' ? ThemeMode.light : ThemeMode.dark;

      await tester.pumpWidget(
        NexaE2ETestApp(
          key: const ValueKey('restarted_app'),
          initialPreset: savedPreset,
          initialThemeMode: savedMode,
        ),
      );
      await tester.pumpAndSettle();

      final restartedScaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(restartedScaffold.backgroundColor, equals(const Color(0xFFF0F9FF)));
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('Scenario 3: Custom HSL Palette Authoring Journey', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);

      // 1. User navigates directly to Settings
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 4));
      await tester.pumpAndSettle();

      // 2. User adjusts HSL slider and taps Save Custom Theme
      expect(find.byKey(E2EKeys.hslHueSlider), findsOneWidget);
      await tester.tap(find.byKey(E2EKeys.hslSaveButton));
      await tester.pumpAndSettle();

      final state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.activePresetName, equals('custom'));
      expect(state.mockStorage['theme_preset'], equals('custom'));

      // 3. User navigates to Songs tab
      await tester.tap(find.byKey(E2EKeys.tabSongs));
      await tester.pumpAndSettle();

      expect(state.currentTab, equals(0));
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('Scenario 4: Responsive Window Resize & Device Rotation Journey', (tester) async {
      // 1. Initial Phone Portrait (390 x 844dp)
      await E2ETestHarness.setViewport(tester, width: 390.0, height: 844.0);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 1)); // Albums tab
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.navigationRail), findsNothing);
      expect(find.byKey(E2EKeys.albumCard), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);

      // 2. Rotate to Phone Landscape (844 x 390dp)
      await E2ETestHarness.setViewport(tester, width: 844.0, height: 390.0);
      await tester.pumpAndSettle();

      // At 844dp width (> 600dp), NavigationRail is rendered
      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);
      E2ETestHarness.expectNoOverflow(tester);

      // 3. Expand to Desktop Window (1200 x 800dp)
      await E2ETestHarness.setViewport(tester, width: 1200.0, height: 800.0);
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);
      expect(find.byKey(E2EKeys.albumCard), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('Scenario 5: Mini-Player Docking & Fullscreen Player Navigation Journey', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);

      // 1. User starts on Albums tab
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 1));
      await tester.pumpAndSettle();

      // 2. MiniPlayerSlot is docked above bottom nav
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);

      // 3. User taps MiniPlayerSlot to expand full player
      await tester.tap(find.byKey(E2EKeys.miniPlayerSlot));
      await tester.pumpAndSettle();

      // 4. Asserts NowPlaying screen covers the entire view; shell navigation is hidden
      final state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.isNowPlayingOpen, isTrue);
      expect(find.byKey(const ValueKey('now_playing_screen')), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsNothing);

      // 5. User taps back button
      await tester.tap(find.byKey(const ValueKey('now_playing_back_button')));
      await tester.pumpAndSettle();

      // 6. Asserts returned to Albums tab with shell navigation restored
      expect(state.isNowPlayingOpen, isFalse);
      expect(state.currentTab, equals(1));
      expect(find.byKey(const ValueKey('now_playing_screen')), findsNothing);
      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });
  });
}
