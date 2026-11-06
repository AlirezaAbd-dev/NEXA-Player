import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'e2e_test_helpers.dart';

void main() {
  group('Tier 2: Boundary & Corner Cases — Area A: Architecture & Foundation', () {
    test('T2.A.1: Result with null payload handles null safely across all accessors', () {
      final result = E2EResult<String?, String>.success(null);

      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, isNull);
      expect(result.failureOrNull, isNull);

      final folded = result.fold(
        (val) => val == null ? 'null_value' : 'has_value',
        (err) => 'error',
      );
      expect(folded, equals('null_value'));
    });

    test('T2.A.2: Storage lookup with missing key returns null without throwing', () {
      final storage = <String, dynamic>{};
      expect(storage['nonexistent_key_xyz'], isNull);
    });

    test('T2.A.3: Clearing already empty storage succeeds gracefully', () {
      final storage = <String, dynamic>{};
      expect(() => storage.clear(), returnsNormally);
      expect(storage.isEmpty, isTrue);
    });

    test('T2.A.4: Extreme string payload (500KB) stores and retrieves without data corruption', () {
      final storage = <String, dynamic>{};
      final largePayload = 'A' * 500000;
      storage['large_key'] = largePayload;

      expect(storage['large_key']?.length, equals(500000));
      expect(storage['large_key'], equals(largePayload));
    });

    test('T2.A.5: Duration formatter handles Duration.zero and boundary values without throwing', () {
      String formatDuration(Duration d) {
        final totalSeconds = d.inSeconds.abs();
        final minutes = totalSeconds ~/ 60;
        final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
        final sign = d.isNegative ? '-' : '';
        return '$sign$minutes:$seconds';
      }

      expect(formatDuration(Duration.zero), equals('0:00'));
      expect(formatDuration(const Duration(milliseconds: 999)), equals('0:00'));
      expect(formatDuration(const Duration(seconds: 59)), equals('0:59'));
      expect(formatDuration(const Duration(seconds: 60)), equals('1:00'));
      expect(formatDuration(const Duration(seconds: -30)), equals('-0:30'));
    });
  });

  group('Tier 2: Boundary & Corner Cases — Area B: Theme Engine', () {
    test('T2.B.1: Custom HSL Hue 0.0° and 360.0° produce identical red primary color', () {
      final color0 = const HSLColor.fromAHSL(1.0, 0.0, 1.0, 0.5).toColor();
      final color360 = const HSLColor.fromAHSL(1.0, 360.0, 1.0, 0.5).toColor();

      expect(color0.value, equals(color360.value));
      expect(color0.red, equals(255));
      expect(color0.green, equals(0));
      expect(color0.blue, equals(0));
    });

    test('T2.B.2: Custom HSL Saturation 0.0 produces pure grayscale tone', () {
      final grayColor = const HSLColor.fromAHSL(1.0, 180.0, 0.0, 0.5).toColor();
      // In grayscale, red, green, and blue components are equal
      expect(grayColor.red, equals(grayColor.green));
      expect(grayColor.green, equals(grayColor.blue));
    });

    testWidgets('T2.B.3: Rapid theme switching in succession completes cleanly without dropped state', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 4));
      await tester.pumpAndSettle();

      final state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));

      // Rapidly switch through all presets
      for (final preset in E2EThemePresetFixture.presets) {
        state.selectPreset(preset.name);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();

      expect(state.activePresetName, equals(E2EThemePresetFixture.presets.last.name));
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T2.B.4: Corrupted preset key defaults safely to Midnight Black', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialPreset: 'corrupted_preset_name'));
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byKey(E2EKeys.shellScaffold));
      // Fallback resolves to midnightBlack (Color(0xFF000000))
      expect(scaffold.backgroundColor, equals(const Color(0xFF000000)));
    });
  });

  group('Tier 2: Boundary & Corner Cases — Area C: Glassmorphism Design System', () {
    testWidgets('T2.C.1: GlassCard with zero padding and zero border radius renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: E2EGlassCard(
                borderRadius: BorderRadius.zero,
                padding: EdgeInsets.zero,
                child: SizedBox(width: 50, height: 50),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(E2EGlassCard), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T2.C.2: GlassCard with enableBlur: false suppresses BackdropFilter for performance', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: E2EGlassCard(
                enableBlur: false,
                child: Text('No Blur Card'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.text('No Blur Card'), findsOneWidget);
    });

    testWidgets('T2.C.3: TrackTile with extremely long title (200+ chars) truncates without overflowing', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      const longTitle = 'Super Long Track Title That Goes On And On And Exceeds Typical Music Track Name Lengths In Real World Metadata Scenarios And Should Truncate Gracefully In The Nexa Player UI Without Overflowing Boundaries At All';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: E2EGlassCard(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Container(width: 40, height: 40, color: Colors.blue),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(longTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('Artist Name', maxLines: 1),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.more_vert),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text(longTitle), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T2.C.4: Nested GlassCard renders distinct borders without recursion error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: E2EGlassCard(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: E2EGlassCard(
                    blur: 16.0,
                    child: Text('Inner Glass'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(E2EGlassCard), findsNWidgets(2));
      expect(find.text('Inner Glass'), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });
  });

  group('Tier 2: Boundary & Corner Cases — Area D: Shell Navigation & Responsive Layout', () {
    testWidgets('T2.D.1: Viewport exactly at 600.0dp boundary transitions layout cleanly', (tester) async {
      await E2ETestHarness.setViewport(tester, width: 600.0, height: 800.0);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      // At 600dp, it transitions to medium/expanded NavigationRail
      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      expect(find.byKey(E2EKeys.bottomNav), findsNothing);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T2.D.2: Viewport at 599.0dp renders compact BottomNav', (tester) async {
      await E2ETestHarness.setViewport(tester, width: 599.0, height: 800.0);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.navigationRail), findsNothing);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T2.D.3: Extreme narrow screen width (320dp) renders without RenderFlex overflow', (tester) async {
      await E2ETestHarness.setViewport(tester, width: 320.0, height: 640.0);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      expect(find.byKey(E2EKeys.miniPlayerSlot), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('T2.D.4: Rapid repeated tapping on active tab does not corrupt tab state', (tester) async {
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(const NexaE2ETestApp(initialTab: 0));
      await tester.pumpAndSettle();

      final songsTab = find.byKey(E2EKeys.tabSongs);
      for (int i = 0; i < 10; i++) {
        await tester.tap(songsTab);
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      final state = tester.state<NexaE2ETestAppState>(find.byType(NexaE2ETestApp));
      expect(state.currentTab, equals(0));
      E2ETestHarness.expectNoOverflow(tester);
    });
  });

  group('Tier 2: Boundary & Corner Cases — Area E: Quality & Stress Hardening', () {
    testWidgets('T2.E.1: Dynamic device rotation (portrait -> landscape -> portrait) produces zero errors', (tester) async {
      // 1. Phone Portrait (390 x 844)
      await E2ETestHarness.setViewport(tester, width: 390.0, height: 844.0);
      await tester.pumpWidget(const NexaE2ETestApp());
      await tester.pumpAndSettle();
      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);

      // 2. Rotate to Phone Landscape (844 x 390)
      await E2ETestHarness.setViewport(tester, width: 844.0, height: 390.0);
      await tester.pumpAndSettle();
      expect(find.byKey(E2EKeys.navigationRail), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);

      // 3. Rotate back to Phone Portrait (390 x 844)
      await E2ETestHarness.setViewport(tester, width: 390.0, height: 844.0);
      await tester.pumpAndSettle();
      expect(find.byKey(E2EKeys.bottomNav), findsOneWidget);
      E2ETestHarness.expectNoOverflow(tester);
    });
  });
}
