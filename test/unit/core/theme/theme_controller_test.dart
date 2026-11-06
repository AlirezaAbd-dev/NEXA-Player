import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/theme/theme_state.dart';

import '../../../../test/helpers/mock_services.dart';

void main() {
  group('ThemeController & ThemeState Unit Tests', () {
    late FakeStorageService fakeStorage;
    late FakeLoggingService fakeLogging;

    ProviderContainer createContainer({Map<String, Object>? initialStorage}) {
      fakeStorage = FakeStorageService(initialStorage);
      fakeLogging = FakeLoggingService();

      final container = ProviderContainer(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          loggingServiceProvider.overrideWithValue(fakeLogging),
        ],
      );
      return container;
    }

    group('Initial State & Storage Loading', () {
      test('defaults to Midnight Black and System mode when storage is empty', () {
        final container = createContainer();
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);

        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
        expect(state.customTheme, isNull);
        expect(state.isCustom, isFalse);
      });

      test('restores previously persisted preset from storage', () {
        final container = createContainer(
          initialStorage: {StorageKeys.themePreset: 'oceanBlue'},
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.oceanBlue));
      });

      test('restores previously persisted theme mode from storage', () {
        final container = createContainer(
          initialStorage: {StorageKeys.themeMode: 'light'},
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.themeMode, equals(ThemeMode.light));
      });

      test('restores fallback un-prefixed keys when nexa_ keys are absent', () {
        final container = createContainer(
          initialStorage: {
            'theme_preset': 'sakura',
            'theme_mode': 'dark',
          },
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.sakura));
        expect(state.themeMode, equals(ThemeMode.dark));
      });

      test('gracefully falls back to Midnight Black when stored preset is corrupted', () {
        final container = createContainer(
          initialStorage: {StorageKeys.themePreset: 'CORRUPTED_VALUE_!@#'},
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.midnightBlack));
      });

      test('gracefully falls back to System mode when stored mode is corrupted', () {
        final container = createContainer(
          initialStorage: {StorageKeys.themeMode: 'INVALID_MODE'},
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.themeMode, equals(ThemeMode.system));
      });

      test('gracefully handles corrupted custom theme JSON', () {
        final container = createContainer(
          initialStorage: {
            StorageKeys.themePreset: 'custom',
            'nexa_custom_theme_data': '{malformed_json...}',
          },
        );
        addTearDown(container.dispose);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.customTheme, isNull);
        expect(fakeLogging.hasMessage('Failed to parse custom theme data'), isTrue);
      });

      test('handles simulated storage read failure without throwing', () {
        final container = createContainer();
        addTearDown(container.dispose);
        fakeStorage.simulateFailure = true;

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
      });
    });

    group('Preset & Mode Switching & Persistence', () {
      test('setPreset updates state and persists to storage', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        await controller.setPreset(ThemePreset.forestGreen);

        final updatedState = container.read(themeControllerProvider);
        expect(updatedState.preset, equals(ThemePreset.forestGreen));
        expect(fakeStorage.getRaw(StorageKeys.themePreset), equals('forestGreen'));
        expect(fakeStorage.getRaw('theme_preset'), equals('forestGreen'));
      });

      test('setPreset is idempotent if preset is already active', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        await controller.setPreset(ThemePreset.midnightBlack); // already midnightBlack

        // Storage should remain untouched
        expect(fakeStorage.containsKey(StorageKeys.themePreset), isFalse);
      });

      test('setThemeMode updates mode and persists to storage', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        await controller.setThemeMode(ThemeMode.dark);

        final state = container.read(themeControllerProvider);
        expect(state.themeMode, equals(ThemeMode.dark));
        expect(fakeStorage.getRaw(StorageKeys.themeMode), equals('dark'));
        expect(fakeStorage.getRaw('theme_mode'), equals('dark'));
      });

      test('toggleThemeMode cycles between modes', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);

        // From system -> dark
        await controller.toggleThemeMode();
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.dark));

        // From dark -> light
        await controller.toggleThemeMode();
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.light));

        // From light -> dark
        await controller.toggleThemeMode();
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.dark));
      });

      test('switching through all 8 presets succeeds and persists each', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        // Start from neonPurple so switching to midnightBlack is a real transition
        await controller.setPreset(ThemePreset.neonPurple);

        final presets = [
          ThemePreset.midnightBlack,
          ThemePreset.deepSpace,
          ThemePreset.sakura,
          ThemePreset.oceanBlue,
          ThemePreset.forestGreen,
          ThemePreset.lava,
          ThemePreset.daylight,
          ThemePreset.neonPurple,
        ];

        for (final preset in presets) {
          await controller.setPreset(preset);
          expect(container.read(themeControllerProvider).preset, equals(preset));
          expect(fakeStorage.getRaw(StorageKeys.themePreset), equals(preset.name));
        }
      });
    });

    group('Custom Theme Authoring', () {
      test('setCustomTheme updates state to custom and persists serialized JSON', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        const customData = CustomThemeData(
          primaryHue: 280.0,
          primarySaturation: 0.90,
          primaryLightness: 0.60,
          isDark: true,
        );

        await controller.setCustomTheme(customData);

        final state = container.read(themeControllerProvider);
        expect(state.preset, equals(ThemePreset.custom));
        expect(state.isCustom, isTrue);
        expect(state.customTheme, equals(customData));
        expect(state.customPrimary, isNotNull);

        final storedJson = fakeStorage.getRaw('nexa_custom_theme_data') as String;
        final decoded = jsonDecode(storedJson) as Map<String, dynamic>;
        expect(decoded['primaryHue'], equals(280.0));
        expect(decoded['primarySaturation'], equals(0.90));
      });
    });

    group('Resilience & Failure Handling', () {
      test('storage write failure updates state in-memory and logs error', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        fakeStorage.simulateFailure = true;
        final controller = container.read(themeControllerProvider.notifier);

        await controller.setPreset(ThemePreset.lava);

        // In-memory state updated
        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.lava));
        // Error logged
        expect(fakeLogging.errors.isNotEmpty, isTrue);
      });

      test('resetToDefaults clears storage and restores initial ThemeState', () async {
        final container = createContainer(
          initialStorage: {
            StorageKeys.themePreset: 'lava',
            StorageKeys.themeMode: 'light',
          },
        );
        addTearDown(container.dispose);

        final controller = container.read(themeControllerProvider.notifier);
        await controller.resetToDefaults();

        final state = container.read(themeControllerProvider);
        expect(state, equals(ThemeState.initial));
        expect(fakeStorage.containsKey(StorageKeys.themePreset), isFalse);
        expect(fakeStorage.containsKey(StorageKeys.themeMode), isFalse);
      });
    });

    group('ThemeState Equatable & Helper Methods', () {
      test('value equality holds for identical states', () {
        const stateA = ThemeState(
          preset: ThemePreset.oceanBlue,
          themeMode: ThemeMode.dark,
        );
        const stateB = ThemeState(
          preset: ThemePreset.oceanBlue,
          themeMode: ThemeMode.dark,
        );
        expect(stateA, equals(stateB));
        expect(stateA.hashCode, equals(stateB.hashCode));
      });

      test('copyWith correctly creates modified instances', () {
        const initial = ThemeState();
        final modified = initial.copyWith(preset: ThemePreset.sakura);

        expect(modified.preset, equals(ThemePreset.sakura));
        expect(modified.themeMode, equals(ThemeMode.system));
      });

      test('isDark correctly evaluates platform brightness for all modes', () {
        const darkState = ThemeState(themeMode: ThemeMode.dark);
        expect(darkState.isDark(Brightness.light), isTrue);
        expect(darkState.isDark(Brightness.dark), isTrue);

        const lightState = ThemeState(themeMode: ThemeMode.light);
        expect(lightState.isDark(Brightness.light), isFalse);
        expect(lightState.isDark(Brightness.dark), isFalse);

        const systemState = ThemeState(themeMode: ThemeMode.system);
        expect(systemState.isDark(Brightness.light), isFalse);
        expect(systemState.isDark(Brightness.dark), isTrue);
      });
    });

    group('AsyncThemeController & asyncThemeControllerProvider', () {
      test('build() resolves synchronously to initial ThemeState without uninitialized ref error', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final asyncValue = container.read(asyncThemeControllerProvider);
        expect(asyncValue, isA<AsyncData<ThemeState>>());
        expect(asyncValue.value?.preset, equals(ThemePreset.midnightBlack));
        expect(asyncValue.value?.themeMode, equals(ThemeMode.system));

        final futureState = await container.read(asyncThemeControllerProvider.future);
        expect(futureState, equals(ThemeState.initial));
      });

      test('build() restores persisted preset and theme mode from storage', () async {
        final container = createContainer(
          initialStorage: {
            StorageKeys.themePreset: 'oceanBlue',
            StorageKeys.themeMode: 'light',
          },
        );
        addTearDown(container.dispose);

        final state = await container.read(asyncThemeControllerProvider.future);
        expect(state.preset, equals(ThemePreset.oceanBlue));
        expect(state.themeMode, equals(ThemeMode.light));
      });

      test('build() restores fallback un-prefixed keys when nexa_ keys are absent', () async {
        final container = createContainer(
          initialStorage: {
            'theme_preset': 'sakura',
            'theme_mode': 'dark',
          },
        );
        addTearDown(container.dispose);

        final state = await container.read(asyncThemeControllerProvider.future);
        expect(state.preset, equals(ThemePreset.sakura));
        expect(state.themeMode, equals(ThemeMode.dark));
      });

      test('setPreset updates state in lockstep and persists to storage', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(asyncThemeControllerProvider.notifier);
        await controller.setPreset(ThemePreset.forestGreen);

        expect(container.read(asyncThemeControllerProvider).value?.preset, equals(ThemePreset.forestGreen));
        expect(container.read(themeControllerProvider).preset, equals(ThemePreset.forestGreen));
        expect(fakeStorage.getRaw(StorageKeys.themePreset), equals('forestGreen'));
        expect(fakeStorage.getRaw('theme_preset'), equals('forestGreen'));
      });

      test('setThemeMode updates theme mode in lockstep and persists to storage', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(asyncThemeControllerProvider.notifier);
        await controller.setThemeMode(ThemeMode.dark);

        expect(container.read(asyncThemeControllerProvider).value?.themeMode, equals(ThemeMode.dark));
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.dark));
        expect(fakeStorage.getRaw(StorageKeys.themeMode), equals('dark'));
      });

      test('setCustomTheme updates state to custom and persists serialized JSON', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(asyncThemeControllerProvider.notifier);
        const customData = CustomThemeData(
          primaryHue: 280.0,
          primarySaturation: 0.90,
          primaryLightness: 0.60,
          isDark: true,
        );

        await controller.setCustomTheme(customData);

        final state = container.read(asyncThemeControllerProvider).value!;
        expect(state.preset, equals(ThemePreset.custom));
        expect(state.isCustom, isTrue);
        expect(state.customTheme, equals(customData));
        expect(container.read(themeControllerProvider).customTheme, equals(customData));
        expect(fakeStorage.containsKey('nexa_custom_theme_data'), isTrue);
      });

      test('toggleThemeMode cycles through brightness modes in lockstep', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        final controller = container.read(asyncThemeControllerProvider.notifier);
        await controller.toggleThemeMode(); // system -> dark
        expect(container.read(asyncThemeControllerProvider).value?.themeMode, equals(ThemeMode.dark));
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.dark));

        await controller.toggleThemeMode(); // dark -> light
        expect(container.read(asyncThemeControllerProvider).value?.themeMode, equals(ThemeMode.light));
        expect(container.read(themeControllerProvider).themeMode, equals(ThemeMode.light));
      });

      test('resetToDefaults clears storage and restores initial state in both controllers', () async {
        final container = createContainer(
          initialStorage: {
            StorageKeys.themePreset: 'lava',
            StorageKeys.themeMode: 'light',
          },
        );
        addTearDown(container.dispose);

        final controller = container.read(asyncThemeControllerProvider.notifier);
        await controller.resetToDefaults();

        expect(container.read(asyncThemeControllerProvider).value, equals(ThemeState.initial));
        expect(container.read(themeControllerProvider), equals(ThemeState.initial));
        expect(fakeStorage.containsKey(StorageKeys.themePreset), isFalse);
        expect(fakeStorage.containsKey(StorageKeys.themeMode), isFalse);
      });

      test('mutations on synchronous themeControllerProvider are reactively mirrored in asyncThemeControllerProvider', () async {
        final container = createContainer();
        addTearDown(container.dispose);

        // Initial read to mount async provider
        expect(container.read(asyncThemeControllerProvider).value?.preset, equals(ThemePreset.midnightBlack));

        // Mutate via synchronous controller
        await container.read(themeControllerProvider.notifier).setPreset(ThemePreset.lava);

        // Verify async controller mirrored the update
        expect(container.read(asyncThemeControllerProvider).value?.preset, equals(ThemePreset.lava));
      });

      test('build() handles corrupted storage data gracefully without throwing', () async {
        final container = createContainer(
          initialStorage: {StorageKeys.themePreset: 'CORRUPTED_!@#'},
        );
        addTearDown(container.dispose);

        final state = await container.read(asyncThemeControllerProvider.future);
        expect(state.preset, equals(ThemePreset.midnightBlack));
        expect(state.themeMode, equals(ThemeMode.system));
      });
    });
  });
}
