import 'package:flutter/foundation.dart';
import 'reverb_preset.dart';

/// Represents a configured audio profile containing band gains, preamp, and DSP effects.
@immutable
class EqualizerPreset {
  const EqualizerPreset({
    required this.id,
    required this.name,
    required this.bandGains,
    this.isBuiltIn = false,
    this.preamp = 0.0,
    this.bassBoost = 0.0,
    this.virtualizer = 0.0,
    this.reverb = ReverbPreset.none,
  });

  /// Unique identifier (e.g. 'preset_rock', 'custom_1699999').
  final String id;

  /// Display name shown in UI (e.g. 'Rock', 'Vocal Boost', 'My Setup').
  final String name;

  /// Whether this is a non-deletable factory preset.
  final bool isBuiltIn;

  /// Preamplification gain in decibels (-15.0 dB to +15.0 dB).
  final double preamp;

  /// List of gains corresponding to the 10 bands in order.
  final List<double> bandGains;

  /// Bass boost effect intensity (0.0 to 1.0).
  final double bassBoost;

  /// Stereo virtualizer effect intensity (0.0 to 1.0).
  final double virtualizer;

  /// Reverb simulation preset.
  final ReverbPreset reverb;

  EqualizerPreset copyWith({
    String? id,
    String? name,
    bool? isBuiltIn,
    double? preamp,
    List<double>? bandGains,
    double? bassBoost,
    double? virtualizer,
    ReverbPreset? reverb,
  }) {
    return EqualizerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      preamp: preamp ?? this.preamp,
      bandGains: bandGains ?? List<double>.from(this.bandGains),
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      reverb: reverb ?? this.reverb,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isBuiltIn': isBuiltIn,
      'preamp': preamp,
      'bandGains': bandGains,
      'bassBoost': bassBoost,
      'virtualizer': virtualizer,
      'reverb': reverb.toJson(),
    };
  }

  factory EqualizerPreset.fromJson(Map<String, dynamic> json) {
    return EqualizerPreset(
      id: json['id'] as String,
      name: json['name'] as String,
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      preamp: (json['preamp'] as num?)?.toDouble() ?? 0.0,
      bandGains: (json['bandGains'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      bassBoost: (json['bassBoost'] as num?)?.toDouble() ?? 0.0,
      virtualizer: (json['virtualizer'] as num?)?.toDouble() ?? 0.0,
      reverb: ReverbPreset.fromJson(json['reverb'] as String?),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqualizerPreset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          isBuiltIn == other.isBuiltIn &&
          preamp == other.preamp &&
          listEquals(bandGains, other.bandGains) &&
          bassBoost == other.bassBoost &&
          virtualizer == other.virtualizer &&
          reverb == other.reverb;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        isBuiltIn,
        preamp,
        Object.hashAll(bandGains),
        bassBoost,
        virtualizer,
        reverb,
      );

  @override
  String toString() =>
      'EqualizerPreset(id: $id, name: $name, isBuiltIn: $isBuiltIn, preamp: $preamp dB)';
}
