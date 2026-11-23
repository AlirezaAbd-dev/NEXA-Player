import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/data/datasources/autoeq_database.dart';
import 'package:nexa_player/features/equalizer/domain/models/headphone_autoeq_profile.dart';

void main() {
  group('AutoEQ Database & Profiles Unit Tests', () {
    const db = AutoEqDatabase();

    test('profile JSON serialization roundtrip preserves all acoustic properties', () {
      const profile = HeadphoneAutoEqProfile(
        id: 'test_hd600',
        brand: 'Sennheiser',
        model: 'HD 600',
        formFactor: 'over_ear',
        targetCurve: 'Harman 2020',
        bandOffsets: [4.5, 3.2, 1.0, 0.0, -0.5, 0.0, 1.2, -1.8, 0.5, 1.0],
        preampDb: -3.5,
      );

      final json = profile.toJson();
      final restored = HeadphoneAutoEqProfile.fromJson(json);

      expect(restored, equals(profile));
      expect(restored.displayName, equals('Sennheiser HD 600'));
      expect(restored.bandOffsets.length, equals(10));
    });

    test('all bundled database profiles strictly satisfy 10-band constraint and negative preamp', () {
      expect(AutoEqDatabase.profiles.length, greaterThanOrEqualTo(10));

      for (final profile in AutoEqDatabase.profiles) {
        expect(profile.bandOffsets.length, equals(10),
            reason: '${profile.displayName} must define exactly 10 bands');
        expect(profile.preampDb, lessThanOrEqualTo(0.0),
            reason: '${profile.displayName} preamp must be non-positive to prevent clipping');

        for (final gain in profile.bandOffsets) {
          expect(gain, greaterThanOrEqualTo(-12.0),
              reason: 'Band gain should not exceed -12.0 dB');
          expect(gain, lessThanOrEqualTo(12.0),
              reason: 'Band gain should not exceed +12.0 dB');
        }
      }
    });

    test('search filters profiles accurately and case-insensitively', () {
      // Search by brand
      final sennheisers = db.search('sennheiser');
      expect(sennheisers.length, greaterThanOrEqualTo(3));
      for (final p in sennheisers) {
        expect(p.brand.toLowerCase(), contains('sennheiser'));
      }

      // Search by model
      final airpods = db.search('airpods');
      expect(airpods.length, greaterThanOrEqualTo(2));

      // Search exact model name
      final xm5 = db.search('wh-1000xm5');
      expect(xm5.length, equals(1));
      expect(xm5.first.model, equals('WH-1000XM5'));

      // Non-existent search
      final none = db.search('xyzNonExistentBrand123');
      expect(none, isEmpty);

      // Empty search returns full catalog
      final all = db.search('');
      expect(all.length, equals(AutoEqDatabase.profiles.length));
    });
  });
}
