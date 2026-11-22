import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../domain/models/auto_settings.dart';

/// Notifier managing persistent driver and wearable configuration.
class AutoSettingsNotifier extends StateNotifier<AutoSettings> {
  AutoSettingsNotifier(this._storage) : super(const AutoSettings()) {
    _load();
  }

  final IStorageService _storage;

  void _load() {
    final keepAwake =
        _storage.getBool(StorageKeys.carModeKeepScreenAwake).valueOrNull ?? true;
    final largeButtons =
        _storage.getBool(StorageKeys.carModeLargeButtons).valueOrNull ?? true;
    final btLaunch =
        _storage.getBool(StorageKeys.carModeBluetoothAutoLaunch).valueOrNull ?? false;
    final wearEnabled =
        _storage.getBool(StorageKeys.wearCompanionEnabled).valueOrNull ?? true;

    state = AutoSettings(
      keepScreenAwake: keepAwake,
      largeButtons: largeButtons,
      bluetoothAutoLaunch: btLaunch,
      wearCompanionEnabled: wearEnabled,
    );
  }

  Future<void> update(AutoSettings settings) async {
    state = settings;
    await _storage.setBool(
        StorageKeys.carModeKeepScreenAwake, settings.keepScreenAwake);
    await _storage.setBool(
        StorageKeys.carModeLargeButtons, settings.largeButtons);
    await _storage.setBool(
        StorageKeys.carModeBluetoothAutoLaunch, settings.bluetoothAutoLaunch);
    await _storage.setBool(
        StorageKeys.wearCompanionEnabled, settings.wearCompanionEnabled);
  }

  Future<void> toggleKeepScreenAwake(bool value) async {
    await update(state.copyWith(keepScreenAwake: value));
  }

  Future<void> toggleLargeButtons(bool value) async {
    await update(state.copyWith(largeButtons: value));
  }

  Future<void> toggleBluetoothAutoLaunch(bool value) async {
    await update(state.copyWith(bluetoothAutoLaunch: value));
  }

  Future<void> toggleAndroidAuto(bool value) async {
    await update(state.copyWith(androidAutoEnabled: value));
  }

  Future<void> toggleWearCompanion(bool value) async {
    await update(state.copyWith(wearCompanionEnabled: value));
  }
}

/// Provider exposing reactive [AutoSettings].
final autoSettingsProvider =
    StateNotifierProvider<AutoSettingsNotifier, AutoSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return AutoSettingsNotifier(storage);
});

/// Indicates whether Car Mode driving dashboard is actively presented.
final carModeActiveProvider = StateProvider<bool>((ref) => false);
