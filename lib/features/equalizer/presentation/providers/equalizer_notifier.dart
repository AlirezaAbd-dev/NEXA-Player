import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/equalizer_preset.dart';
import '../../domain/entities/equalizer_state.dart';
import '../../domain/entities/reverb_preset.dart';
import '../../domain/services/equalizer_service.dart';

/// StateNotifier that manages reactive equalizer state for the UI.
class EqualizerNotifier extends StateNotifier<EqualizerState> {
  EqualizerNotifier(this._service) : super(_service.currentState) {
    _subscription = _service.stateStream.listen((newState) {
      state = newState;
    });
  }

  final IEqualizerService _service;
  StreamSubscription<EqualizerState>? _subscription;

  Future<void> setEnabled(bool enabled) => _service.setEnabled(enabled);

  Future<void> toggleEnabled() => _service.setEnabled(!state.isEnabled);

  Future<void> setPreamp(double gain) => _service.setPreamp(gain);

  Future<void> setBandGain(int bandIndex, double gain) =>
      _service.setBandGain(bandIndex, gain);

  Future<void> setBassBoost(double strength) =>
      _service.setBassBoost(strength);

  Future<void> setVirtualizer(double strength) =>
      _service.setVirtualizer(strength);

  Future<void> setReverb(ReverbPreset preset) => _service.setReverb(preset);

  Future<void> applyPreset(String presetId) => _service.applyPreset(presetId);

  Future<void> resetToFlat() => _service.resetToFlat();

  Future<EqualizerPreset> saveCustomPreset(String name) =>
      _service.saveCustomPreset(name);

  Future<bool> deleteCustomPreset(String presetId) =>
      _service.deleteCustomPreset(presetId);

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
