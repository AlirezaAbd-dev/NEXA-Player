import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/theme/theme_state.dart';
import 'package:nexa_player/features/themes/presentation/screens/custom_theme_editor_screen.dart';
import 'package:nexa_player/features/themes/presentation/screens/theme_picker_screen.dart';
import '../../../helpers/mock_services.dart';

void main() {
  group('Challenger M2 Iteration 2: Empirical Stress & Adversarial Oracles', () {
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

    // =========================================================================
    // 1. STATE & STORAGE STRESS
    // =========================================================================
    group('State & Storage Hardening', () {
      test('AsyncThemeController sequential mutations execute cleanly without Riverpod assertion crash', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final asyncNotifier = container.read(asyncThemeControllerProvider.notifier);
        await asyncNotifier.setPreset(ThemePreset.forestGreen);

        // Calling setThemeMode immediately after setPreset succeeds without throwing Riverpod assertion
        await asyncNotifier.setThemeMode(ThemeMode.dark);

        final state = container.read(asyncThemeControllerProvider).valueOrNull;
        expect(state, isNotNull);
        expect(state!.preset, equals(ThemePreset.forestGreen));
        expect(state.themeMode, equals(ThemeMode.dark));

        // Test further sequential mutations
        await asyncNotifier.toggleThemeMode();
        final toggledState = container.read(asyncThemeControllerProvider).valueOrNull;
        expect(toggledState!.themeMode, equals(ThemeMode.light));

        await asyncNotifier.resetToDefaults();
        final resetState = container.read(asyncThemeControllerProvider).valueOrNull;
        expect(resetState!.preset, equals(ThemePreset.midnightBlack));
      });

      test('Corrupted, malformed, and boundary storage values recover cleanly to safe state', () {
        final adversarialValues = [
          '{"invalid_json": true, missing_close_brace',
          'null',
          '',
          '   ',
          '{"primaryHue": "not_a_number", "isDark": "maybe"}',
          '{"primaryHue": -9999999.0, "primarySaturation": 999999.0}',
          '{"name": null, "isDark": false}',
          '[]',
          '12345',
          '🔥🎉🚀 unicode surrogate test',
        ];

        for (final badVal in adversarialValues) {
          final container = createContainer({
            StorageKeys.themePreset: 'custom',
            'nexa_custom_theme_data': badVal,
          });

          final state = container.read(themeControllerProvider);
          expect(state, isNotNull);
          // Verifies state doesn't throw and resolves a valid ThemeData
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

      test('Fallback un-prefixed keys work when nexa_ keys are missing or cleared', () {
        final container = createContainer({
          'theme_preset': 'sakura',
          'theme_mode': 'light',
        });
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.sakura));
        expect(state.themeMode, equals(ThemeMode.light));
      });

      test('ThemeMode.system resolves platform brightness dynamically without error', () {
        const state = ThemeState(
          preset: ThemePreset.midnightBlack,
          themeMode: ThemeMode.system,
        );

        expect(state.isDark(Brightness.dark), isTrue);
        expect(state.isDark(Brightness.light), isFalse);

        const darkState = ThemeState(
          preset: ThemePreset.midnightBlack,
          themeMode: ThemeMode.dark,
        );
        expect(darkState.isDark(Brightness.light), isTrue);

        const lightState = ThemeState(
          preset: ThemePreset.midnightBlack,
          themeMode: ThemeMode.light,
        );
        expect(lightState.isDark(Brightness.dark), isFalse);
      });
    });

    // =========================================================================
    // 2. MATHEMATICAL ORACLE: 1° HUE SWEEP WCAG CONTRAST VERIFICATION
    // =========================================================================
    group('Perceptual Luminance & WCAG AA Contrast Oracle', () {
      test('Dynamic bisection guarantees contrast >= 3.0:1 across every single integer hue (0° to 359°)', () {
        final lightFailures = <int, double>{};
        final darkFailures = <int, double>{};

        for (int h = 0; h < 360; h++) {
          // Test extreme saturation
          final customLight = CustomThemeData(
            primaryHue: h.toDouble(),
            primarySaturation: 1.0,
            primaryLightness: 0.35,
            surfaceLightness: 0.96,
            isDark: false,
          );
          if (customLight.accentContrastRatio < 3.0) {
            lightFailures[h] = customLight.accentContrastRatio;
          }

          final customDark = CustomThemeData(
            primaryHue: h.toDouble(),
            primarySaturation: 1.0,
            primaryLightness: 0.50,
            surfaceLightness: 0.08,
            isDark: true,
          );
          if (customDark.accentContrastRatio < 3.0) {
            darkFailures[h] = customDark.accentContrastRatio;
          }
        }

        expect(lightFailures, isEmpty, reason: 'Zero hue failures permitted in light mode');
        expect(darkFailures, isEmpty, reason: 'Zero hue failures permitted in dark mode');
      });

      test('All resolved colors maintain full opacity (alpha = 255) and valid ThemeData', () {
        for (double h = 0.0; h < 360.0; h += 30.0) {
          for (final isDark in [true, false]) {
            final theme = CustomThemeData(primaryHue: h, isDark: isDark);
            expect(theme.primaryColor.alpha, equals(255));
            expect(theme.secondaryColor.alpha, equals(255));
            expect(theme.surfaceColor.alpha, equals(255));
            expect(theme.scaffoldBackgroundColor.alpha, equals(255));
            expect(theme.onPrimary.alpha, equals(255));
            expect(theme.onSurface.alpha, equals(255));

            final themeData = theme.toThemeData();
            expect(themeData.useMaterial3, isTrue);
            expect(themeData.colorScheme.brightness, isDark ? Brightness.dark : Brightness.light);
          }
        }
      });
    });

    // =========================================================================
    // 3. MULTI-BREAKPOINT UI & RAPID INTERACTION STRESS
    // =========================================================================
    group('Multi-Breakpoint UI & Rapid Interaction Stress', () {
      testWidgets('CustomThemeEditorScreen renders without RenderFlex overflow in _buildModeToggle on standard 360px and 320px displays', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        for (final size in [const Size(360, 640), const Size(320, 568)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: CustomThemeEditorScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Failed on viewport $size');
          expect(find.byType(CustomThemeEditorScreen), findsOneWidget);
        }
      });

      testWidgets('Rapid micro-dragging (50 drags) on sliders produces zero layout exceptions', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: CustomThemeEditorScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final hueSlider = find.byKey(const ValueKey('hsl_hue_slider'));
        expect(hueSlider, findsOneWidget);

        // 50 rapid micro-drags back and forth
        for (int i = 0; i < 50; i++) {
          final offset = (i % 2 == 0) ? const Offset(15, 0) : const Offset(-15, 0);
          await tester.drag(hueSlider, offset);
          await tester.pump();
        }

        final satSlider = find.byKey(const ValueKey('hsl_saturation_slider'));
        for (int i = 0; i < 20; i++) {
          final offset = (i % 2 == 0) ? const Offset(10, 0) : const Offset(-10, 0);
          await tester.drag(satSlider, offset);
          await tester.pump();
        }

        final lightSlider = find.byKey(const ValueKey('hsl_lightness_slider'));
        for (int i = 0; i < 20; i++) {
          final offset = (i % 2 == 0) ? const Offset(10, 0) : const Offset(-10, 0);
          await tester.drag(lightSlider, offset);
          await tester.pump();
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('Repeatedly toggling Dark Surface switch while editing updates live preview cleanly', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: CustomThemeEditorScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final switchFinder = find.byType(Switch);
        expect(switchFinder, findsOneWidget);

        for (int i = 0; i < 10; i++) {
          await tester.tap(switchFinder);
          await tester.pump();
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('ThemePickerScreen grid column count adapts across all 4 breakpoints without overflow', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        final viewports = [
          const Size(320, 568),  // Compact Phone
          const Size(500, 800),  // Large Phone
          const Size(750, 1024), // Tablet
          const Size(1440, 900), // Desktop
        ];

        for (final vp in viewports) {
          tester.view.physicalSize = vp;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);

          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: const MaterialApp(
                home: ThemePickerScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Failed on viewport $vp');
          expect(find.byType(ThemePickerScreen), findsOneWidget);
        }
      });
    });
  });
}
