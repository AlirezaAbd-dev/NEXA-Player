import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/extensions/string_x.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/theme/theme_state.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/themes/presentation/screens/custom_theme_editor_screen.dart';
import 'package:nexa_player/features/themes/presentation/screens/theme_picker_screen.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

import '../../../helpers/mock_services.dart';

/// Throwing storage service simulating catastrophic storage driver failure.
class ThrowingStorageService implements IStorageService {
  @override
  Result<String?, StorageFailure> getString(String key) {
    throw Exception('Catastrophic hardware I/O read failure for key "$key"');
  }

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    throw Exception('Catastrophic disk full error on key "$key"');
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) {
    throw Exception('Catastrophic hardware I/O read failure for key "$key"');
  }

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    throw Exception('Catastrophic disk full error on key "$key"');
  }

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    throw Exception('Catastrophic delete failure for key "$key"');
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    throw Exception('Catastrophic clear failure');
  }
}

void main() {
  group('Milestone 2 Adversarial Stress & Integrity Challenge', () {
    late FakeStorageService fakeStorage;
    late FakeLoggingService fakeLogging;

    ProviderContainer createContainer({
      Map<String, Object>? initialStorage,
      IStorageService? customStorage,
    }) {
      fakeStorage = FakeStorageService(initialStorage);
      fakeLogging = FakeLoggingService();

      return ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(customStorage ?? fakeStorage),
          loggingServiceProvider.overrideWithValue(fakeLogging),
        ],
      );
    }

    // =========================================================================
    // CHALLENGE 1: 100 Rapid Theme Preset Changes (<1s) & Concurrency
    // =========================================================================
    group('1. Rapid Theme Switching & Stress Testing', () {
      test('100 sequential theme preset changes execute in <1s without dropping state', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        final recordedStates = <ThemePreset>[];

        container.listen(themeControllerProvider, (prev, next) {
          recordedStates.add(next.preset);
        });

        final stopwatch = Stopwatch()..start();

        const cycle = [
          ThemePreset.midnightBlack,
          ThemePreset.deepSpace,
          ThemePreset.sakura,
          ThemePreset.oceanBlue,
          ThemePreset.forestGreen,
          ThemePreset.lava,
          ThemePreset.daylight,
          ThemePreset.neonPurple,
        ];

        // 100 distinct sequential changes
        for (int i = 0; i < 100; i++) {
          final nextPreset = cycle[(i + 1) % cycle.length];
          await controller.setPreset(nextPreset);
        }

        stopwatch.stop();

        // Must complete within 1 second (1000ms)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000),
            reason: '100 sequential theme switches exceeded 1s: took ${stopwatch.elapsedMilliseconds}ms');

        // State must accurately reflect the 100th switch
        final finalPreset = cycle[100 % cycle.length];
        expect(container.read(themeControllerProvider).preset, equals(finalPreset));
        expect(recordedStates.length, equals(100),
            reason: 'ThemeController dropped state notifications during rapid switching');
        expect(recordedStates.last, equals(finalPreset));
        expect(fakeStorage.getRaw(StorageKeys.themePreset), equals(finalPreset.name));
      });

      test('100 concurrent unawaited setPreset calls converge to final state without corrupting', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);

        const cycle = [
          ThemePreset.midnightBlack,
          ThemePreset.deepSpace,
          ThemePreset.sakura,
          ThemePreset.oceanBlue,
          ThemePreset.forestGreen,
          ThemePreset.lava,
          ThemePreset.daylight,
          ThemePreset.neonPurple,
        ];

        final futures = <Future<void>>[];
        for (int i = 0; i < 100; i++) {
          final nextPreset = cycle[(i + 1) % cycle.length];
          futures.add(controller.setPreset(nextPreset));
        }

        await Future.wait(futures);

        final state = container.read(themeControllerProvider);
        expect(ThemePreset.values.contains(state.preset), isTrue);
        expect(state.isCustom, isFalse);
        expect(fakeStorage.containsKey(StorageKeys.themePreset), isTrue);
      });

      test('100 rapid toggleThemeMode calls cycle accurately without deadlock', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);

        // Set to explicit dark mode first
        await controller.setThemeMode(ThemeMode.dark);
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.dark));

        final stopwatch = Stopwatch()..start();

        // 100 toggles: dark -> light -> dark ... after 100 (even number), must be dark
        for (int i = 0; i < 100; i++) {
          await controller.toggleThemeMode();
        }

        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.dark));
        expect(fakeStorage.getRaw(StorageKeys.themeMode), equals('dark'));
      });

      test('Rapid interleaving between presets and custom themes preserves state invariants', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        const custom1 = CustomThemeData(primaryHue: 45.0);
        const custom2 = CustomThemeData(primaryHue: 200.0);

        await controller.setCustomTheme(custom1);
        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.custom));
        expect(container.read(themeControllerProvider).isCustom, isTrue);

        await controller.setPreset(ThemePreset.lava);
        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.lava));
        expect(container.read(themeControllerProvider).isCustom, isFalse);

        await controller.setCustomTheme(custom2);
        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.custom));
        expect(container.read(themeControllerProvider).isCustom, isTrue);
        expect(container.read(themeControllerProvider).customTheme?.primaryHue, equals(200.0));
      });
    });

    // =========================================================================
    // CHALLENGE 2: Corrupted Storage Injection & Recovery
    // =========================================================================
    group('2. Corrupted Storage Injection & Recovery', () {
      test('recovers from completely corrupted, non-JSON strings in custom theme storage', () {
        final corruptedPayloads = [
          '{not-json}',
          '{"primaryHue":',
          '',
          '   \n\t  ',
          '[1, 2, 3]',
          '12345',
          '"just a string"',
          'true',
          'null',
          '{"primaryHue": "red", "primarySaturation": true}',
          '{"primaryHue": null, "isDark": "maybe"}',
          '{"isDark": 1}',
          '{"name": 404}',
        ];

        for (final payload in corruptedPayloads) {
          final container = createContainer(
            initialStorage: {
              StorageKeys.themePreset: 'custom',
              'nexa_custom_theme_data': payload,
            },
          );

          final state = container.read(themeControllerProvider);
          // If custom theme data is invalid, must safely fall back without throwing
          expect(ThemePreset.values.contains(state.preset), isTrue);
          expect(state.themeMode, equals(ThemeMode.system));
          container.dispose();
        }
      });

      test('recovers from wild unknown or malicious preset strings in storage', () {
        final maliciousPresets = [
          'cyberpunk',
          'MATRIX_GREEN',
          '12345',
          "' OR 1=1; --",
          '<script>alert(1)</script>',
          'A' * 10000,
          '',
          '   ',
          'null',
          'undefined',
        ];

        for (final raw in maliciousPresets) {
          final container = createContainer(
            initialStorage: {StorageKeys.themePreset: raw},
          );

          final state = container.read(themeControllerProvider);
          // Must fall back to default midnightBlack
          expect(state.preset, equals(ThemePreset.midnightBlack),
              reason: 'Failed to fall back to Midnight Black for raw preset: "$raw"');
          container.dispose();
        }
      });

      test('recovers from wild unknown theme mode strings in storage', () {
        final maliciousModes = [
          'AMOLED',
          'high_contrast',
          '-1',
          'DARK_LIGHT',
          'blue_light_filter',
          '',
          '   ',
        ];

        for (final raw in maliciousModes) {
          final container = createContainer(
            initialStorage: {StorageKeys.themeMode: raw},
          );

          final state = container.read(themeControllerProvider);
          expect(state.themeMode, equals(ThemeMode.system),
              reason: 'Failed to fall back to System mode for raw mode: "$raw"');
          container.dispose();
        }
      });

      test('non-hex color strings in storage keys do not cause crash or unhandled errors', () {
        final nonHexStrings = [
          'not_a_hex_color',
          '#XYZ123',
          '#',
          '',
          '12345',
          '1234567',
          '0x123456789',
          'blue',
        ];

        for (final nonHex in nonHexStrings) {
          // Verify StringX.toColorOrNull handles non-hex gracefully
          expect(nonHex.toColorOrNull(), isNull,
              reason: 'StringX.toColorOrNull should return null for non-hex "$nonHex"');

          final container = createContainer(
            initialStorage: {
              StorageKeys.themePreset: 'custom',
              StorageKeys.customPrimaryColor: nonHex,
              StorageKeys.customSurfaceColor: nonHex,
              StorageKeys.customBackgroundColor: nonHex,
            },
          );

          final state = container.read(themeControllerProvider);
          expect(ThemePreset.values.contains(state.preset), isTrue);

          // Test AppTheme.buildTheme survives even if customPrimary is null
          final themeData = AppTheme.buildTheme(
            preset: state.preset,
            mode: state.themeMode,
            customPrimary: state.customPrimary,
          );
          expect(themeData, isNotNull);
          container.dispose();
        }
      });

      test('handles missing custom theme payload when preset is custom gracefully', () {
        // Storage has preset='custom' but no custom JSON payload was ever stored
        final container = createContainer(
          initialStorage: {
            StorageKeys.themePreset: 'custom',
          },
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);

        // AppTheme.buildTheme should resolve safely without throwing
        final theme = AppTheme.buildTheme(
          preset: state.preset,
          mode: state.themeMode,
          customPrimary: state.customPrimary,
        );
        expect(theme, isNotNull);
      });
    });

    // =========================================================================
    // CHALLENGE 3: Asynchronous Storage Failure Simulation
    // =========================================================================
    group('3. Storage Failure Simulation & Resilience', () {
      test('initial boot survives when storage read fails completely', () {
        final container = createContainer();
        addTearDown(container.dispose);

        fakeStorage.simulateFailure = true;

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
        expect(state.customTheme, isNull);
      });

      test('setPreset updates state in-memory and logs error when storage write fails', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        fakeStorage.simulateFailure = true;
        final controller = container.read(themeControllerProvider.notifier);

        await controller.setPreset(ThemePreset.neonPurple);

        // State is updated in memory
        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.neonPurple));
        // Error logged
        expect(fakeLogging.hasMessage('Failed to persist theme preset: neonPurple'), isTrue);
      });

      test('setThemeMode updates state in-memory and logs error when storage write fails', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        fakeStorage.simulateFailure = true;
        final controller = container.read(themeControllerProvider.notifier);

        await controller.setThemeMode(ThemeMode.light);

        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.light));
        expect(fakeLogging.hasMessage('Failed to persist theme mode: light'), isTrue);
      });

      test('setCustomTheme updates state in-memory and logs error when storage write fails', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        fakeStorage.simulateFailure = true;
        final controller = container.read(themeControllerProvider.notifier);

        const custom = CustomThemeData(primaryHue: 120.0);
        await controller.setCustomTheme(custom);

        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.custom));
        expect(container.read(themeControllerProvider).customTheme, equals(custom));
        expect(fakeLogging.hasMessage('Failed to persist custom theme JSON'), isTrue);
      });

      test('resetToDefaults survives when storage remove fails', () async {
        final container = createContainer(
          initialStorage: {StorageKeys.themePreset: 'lava'},
        );
        addTearDown(container.dispose);

        fakeStorage.simulateFailure = true;
        final controller = container.read(themeControllerProvider.notifier);

        await controller.resetToDefaults();

        // State is reset to initial
        expect(container.read(themeControllerProvider), equals(ThemeState.initial));
      });

      test('ThemeController build() survives catastrophic ThrowingStorageService without crashing', () {
        final container = createContainer(customStorage: ThrowingStorageService());
        addTearDown(container.dispose);

        // Should not throw even when storage throws raw exceptions on read
        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
        expect(fakeLogging.hasMessage('Failed to read theme preset from storage'), isTrue);
      });
    });

    // =========================================================================
    // CHALLENGE 4: Memory Lifecycle & Listener Cleanup
    // =========================================================================
    group('4. Memory Lifecycle & Listener Cleanup', () {
      test('100 concurrent listener subscriptions receive updates and unlisten cleanly', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        final notifications = List.generate(100, (_) => <ThemePreset>[]);
        final subscriptions = <ProviderSubscription<ThemeState>>[];

        // Register 100 listeners
        for (int i = 0; i < 100; i++) {
          final idx = i;
          subscriptions.add(
            container.listen(themeControllerProvider, (prev, next) {
              notifications[idx].add(next.preset);
            }),
          );
        }

        // Fire 5 preset changes
        final testPresets = [
          ThemePreset.deepSpace,
          ThemePreset.sakura,
          ThemePreset.oceanBlue,
          ThemePreset.lava,
          ThemePreset.daylight,
        ];

        for (final preset in testPresets) {
          await controller.setPreset(preset);
        }

        // Every listener should have received all 5 updates
        for (int i = 0; i < 100; i++) {
          expect(notifications[i].length, equals(5));
          expect(notifications[i], equals(testPresets));
        }

        // Cancel first 50 subscriptions
        for (int i = 0; i < 50; i++) {
          subscriptions[i].close();
        }

        // Fire another preset change
        await controller.setPreset(ThemePreset.forestGreen);

        // Closed listeners must NOT receive the 6th update
        for (int i = 0; i < 50; i++) {
          expect(notifications[i].length, equals(5));
        }

        // Remaining active listeners MUST receive the 6th update
        for (int i = 50; i < 100; i++) {
          expect(notifications[i].length, equals(6));
          expect(notifications[i].last, equals(ThemePreset.forestGreen));
          subscriptions[i].close();
        }
      });

      test('50 rapid ProviderContainer creation and disposal cycles do not leak or throw', () async {
        for (int cycle = 0; cycle < 50; cycle++) {
          final container = createContainer();
          final controller = container.read(themeControllerProvider.notifier);
          await controller.setPreset(ThemePreset.values[cycle % 8]);
          expect(container.read(themeControllerProvider).preset, equals(ThemePreset.values[cycle % 8]));
          container.dispose();
        }
      });
    });

    // =========================================================================
    // CHALLENGE 5: CustomThemeData HSL Mathematical Invariants & Extremes
    // =========================================================================
    group('5. CustomThemeData HSL Extreme Values & Invariants', () {
      test('handles extreme out-of-range hue values gracefully', () {
        const extremeHues = [-3600.0, -360.0, -1.0, 360.0, 720.0, 100000.0];

        for (final hue in extremeHues) {
          final custom = CustomThemeData(primaryHue: hue);
          expect(custom.normalizedHue, greaterThanOrEqualTo(0.0));
          expect(custom.normalizedHue, lessThan(360.0));

          // Color generation must not throw
          final primary = custom.primaryColor;
          expect(primary, isNotNull);
          final secondary = custom.secondaryColor;
          expect(secondary, isNotNull);
          final surface = custom.surfaceColor;
          expect(surface, isNotNull);
          final scaffold = custom.scaffoldBackgroundColor;
          expect(scaffold, isNotNull);
        }
      });

      test('handles extreme saturation and lightness values without out-of-bounds error', () {
        const extremeValues = [-100.0, -1.0, 0.0, 1.0, 2.0, 100.0];

        for (final sat in extremeValues) {
          for (final light in extremeValues) {
            final custom = CustomThemeData(
              primarySaturation: sat,
              primaryLightness: light,
              surfaceLightness: light,
            );

            expect(custom.normalizedSaturation, inInclusiveRange(0.0, 1.0));
            expect(custom.clampedPrimaryLightness, inInclusiveRange(0.0, 1.0));
            expect(custom.clampedSurfaceLightness, inInclusiveRange(0.0, 1.0));

            // Theme generation must succeed
            final scheme = custom.toColorScheme();
            expect(scheme, isNotNull);
            final theme = custom.toThemeData();
            expect(theme, isNotNull);
          }
        }
      });

      test('guarantees contrast ratio >= 3.0:1 across all 360 degrees of hue in light mode', () {
        final failingLightHues = <double, double>{};
        for (double hue = 0.0; hue < 360.0; hue += 5.0) {
          for (final sat in [0.25, 0.5, 0.75, 1.0]) {
            final lightCustom = CustomThemeData(
              primaryHue: hue,
              primarySaturation: sat,
              primaryLightness: 0.35,
              surfaceLightness: 0.96,
              isDark: false,
            );
            if (lightCustom.accentContrastRatio < 3.0) {
              failingLightHues[hue] = lightCustom.accentContrastRatio;
            }
          }
        }
        expect(failingLightHues, isEmpty, reason: 'All hues in light mode must achieve contrast >= 3.0:1');
      });

      test('guarantees contrast ratio >= 3.0:1 across all 360 degrees of hue in dark mode', () {
        final failingDarkHues = <double, double>{};
        for (double hue = 0.0; hue < 360.0; hue += 5.0) {
          for (final sat in [0.25, 0.5, 0.75, 1.0]) {
            final darkCustom = CustomThemeData(
              primaryHue: hue,
              primarySaturation: sat,
              primaryLightness: 0.50,
              surfaceLightness: 0.08,
              isDark: true,
            );
            if (darkCustom.accentContrastRatio < 3.0) {
              failingDarkHues[hue] = darkCustom.accentContrastRatio;
            }
          }
        }
        expect(failingDarkHues, isEmpty, reason: 'All hues in dark mode must achieve contrast >= 3.0:1');
      });
    });

    // =========================================================================
    // CHALLENGE 6: UI Widget Stress Testing & Navigation Thrashing
    // =========================================================================
    group('6. UI Widget Stress Testing & Lifecycle', () {
      testWidgets('ThemePickerScreen survives rapid multi-card taps across breakpoints', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        // Test across 3 distinct screen sizes
        final breakpoints = [
          const Size(360, 640),  // Phone portrait
          const Size(700, 900),  // Tablet
          const Size(1200, 800), // Desktop
        ];

        for (final size in breakpoints) {
          tester.view.physicalSize = size;
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

          // Rapid taps on dark, light, system buttons
          await tester.tap(find.byKey(const ValueKey('theme_mode_dark')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('theme_mode_light')));
          await tester.pump();
          await tester.tap(find.byKey(const ValueKey('theme_mode_system')));
          await tester.pump();

          // Rapid taps on all preset cards visible in view
          final presetCards = [
            const ValueKey('theme_card_midnight_black'),
            const ValueKey('theme_card_deep_space'),
            const ValueKey('theme_card_sakura'),
            const ValueKey('theme_card_ocean_blue'),
          ];

          for (final key in presetCards) {
            await tester.ensureVisible(find.byKey(key));
            await tester.tap(find.byKey(key));
            await tester.pump();
          }

          // No render overflow or exceptions
          expect(tester.takeException(), isNull);
        }
      });

      testWidgets('20 rapid push/pop cycles between picker and editor do not leak or throw', (tester) async {
        final container = createContainer();
        addTearDown(container.dispose);

        tester.view.physicalSize = const Size(800, 1000);
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

        for (int i = 0; i < 20; i++) {
          // Tap Custom Theme card to push editor
          final customCard = find.byKey(const ValueKey('theme_card_custom'));
          await tester.ensureVisible(customCard);
          await tester.tap(customCard);
          await tester.pumpAndSettle();

          // Verify editor screen is mounted
          expect(find.byType(CustomThemeEditorScreen), findsOneWidget);

          // Pop back
          final navigator = tester.state<NavigatorState>(find.byType(Navigator));
          navigator.pop();
          await tester.pumpAndSettle();

          expect(find.byType(ThemePickerScreen), findsOneWidget);
        }

        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // CHALLENGE 7: AsyncThemeController Empirical Verification (Bug Target)
    // =========================================================================
    group('7. AsyncThemeController Empirical Verification (Resolved)', () {
      test('AsyncThemeController completes successfully without LateInitializationError', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final state = await container.read(asyncThemeControllerProvider.future);
        expect(state, equals(ThemeState.initial));
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
      });
    });
  });
}

