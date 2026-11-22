import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/di/service_providers.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../domain/models/cloud_streaming_settings.dart';

/// State notifier managing user preferences for network audio and DLNA streaming.
class CloudSettingsNotifier extends StateNotifier<CloudStreamingSettings> {
  CloudSettingsNotifier(this._storage) : super(const CloudStreamingSettings()) {
    _load();
  }

  final IStorageService _storage;

  void _load() {
    final rawMaxMb = _storage.getString(StorageKeys.cloudCacheMaxMb).valueOrNull;
    final maxMb = rawMaxMb != null ? int.tryParse(rawMaxMb) ?? 1024 : 1024;

    final autoDiscover =
        _storage.getBool(StorageKeys.cloudAutoDiscoverCast).valueOrNull ?? true;

    final rawBuffer =
        _storage.getString(StorageKeys.cloudBufferAheadSec).valueOrNull;
    final bufferSec = rawBuffer != null ? int.tryParse(rawBuffer) ?? 15 : 15;

    final lossless =
        _storage.getBool(StorageKeys.cloudLosslessAudio).valueOrNull ?? true;

    final lastDevice =
        _storage.getString(StorageKeys.lastCastDeviceId).valueOrNull;

    state = CloudStreamingSettings(
      maxCacheMb: maxMb,
      autoDiscoverCast: autoDiscover,
      bufferAheadSeconds: bufferSec,
      losslessStreaming: lossless,
      lastConnectedCastDeviceId: lastDevice,
    );
  }

  Future<void> updateSettings(CloudStreamingSettings settings) async {
    state = settings;
    await _storage.setString(
        StorageKeys.cloudCacheMaxMb, settings.maxCacheMb.toString());
    await _storage.setBool(
        StorageKeys.cloudAutoDiscoverCast, settings.autoDiscoverCast);
    await _storage.setString(
        StorageKeys.cloudBufferAheadSec, settings.bufferAheadSeconds.toString());
    await _storage.setBool(
        StorageKeys.cloudLosslessAudio, settings.losslessStreaming);
    if (settings.lastConnectedCastDeviceId != null) {
      await _storage.setString(
          StorageKeys.lastCastDeviceId, settings.lastConnectedCastDeviceId!);
    }
  }

  Future<void> setMaxCacheMb(int mb) async {
    await updateSettings(state.copyWith(maxCacheMb: mb));
  }

  Future<void> toggleAutoDiscoverCast(bool enabled) async {
    await updateSettings(state.copyWith(autoDiscoverCast: enabled));
  }

  Future<void> toggleLossless(bool enabled) async {
    await updateSettings(state.copyWith(losslessStreaming: enabled));
  }

  Future<void> setBufferAheadSec(int seconds) async {
    await updateSettings(state.copyWith(bufferAheadSeconds: seconds));
  }

  Future<void> setLastConnectedCastDeviceId(String? deviceId) async {
    await updateSettings(state.copyWith(lastConnectedCastDeviceId: deviceId));
  }
}

/// Exposes the reactive [CloudStreamingSettings] state.
final cloudSettingsProvider =
    StateNotifierProvider<CloudSettingsNotifier, CloudStreamingSettings>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return CloudSettingsNotifier(storage);
});
