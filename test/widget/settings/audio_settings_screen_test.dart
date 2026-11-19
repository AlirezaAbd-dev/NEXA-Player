import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/presentation/screens/audio_settings_screen.dart';
import '../../helpers/mock_services.dart';

void main() {
  late FakeStorageService fakeStorage;
  late SettingsServiceImpl settingsService;

  setUp(() {
    fakeStorage = FakeStorageService();
    settingsService = SettingsServiceImpl(fakeStorage);
  });

  Widget buildTestScreen() {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(fakeStorage),
        loggingServiceProvider.overrideWithValue(FakeLoggingService()),
        settingsServiceProvider.overrideWithValue(settingsService),
      ],
      child: const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(800, 1800)),
          child: AudioSettingsScreen(),
        ),
      ),
    );
  }

  group('AudioSettingsScreen Widget Tests', () {
    testWidgets('renders all audio engine sections and default controls',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Audio Settings'), findsOneWidget);
      expect(find.text('PLAYBACK & TRANSITIONS'), findsOneWidget);
      expect(find.text('HARDWARE OUTPUT & CLOCK'), findsOneWidget);
      expect(find.text('DYNAMICS & LOUDNESS'), findsOneWidget);
      expect(find.text('DIGITAL SIGNAL PROCESSING'), findsOneWidget);

      expect(find.text('Gapless Playback'), findsOneWidget);
      expect(find.text('Crossfade on Track Change'), findsOneWidget);
      expect(find.text('Fading on Play / Pause'), findsOneWidget);
      expect(find.text('Audio Buffer Size'), findsOneWidget);
      expect(find.text('Audio Output Routing'), findsOneWidget);
      expect(find.text('Sample Rate'), findsOneWidget);
      expect(find.text('Bit Depth Output'), findsOneWidget);
      expect(find.text('Dithering'), findsOneWidget);
      expect(find.text('Hi-Res Audio Mode'), findsOneWidget);
      expect(find.text('Direct Volume Control (DVC)'), findsOneWidget);
    });

    testWidgets('enabling crossfade reveals the crossfade duration slider',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // By default crossfade is disabled, so slider is not present
      expect(find.text('Crossfade Length'), findsNothing);

      // Find Crossfade on Track Change switch and tap it
      final crossfadeSwitch = find.ancestor(
        of: find.text('Crossfade on Track Change'),
        matching: find.byType(Row),
      );
      final switchWidget = find.descendant(
        of: crossfadeSwitch,
        matching: find.byType(Switch),
      );

      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      // Now Crossfade Length slider and duration label should be visible
      expect(find.text('Crossfade Length'), findsOneWidget);
      expect(find.text('3s'), findsOneWidget);
    });

    testWidgets('tapping selector tile opens modal options sheet',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Tap on Audio Buffer Size selector
      await tester.tap(find.text('Audio Buffer Size'));
      await tester.pumpAndSettle();

      // Bottom sheet options appear
      expect(find.text('Low Latency (50ms)'), findsOneWidget);
      expect(find.text('Safe Buffer (200ms)'), findsOneWidget);

      // Select Low Latency
      await tester.tap(find.text('Low Latency (50ms)'));
      await tester.pumpAndSettle();

      // Modal closed and badge reflects Low Latency
      expect(find.text('Low Latency (50ms)'), findsOneWidget);
    });
  });
}
