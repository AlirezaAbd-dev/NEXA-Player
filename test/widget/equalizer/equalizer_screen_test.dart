import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/equalizer/presentation/providers/equalizer_providers.dart';
import 'package:nexa_player/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

class MockTestStorageService implements IStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _data.clear();
    return const Result.success(null);
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) =>
      Result.success(_data[key] as bool?);

  @override
  Result<String?, StorageFailure> getString(String key) =>
      Result.success(_data[key] as String?);

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    _data.remove(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _data[key] = value;
    return const Result.success(null);
  }
}

void main() {
  late MockTestStorageService mockStorage;
  late PureDartEqualizerService eqService;

  setUp(() async {
    mockStorage = MockTestStorageService();
    eqService = PureDartEqualizerService(storageService: mockStorage);
    await eqService.initialize();
  });

  tearDown(() {
    eqService.dispose();
  });

  Widget buildTestableScreen() {
    return ProviderScope(
      overrides: [
        equalizerServiceProvider.overrideWithValue(eqService),
      ],
      child: const MaterialApp(
        home: EqualizerScreen(),
      ),
    );
  }

  group('EqualizerScreen Widget Tests', () {
    testWidgets('renders all studio controls, faders, and DSP sections', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Top app bar
      expect(find.text('Equalizer & DSP'), findsOneWidget);
      expect(find.text('10-Band Parametric • Studio DSP'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);

      // Preset bar
      expect(find.text('SOUND PRESET'), findsOneWidget);
      expect(find.text('Flat'), findsOneWidget);

      // Preamp
      expect(find.text('PREAMP'), findsOneWidget);

      // 10 Frequency bands
      expect(find.text('10-BAND PARAMETRIC FILTER'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('1k'), findsOneWidget);
      expect(find.text('2k'), findsOneWidget);
      expect(find.text('4k'), findsOneWidget);
      expect(find.text('8k'), findsOneWidget);
      expect(find.text('16k'), findsOneWidget);

      // DSP Section
      expect(find.text('PSYCHOACOUSTIC DSP EFFECTS'), findsOneWidget);
      expect(find.text('BASS BOOST'), findsOneWidget);
      expect(find.text('3D VIRTUALIZER'), findsOneWidget);
      expect(find.text('ACOUSTIC REVERB'), findsOneWidget);
    });

    testWidgets('toggles master bypass switch between ACTIVE and BYPASS', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsOneWidget);

      // Toggle switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('BYPASS'), findsOneWidget);
      expect(eqService.currentState.isEnabled, isFalse);

      // Toggle back
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.text('ACTIVE'), findsOneWidget);
      expect(eqService.currentState.isEnabled, isTrue);
    });

    testWidgets('opens preset selector modal and applies Rock preset', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      expect(find.text('Flat'), findsOneWidget);

      // Tap preset bar to open modal
      await tester.tap(find.text('SOUND PRESET'));
      await tester.pumpAndSettle();

      expect(find.text('Sound Presets'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);

      // Select Rock
      await tester.tap(find.text('Rock'));
      await tester.pumpAndSettle();

      // Active preset should now be Rock
      expect(eqService.currentState.activePresetId, 'rock');
      expect(find.text('Rock'), findsOneWidget);
    });

    testWidgets('resets to Flat via reset button with snackbar confirmation', (tester) async {
      await tester.pumpWidget(buildTestableScreen());
      await tester.pumpAndSettle();

      // Apply Rock first
      await eqService.applyPreset('rock');
      await tester.pumpAndSettle();
      expect(find.text('Rock'), findsOneWidget);

      // Tap reset button in AppBar
      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pumpAndSettle();

      expect(eqService.currentState.activePresetId, 'flat');
      expect(find.text('Flat'), findsOneWidget);
      expect(find.text('Equalizer reset to Flat'), findsOneWidget);
    });
  });
}
