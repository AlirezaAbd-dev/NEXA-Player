import '../entities/equalizer_preset.dart';
import '../entities/equalizer_state.dart';
import '../entities/reverb_preset.dart';

/// Service contract defining operations for managing the 10-band parametric
/// equalizer, psychoacoustic DSP effects, and preset management.
abstract interface class IEqualizerService {
  /// Stream emitting real-time updates whenever EQ bands, preamp, or DSP effects change.
  Stream<EqualizerState> get stateStream;

  /// Returns the current state synchronously.
  EqualizerState get currentState;

  /// Initializes the service by loading persisted user settings and presets.
  Future<void> initialize();

  /// Toggles master bypass switch for the equalizer and DSP engine.
  Future<void> setEnabled(bool enabled);

  /// Sets global preamplification gain in decibels (-15.0 dB to +15.0 dB).
  Future<void> setPreamp(double gain);

  /// Sets the gain for a specific band index in decibels (-15.0 dB to +15.0 dB).
  Future<void> setBandGain(int bandIndex, double gain);

  /// Sets the psychoacoustic bass enhancement strength (0.0 to 1.0).
  Future<void> setBassBoost(double strength);

  /// Sets the stereo wideness/virtualizer strength (0.0 to 1.0).
  Future<void> setVirtualizer(double strength);

  /// Sets the active reverb room simulation environment.
  Future<void> setReverb(ReverbPreset preset);

  /// Applies a preset by its identifier.
  Future<void> applyPreset(String presetId);

  /// Resets all 10 bands and preamp to 0.0 dB (Flat).
  Future<void> resetToFlat();

  /// Captures the current configuration and saves it as a new custom preset.
  Future<EqualizerPreset> saveCustomPreset(String name);

  /// Removes a user-created custom preset by its [presetId]. Factory presets cannot be deleted.
  Future<bool> deleteCustomPreset(String presetId);

  /// Releases resources, timers, and stream controllers.
  void dispose();
}
