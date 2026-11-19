import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import '../../domain/models/visualizer_settings.dart';
import '../../domain/services/fft_engine.dart';

/// Visualizer settings notifier managing style, sensitivity, fps cap, and colors.
class VisualizerSettingsNotifier extends StateNotifier<VisualizerSettings> {
  VisualizerSettingsNotifier(this._ref) : super(const VisualizerSettings()) {
    _load();
  }

  final Ref _ref;

  void _load() {
    final storage = _ref.read(storageServiceProvider);
    final styleRaw = storage.getString(StorageKeys.visualizerStyle).valueOrNull;
    final colorRaw = storage.getString(StorageKeys.visualizerColor).valueOrNull;
    final sensRaw = storage.getString(StorageKeys.visualizerSensitivity).valueOrNull;
    final fpsRaw = storage.getString(StorageKeys.visualizerFpsCap).valueOrNull;
    final lockRaw = storage.getBool(StorageKeys.visualizerShowOnLockscreen).valueOrNull;

    state = VisualizerSettings(
      style: VisualizerStyle.values.firstWhere(
        (e) => e.name == styleRaw,
        orElse: () => VisualizerStyle.bars,
      ),
      colorHex: colorRaw ?? '0xFF00E5FF',
      sensitivity: double.tryParse(sensRaw ?? '') ?? 1.0,
      fpsCap: int.tryParse(fpsRaw ?? '') ?? 60,
      showOnLockScreen: lockRaw ?? false,
    );
  }

  Future<void> update(VisualizerSettings settings) async {
    state = settings;
    final storage = _ref.read(storageServiceProvider);
    await storage.setString(StorageKeys.visualizerStyle, settings.style.name);
    await storage.setString(StorageKeys.visualizerColor, settings.colorHex);
    await storage.setString(StorageKeys.visualizerSensitivity, settings.sensitivity.toString());
    await storage.setString(StorageKeys.visualizerFpsCap, settings.fpsCap.toString());
    await storage.setBool(StorageKeys.visualizerShowOnLockscreen, settings.showOnLockScreen);
  }

  void cycleStyle() {
    const styles = VisualizerStyle.values;
    final nextIndex = (styles.indexOf(state.style) + 1) % styles.length;
    update(state.copyWith(style: styles[nextIndex]));
  }
}

final visualizerSettingsProvider =
    StateNotifierProvider<VisualizerSettingsNotifier, VisualizerSettings>((ref) {
  return VisualizerSettingsNotifier(ref);
});

/// Live real-time audio FFT magnitude stream for visualizers.
final liveMagnitudesProvider = StreamProvider.autoDispose<List<double>>((ref) {
  final playerState = ref.watch(playerNotifierProvider);
  final settings = ref.watch(visualizerSettingsProvider);

  if (settings.style == VisualizerStyle.off || !playerState.isPlaying) {
    return Stream.value(List<double>.filled(settings.fftSize ~/ 2, 0.0));
  }

  final engine = FftEngine(size: settings.fftSize);
  final fps = settings.fpsCap.clamp(15, 120);
  final intervalMs = 1000 ~/ fps;

  return Stream.periodic(Duration(milliseconds: intervalMs), (tick) {
    final posSeconds = playerState.position.inMilliseconds / 1000.0 + (tick * (intervalMs / 1000.0));
    final samples = FftEngine.synthesizeTimeDomainSamples(
      sampleCount: settings.fftSize,
      positionSeconds: posSeconds,
      isPlaying: playerState.isPlaying,
      sensitivity: settings.sensitivity,
    );
    return engine.computeMagnitudes(samples, sensitivity: settings.sensitivity);
  });
});
