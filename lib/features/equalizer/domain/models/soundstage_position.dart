import 'package:equatable/equatable.dart';

/// Pure Dart immutable representation of 2D spatial acoustic soundstage coordinates.
/// - [x]: Stereo balance / width displacement, normalized from -1.0 (far left) to +1.0 (far right).
/// - [y]: Room acoustic depth / distance, normalized from 0.0 (nearfield direct) to 1.0 (distant hall).
class SoundstagePosition extends Equatable {
  final double x;
  final double y;

  const SoundstagePosition({
    this.x = 0.0,
    this.y = 0.35,
  });

  /// Default balanced nearfield studio monitor setup.
  static const SoundstagePosition studioDefault = SoundstagePosition(x: 0.0, y: 0.35);

  /// Default expanded wide acoustic field.
  static const SoundstagePosition wideImmersion = SoundstagePosition(x: 0.0, y: 0.75);

  /// Stereo widening factor derived from width displacement [0.0, 1.0].
  /// 0.0 = focused narrow, 1.0 = ultra-wide acoustic panorama.
  double get stereoWideningFactor => (0.5 + (x.abs() * 0.5)).clamp(0.0, 1.0);

  /// Reverb & crossfeed depth derived from Y distance [0.0, 1.0].
  double get acousticDepth => y.clamp(0.0, 1.0);

  /// Balance displacement: -1.0 (full left) to +1.0 (full right).
  double get balance => x.clamp(-1.0, 1.0);

  SoundstagePosition copyWith({
    double? x,
    double? y,
  }) {
    return SoundstagePosition(
      x: (x ?? this.x).clamp(-1.0, 1.0),
      y: (y ?? this.y).clamp(0.0, 1.0),
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };

  factory SoundstagePosition.fromJson(Map<String, dynamic> json) =>
      SoundstagePosition(
        x: ((json['x'] as num?)?.toDouble() ?? 0.0).clamp(-1.0, 1.0),
        y: ((json['y'] as num?)?.toDouble() ?? 0.35).clamp(0.0, 1.0),
      );

  @override
  List<Object?> get props => [x, y];
}
