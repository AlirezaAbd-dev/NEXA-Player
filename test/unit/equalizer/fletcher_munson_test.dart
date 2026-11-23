import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/domain/fletcher_munson_loudness_compensator.dart';

void main() {
  group('FletcherMunsonLoudnessCompensator Unit Tests', () {
    const compensator = FletcherMunsonLoudnessCompensator();

    test('returns flat response (0.0 dB) when isEnabled is false', () {
      final offsets = compensator.computeOffsets(volume: 0.10, isEnabled: false);
      expect(offsets.bassBoostDb, equals(0.0));
      expect(offsets.trebleBoostDb, equals(0.0));
      expect(offsets.isFlat, isTrue);
    });

    test('returns flat response (0.0 dB) for volumes at or above 45%', () {
      final at45 = compensator.computeOffsets(volume: 0.45);
      expect(at45.isFlat, isTrue);

      final at50 = compensator.computeOffsets(volume: 0.50);
      expect(at50.isFlat, isTrue);

      final at100 = compensator.computeOffsets(volume: 1.0);
      expect(at100.isFlat, isTrue);
    });

    test('applies psychoacoustic low-shelf and high-shelf boosts below 35% volume', () {
      // Very low volume (whisper: 5%)
      final at05 = compensator.computeOffsets(volume: 0.05);
      expect(at05.bassBoostDb, greaterThanOrEqualTo(5.5));
      expect(at05.bassBoostDb, lessThanOrEqualTo(6.5));
      expect(at05.trebleBoostDb, greaterThanOrEqualTo(2.8));
      expect(at05.trebleBoostDb, lessThanOrEqualTo(3.5));

      // Low volume (15%)
      final at15 = compensator.computeOffsets(volume: 0.15);
      expect(at15.bassBoostDb, greaterThan(3.0));
      expect(at15.trebleBoostDb, greaterThan(1.5));

      // Moderate volume (30%)
      final at30 = compensator.computeOffsets(volume: 0.30);
      expect(at30.bassBoostDb, greaterThan(0.5));
      expect(at30.bassBoostDb, lessThan(at15.bassBoostDb));
    });

    test('compensation gain decreases monotonically as volume rises', () {
      final v05 = compensator.computeOffsets(volume: 0.05);
      final v15 = compensator.computeOffsets(volume: 0.15);
      final v25 = compensator.computeOffsets(volume: 0.25);
      final v35 = compensator.computeOffsets(volume: 0.35);

      expect(v05.bassBoostDb, greaterThan(v15.bassBoostDb));
      expect(v15.bassBoostDb, greaterThan(v25.bassBoostDb));
      expect(v25.bassBoostDb, greaterThan(v35.bassBoostDb));
      expect(v35.bassBoostDb, greaterThanOrEqualTo(0.0));
    });

    test('safely clamps out-of-range volume values without throwing', () {
      final negative = compensator.computeOffsets(volume: -0.5);
      expect(negative.bassBoostDb, closeTo(6.5, 0.1));

      final overflow = compensator.computeOffsets(volume: 2.5);
      expect(overflow.isFlat, isTrue);
    });
  });
}
