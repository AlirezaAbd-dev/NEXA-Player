import 'package:flutter/foundation.dart';
import 'equalizer_band.dart';
import 'equalizer_preset.dart';
import 'reverb_preset.dart';

/// Complete immutable snapshot of the equalizer and DSP audio processing state.
@immutable
class EqualizerState {
  const EqualizerState({
    required this.isEnabled,
    required this.preamp,
    required this.bands,
    required this.bassBoost,
    required this.virtualizer,
    required this.reverb,
    required this.activePresetId,
    required this.presets,
  });

  /// Master switch enabling or bypassing the equalizer and DSP pipeline.
  final bool isEnabled;

  /// Global preamplification gain in dB (-15.0 dB to +15.0 dB).
  final double preamp;

  /// Ordered list of parametric frequency bands (typically 10 bands: 31Hz -> 16kHz).
  final List<EqualizerBand> bands;

  /// Psychoacoustic bass enhancement strength (0.0 = off, 1.0 = maximum).
  final double bassBoost;

  /// Psychoacoustic 3D stereo wideness / virtualizer strength (0.0 = off, 1.0 = maximum).
  final double virtualizer;

  /// Reverb acoustic environment preset.
  final ReverbPreset reverb;

  /// ID of the currently selected preset, or null if customized.
  final String? activePresetId;

  /// All available presets (built-in factory profiles + user custom profiles).
  final List<EqualizerPreset> presets;

  /// Resolves the currently active [EqualizerPreset], if matched.
  EqualizerPreset? get activePreset {
    if (activePresetId == null) return null;
    try {
      return presets.firstWhere((p) => p.id == activePresetId);
    } catch (_) {
      return null;
    }
  }

  /// Whether current band gains match the active preset.
  bool get isModifiedFromActivePreset {
    final preset = activePreset;
    if (preset == null) return true;
    if (bands.length != preset.bandGains.length) return true;
    for (int i = 0; i < bands.length; i++) {
      if ((bands[i].gain - preset.bandGains[i]).abs() > 0.05) return true;
    }
    if ((preamp - preset.preamp).abs() > 0.05) return true;
    if ((bassBoost - preset.bassBoost).abs() > 0.05) return true;
    if ((virtualizer - preset.virtualizer).abs() > 0.05) return true;
    if (reverb != preset.reverb) return true;
    return false;
  }

  EqualizerState copyWith({
    bool? isEnabled,
    double? preamp,
    List<EqualizerBand>? bands,
    double? bassBoost,
    double? virtualizer,
    ReverbPreset? reverb,
    String? activePresetId,
    bool clearActivePresetId = false,
    List<EqualizerPreset>? presets,
  }) {
    return EqualizerState(
      isEnabled: isEnabled ?? this.isEnabled,
      preamp: preamp ?? this.preamp,
      bands: bands ?? List<EqualizerBand>.from(this.bands),
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      reverb: reverb ?? this.reverb,
      activePresetId: clearActivePresetId
          ? null
          : (activePresetId ?? this.activePresetId),
      presets: presets ?? List<EqualizerPreset>.from(this.presets),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqualizerState &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          preamp == other.preamp &&
          listEquals(bands, other.bands) &&
          bassBoost == other.bassBoost &&
          virtualizer == other.virtualizer &&
          reverb == other.reverb &&
          activePresetId == other.activePresetId &&
          listEquals(presets, other.presets);

  @override
  int get hashCode => Object.hash(
        isEnabled,
        preamp,
        Object.hashAll(bands),
        bassBoost,
        virtualizer,
        reverb,
        activePresetId,
        Object.hashAll(presets),
      );

  @override
  String toString() =>
      'EqualizerState(enabled: $isEnabled, activePreset: $activePresetId, bands: ${bands.length})';
}
