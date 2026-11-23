import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/domain/models/soundstage_position.dart';

void main() {
  group('SoundstagePosition Model & Mapping Tests', () {
    test('JSON serialization roundtrip preserves coordinates', () {
      const pos = SoundstagePosition(x: -0.45, y: 0.65);
      final json = pos.toJson();
      final restored = SoundstagePosition.fromJson(json);

      expect(restored, equals(pos));
      expect(restored.x, equals(-0.45));
      expect(restored.y, equals(0.65));
    });

    test('derives stereo widening factor smoothly from width displacement', () {
      // Center position has balanced stereo width (0.50)
      const center = SoundstagePosition(x: 0.0, y: 0.35);
      expect(center.stereoWideningFactor, equals(0.50));
      expect(center.balance, equals(0.0));

      // Far left (-1.0) or far right (+1.0) maps to maximum width (1.0)
      const farLeft = SoundstagePosition(x: -1.0, y: 0.50);
      expect(farLeft.stereoWideningFactor, equals(1.0));
      expect(farLeft.balance, equals(-1.0));

      const farRight = SoundstagePosition(x: 1.0, y: 0.50);
      expect(farRight.stereoWideningFactor, equals(1.0));
      expect(farRight.balance, equals(1.0));
    });

    test('derives acoustic room depth directly from Y coordinate', () {
      const nearfield = SoundstagePosition(x: 0.0, y: 0.0);
      expect(nearfield.acousticDepth, equals(0.0));

      const cathedral = SoundstagePosition(x: 0.0, y: 1.0);
      expect(cathedral.acousticDepth, equals(1.0));

      const midHall = SoundstagePosition(x: 0.0, y: 0.62);
      expect(midHall.acousticDepth, equals(0.62));
    });

    test('clamps out-of-bounds coordinates safely', () {
      const extreme = SoundstagePosition(x: -2.5, y: 1.8);
      final clamped = extreme.copyWith();

      expect(clamped.x, equals(-1.0));
      expect(clamped.y, equals(1.0));
      expect(clamped.balance, equals(-1.0));
      expect(clamped.acousticDepth, equals(1.0));
    });

    test('presets studioDefault and wideImmersion match soundstage profiles', () {
      expect(SoundstagePosition.studioDefault.x, equals(0.0));
      expect(SoundstagePosition.studioDefault.y, equals(0.35));

      expect(SoundstagePosition.wideImmersion.x, equals(0.0));
      expect(SoundstagePosition.wideImmersion.y, equals(0.75));
    });
  });
}
