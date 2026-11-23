import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/domain/models/frequency_spotlight_filter.dart';

void main() {
  group('FrequencySpotlightFilter Unit Tests', () {
    test('computes logarithmic center frequency accurately from sweep fraction', () {
      // 0.0 fraction corresponds to min frequency (40 Hz)
      const minFilter = FrequencySpotlightFilter(sweepFraction: 0.0);
      expect(minFilter.centerFrequencyHz, closeTo(40.0, 0.1));
      expect(minFilter.formattedFrequency, equals('40 Hz'));
      expect(minFilter.bandCategory, equals('Sub-Bass'));

      // 1.0 fraction corresponds to max frequency (16000 Hz / 16 kHz)
      const maxFilter = FrequencySpotlightFilter(sweepFraction: 1.0);
      expect(maxFilter.centerFrequencyHz, closeTo(16000.0, 1.0));
      expect(maxFilter.formattedFrequency, equals('16 kHz'));
      expect(maxFilter.bandCategory, equals('Brilliance & Air'));

      // 0.5 geometric midpoint = sqrt(40 * 16000) = 800 Hz
      const midFilter = FrequencySpotlightFilter(sweepFraction: 0.5);
      expect(midFilter.centerFrequencyHz, closeTo(800.0, 1.0));
      expect(midFilter.formattedFrequency, equals('800 Hz'));
      expect(midFilter.bandCategory, equals('Vocal Midrange'));
    });

    test('categorizes vocal and treble frequency zones correctly', () {
      // ~1.2 kHz vocal midrange
      const vocalFilter = FrequencySpotlightFilter(sweepFraction: 0.56);
      expect(vocalFilter.centerFrequencyHz, greaterThan(1000.0));
      expect(vocalFilter.centerFrequencyHz, lessThan(2000.0));
      expect(vocalFilter.formattedFrequency, contains('kHz'));
      expect(vocalFilter.bandCategory, equals('Vocal Midrange'));

      // ~3.5 kHz high-mid clarity
      const clarityFilter = FrequencySpotlightFilter(sweepFraction: 0.75);
      expect(clarityFilter.centerFrequencyHz, greaterThan(2500.0));
      expect(clarityFilter.centerFrequencyHz, lessThan(4000.0));
      expect(clarityFilter.bandCategory, equals('High-Mid Clarity'));

      // ~6 kHz presence
      const presenceFilter = FrequencySpotlightFilter(sweepFraction: 0.84);
      expect(presenceFilter.centerFrequencyHz, greaterThan(4000.0));
      expect(presenceFilter.centerFrequencyHz, lessThan(8000.0));
      expect(presenceFilter.bandCategory, equals('Presence & Attack'));
    });

    test('safely clamps out-of-range sweep fractions', () {
      const negative = FrequencySpotlightFilter(sweepFraction: -0.8);
      expect(negative.centerFrequencyHz, closeTo(40.0, 0.1));

      const overflow = FrequencySpotlightFilter(sweepFraction: 2.5);
      expect(overflow.centerFrequencyHz, closeTo(16000.0, 1.0));
    });

    test('copyWith updates state cleanly', () {
      const initial = FrequencySpotlightFilter(
        sweepFraction: 0.2,
        boostGainDb: 6.0,
        isActive: false,
      );

      final updated = initial.copyWith(
        sweepFraction: 0.7,
        isActive: true,
      );

      expect(updated.sweepFraction, equals(0.7));
      expect(updated.boostGainDb, equals(6.0));
      expect(updated.isActive, isTrue);
    });
  });
}
