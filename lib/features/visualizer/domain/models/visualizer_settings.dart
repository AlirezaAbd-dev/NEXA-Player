/// Supported visualization display modes.
enum VisualizerStyle {
  /// Multi-bar vertical frequency equalizer bars.
  bars,

  /// Radial/circular frequency spectrum radiating outward.
  circle,

  /// Continuous smooth flowing wave with gradient fill.
  wave,

  /// Heatmap frequency over time display.
  spectrogram,

  /// Vintage analog dual needle VU meter.
  vuMeter,

  /// Hidden visualizer.
  off,
}

/// Visualizer settings model for styling, frame limits, and sensitivity.
class VisualizerSettings {
  const VisualizerSettings({
    this.style = VisualizerStyle.bars,
    this.colorHex = '0xFF00E5FF', // Neon Cyan default
    this.sensitivity = 1.0, // 0.5x to 2.5x
    this.fpsCap = 60, // 30, 60, 120
    this.fftSize = 64, // 32, 64, 128
    this.showOnLockScreen = false,
  });

  final VisualizerStyle style;
  final String colorHex;
  final double sensitivity;
  final int fpsCap;
  final int fftSize;
  final bool showOnLockScreen;

  VisualizerSettings copyWith({
    VisualizerStyle? style,
    String? colorHex,
    double? sensitivity,
    int? fpsCap,
    int? fftSize,
    bool? showOnLockScreen,
  }) {
    return VisualizerSettings(
      style: style ?? this.style,
      colorHex: colorHex ?? this.colorHex,
      sensitivity: sensitivity ?? this.sensitivity,
      fpsCap: fpsCap ?? this.fpsCap,
      fftSize: fftSize ?? this.fftSize,
      showOnLockScreen: showOnLockScreen ?? this.showOnLockScreen,
    );
  }

  Map<String, dynamic> toJson() => {
        'style': style.name,
        'colorHex': colorHex,
        'sensitivity': sensitivity,
        'fpsCap': fpsCap,
        'fftSize': fftSize,
        'showOnLockScreen': showOnLockScreen,
      };

  factory VisualizerSettings.fromJson(Map<String, dynamic> json) {
    return VisualizerSettings(
      style: VisualizerStyle.values.firstWhere(
        (e) => e.name == json['style'],
        orElse: () => VisualizerStyle.bars,
      ),
      colorHex: json['colorHex'] as String? ?? '0xFF00E5FF',
      sensitivity: (json['sensitivity'] as num?)?.toDouble() ?? 1.0,
      fpsCap: (json['fpsCap'] as num?)?.toInt() ?? 60,
      fftSize: (json['fftSize'] as num?)?.toInt() ?? 64,
      showOnLockScreen: json['showOnLockScreen'] as bool? ?? false,
    );
  }
}
