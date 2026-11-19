import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/visualizer/domain/models/visualizer_settings.dart';
import 'package:nexa_player/features/visualizer/presentation/providers/visualizer_providers.dart';
import 'package:nexa_player/features/visualizer/presentation/screens/visualizer_settings_screen.dart';
import 'package:nexa_player/features/visualizer/presentation/widgets/spectrum_visualizer_widget.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late IStorageService storage;

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

  Widget buildScreen() {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storage),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(800, 1800)),
          child: VisualizerSettingsScreen(),
        ),
      ),
    );
  }

  group('VisualizerSettingsScreen Widget Tests', () {
    testWidgets('renders screen title, live preview, and setting sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      expect(find.text('Visualizer & Spectrum'), findsOneWidget);
      expect(find.byType(SpectrumVisualizerWidget), findsOneWidget);
      expect(find.text('DISPLAY STYLE & ENGINE'), findsOneWidget);
      expect(find.text('PERFORMANCE & RESOLUTION'), findsOneWidget);
      expect(find.text('Visualization Mode'), findsOneWidget);
      expect(find.text('Color Accent Glow'), findsOneWidget);
      expect(find.text('Motion Sensitivity'), findsOneWidget);
      expect(find.text('Frame Rate Cap (FPS)'), findsOneWidget);
      expect(find.text('FFT Frequency Resolution'), findsOneWidget);
      expect(find.text('Show on Lock Screen'), findsOneWidget);
    });

    testWidgets('tapping different styles updates visualizer style', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Open Visualization Mode modal
      final modeTile = find.text('Visualization Mode');
      expect(modeTile, findsOneWidget);
      await tester.tap(modeTile);
      await tester.pumpAndSettle();

      // Select 'Radial Circle (Mandala Glow)'
      final circleOption = find.text('Radial Circle (Mandala Glow)');
      expect(circleOption, findsOneWidget);
      await tester.tap(circleOption);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(VisualizerSettingsScreen)));
      expect(container.read(visualizerSettingsProvider).style, equals(VisualizerStyle.circle));
    });

    testWidgets('changing sensitivity slider updates notifier state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      await tester.drag(slider, const Offset(80, 0));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(VisualizerSettingsScreen)));
      expect(container.read(visualizerSettingsProvider).sensitivity, isNot(equals(1.0)));
    });

    testWidgets('toggling lock screen switch updates settings', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      final toggle = find.byType(Switch);
      expect(toggle, findsOneWidget);

      await tester.tap(toggle);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(tester.element(find.byType(VisualizerSettingsScreen)));
      expect(container.read(visualizerSettingsProvider).showOnLockScreen, isTrue);
    });
  });
}
