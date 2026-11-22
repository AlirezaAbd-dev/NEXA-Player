import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/auto/domain/models/auto_settings.dart';

void main() {
  group('AutoSettings Tests', () {
    test('default constructor provides expected values', () {
      const settings = AutoSettings();

      expect(settings.keepScreenAwake, isTrue);
      expect(settings.largeButtons, isTrue);
      expect(settings.bluetoothAutoLaunch, isFalse);
      expect(settings.androidAutoEnabled, isTrue);
      expect(settings.wearCompanionEnabled, isTrue);
      expect(settings.seekJumpSeconds, 15);
    });

    test('copyWith updates specified fields', () {
      const initial = AutoSettings();
      final updated = initial.copyWith(
        keepScreenAwake: false,
        largeButtons: false,
        bluetoothAutoLaunch: true,
        androidAutoEnabled: false,
        wearCompanionEnabled: false,
        seekJumpSeconds: 30,
      );

      expect(updated.keepScreenAwake, isFalse);
      expect(updated.largeButtons, isFalse);
      expect(updated.bluetoothAutoLaunch, isTrue);
      expect(updated.androidAutoEnabled, isFalse);
      expect(updated.wearCompanionEnabled, isFalse);
      expect(updated.seekJumpSeconds, 30);
    });

    test('toJson and fromJson round-trip accurately', () {
      const original = AutoSettings(
        keepScreenAwake: false,
        largeButtons: false,
        bluetoothAutoLaunch: true,
        androidAutoEnabled: false,
        wearCompanionEnabled: false,
        seekJumpSeconds: 10,
      );

      final json = original.toJson();
      final restored = AutoSettings.fromJson(json);

      expect(restored, equals(original));
      expect(restored.seekJumpSeconds, 10);
    });

    test('fromJson handles null or empty map gracefully', () {
      final restored = AutoSettings.fromJson(const {});

      expect(restored.keepScreenAwake, isTrue);
      expect(restored.largeButtons, isTrue);
      expect(restored.bluetoothAutoLaunch, isFalse);
      expect(restored.androidAutoEnabled, isTrue);
      expect(restored.wearCompanionEnabled, isTrue);
      expect(restored.seekJumpSeconds, 15);
    });
  });
}
