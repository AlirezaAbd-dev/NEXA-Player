import 'audio_settings.dart';

/// Preset modes for audiophile listening environments.
enum AudiophilePresetType {
  bitPerfectPurist,
  warmTube,
  lateNightClamp,
  batterySaver,
}

/// Metadata and settings configuration for 1-tap audiophile presets.
class AudiophilePreset {
  final AudiophilePresetType type;
  final String title;
  final String description;
  final String badge;
  final AudioSettings settings;

  const AudiophilePreset({
    required this.type,
    required this.title,
    required this.description,
    required this.badge,
    required this.settings,
  });

  static const List<AudiophilePreset> presets = [
    AudiophilePreset(
      type: AudiophilePresetType.bitPerfectPurist,
      title: 'Bit-Perfect Purist',
      description: 'Hi-Res 192k direct DVC, triangular dither, zero crossfade & DSP bypass',
      badge: '192k / 24-bit',
      settings: AudioSettings(
        hiResMode: true,
        sampleRate: '192',
        bitDepth: '24',
        dvcEnabled: true,
        dithering: 'triangular',
        gaplessPlayback: true,
        crossfadeEnabled: false,
        replayGainMode: 'off',
        stereoWidening: 'off',
      ),
    ),
    AudiophilePreset(
      type: AudiophilePresetType.warmTube,
      title: 'Warm Tube Harmonic',
      description: 'Analog smoothing with shaped dithering, gentle crossfade & acoustic widening',
      badge: 'ANALOG WARMTH',
      settings: AudioSettings(
        hiResMode: true,
        sampleRate: '96',
        bitDepth: '24',
        dvcEnabled: true,
        dithering: 'shaped',
        gaplessPlayback: true,
        crossfadeEnabled: true,
        crossfadeDurationSeconds: 2,
        replayGainMode: 'smart',
        stereoWidening: 'software',
      ),
    ),
    AudiophilePreset(
      type: AudiophilePresetType.lateNightClamp,
      title: 'Late Night Dynamic Clamp',
      description: 'Even volume normalization with smart ReplayGain and soft fade transitions',
      badge: 'LEVEL BALANCED',
      settings: AudioSettings(
        hiResMode: false,
        sampleRate: '48',
        bitDepth: '16',
        dvcEnabled: true,
        dithering: 'triangular',
        gaplessPlayback: true,
        crossfadeEnabled: true,
        crossfadeDurationSeconds: 4,
        replayGainMode: 'track',
        replayGainPreampDb: -2.0,
        stereoWidening: 'off',
      ),
    ),
    AudiophilePreset(
      type: AudiophilePresetType.batterySaver,
      title: 'Battery Saver',
      description: 'Energy-optimized 44.1k pipeline, hardware offload buffer, no dithering overhead',
      badge: 'LOW POWER',
      settings: AudioSettings(
        hiResMode: false,
        sampleRate: '44.1',
        bitDepth: '16',
        dvcEnabled: false,
        dithering: 'off',
        gaplessPlayback: true,
        crossfadeEnabled: false,
        replayGainMode: 'off',
        audioBufferSize: 'high',
        stereoWidening: 'off',
      ),
    ),
  ];
}
