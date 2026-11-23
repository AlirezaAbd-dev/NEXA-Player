import 'package:equatable/equatable.dart';

/// Calibrated headphone frequency compensation profile derived from AutoEQ / Harman acoustic target.
class HeadphoneAutoEqProfile extends Equatable {
  final String id;
  final String brand;
  final String model;
  final String formFactor; // 'over_ear', 'in_ear', 'earbud'
  final String targetCurve; // 'Harman 2020', 'Diffuse Field', 'Neutral'
  final List<double> bandOffsets; // 10 frequency band gains in dB (-12.0 to +12.0)
  final double preampDb;

  const HeadphoneAutoEqProfile({
    required this.id,
    required this.brand,
    required this.model,
    required this.formFactor,
    required this.targetCurve,
    required this.bandOffsets,
    this.preampDb = -2.0,
  }) : assert(bandOffsets.length == 10, 'AutoEQ profile must define exactly 10 bands');

  String get displayName => '$brand $model';

  Map<String, dynamic> toJson() => {
        'id': id,
        'brand': brand,
        'model': model,
        'formFactor': formFactor,
        'targetCurve': targetCurve,
        'bandOffsets': bandOffsets,
        'preampDb': preampDb,
      };

  factory HeadphoneAutoEqProfile.fromJson(Map<String, dynamic> json) =>
      HeadphoneAutoEqProfile(
        id: json['id'] as String,
        brand: json['brand'] as String,
        model: json['model'] as String,
        formFactor: json['formFactor'] as String? ?? 'over_ear',
        targetCurve: json['targetCurve'] as String? ?? 'Harman 2020',
        bandOffsets: (json['bandOffsets'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
        preampDb: (json['preampDb'] as num?)?.toDouble() ?? -2.0,
      );

  @override
  List<Object?> get props => [id, brand, model, formFactor, targetCurve, bandOffsets, preampDb];
}
