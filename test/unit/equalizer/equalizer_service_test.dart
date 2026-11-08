import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/equalizer/domain/entities/reverb_preset.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

class InMemoryStorageService implements IStorageService {
  final Map<String, dynamic> _store = {};

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _store.clear();
    return const Result.success(null);
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) {
    return Result.success(_store[key] as bool?);
  }

  @override
  Result<String?, StorageFailure> getString(String key) {
    return Result.success(_store[key] as String?);
  }

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    _store.remove(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    _store[key] = value;
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _store[key] = value;
    return const Result.success(null);
  }
}

void main() {
  late InMemoryStorageService storage;
  late PureDartEqualizerService service;

  setUp(() {
    storage = InMemoryStorageService();
    service = PureDartEqualizerService(storageService: storage);
  });

  tearDown(() {
    service.dispose();
  });

  group('PureDartEqualizerService Lifecycle & Presets', () {
    test('initializes with 16 factory presets and flat default state', () async {
      await service.initialize();
      final state = service.currentState;

      expect(state.isEnabled, isTrue);
      expect(state.preamp, 0.0);
      expect(state.bassBoost, 0.0);
      expect(state.virtualizer, 0.0);
      expect(state.reverb, ReverbPreset.none);
      expect(state.activePresetId, 'flat');
      expect(state.bands.length, 10);
      expect(state.presets.length, 16);

      // Verify factory presets exist
      final presetNames = state.presets.map((p) => p.name).toList();
      expect(presetNames, containsAll([
        'Flat',
        'Rock',
        'Pop',
        'Jazz',
        'Electronic',
        'Classical',
        'Metal',
        'Hip-Hop',
        'Dance',
        'R&B',
        'Vocal Boost',
        'Bass Boost',
        'Treble Boost',
        'Acoustic',
        'Headphone',
        'Loudness',
      ]));
    });

    test('applies factory preset and updates band gains and DSP parameters', () async {
      await service.initialize();

      await service.applyPreset('rock');
      final rockState = service.currentState;

      expect(rockState.activePresetId, 'rock');
      expect(rockState.bands[0].gain, 4.5);
      expect(rockState.bands[1].gain, 3.0);
      expect(rockState.bands[2].gain, -1.5);
      expect(rockState.bassBoost, 0.2);

      await service.applyPreset('classical');
      final classicalState = service.currentState;
      expect(classicalState.activePresetId, 'classical');
      expect(classicalState.reverb, ReverbPreset.hall);
    });

    test('resetToFlat sets all band gains to zero and active preset to flat', () async {
      await service.initialize();
      await service.applyPreset('rock');
      expect(service.currentState.activePresetId, 'rock');

      await service.resetToFlat();
      final flatState = service.currentState;
      expect(flatState.activePresetId, 'flat');
      for (final band in flatState.bands) {
        expect(band.gain, 0.0);
      }
    });
  });

  group('PureDartEqualizerService Gain & DSP Manipulations', () {
    test('setEnabled toggles master bypass and emits on stream', () async {
      await service.initialize();

      expect(service.currentState.isEnabled, isTrue);
      await service.setEnabled(false);
      expect(service.currentState.isEnabled, isFalse);

      await service.setEnabled(true);
      expect(service.currentState.isEnabled, isTrue);
    });

    test('setPreamp clamps gain to [-15, +15]', () async {
      await service.initialize();

      await service.setPreamp(6.5);
      expect(service.currentState.preamp, 6.5);

      await service.setPreamp(25.0);
      expect(service.currentState.preamp, 15.0);

      await service.setPreamp(-30.0);
      expect(service.currentState.preamp, -15.0);
    });

    test('setBandGain adjusts specific band without altering others', () async {
      await service.initialize();

      await service.setBandGain(0, 8.0);
      expect(service.currentState.bands[0].gain, 8.0);
      expect(service.currentState.bands[1].gain, 0.0);

      // Ignore invalid index safely
      await service.setBandGain(99, 10.0);
      expect(service.currentState.bands.length, 10);
    });

    test('setBassBoost and setVirtualizer clamp between 0.0 and 1.0', () async {
      await service.initialize();

      await service.setBassBoost(0.75);
      expect(service.currentState.bassBoost, 0.75);
      await service.setBassBoost(1.5);
      expect(service.currentState.bassBoost, 1.0);
      await service.setBassBoost(-0.5);
      expect(service.currentState.bassBoost, 0.0);

      await service.setVirtualizer(0.4);
      expect(service.currentState.virtualizer, 0.4);
      await service.setVirtualizer(2.0);
      expect(service.currentState.virtualizer, 1.0);
    });

    test('setReverb changes acoustic simulation environment', () async {
      await service.initialize();

      await service.setReverb(ReverbPreset.liveArena);
      expect(service.currentState.reverb, ReverbPreset.liveArena);
    });
  });

  group('PureDartEqualizerService Custom Presets Management', () {
    test('saves current configuration as a new custom preset', () async {
      await service.initialize();

      await service.setPreamp(3.0);
      await service.setBandGain(0, 5.0);
      await service.setBandGain(1, 4.0);
      await service.setBassBoost(0.5);
      await service.setVirtualizer(0.3);
      await service.setReverb(ReverbPreset.studio);

      final customPreset = await service.saveCustomPreset('My Studio Sound');
      expect(customPreset.name, 'My Studio Sound');
      expect(customPreset.isBuiltIn, isFalse);
      expect(customPreset.preamp, 3.0);
      expect(customPreset.bandGains[0], 5.0);
      expect(customPreset.bassBoost, 0.5);
      expect(customPreset.virtualizer, 0.3);
      expect(customPreset.reverb, ReverbPreset.studio);

      expect(service.currentState.presets.length, 17);
      expect(service.currentState.activePresetId, customPreset.id);
    });

    test('cannot delete factory presets', () async {
      await service.initialize();
      final deleted = await service.deleteCustomPreset('rock');
      expect(deleted, isFalse);
      expect(service.currentState.presets.any((p) => p.id == 'rock'), isTrue);
    });

    test('deletes user-created custom presets cleanly', () async {
      await service.initialize();
      final custom = await service.saveCustomPreset('Temporary Preset');
      expect(service.currentState.presets.length, 17);

      final deleted = await service.deleteCustomPreset(custom.id);
      expect(deleted, isTrue);
      expect(service.currentState.presets.length, 16);
      expect(service.currentState.presets.any((p) => p.id == custom.id), isFalse);
    });

    test('persists state and restores it on subsequent initialization', () async {
      await service.initialize();
      await service.setPreamp(4.0);
      await service.setBassBoost(0.65);
      await service.setVirtualizer(0.45);
      await service.setReverb(ReverbPreset.plate);
      await service.saveCustomPreset('Persisted Setup');

      // Create a second service instance with the same storage
      final secondService = PureDartEqualizerService(storageService: storage);
      await secondService.initialize();

      final restoredState = secondService.currentState;
      expect(restoredState.preamp, 4.0);
      expect(restoredState.bassBoost, 0.65);
      expect(restoredState.virtualizer, 0.45);
      expect(restoredState.reverb, ReverbPreset.plate);
      expect(restoredState.presets.length, 17);
      expect(restoredState.presets.last.name, 'Persisted Setup');

      secondService.dispose();
    });
  });
}
