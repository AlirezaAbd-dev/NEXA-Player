/// Immutable model representing audiophile audio engine settings.
class AudioSettings {
  const AudioSettings({
    this.gaplessPlayback = true,
    this.crossfadeEnabled = false,
    this.crossfadeDurationSeconds = 3,
    this.fadingOnPlayPause = true,
    this.audioBufferSize = 'medium', // low, medium, high
    this.audioOutput = 'auto', // auto, speaker, headset, bluetooth, usb_dac
    this.sampleRate = 'auto', // auto, 44.1, 48, 88.2, 96, 192
    this.bitDepth = '24', // 16, 24, 32_float
    this.dithering = 'triangular', // off, triangular, shaped
    this.hiResMode = true,
    this.replayGainMode = 'smart', // off, track, album, smart
    this.replayGainPreampDb = 0.0, // -12 to +12
    this.dvcEnabled = true, // Direct Volume Control
    this.stereoWidening = 'off', // off, software, hardware
  });

  final bool gaplessPlayback;
  final bool crossfadeEnabled;
  final int crossfadeDurationSeconds;
  final bool fadingOnPlayPause;
  final String audioBufferSize;
  final String audioOutput;
  final String sampleRate;
  final String bitDepth;
  final String dithering;
  final bool hiResMode;
  final String replayGainMode;
  final double replayGainPreampDb;
  final bool dvcEnabled;
  final String stereoWidening;

  AudioSettings copyWith({
    bool? gaplessPlayback,
    bool? crossfadeEnabled,
    int? crossfadeDurationSeconds,
    bool? fadingOnPlayPause,
    String? audioBufferSize,
    String? audioOutput,
    String? sampleRate,
    String? bitDepth,
    String? dithering,
    bool? hiResMode,
    String? replayGainMode,
    double? replayGainPreampDb,
    bool? dvcEnabled,
    String? stereoWidening,
  }) {
    return AudioSettings(
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      crossfadeEnabled: crossfadeEnabled ?? this.crossfadeEnabled,
      crossfadeDurationSeconds:
          crossfadeDurationSeconds ?? this.crossfadeDurationSeconds,
      fadingOnPlayPause: fadingOnPlayPause ?? this.fadingOnPlayPause,
      audioBufferSize: audioBufferSize ?? this.audioBufferSize,
      audioOutput: audioOutput ?? this.audioOutput,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      dithering: dithering ?? this.dithering,
      hiResMode: hiResMode ?? this.hiResMode,
      replayGainMode: replayGainMode ?? this.replayGainMode,
      replayGainPreampDb: replayGainPreampDb ?? this.replayGainPreampDb,
      dvcEnabled: dvcEnabled ?? this.dvcEnabled,
      stereoWidening: stereoWidening ?? this.stereoWidening,
    );
  }

  Map<String, dynamic> toJson() => {
        'gaplessPlayback': gaplessPlayback,
        'crossfadeEnabled': crossfadeEnabled,
        'crossfadeDurationSeconds': crossfadeDurationSeconds,
        'fadingOnPlayPause': fadingOnPlayPause,
        'audioBufferSize': audioBufferSize,
        'audioOutput': audioOutput,
        'sampleRate': sampleRate,
        'bitDepth': bitDepth,
        'dithering': dithering,
        'hiResMode': hiResMode,
        'replayGainMode': replayGainMode,
        'replayGainPreampDb': replayGainPreampDb,
        'dvcEnabled': dvcEnabled,
        'stereoWidening': stereoWidening,
      };

  factory AudioSettings.fromJson(Map<String, dynamic> json) => AudioSettings(
        gaplessPlayback: json['gaplessPlayback'] as bool? ?? true,
        crossfadeEnabled: json['crossfadeEnabled'] as bool? ?? false,
        crossfadeDurationSeconds:
            (json['crossfadeDurationSeconds'] as num?)?.toInt() ?? 3,
        fadingOnPlayPause: json['fadingOnPlayPause'] as bool? ?? true,
        audioBufferSize: json['audioBufferSize'] as String? ?? 'medium',
        audioOutput: json['audioOutput'] as String? ?? 'auto',
        sampleRate: json['sampleRate'] as String? ?? 'auto',
        bitDepth: json['bitDepth'] as String? ?? '24',
        dithering: json['dithering'] as String? ?? 'triangular',
        hiResMode: json['hiResMode'] as bool? ?? true,
        replayGainMode: json['replayGainMode'] as String? ?? 'smart',
        replayGainPreampDb:
            (json['replayGainPreampDb'] as num?)?.toDouble() ?? 0.0,
        dvcEnabled: json['dvcEnabled'] as bool? ?? true,
        stereoWidening: json['stereoWidening'] as String? ?? 'off',
      );
}
