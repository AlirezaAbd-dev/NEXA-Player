import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/visualizer/domain/models/visualizer_settings.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/painters/bars_visualizer_painter.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/painters/circle_visualizer_painter.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/painters/spectrogram_painter.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/painters/vu_meter_painter.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/painters/wave_visualizer_painter.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/spectrum_visualizer_widget.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IStorageService storage;
  const testMags = [0.1, 0.4, 0.8, 0.6, 0.3, 0.9, 0.5, 0.2];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    if (!getIt.isRegistered<IStorageService>()) {
      getIt.registerSingleton<IStorageService>(storage);
    }
  });

  tearDown(() async {
    if (getIt.isRegistered<IStorageService>()) {
      await getIt.unregister<IStorageService>();
    }
  });

  Widget buildTestWidget({required VisualizerStyle style}) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 120,
              child: SpectrumVisualizerWidget(
                magnitudes: testMags,
                style: style,
                accentColor: const Color(0xFF00E5FF),
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('SpectrumVisualizerWidget Tests', () {
    testWidgets('renders BarsVisualizerPainter when style is bars', (tester) async {
      await tester.pumpWidget(buildTestWidget(style: VisualizerStyle.bars));
      await tester.pumpAndSettle();

      final customPaints = tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(SpectrumVisualizerWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaints.first.painter, isA<BarsVisualizerPainter>());
    });

    testWidgets('renders CircleVisualizerPainter when style is circle', (tester) async {
      await tester.pumpWidget(buildTestWidget(style: VisualizerStyle.circle));
      await tester.pumpAndSettle();

      final customPaints = tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(SpectrumVisualizerWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaints.first.painter, isA<CircleVisualizerPainter>());
    });

    testWidgets('renders WaveVisualizerPainter when style is wave', (tester) async {
      await tester.pumpWidget(buildTestWidget(style: VisualizerStyle.wave));
      await tester.pumpAndSettle();

      final customPaints = tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(SpectrumVisualizerWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaints.first.painter, isA<WaveVisualizerPainter>());
    });

    testWidgets('renders SpectrogramPainter when style is spectrogram', (tester) async {
      await tester.pumpWidget(buildTestWidget(style: VisualizerStyle.spectrogram));
      await tester.pumpAndSettle();

      final customPaints = tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(SpectrumVisualizerWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaints.first.painter, isA<SpectrogramPainter>());
    });

    testWidgets('renders VuMeterPainter when style is vuMeter', (tester) async {
      await tester.pumpWidget(buildTestWidget(style: VisualizerStyle.vuMeter));
      await tester.pumpAndSettle();

      final customPaints = tester.widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(SpectrumVisualizerWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      expect(customPaints.first.painter, isA<VuMeterPainter>());
    });

    testWidgets('renders SizedBox.shrink when style is off', (tester) async {
      await tester.pumpWidget(buildTestWidget(style: VisualizerStyle.off));
      await tester.pumpAndSettle();

      final descendantCustomPaints = find.descendant(
        of: find.byType(SpectrumVisualizerWidget),
        matching: find.byType(CustomPaint),
      );
      expect(descendantCustomPaints, findsNothing);
    });
  });
}
