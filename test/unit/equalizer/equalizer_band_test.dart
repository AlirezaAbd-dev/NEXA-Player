import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_band.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_preset.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_state.dart';
import 'package:nexa_player/features/equalizer/domain/entities/reverb_preset.dart';

void main() {
  group('EqualizerBand Entity Tests', () {
    test('formats display and short frequency correctly', () {
      const band31 = EqualizerBand(index: 0, centerFrequency: 31, gain: 0.0);
      expect(band31.displayFrequency, '31 Hz');
      expect(band31.shortFrequency, '31');

      const band500 = EqualizerBand(index: 4, centerFrequency: 500, gain: 0.0);
      expect(band500.displayFrequency, '500 Hz');
      expect(band500.shortFrequency, '500');

      const band1k = EqualizerBand(index: 5, centerFrequency: 1000, gain: 0.0);
      expect(band1k.displayFrequency, '1 kHz');
      expect(band1k.shortFrequency, '1k');

      const band16k = EqualizerBand(index: 9, centerFrequency: 16000, gain: 0.0);
      expect(band16k.displayFrequency, '16 kHz');
      expect(band16k.shortFrequency, '16k');

      const band2500 = EqualizerBand(index: 6, centerFrequency: 2500, gain: 0.0);
      expect(band2500.displayFrequency, '2.5 kHz');
      expect(band2500.shortFrequency, '2.5k');
    });

    test('formats gain strings with positive sign and zero', () {
      const pos = EqualizerBand(index: 0, centerFrequency: 31, gain: 4.5);
      expect(pos.formattedGain, '+4.5 dB');

      const zero = EqualizerBand(index: 0, centerFrequency: 31, gain: 0.0);
      expect(zero.formattedGain, '0.0 dB');

      const neg = EqualizerBand(index: 0, centerFrequency: 31, gain: -3.2);
      expect(neg.formattedGain, '-3.2 dB');
    });

    test('clamps gain to [minGain, maxGain] on copyWith', () {
      const band = EqualizerBand(
        index: 0,
        centerFrequency: 62,
        gain: 0.0,
        minGain: -15.0,
        maxGain: 15.0,
      );

      final over = band.copyWith(gain: 25.0);
      expect(over.gain, 15.0);

      final under = band.copyWith(gain: -20.0);
      expect(under.gain, -15.0);

      final normal = band.copyWith(gain: 6.0);
      expect(normal.gain, 6.0);
    });

    test('serializes and deserializes cleanly via toJson and fromJson', () {
      const original = EqualizerBand(
        index: 2,
        centerFrequency: 125,
        gain: 3.5,
        minGain: -12.0,
        maxGain: 12.0,
      );

      final json = original.toJson();
      final restored = EqualizerBand.fromJson(json);

      expect(restored, equals(original));
      expect(restored.hashCode, equals(original.hashCode));
      expect(restored.toString(), contains('125 Hz'));
    });
  });

  group('ReverbPreset Enum Tests', () {
    test('contains 6 standard presets with correct labels', () {
      expect(ReverbPreset.values.length, 6);
      expect(ReverbPreset.none.label, 'None');
      expect(ReverbPreset.room.label, 'Small Room');
      expect(ReverbPreset.hall.label, 'Concert Hall');
      expect(ReverbPreset.plate.label, 'Plate Reverb');
      expect(ReverbPreset.studio.label, 'Studio');
      expect(ReverbPreset.liveArena.label, 'Live Arena');
    });

    test('serializes and deserializes gracefully with fallback', () {
      expect(ReverbPreset.hall.toJson(), 'hall');
      expect(ReverbPreset.fromJson('hall'), ReverbPreset.hall);
      expect(ReverbPreset.fromJson('STUDIO'), ReverbPreset.studio);
      expect(ReverbPreset.fromJson('invalid_preset'), ReverbPreset.none);
      expect(ReverbPreset.fromJson(null), ReverbPreset.none);
    });
  });

  group('EqualizerPreset Entity Tests', () {
    test('serializes and deserializes accurately', () {
      const preset = EqualizerPreset(
        id: 'test_preset',
        name: 'Test Sound',
        isBuiltIn: false,
        preamp: 2.0,
        bandGains: [1.0, 2.0, 3.0, 0.0, -1.0, -2.0, 1.0, 2.0, 3.0, 4.0],
        bassBoost: 0.4,
        virtualizer: 0.25,
        reverb: ReverbPreset.room,
      );

      final json = preset.toJson();
      final restored = EqualizerPreset.fromJson(json);

      expect(restored, equals(preset));
      expect(restored.name, 'Test Sound');
      expect(restored.reverb, ReverbPreset.room);
      expect(restored.bandGains.length, 10);
    });

    test('copyWith duplicates and overrides fields', () {
      const preset = EqualizerPreset(
        id: 'preset_1',
        name: 'Preset 1',
        bandGains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      );

      final copy = preset.copyWith(
        name: 'Updated Preset',
        bassBoost: 0.5,
      );

      expect(copy.id, 'preset_1');
      expect(copy.name, 'Updated Preset');
      expect(copy.bassBoost, 0.5);
    });
  });

  group('EqualizerState Entity Tests', () {
    test('resolves activePreset and tracks modification accurately', () {
      const flatPreset = EqualizerPreset(
        id: 'flat',
        name: 'Flat',
        isBuiltIn: true,
        bandGains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
      );

      final bands = List.generate(
        10,
        (i) => EqualizerBand(index: i, centerFrequency: 100 * (i + 1), gain: 0.0),
      );

      final state = EqualizerState(
        isEnabled: true,
        preamp: 0.0,
        bands: bands,
        bassBoost: 0.0,
        virtualizer: 0.0,
        reverb: ReverbPreset.none,
        activePresetId: 'flat',
        presets: const [flatPreset],
      );

      expect(state.activePreset, equals(flatPreset));
      expect(state.isModifiedFromActivePreset, isFalse);

      // Modify a band gain
      final modifiedBands = List<EqualizerBand>.from(bands);
      modifiedBands[0] = modifiedBands[0].copyWith(gain: 3.0);

      final modifiedState = state.copyWith(bands: modifiedBands);
      expect(modifiedState.isModifiedFromActivePreset, isTrue);
    });
  });
}
