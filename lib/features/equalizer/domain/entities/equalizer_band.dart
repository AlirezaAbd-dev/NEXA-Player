import 'package:flutter/foundation.dart';

/// Represents a single frequency band in a parametric/graphic equalizer.
@immutable
class EqualizerBand {
  const EqualizerBand({
    required this.index,
    required this.centerFrequency,
    required this.gain,
    this.minGain = -15.0,
    this.maxGain = 15.0,
  });

  /// 0-indexed position of this band in the filter bank.
  final int index;

  /// Center frequency in Hertz (Hz).
  final int centerFrequency;

  /// Current gain in decibels (dB), typically between [minGain] and [maxGain].
  final double gain;

  /// Minimum allowable gain in decibels (dB). Default is -15.0 dB.
  final double minGain;

  /// Maximum allowable gain in decibels (dB). Default is +15.0 dB.
  final double maxGain;

  /// Returns a user-friendly label for the frequency (e.g. "31 Hz", "1 kHz", "16 kHz").
  String get displayFrequency {
    if (centerFrequency >= 1000) {
      final khz = centerFrequency / 1000.0;
      return khz % 1 == 0 ? '${khz.toInt()} kHz' : '${khz.toStringAsFixed(1)} kHz';
    }
    return '$centerFrequency Hz';
  }

  /// Returns a compact label for tight UI spaces (e.g. "31", "1k", "16k").
  String get shortFrequency {
    if (centerFrequency >= 1000) {
      final khz = centerFrequency / 1000.0;
      return khz % 1 == 0 ? '${khz.toInt()}k' : '${khz.toStringAsFixed(1)}k';
    }
    return '$centerFrequency';
  }

  /// Returns a formatted gain string (e.g. "+3.5 dB", "0.0 dB", "-2.0 dB").
  String get formattedGain {
    final prefix = gain > 0 ? '+' : '';
    return '$prefix${gain.toStringAsFixed(1)} dB';
  }

  /// Creates a copy with the given fields replaced.
  EqualizerBand copyWith({
    int? index,
    int? centerFrequency,
    double? gain,
    double? minGain,
    double? maxGain,
  }) {
    return EqualizerBand(
      index: index ?? this.index,
      centerFrequency: centerFrequency ?? this.centerFrequency,
      gain: (gain ?? this.gain).clamp(
        minGain ?? this.minGain,
        maxGain ?? this.maxGain,
      ),
      minGain: minGain ?? this.minGain,
      maxGain: maxGain ?? this.maxGain,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'centerFrequency': centerFrequency,
      'gain': gain,
      'minGain': minGain,
      'maxGain': maxGain,
    };
  }

  factory EqualizerBand.fromJson(Map<String, dynamic> json) {
    return EqualizerBand(
      index: json['index'] as int,
      centerFrequency: json['centerFrequency'] as int,
      gain: (json['gain'] as num).toDouble(),
      minGain: (json['minGain'] as num?)?.toDouble() ?? -15.0,
      maxGain: (json['maxGain'] as num?)?.toDouble() ?? 15.0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqualizerBand &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          centerFrequency == other.centerFrequency &&
          gain == other.gain &&
          minGain == other.minGain &&
          maxGain == other.maxGain;

  @override
  int get hashCode => Object.hash(index, centerFrequency, gain, minGain, maxGain);

  @override
  String toString() =>
      'EqualizerBand(index: $index, freq: $displayFrequency, gain: $formattedGain)';
}
