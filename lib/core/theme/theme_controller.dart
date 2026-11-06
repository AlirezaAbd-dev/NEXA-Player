import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/storage_keys.dart';
import '../di/service_providers.dart';
import '../../shared/services/logging/logging_service.dart';
import '../../shared/services/storage/storage_service.dart';
import 'custom_theme_data.dart';
import 'theme_preset.dart';
import 'theme_state.dart';

/// Fallback storage keys for test compatibility.
const String _fallbackKeyPreset = 'theme_preset';
const String _fallbackKeyMode = 'theme_mode';
const String _keyCustomThemeData = 'nexa_custom_theme_data';

/// Riverpod controller managing theme preset, brightness mode, and persistence.
class ThemeController extends Notifier<ThemeState> {
  late final IStorageService _storage;
  late final ILoggingService _logger;

  @override
  ThemeState build() {
    _storage = ref.watch(storageServiceProvider);
    _logger = ref.watch(loggingServiceProvider);
    return _loadInitialState();
  }

  /// Loads and validates persisted theme settings from [IStorageService].
  ///
  /// Any corrupted, missing, or unparseable values fall back gracefully
  /// to Midnight Black and System mode.
  ThemeState _loadInitialState() {
    ThemePreset resolvedPreset = ThemePreset.midnightBlack;
    ThemeMode resolvedMode = ThemeMode.system;
    CustomThemeData? resolvedCustomTheme;

    // 1. Read Theme Preset
    try {
      final primaryResult = _storage.getString(StorageKeys.themePreset);
      String? rawPreset = primaryResult.valueOrNull;

      if (rawPreset == null || rawPreset.isEmpty) {
        final fallbackResult = _storage.getString(_fallbackKeyPreset);
        rawPreset = fallbackResult.valueOrNull;
      }

      if (rawPreset != null && rawPreset.isNotEmpty) {
        resolvedPreset = ThemePreset.fromString(rawPreset);
      }
    } catch (e) {
      _logger.warning('Failed to read theme preset from storage: $e');
      resolvedPreset = ThemePreset.midnightBlack;
    }

    // 2. Read Theme Mode
    try {
      final primaryResult = _storage.getString(StorageKeys.themeMode);
      String? rawMode = primaryResult.valueOrNull;

      if (rawMode == null || rawMode.isEmpty) {
        final fallbackResult = _storage.getString(_fallbackKeyMode);
        rawMode = fallbackResult.valueOrNull;
      }

      if (rawMode != null && rawMode.isNotEmpty) {
        resolvedMode = _parseThemeMode(rawMode);
      }
    } catch (e) {
      _logger.warning('Failed to read theme mode from storage: $e');
      resolvedMode = ThemeMode.system;
    }

    // 3. Read Custom Theme Data
    try {
      final customResult = _storage.getString(_keyCustomThemeData);
      final rawCustom = customResult.valueOrNull;

      if (rawCustom != null && rawCustom.isNotEmpty) {
        final Map<String, dynamic> json =
            jsonDecode(rawCustom) as Map<String, dynamic>;
        resolvedCustomTheme = CustomThemeData.fromJson(json);
      }
    } catch (e) {
      _logger.warning('Failed to parse custom theme data from storage: $e');
      resolvedCustomTheme = null;
      if (resolvedPreset == ThemePreset.custom) {
        resolvedPreset = ThemePreset.midnightBlack;
      }
    }

    return ThemeState(
      preset: resolvedPreset,
      themeMode: resolvedMode,
      customTheme: resolvedCustomTheme,
    );
  }

  /// Switches active theme preset and asynchronously persists selection.
  Future<void> setPreset(ThemePreset preset) async {
    if (state.preset == preset) return;

    state = state.copyWith(preset: preset);

    final res1 = await _storage.setString(StorageKeys.themePreset, preset.name);
    await _storage.setString(_fallbackKeyPreset, preset.name);

    if (res1.isFailure) {
      _logger.error(
        'Failed to persist theme preset: ${preset.name}',
        res1.failureOrNull,
      );
    }
  }

  /// Updates active theme brightness mode and asynchronously persists selection.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state.themeMode == mode) return;

