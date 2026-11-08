import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../domain/entities/equalizer_band.dart';
import '../../domain/entities/equalizer_preset.dart';
import '../../domain/entities/equalizer_state.dart';
import '../../domain/entities/reverb_preset.dart';
import '../../domain/services/equalizer_service.dart';

/// Pure Dart implementation of [IEqualizerService] with 16 factory presets,
/// persistence via [IStorageService], and psychoacoustic DSP parameters.
class PureDartEqualizerService implements IEqualizerService {
  PureDartEqualizerService({IStorageService? storageService})
      : _storageService = storageService {
    _state = _buildInitialState();
  }

  final IStorageService? _storageService;
  final StreamController<EqualizerState> _stateController =
      StreamController<EqualizerState>.broadcast();

  late EqualizerState _state;
  bool _isInitialized = false;

  /// Standard ISO 10-band center frequencies (in Hz).
  static const List<int> defaultFrequencies = [
    31,
    62,
    125,
    250,
    500,
    1000,
    2000,
    4000,
    8000,
    16000,
  ];

  /// 16 Factory Presets calibrated for optimal acoustic fidelity.
  static final List<EqualizerPreset> factoryPresets = [
    const EqualizerPreset(
      id: 'flat',
      name: 'Flat',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    ),
    const EqualizerPreset(
      id: 'rock',
      name: 'Rock',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [4.5, 3.0, -1.5, -2.5, 1.0, 2.5, 4.0, 5.0, 5.5, 6.0],
      bassBoost: 0.2,
    ),
    const EqualizerPreset(
      id: 'pop',
      name: 'Pop',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [-1.5, 1.0, 3.0, 4.0, 3.5, 1.5, -1.0, -1.5, -1.5, -1.5],
      virtualizer: 0.15,
    ),
    const EqualizerPreset(
      id: 'jazz',
      name: 'Jazz',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [3.5, 2.5, 1.0, 1.5, -1.5, -1.5, 0.0, 1.5, 3.0, 3.5],
    ),
    const EqualizerPreset(
      id: 'electronic',
      name: 'Electronic',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [4.0, 3.5, 1.0, 0.0, -2.0, 2.0, 1.0, 2.0, 4.0, 4.5],
      bassBoost: 0.35,
      virtualizer: 0.25,
    ),
    const EqualizerPreset(
      id: 'classical',
      name: 'Classical',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [4.5, 3.5, 3.0, 2.5, -1.5, -1.5, 0.0, 2.0, 3.5, 3.5],
      reverb: ReverbPreset.hall,
    ),
    const EqualizerPreset(
      id: 'metal',
      name: 'Metal',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [4.0, 1.0, 0.0, 0.0, -1.5, 0.0, 2.0, 1.0, 4.0, 4.5],
      bassBoost: 0.25,
    ),
    const EqualizerPreset(
      id: 'hiphop',
      name: 'Hip-Hop',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [5.0, 4.5, 1.5, 2.5, -1.0, -1.0, 1.5, -1.0, 2.0, 3.0],
      bassBoost: 0.4,
    ),
    const EqualizerPreset(
      id: 'dance',
      name: 'Dance',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [4.5, 6.0, 2.5, 0.0, 2.0, 3.5, 4.0, 3.5, 0.0, 0.0],
      bassBoost: 0.3,
    ),
    const EqualizerPreset(
      id: 'rnb',
      name: 'R&B',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [3.0, 6.5, 5.0, 1.5, -2.0, 1.5, 2.5, 3.0, 3.5, 4.0],
    ),
    const EqualizerPreset(
      id: 'vocal',
      name: 'Vocal Boost',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [-2.0, -3.5, -2.0, 1.5, 4.0, 4.0, 3.0, 1.5, 0.0, -1.5],
    ),
    const EqualizerPreset(
      id: 'bass_boost',
      name: 'Bass Boost',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [6.0, 5.0, 4.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      bassBoost: 0.6,
    ),
    const EqualizerPreset(
      id: 'treble_boost',
      name: 'Treble Boost',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [0.0, 0.0, 0.0, 0.0, 0.0, 1.5, 3.0, 5.0, 6.5, 7.5],
    ),
    const EqualizerPreset(
      id: 'acoustic',
      name: 'Acoustic',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [3.5, 3.0, 1.5, 1.0, 2.0, 2.0, 3.0, 3.5, 3.0, 2.0],
      reverb: ReverbPreset.room,
    ),
    const EqualizerPreset(
      id: 'headphone',
      name: 'Headphone',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [3.0, 5.0, 2.5, -2.0, -1.5, 1.0, 2.5, 4.0, 5.5, 6.0],
      virtualizer: 0.3,
    ),
    const EqualizerPreset(
      id: 'loudness',
      name: 'Loudness',
      isBuiltIn: true,
      preamp: 0.0,
      bandGains: [5.5, 4.0, 0.0, -1.5, -2.5, 0.0, -1.0, -4.5, 6.0, 2.0],
      bassBoost: 0.35,
    ),
  ];

  @override
  Stream<EqualizerState> get stateStream => _stateController.stream;

  @override
  EqualizerState get currentState => _state;

  EqualizerState _buildInitialState() {
    final bands = List.generate(
      defaultFrequencies.length,
      (index) => EqualizerBand(
        index: index,
        centerFrequency: defaultFrequencies[index],
        gain: 0.0,
      ),
    );

    return EqualizerState(
      isEnabled: true,
      preamp: 0.0,
      bands: bands,
      bassBoost: 0.0,
      virtualizer: 0.0,
      reverb: ReverbPreset.none,
      activePresetId: 'flat',
      presets: List<EqualizerPreset>.from(factoryPresets),
    );
  }

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (_storageService == null) {
      _emit(_state);
      return;
    }

    try {
      // 1. Load Custom Presets
      List<EqualizerPreset> allPresets = List<EqualizerPreset>.from(factoryPresets);
      final customJson = _storageService.getString(StorageKeys.equalizerCustomPresets).valueOrNull;
      if (customJson != null) {
        try {
          final decoded = jsonDecode(customJson) as List<dynamic>;
          final customPresets = decoded
              .map((item) => EqualizerPreset.fromJson(item as Map<String, dynamic>))
              .toList();
          allPresets.addAll(customPresets);
        } catch (e) {
          debugPrint('Error parsing custom presets: $e');
        }
      }

      // 2. Load Master Enabled Toggle
      final isEnabled = _storageService.getBool(StorageKeys.equalizerEnabled).valueOrNull ?? true;

      // 3. Load Preamp
      final preampStr = _storageService.getString(StorageKeys.equalizerPreamp).valueOrNull;
      final preamp = preampStr != null ? double.tryParse(preampStr) ?? 0.0 : 0.0;

      // 4. Load Bass Boost
      final bassStr = _storageService.getString(StorageKeys.bassBoost).valueOrNull;
      final bassBoost = bassStr != null ? double.tryParse(bassStr) ?? 0.0 : 0.0;

      // 5. Load Virtualizer
      final virtStr = _storageService.getString(StorageKeys.virtualizer).valueOrNull;
      final virtualizer = virtStr != null ? double.tryParse(virtStr) ?? 0.0 : 0.0;

      // 6. Load Reverb Preset
      final reverbStr = _storageService.getString(StorageKeys.equalizerReverb).valueOrNull;
      final reverb = reverbStr != null ? ReverbPreset.fromJson(reverbStr) : ReverbPreset.none;

      // 7. Load Active Preset ID
      final activePresetId =
          _storageService.getString(StorageKeys.equalizerPreset).valueOrNull ?? 'flat';

      // 8. Load Bands
      List<EqualizerBand> bands = List.generate(
        defaultFrequencies.length,
        (index) => EqualizerBand(
          index: index,
          centerFrequency: defaultFrequencies[index],
          gain: 0.0,
        ),
      );

      final bandsJson = _storageService.getString(StorageKeys.equalizerBands).valueOrNull;
      if (bandsJson != null) {
        try {
          final decoded = jsonDecode(bandsJson) as List<dynamic>;
          for (int i = 0; i < decoded.length && i < bands.length; i++) {
            final gain = (decoded[i] as num).toDouble();
            bands[i] = bands[i].copyWith(gain: gain);
          }
        } catch (e) {
          debugPrint('Error parsing saved EQ bands: $e');
        }
      } else {
        // If no explicit bands saved, use the active preset's band gains if available
        final matchedPreset = allPresets.firstWhere(
          (p) => p.id == activePresetId,
          orElse: () => factoryPresets.first,
        );
        for (int i = 0; i < matchedPreset.bandGains.length && i < bands.length; i++) {
          bands[i] = bands[i].copyWith(gain: matchedPreset.bandGains[i]);
        }
      }

      _state = EqualizerState(
        isEnabled: isEnabled,
        preamp: preamp.clamp(-15.0, 15.0),
        bands: bands,
        bassBoost: bassBoost.clamp(0.0, 1.0),
        virtualizer: virtualizer.clamp(0.0, 1.0),
        reverb: reverb,
        activePresetId: activePresetId,
        presets: allPresets,
      );

      _emit(_state);
    } catch (e) {
      debugPrint('PureDartEqualizerService.initialize error: $e');
      _emit(_state);
    }
  }

