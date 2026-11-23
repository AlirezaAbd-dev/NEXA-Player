import 'package:equatable/equatable.dart';

/// Offset gains in decibels for bass and treble compensation.
class LoudnessOffsets extends Equatable {
  final double bassBoostDb;
  final double trebleBoostDb;

  const LoudnessOffsets({
    required this.bassBoostDb,
    required this.trebleBoostDb,
  });

  bool get isFlat => bassBoostDb == 0.0 && trebleBoostDb == 0.0;

  @override
  List<Object?> get props => [bassBoostDb, trebleBoostDb];
}

/// Pure Dart dynamic equalizer compensator based on Fletcher-Munson / ISO 226
/// equal-loudness contours for low-volume listening ("Whisper Loudness").
class FletcherMunsonLoudnessCompensator {
  const FletcherMunsonLoudnessCompensator();

  /// Calculates dynamic low-shelf and high-shelf boost gains in dB given a
  /// volume level [volume] between 0.0 and 1.0.
  ///
  /// - Below volume 0.35, human ears lose sensitivity to low bass and high treble.
  /// - At 0.05 volume, bass boost is ~ +6.5 dB, treble boost is ~ +3.5 dB.
  /// - At >= 0.45 volume, boost smoothly tapers to identically 0.0 dB (flat response).
  LoudnessOffsets computeOffsets({
    required double volume,
    bool isEnabled = true,
  }) {
    if (!isEnabled) {
      return const LoudnessOffsets(bassBoostDb: 0.0, trebleBoostDb: 0.0);
    }

    final clampedVol = volume.clamp(0.0, 1.0);

    // Flat threshold at 45% volume
    if (clampedVol >= 0.45) {
      return const LoudnessOffsets(bassBoostDb: 0.0, trebleBoostDb: 0.0);
    }

    // Normalized factor from 0.0 (at 45% vol) to 1.0 (at 0% vol)
    final factor = (1.0 - (clampedVol / 0.45)).clamp(0.0, 1.0);

    // Smooth cubic easing: 3 * t^2 - 2 * t^3
    final smooth = factor * factor * (3.0 - 2.0 * factor);

    final bassDb = (smooth * 6.5).clamp(0.0, 6.5);
    final trebleDb = (smooth * 3.5).clamp(0.0, 3.5);

    return LoudnessOffsets(
      bassBoostDb: (bassDb * 10).round() / 10.0,
      trebleBoostDb: (trebleDb * 10).round() / 10.0,
    );
  }
}