    state = state.copyWith(themeMode: mode);

    final res1 = await _storage.setString(StorageKeys.themeMode, mode.name);
    await _storage.setString(_fallbackKeyMode, mode.name);

    if (res1.isFailure) {
      _logger.error(
        'Failed to persist theme mode: ${mode.name}',
        res1.failureOrNull,
      );
    }
  }

  /// Sets custom HSL palette, switches preset to [ThemePreset.custom], and persists.
  Future<void> setCustomTheme(CustomThemeData customTheme) async {
    state = state.copyWith(
      preset: ThemePreset.custom,
      customTheme: customTheme,
    );

    final jsonStr = jsonEncode(customTheme.toJson());

    await _storage.setString(StorageKeys.themePreset, ThemePreset.custom.name);
    await _storage.setString(_fallbackKeyPreset, ThemePreset.custom.name);
    await _storage.setString(
      StorageKeys.customPrimaryColor,
      customTheme.primaryColor.value.toRadixString(16),
    );
    final res = await _storage.setString(_keyCustomThemeData, jsonStr);

    if (res.isFailure) {
      _logger.error('Failed to persist custom theme JSON', res.failureOrNull);
    }
  }

  /// Toggles between Dark and Light mode. If System, transitions to Dark.
  Future<void> toggleThemeMode() async {
    final nextMode = switch (state.themeMode) {
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.system => ThemeMode.dark,
    };
    await setThemeMode(nextMode);
  }

  /// Resets theme settings back to initial factory defaults and clears storage.
  Future<void> resetToDefaults() async {
    state = ThemeState.initial;

    await _storage.remove(StorageKeys.themePreset);
    await _storage.remove(_fallbackKeyPreset);
    await _storage.remove(StorageKeys.themeMode);
    await _storage.remove(_fallbackKeyMode);
    await _storage.remove(_keyCustomThemeData);
    await _storage.remove(StorageKeys.customPrimaryColor);

    _logger.info('Reset theme settings to initial defaults');
  }

  /// Parses a string into [ThemeMode] with graceful fallback.
  ThemeMode _parseThemeMode(String raw) {
    final normalized = raw.trim().toLowerCase();
    return switch (normalized) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }
}

/// Global provider for [ThemeController] exposing reactive [ThemeState].
final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeState>(
  ThemeController.new,
);

/// Convenience provider exposing [ThemeState].
final themeStateProvider = Provider<ThemeState>((ref) {
  return ref.watch(themeControllerProvider);
});

/// AsyncNotifier implementation for teams or modules requiring AsyncNotifier interface.
///
/// Reactively synchronizes with [themeControllerProvider] to maintain a single
/// source of truth for theme state, persistence, and logging.
class AsyncThemeController extends AsyncNotifier<ThemeState> {
  @override
  FutureOr<ThemeState> build() {
    ref.listen<ThemeState>(themeControllerProvider, (_, next) {
      state = AsyncData(next);
    });
    return ref.read(themeControllerProvider);
  }

  /// Switches active theme preset and asynchronously persists selection.
  Future<void> setPreset(ThemePreset preset) async {
    await ref.read(themeControllerProvider.notifier).setPreset(preset);
  }

  /// Updates active theme brightness mode and asynchronously persists selection.
  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(themeControllerProvider.notifier).setThemeMode(mode);
  }

  /// Sets custom HSL palette, switches preset to [ThemePreset.custom], and persists.
  Future<void> setCustomTheme(CustomThemeData customTheme) async {
    await ref.read(themeControllerProvider.notifier).setCustomTheme(customTheme);
  }

  /// Toggles between Dark and Light mode. If System, transitions to Dark.
  Future<void> toggleThemeMode() async {
    await ref.read(themeControllerProvider.notifier).toggleThemeMode();
  }

  /// Resets theme settings back to initial factory defaults and clears storage.
  Future<void> resetToDefaults() async {
    await ref.read(themeControllerProvider.notifier).resetToDefaults();
  }
}

final asyncThemeControllerProvider =
    AsyncNotifierProvider<AsyncThemeController, ThemeState>(
  AsyncThemeController.new,
);
