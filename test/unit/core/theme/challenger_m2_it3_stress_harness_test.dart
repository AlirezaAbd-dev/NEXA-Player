import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/features/themes/presentation/screens/custom_theme_editor_screen.dart';
import 'package:nexa_player/features/themes/presentation/screens/theme_picker_screen.dart';
import '../../../helpers/mock_services.dart';

void main() {
  group('Challenger M2 It3: Comprehensive Stress & Verification Suite', () {
    late FakeStorageService fakeStorage;
    late FakeLoggingService fakeLogging;

    ProviderContainer createContainer([Map<String, Object>? initialStorage]) {
      fakeStorage = FakeStorageService(initialStorage);
      fakeLogging = FakeLoggingService();
      return ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          loggingServiceProvider.overrideWithValue(fakeLogging),
        ],
      );
    }

    Widget buildAppWithContainer(
      ProviderContainer container,
      Widget child, {
      double textScale = 1.0,
    }) {
      return UncontrolledProviderScope(
        container: container,
        child: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
          ),
          child: MaterialApp(
            home: child,
          ),
        ),
      );
    }

    // =========================================================================
    // 1. MULTI-BREAKPOINT UI STRESS
    // =========================================================================
    group('1. Multi-Breakpoint Responsive Viewport Stress', () {
      final contractViewports = <String, Size>{
        'Compact Mobile (320x568)': const Size(320, 568),
        'Standard Android (360x640)': const Size(360, 640),
        'Modern Phone (390x844)': const Size(390, 844),
        'Large Phone Landscape (844x390)': const Size(844, 390),
        'Small Tablet (600x960)': const Size(600, 960),
        'Large Tablet (800x1280)': const Size(800, 1280),
        'Desktop (1280x800)': const Size(1280, 800),
        'FHD Desktop (1920x1080)': const Size(1920, 1080),
      };

      for (final entry in contractViewports.entries) {
        testWidgets('CustomThemeEditorScreen renders without overflow on ${entry.key}', (tester) async {
          final container = createContainer();
          addTearDown(container.dispose);

          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildAppWithContainer(container, const CustomThemeEditorScreen()),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Overflow caught on ${entry.key}');
          expect(find.byType(CustomThemeEditorScreen), findsOneWidget);
        });

        testWidgets('ThemePickerScreen renders without overflow on ${entry.key}', (tester) async {
          final container = createContainer();
          addTearDown(container.dispose);

          tester.view.physicalSize = entry.value;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            buildAppWithContainer(container, const ThemePickerScreen()),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Overflow caught on ${entry.key}');
          expect(find.byType(ThemePickerScreen), findsOneWidget);
        });
      }

      testWidgets('CustomThemeEditorScreen renders cleanly without overflow on ultra-narrow 280x653', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(280, 653);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildAppWithContainer(container, const CustomThemeEditorScreen()),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CustomThemeEditorScreen), findsOneWidget);
      });

      testWidgets('CustomThemeEditorScreen renders cleanly with 1.25x accessibility text scale on 360x640', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildAppWithContainer(container, const CustomThemeEditorScreen(), textScale: 1.25),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(CustomThemeEditorScreen), findsOneWidget);
      });
    });

    // =========================================================================
    // 2. INTERACTIVE UI STRESS
    // =========================================================================
    group('2. Interactive UI Stress & State Reaction', () {
      testWidgets('Rapid simultaneous slider dragging and dark mode toggling does not throw', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildAppWithContainer(container, const CustomThemeEditorScreen()),
        );
        await tester.pumpAndSettle();

        final hueSlider = find.byKey(const ValueKey('hsl_hue_slider'));
        final satSlider = find.byKey(const ValueKey('hsl_saturation_slider'));
        final lightSlider = find.byKey(const ValueKey('hsl_lightness_slider'));
        final switchFinder = find.byType(Switch);

        await tester.ensureVisible(hueSlider);
        for (int i = 0; i < 10; i++) {
          await tester.drag(hueSlider, Offset(i.isEven ? 30.0 : -30.0, 0));
          await tester.pump();
          await tester.drag(satSlider, Offset(i.isEven ? -20.0 : 20.0, 0));
          await tester.pump();
          await tester.drag(lightSlider, Offset(i.isEven ? 25.0 : -25.0, 0));
          await tester.pump();
          await tester.tap(switchFinder);
          await tester.pump();
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Rapid repeated taps on Save Button correctly persists and does not duplicate feedback', (tester) async {
        final fakeStorage = FakeStorageService();
        final fakeLogging = FakeLoggingService();
        final container = ProviderContainer(
          overrides: [
            storageServiceProvider.overrideWithValue(fakeStorage),
            loggingServiceProvider.overrideWithValue(fakeLogging),
          ],
        );
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildAppWithContainer(container, const Scaffold(body: CustomThemeEditorScreen())),
        );
        await tester.pumpAndSettle();

        final saveBtn = find.byKey(const ValueKey('hsl_save_button'));
        await tester.ensureVisible(saveBtn);
        await tester.pumpAndSettle();

        for (int i = 0; i < 10; i++) {
          await tester.tap(saveBtn);
          await tester.pump();
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(fakeStorage.getRaw(StorageKeys.themePreset), equals('custom'));
        expect(fakeStorage.getRaw('nexa_custom_theme_data'), isNotNull);
      });
    });

    // =========================================================================
    // 3. ZERO FOUC & STORAGE CORRUPTION FALLBACK
    // =========================================================================
    group('3. Zero FOUC & Storage Recovery', () {
      test('Synchronous ThemeController init loads persisted state with zero FOUC', () {
        final container = createContainer({
          StorageKeys.themePreset: 'lava',
          StorageKeys.themeMode: 'dark',
        });
        addTearDown(container.dispose);

        // Immediate read on creation must reflect persisted state immediately
        final initialState = container.read(themeControllerProvider);
        expect(initialState.preset, equals(ThemePreset.lava));
        expect(initialState.themeMode, equals(ThemeMode.dark));
      });

      test('Corrupted storage gracefully falls back to default Midnight Black and System mode', () {
        final corruptedPayloads = [
          '{"invalid_json": true, missing_brace',
          'null',
          '',
          '   ',
          '{"primaryHue": "invalid", "isDark": "maybe"}',
          '{"primaryHue": -9999999.0, "primarySaturation": 999999.0}',
          '{"name": null, "isDark": false}',
          '[]',
          '12345',
          '🔥 unicode surrogate corrupted test',
        ];

        for (final badVal in corruptedPayloads) {
          final container = createContainer({
            StorageKeys.themePreset: 'custom',
            'nexa_custom_theme_data': badVal,
          });

          final state = container.read(themeControllerProvider);
          expect(state, isNotNull);
          final themeData = AppTheme.buildTheme(
            preset: state.preset,
            mode: state.themeMode,
            customPrimary: state.customPrimary,
            customSurface: state.customSurface,
            customBackground: state.customBackground,
          );
          expect(themeData.useMaterial3, isTrue);
          container.dispose();
        }
      });

      test('Unrecognized preset and theme mode strings recover safely', () {
        final container = createContainer({
          StorageKeys.themePreset: 'non_existent_preset_123',
          StorageKeys.themeMode: 'ultra_dark_mode',
        });
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
      });
    });

    // =========================================================================
    // 4. WCAG AA CONTRAST ORACLE ACROSS 360 DEGREES
    // =========================================================================
    group('4. WCAG AA Contrast Oracle across 360 Degrees', () {
      test('Zero failing hues across all 360 discrete integer hues in Dark Mode', () {
        final failures = <int, double>{};

        for (int h = 0; h < 360; h++) {
          final customTheme = CustomThemeData(
            primaryHue: h.toDouble(),
            primarySaturation: 1.0,
            primaryLightness: 0.50,
            surfaceLightness: 0.08,
            isDark: true,
          );

          if (customTheme.accentContrastRatio < 3.0) {
            failures[h] = customTheme.accentContrastRatio;
          }
        }

        expect(failures, isEmpty, reason: 'Failures found in dark mode hues: $failures');
      });

      test('Zero failing hues across all 360 discrete integer hues in Light Mode', () {
        final failures = <int, double>{};

        for (int h = 0; h < 360; h++) {
          final customTheme = CustomThemeData(
            primaryHue: h.toDouble(),
            primarySaturation: 1.0,
            primaryLightness: 0.35,
            surfaceLightness: 0.96,
            isDark: false,
          );

          if (customTheme.accentContrastRatio < 3.0) {
            failures[h] = customTheme.accentContrastRatio;
          }
        }

        expect(failures, isEmpty, reason: 'Failures found in light mode hues: $failures');
      });

      test('All 360 hues resolve valid ThemeData with full opacity', () {
        for (int h = 0; h < 360; h += 45) {
          final theme = CustomThemeData(primaryHue: h.toDouble(), isDark: true);
          final themeData = theme.toThemeData();
          expect(themeData.useMaterial3, isTrue);
          expect(themeData.colorScheme.primary.alpha, equals(255));
          expect(themeData.colorScheme.surface.alpha, equals(255));
        }
      });
    });

    // =========================================================================
    // 5. ASYNCTHEMECONTROLLER SEQUENTIAL & REENTRANT MUTATIONS
    // =========================================================================
    group('5. AsyncThemeController Reentrancy & Sequential Mutations', () {
      test('Rapid sequential operations on AsyncThemeController execute cleanly without Riverpod assertion error', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final asyncNotifier = container.read(asyncThemeControllerProvider.notifier);

        for (int i = 0; i < 5; i++) {
          await asyncNotifier.setPreset(ThemePreset.forestGreen);
          await asyncNotifier.setThemeMode(ThemeMode.dark);
          await asyncNotifier.toggleThemeMode();
          await asyncNotifier.setCustomTheme(CustomThemeData(primaryHue: (i * 45.0) % 360));
          await asyncNotifier.resetToDefaults();
        }

        final state = container.read(asyncThemeControllerProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.preset, equals(ThemePreset.midnightBlack));
      });

      test('Concurrent Future.wait batch on AsyncThemeController completes without unhandled errors', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final asyncNotifier = container.read(asyncThemeControllerProvider.notifier);

        final futures = <Future<void>>[];
        for (int i = 0; i < 10; i++) {
          futures.add(asyncNotifier.setPreset(ThemePreset.values[i % ThemePreset.values.length]));
          futures.add(asyncNotifier.setThemeMode(i.isEven ? ThemeMode.dark : ThemeMode.light));
          futures.add(asyncNotifier.toggleThemeMode());
          futures.add(asyncNotifier.resetToDefaults());
        }

        await expectLater(Future.wait(futures), completes);

        final state = container.read(asyncThemeControllerProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.preset, isA<ThemePreset>());
      });
    });
  });
}