  void _emit(EqualizerState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
  }

  @override
  Future<void> setEnabled(bool enabled) async {
    _emit(_state.copyWith(isEnabled: enabled));
    await _storageService?.setBool(StorageKeys.equalizerEnabled, enabled);
  }

  @override
  Future<void> setPreamp(double gain) async {
    final clamped = gain.clamp(-15.0, 15.0);
    _emit(_state.copyWith(preamp: clamped));
    await _storageService?.setString(StorageKeys.equalizerPreamp, clamped.toString());
  }

  @override
  Future<void> setBandGain(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= _state.bands.length) return;
    final updatedBands = List<EqualizerBand>.from(_state.bands);
    updatedBands[bandIndex] = updatedBands[bandIndex].copyWith(gain: gain);

    _emit(_state.copyWith(bands: updatedBands));
    await _persistBands(updatedBands);
  }

  @override
  Future<void> setBassBoost(double strength) async {
    final clamped = strength.clamp(0.0, 1.0);
    _emit(_state.copyWith(bassBoost: clamped));
    await _storageService?.setString(StorageKeys.bassBoost, clamped.toString());
  }

  @override
  Future<void> setVirtualizer(double strength) async {
    final clamped = strength.clamp(0.0, 1.0);
    _emit(_state.copyWith(virtualizer: clamped));
    await _storageService?.setString(StorageKeys.virtualizer, clamped.toString());
  }

  @override
  Future<void> setReverb(ReverbPreset preset) async {
    _emit(_state.copyWith(reverb: preset));
    await _storageService?.setString(StorageKeys.equalizerReverb, preset.toJson());
  }

  @override
  Future<void> applyPreset(String presetId) async {
    final preset = _state.presets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => factoryPresets.first,
    );

    final updatedBands = List<EqualizerBand>.generate(
      _state.bands.length,
      (index) {
        final gain = index < preset.bandGains.length ? preset.bandGains[index] : 0.0;
        return _state.bands[index].copyWith(gain: gain);
      },
    );

    _emit(_state.copyWith(
      activePresetId: preset.id,
      preamp: preset.preamp,
      bands: updatedBands,
      bassBoost: preset.bassBoost,
      virtualizer: preset.virtualizer,
      reverb: preset.reverb,
    ));

    await _storageService?.setString(StorageKeys.equalizerPreset, preset.id);
    await _storageService?.setString(StorageKeys.equalizerPreamp, preset.preamp.toString());
    await _storageService?.setString(StorageKeys.bassBoost, preset.bassBoost.toString());
    await _storageService?.setString(StorageKeys.virtualizer, preset.virtualizer.toString());
    await _storageService?.setString(StorageKeys.equalizerReverb, preset.reverb.toJson());
    await _persistBands(updatedBands);
  }

  @override
  Future<void> resetToFlat() async {
    await applyPreset('flat');
  }

  @override
  Future<EqualizerPreset> saveCustomPreset(String name) async {
    final cleanName = name.trim().isEmpty ? 'Custom Preset' : name.trim();
    final newId = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final customPreset = EqualizerPreset(
      id: newId,
      name: cleanName,
      isBuiltIn: false,
      preamp: _state.preamp,
      bandGains: _state.bands.map((b) => b.gain).toList(),
      bassBoost: _state.bassBoost,
      virtualizer: _state.virtualizer,
      reverb: _state.reverb,
    );

    final updatedPresets = List<EqualizerPreset>.from(_state.presets)..add(customPreset);

    _emit(_state.copyWith(
      activePresetId: newId,
      presets: updatedPresets,
    ));

    await _storageService?.setString(StorageKeys.equalizerPreset, newId);
    await _persistCustomPresets(updatedPresets);
    return customPreset;
  }

  @override
  Future<bool> deleteCustomPreset(String presetId) async {
    final target = _state.presets.firstWhere(
      (p) => p.id == presetId,
      orElse: () => const EqualizerPreset(id: '', name: '', bandGains: []),
    );

    // Factory presets cannot be deleted
    if (target.id.isEmpty || target.isBuiltIn) {
      return false;
    }

    final updatedPresets = _state.presets.where((p) => p.id != presetId).toList();
    final newActiveId = _state.activePresetId == presetId ? 'flat' : _state.activePresetId;

    _emit(_state.copyWith(
      activePresetId: newActiveId,
      presets: updatedPresets,
    ));

    if (newActiveId == 'flat') {
      await applyPreset('flat');
    }
    await _persistCustomPresets(updatedPresets);
    return true;
  }

  Future<void> _persistBands(List<EqualizerBand> bands) async {
    final gains = bands.map((b) => b.gain).toList();
    await _storageService?.setString(StorageKeys.equalizerBands, jsonEncode(gains));
  }

  Future<void> _persistCustomPresets(List<EqualizerPreset> allPresets) async {
    final customPresets = allPresets.where((p) => !p.isBuiltIn).toList();
    final encoded = jsonEncode(customPresets.map((p) => p.toJson()).toList());
    await _storageService?.setString(StorageKeys.equalizerCustomPresets, encoded);
  }

  @override
  void dispose() {
    _stateController.close();
  }
}
