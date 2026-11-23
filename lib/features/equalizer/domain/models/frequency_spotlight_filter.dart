import 'dart:math' as math;
import 'package:equatable/equatable.dart';

/// Pure Dart mathematical frequency spotlight model ("Acoustic Magnifying Glass").
/// Dynamically isolations and boosts a specific frequency zone on a logarithmic scale.
class FrequencySpotlightFilter extends Equatable {
  final double sweepFraction; // 0.0 to 1.0
  final double boostGainDb;
  final double qFactor;
  final bool isActive;

  const FrequencySpotlightFilter({
    this.sweepFraction = 0.5,
    this.boostGainDb = 8.0,
    this.qFactor = 1.4,
    this.isActive = false,
  });

  static const double minFrequency = 40.0;
  static const double maxFrequency = 16000.0;

  /// Logarithmic center frequency in Hertz.
  double get centerFrequencyHz {
    final clamped = sweepFraction.clamp(0.0, 1.0);
    return minFrequency * math.pow(maxFrequency / minFrequency, clamped);
  }

  /// Human-readable frequency label (e.g. "60 Hz", "1.2 kHz").
  String get formattedFrequency {
    final hz = centerFrequencyHz;
    if (hz >= 1000.0) {
      final khz = hz / 1000.0;
      return '${khz >= 10 ? khz.toStringAsFixed(0) : khz.toStringAsFixed(1)} kHz';
    }
    return '${hz.round()} Hz';
  }

  /// Psychoacoustic frequency band category.
  String get bandCategory {
    final hz = centerFrequencyHz;
    if (hz < 60.0) return 'Sub-Bass';
    if (hz < 250.0) return 'Bass & Warmth';
    if (hz < 500.0) return 'Low-Mid Body';
    if (hz < 2000.0) return 'Vocal Midrange';
    if (hz < 4000.0) return 'High-Mid Clarity';
    if (hz < 8000.0) return 'Presence & Attack';
    return 'Brilliance & Air';
  }

  FrequencySpotlightFilter copyWith({
    double? sweepFraction,
    double? boostGainDb,
    double? qFactor,
    bool? isActive,
  }) {
    return FrequencySpotlightFilter(
      sweepFraction: (sweepFraction ?? this.sweepFraction).clamp(0.0, 1.0),
      boostGainDb: boostGainDb ?? this.boostGainDb,
      qFactor: qFactor ?? this.qFactor,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [sweepFraction, boostGainDb, qFactor, isActive];
}
