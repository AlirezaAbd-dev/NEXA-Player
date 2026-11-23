import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_band.dart';
import 'package:nexa_player/features/equalizer/presentation/providers/equalizer_providers.dart';
import 'package:nexa_player/features/equalizer/presentation/screens/equalizer_screen.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/spline_equalizer_canvas.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/tactile_rotary_knob.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

class _MockStorage implements IStorageService {
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
  late _MockStorage mockStorage;
  late PureDartEqualizerService eqService;

  setUp(() async {
    mockStorage = _MockStorage();
    eqService = PureDartEqualizerService(storageService: mockStorage);
    await eqService.initialize();
  });

  tearDown(() {
    eqService.dispose();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        equalizerServiceProvider.overrideWithValue(eqService),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const EqualizerScreen(),
      ),
    );
  }

  group('EqualizerScreen Studio DSP Architecture Tests', () {
    testWidgets('renders SplineEqualizerCanvas and tactile rotary knobs', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byType(SplineEqualizerCanvas), findsOneWidget);
      expect(find.byType(TactileRotaryKnob), findsNWidgets(2));
      expect(find.text('BASS BOOST'), findsOneWidget);
      expect(find.text('3D VIRTUALIZER'), findsOneWidget);
      expect(find.text('Equalizer & DSP'), findsOneWidget);
    });

    testWidgets('dragging on SplineEqualizerCanvas sculpts band gain', (tester) async {
      int? changedIndex;
      double? changedGain;

      final bands = List.generate(
        10,
        (i) => EqualizerBand(
          index: i,
          centerFrequency: 100 * (i + 1),
          gain: 0.0,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 190,
                child: SplineEqualizerCanvas(
                  bands: bands,
                  preamp: 0.0,
                  isEnabled: true,
                  onBandGainChanged: (index, gain) {
                    changedIndex = index;
                    changedGain = gain;
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on canvas near band 2
      final canvas = find.byType(SplineEqualizerCanvas);
      await tester.tapAt(tester.getTopLeft(canvas) + const Offset(100, 40));
      await tester.pump();

      expect(changedIndex, isNotNull);
      expect(changedGain, isNotNull);
      expect(changedGain!, greaterThan(0.0));
    });

    testWidgets('dragging on TactileRotaryKnob turns value', (tester) async {
      double changedValue = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: TactileRotaryKnob(
                label: 'TEST KNOB',
                value: 0.2,
                isEnabled: true,
                onChanged: (val) => changedValue = val,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('TEST KNOB'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);

      // Drag vertically up to increase value
      await tester.drag(find.byType(TactileRotaryKnob), const Offset(0, -40));
      await tester.pumpAndSettle();

      expect(changedValue, greaterThan(0.2));
    });
  });
}
