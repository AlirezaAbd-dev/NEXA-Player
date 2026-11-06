import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'e2e_test_helpers.dart';

void main() {
  group('Tier 3: Cross-Feature Combinations (Pairwise Matrix)', () {
    testWidgets('T3.1: Midnight Black + Compact (390dp) + Songs tab + Empty Player', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 0,
          initialPreset: 'midnightBlack',
          initialThemeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.navigationRail), findsNothing);
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget);
      expect(find.byKey(E2EKeys.trackTile), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.2: Sakura + Expanded (1200dp) + Artists tab + Light Mode', (tester) async {
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 2,
          initialPreset: 'sakura',
          initialThemeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFFFF5F7)));

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);
      expect(find.byKey(E2EKeys.artistCard), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.3: Ocean Blue + Medium (720dp) + Albums tab + Dark Mode', (tester) async {
      await E2ETestHarness.setMediumTabletSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 1,
          initialPreset: 'oceanBlue',
          initialThemeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0B192C)));

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.albumCard), findsOneWidget);
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.4: Custom HSL + Compact (390dp) + Settings tab + Live Color Update', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 4,
          initialPreset: 'midnightBlack',
          initialThemeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save Custom Theme
      await tester.tap(find.byKey(E2EKeys.hslSaveButton));
      await tester.pumpAndSettle();

      final state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.activePresetName, equals('custom'));
      expect(state.mockStorage['theme_preset'], equals('custom'));
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.5: Daylight + Expanded (1200dp) + Settings tab + Light Mode', (tester) async {
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 4,
          initialPreset: 'daylight',
          initialThemeMode: ThemeMode.light,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFFF8FAFC)));

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.themeModeLight), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.6: Lava + Expanded (1200dp) + Songs tab + Dark Mode', (tester) async {
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 0,
          initialPreset: 'lava',
          initialThemeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF150806)));

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.trackTile), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.7: Forest Green + Compact (390dp) + Playlists tab + Dark Mode', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 3,
          initialPreset: 'forestGreen',
          initialThemeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0B170E)));

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.text('Playlists Screen'), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T3.8: Neon Purple + Medium (720dp) + Artists tab + Dark Mode', (tester) async {
      await E2ETestHarness.setMediumTabletSize(tester);
      await tester.pumpWidget(
        const NexaE2ETestApp(
          initialTab: 2,
          initialPreset: 'neonPurple',
          initialThemeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      expect(scaffold.backgroundColor, equals(const Color(0xFF0F071A)));

      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.artistCard), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });
  });
}
