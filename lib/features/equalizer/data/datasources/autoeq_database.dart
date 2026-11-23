import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/headphone_autoeq_profile.dart';

/// Curated offline database of AutoEQ headphone target calibration profiles.
class AutoEqDatabase {
  const AutoEqDatabase();

  static const List<HeadphoneAutoEqProfile> profiles = [
    HeadphoneAutoEqProfile(
      id: 'sennheiser_hd600_harman',
      brand: 'Sennheiser',
      model: 'HD 600',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -3.5,
      bandOffsets: [4.5, 3.2, 1.0, 0.0, -0.5, 0.0, 1.2, -1.8, 0.5, 1.0],
    ),
    HeadphoneAutoEqProfile(
      id: 'sennheiser_hd650_harman',
      brand: 'Sennheiser',
      model: 'HD 650',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -3.0,
      bandOffsets: [5.0, 3.5, 0.8, -0.4, -0.8, 0.0, 1.5, -1.2, 0.8, 1.5],
    ),
    HeadphoneAutoEqProfile(
      id: 'sennheiser_hd800s_harman',
      brand: 'Sennheiser',
      model: 'HD 800 S',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -4.0,
      bandOffsets: [6.0, 4.2, 1.5, 0.2, 0.0, 0.0, -0.5, -3.8, 1.0, 2.0],
    ),
    HeadphoneAutoEqProfile(
      id: 'sony_wh1000xm5_harman',
      brand: 'Sony',
      model: 'WH-1000XM5',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -2.5,
      bandOffsets: [-2.0, -1.5, -2.8, -1.0, 0.5, 1.2, 2.5, 1.0, -0.5, 0.0],
    ),
    HeadphoneAutoEqProfile(
      id: 'sony_wh1000xm4_harman',
      brand: 'Sony',
      model: 'WH-1000XM4',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -3.0,
      bandOffsets: [-3.2, -2.5, -3.5, -1.8, 0.2, 1.5, 3.0, 1.2, -0.8, -0.5],
    ),
    HeadphoneAutoEqProfile(
      id: 'apple_airpods_pro_2_harman',
      brand: 'Apple',
      model: 'AirPods Pro 2',
      formFactor: 'in_ear',
      targetCurve: 'Harman In-Ear',
      preampDb: -1.5,
      bandOffsets: [1.2, 0.8, 0.0, -0.5, 0.0, 0.4, -1.0, 1.5, -0.5, 0.8],
    ),
    HeadphoneAutoEqProfile(
      id: 'apple_airpods_max_harman',
      brand: 'Apple',
      model: 'AirPods Max',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -2.0,
      bandOffsets: [-0.5, 0.2, -0.8, -1.0, 0.5, 1.0, 0.5, -2.2, 1.5, 0.0],
    ),
    HeadphoneAutoEqProfile(
      id: 'beyerdynamic_dt770_80_harman',
      brand: 'Beyerdynamic',
      model: 'DT 770 Pro (80Ω)',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -4.5,
      bandOffsets: [-1.5, -1.0, 0.5, 1.0, 0.8, -0.5, 0.0, -4.5, -3.2, 1.0],
    ),
    HeadphoneAutoEqProfile(
      id: 'beyerdynamic_dt990_250_harman',
      brand: 'Beyerdynamic',
      model: 'DT 990 Pro (250Ω)',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -5.0,
      bandOffsets: [2.5, 1.0, -0.5, 0.2, 0.5, 0.0, -1.2, -5.5, -4.0, 0.5],
    ),
    HeadphoneAutoEqProfile(
      id: 'audiotechnica_ath_m50x_harman',
      brand: 'Audio-Technica',
      model: 'ATH-M50x',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -3.0,
      bandOffsets: [-2.0, -1.5, -1.8, 0.5, 0.8, 0.0, -0.5, -2.5, 1.0, 1.5],
    ),
    HeadphoneAutoEqProfile(
      id: 'moondrop_blessing2_dusk_harman',
      brand: 'Moondrop',
      model: 'Blessing 2 Dusk',
      formFactor: 'in_ear',
      targetCurve: 'Harman In-Ear',
      preampDb: -1.0,
      bandOffsets: [0.5, 0.0, -0.5, 0.0, 0.0, 0.5, 0.0, -0.5, 1.0, -0.5],
    ),
    HeadphoneAutoEqProfile(
      id: 'moondrop_aria_harman',
      brand: 'Moondrop',
      model: 'Aria',
      formFactor: 'in_ear',
      targetCurve: 'Harman In-Ear',
      preampDb: -1.5,
      bandOffsets: [-0.5, 0.0, 0.5, 0.0, -0.5, 0.2, 0.8, -1.5, 0.5, 0.0],
    ),
    HeadphoneAutoEqProfile(
      id: 'hifiman_sundara_harman',
      brand: 'Hifiman',
      model: 'Sundara',
      formFactor: 'over_ear',
      targetCurve: 'Harman 2020',
      preampDb: -3.5,
      bandOffsets: [4.0, 3.0, 1.2, 0.0, -0.4, 0.0, 0.5, -1.0, 0.5, 1.2],
    ),
  ];

  /// Fast case-insensitive search by brand or model name.
  List<HeadphoneAutoEqProfile> search(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return profiles;
    return profiles.where((p) {
      return p.brand.toLowerCase().contains(clean) ||
          p.model.toLowerCase().contains(clean) ||
          p.displayName.toLowerCase().contains(clean);
    }).toList();
  }
}

final autoEqDatabaseProvider = Provider<AutoEqDatabase>((ref) {
  return const AutoEqDatabase();
});

/// Currently selected active AutoEQ profile.
final selectedAutoEqProfileProvider =
    StateProvider<HeadphoneAutoEqProfile?>((ref) => null);
