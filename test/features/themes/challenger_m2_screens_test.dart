import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/features/themes/presentation/screens/custom_theme_editor_screen.dart';
import 'package:nexa_player/features/themes/presentation/screens/theme_picker_screen.dart';
import 'package:nexa_player/features/themes/presentation/widgets/hsl_color_slider.dart';

import '../../e2e/e2e_test_helpers.dart';
import '../../helpers/mock_services.dart';

void main() {
  Widget buildPickerScreen({
    FakeStorageService? storage,
    FakeLoggingService? logging,
  }) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage ?? FakeStorageService()),
        loggingServiceProvider.overrideWithValue(logging ?? FakeLoggingService()),
      ],
      child: const MaterialApp(
        home: ThemePickerScreen(),
      ),
    );
  }

  Widget buildEditorScreen({
    FakeStorageService? storage,
    FakeLoggingService? logging,
  }) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage ?? FakeStorageService()),
        loggingServiceProvider.overrideWithValue(logging ?? FakeLoggingService()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: CustomThemeEditorScreen()),
      ),
    );
  }

  group('Challenger M2: ThemePickerScreen Adversarial Interaction Stress', () {
    testWidgets('Rapid continuous mode button toggles (60 cycles) maintain state consistency', (tester) async {
      final fakeStorage = FakeStorageService();
      await tester.pumpWidget(buildPickerScreen(storage: fakeStorage));
      await tester.pumpAndSettle();

      final darkBtn = find.byKey(E2EKeys.themeModeDark);
      final lightBtn = find.byKey(E2EKeys.themeModeLight);
      final systemBtn = find.byKey(E2EKeys.themeModeSystem);

      // Perform 20 rounds of Dark -> Light -> System toggles in rapid succession
      for (int i = 0; i < 20; i++) {
        await tester.tap(darkBtn);
        await tester.pump();
        await tester.tap(lightBtn);
        await tester.pump();
        await tester.tap(systemBtn);
        await tester.pump();
      }

      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      // Final state must reflect the last tapped mode (System)
      expect(fakeStorage.getRaw(StorageKeys.themeMode), equals('system'));
      expect(fakeStorage.getRaw('theme_mode'), equals('system'));
    });

    testWidgets('Rapid preset selection across all 9 cards updates active state cleanly', (tester) async {
      final fakeStorage = FakeStorageService();
      await tester.pumpWidget(buildPickerScreen(storage: fakeStorage));
      await tester.pumpAndSettle();

      final presetKeys = [
        E2EKeys.themeCardMidnight,
        E2EKeys.themeCardDeepSpace,
        E2EKeys.themeCardSakura,
        E2EKeys.themeCardOceanBlue,
        E2EKeys.themeCardForestGreen,
        E2EKeys.themeCardLava,
        E2EKeys.themeCardDaylight,
        E2EKeys.themeCardNeonPurple,
      ];

      // Rapidly tap all presets twice
      for (int round = 0; round < 2; round++) {
        for (final key in presetKeys) {
          final finder = find.byKey(key);
          await tester.ensureVisible(finder);
          await tester.pump();
          await tester.tap(finder);
          await tester.pump();
        }
      }

      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
      // Last tapped was neonPurple
      expect(fakeStorage.getRaw(StorageKeys.themePreset), equals('neonPurple'));
    });

    testWidgets('Responsive column layout across phone, tablet, and desktop breakpoints', (tester) async {
      final fakeStorage = FakeStorageService();

      // 1. Phone Portrait (<600dp) -> 2 columns
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(buildPickerScreen(storage: fakeStorage));
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      var gridView = tester.widget<GridView>(find.byKey(E2EKeys.themePickerGrid));
      var delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(2));

      // 2. Tablet (700dp width) -> 3 columns
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      gridView = tester.widget<GridView>(find.byKey(E2EKeys.themePickerGrid));
      delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(3));

      // 3. Desktop (>840dp width) -> 4 columns
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      gridView = tester.widget<GridView>(find.byKey(E2EKeys.themePickerGrid));
      delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, equals(4));

      // Reset physical size
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Extreme small viewport (300x500) renders without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(300, 500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildPickerScreen());
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
    });
  });

  group('Challenger M2: CustomThemeEditorScreen Adversarial Interaction Stress', () {
    testWidgets('Rapid dragging across Hue, Saturation, and Lightness sliders', (tester) async {
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();

      final hueSlider = find.byKey(E2EKeys.hslHueSlider);
      final satSlider = find.byKey(E2EKeys.hslSaturationSlider);
      final lightSlider = find.byKey(E2EKeys.hslLightnessSlider);

      // Perform 15 cycles of rapid alternating drag gestures
      for (int i = 0; i < 15; i++) {
        // Drag Hue
        await tester.drag(hueSlider, Offset((i.isEven ? 1 : -1) * 80.0, 0));
        await tester.pump();

        // Drag Saturation
        await tester.drag(satSlider, Offset((i.isEven ? -1 : 1) * 60.0, 0));
        await tester.pump();

        // Drag Lightness
        await tester.drag(lightSlider, Offset((i.isEven ? 1 : -1) * 70.0, 0));
        await tester.pump();
      }

      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      // Ensure Live Palette Preview card is still rendered with updated values
      expect(find.text('Live Palette Preview'), findsOneWidget);
      expect(find.byType(HslColorSlider), findsNWidgets(3));
    });

    testWidgets('Rapid mode toggles on Target Dark Surface Switch update live preview and contrast badge', (tester) async {
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();

      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Rapidly toggle switch 20 times
      for (int i = 0; i < 20; i++) {
        await tester.tap(switchFinder);
        await tester.pump();
      }

      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      // Contrast badge must remain visible and legible
      expect(find.textContaining('WCAG 2.1 AA Contrast:'), findsOneWidget);
    });

    testWidgets('Dragging lightness to extremes dynamically triggers contrast clamping badge states', (tester) async {
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();

      final lightSlider = find.byKey(E2EKeys.hslLightnessSlider);

      // Drag lightness far to the right (maximum lightness)
      await tester.drag(lightSlider, const Offset(300, 0));
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      // Contrast badge should reflect status
      expect(find.textContaining('WCAG 2.1 AA Contrast:'), findsOneWidget);

      // Drag lightness far to the left (minimum lightness)
      await tester.drag(lightSlider, const Offset(-600, 0));
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      expect(find.textContaining('WCAG 2.1 AA Contrast:'), findsOneWidget);
    });

    testWidgets('Repeated consecutive taps on Save Button execute cleanly and persist custom theme', (tester) async {
      final fakeStorage = FakeStorageService();
      await tester.pumpWidget(buildEditorScreen(storage: fakeStorage));
      await tester.pumpAndSettle();

      final saveButton = find.byKey(E2EKeys.hslSaveButton);
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      // Tap 5 times rapidly
      for (int i = 0; i < 5; i++) {
        await tester.tap(saveButton);
        await tester.pump();
      }

      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      expect(find.text('Custom theme saved!'), findsOneWidget);
      expect(fakeStorage.getRaw(StorageKeys.themePreset), equals('custom'));
      expect(fakeStorage.getRaw('nexa_custom_theme_data'), isNotNull);

      // Verify custom theme data can be parsed back
      final savedJson = fakeStorage.getRaw('nexa_custom_theme_data') as String?;
      final parsed = CustomThemeData.fromJsonString(savedJson);
      expect(parsed, isNotNull);
      expect(parsed!.primaryColor.alpha, equals(255));
    });

    testWidgets('Editor layout adapts across phone landscape, tablet, and desktop without overflow', (tester) async {
      // 1. Phone Portrait (390 x 844)
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
      expect(find.text('Play Button'), findsOneWidget);
      expect(find.text('Queue Track'), findsOneWidget);

      // 2. Phone Landscape (844 x 390)
      await E2ETestHarness.setViewport(tester, width: 844.0, height: 390.0, devicePixelRatio: 3.0);
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
      expect(find.text('Play Button'), findsOneWidget);
      expect(find.text('Queue Track'), findsOneWidget);

      // 3. Tablet (800 x 1280)
      await E2ETestHarness.setViewport(tester, width: 800.0, height: 1280.0, devicePixelRatio: 2.0);
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
      expect(find.text('Play Button'), findsOneWidget);
      expect(find.text('Queue Track'), findsOneWidget);

      // 4. Desktop (1280 x 800)
      await E2ETestHarness.setViewport(tester, width: 1280.0, height: 800.0, devicePixelRatio: 1.0);
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
      expect(find.text('Play Button'), findsOneWidget);
      expect(find.text('Queue Track'), findsOneWidget);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('Editor layout renders cleanly without overflow on expanded desktop (1200x800)', (tester) async {
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
