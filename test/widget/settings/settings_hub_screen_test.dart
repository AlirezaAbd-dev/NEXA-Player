import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/presentation/providers/settings_providers.dart';
import 'package:nexa_player/features/settings/presentation/screens/settings_hub_screen.dart';
import 'package:nexa_player/features/settings/presentation/widgets/audio_status_strip.dart';
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
          data: MediaQueryData(size: Size(800, 1600)),
          child: SettingsHubScreen(),
        ),
      ),
    );
  }

  group('SettingsHubScreen Widget Tests', () {
    testWidgets('renders search input, audio status strip, 3 tiers, and categories',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byKey(const ValueKey('search_settings_input')), findsOneWidget);
      expect(find.byKey(AudioStatusStripKeys.root), findsOneWidget);
      expect(find.text('AUDIO PIPELINE STATUS'), findsOneWidget);

      // 3 Tiers
      expect(find.text('DAILY ESSENTIALS'), findsOneWidget);
      expect(find.text('ACOUSTIC ENGINE'), findsOneWidget);
      expect(find.text('SYSTEM & STORAGE'), findsOneWidget);

      // Core categories
      expect(find.byKey(const ValueKey('theme_settings_tile')), findsOneWidget);
      expect(find.text('Audio Settings'), findsOneWidget);
      expect(find.text('Equalizer & DSP Engine'), findsOneWidget);
      expect(find.text('Playback & Controls'), findsOneWidget);
      expect(find.text('Scanner Settings'), findsOneWidget);
      expect(find.text('Album Art'), findsOneWidget);
      expect(find.text('Lyrics & Metadata'), findsOneWidget);
      expect(find.text('Power Saving'), findsOneWidget);
    });

    testWidgets('tapping 1-tap audiophile preset updates audio pipeline telemetry',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final bitPerfectButton = find.byKey(AudioStatusStripKeys.presetBitPerfect);
      expect(bitPerfectButton, findsOneWidget);

      await tester.tap(bitPerfectButton);
      await tester.pumpAndSettle();

      // Should display 192kHz in telemetry
      expect(find.textContaining('192kHz'), findsOneWidget);
    });

    testWidgets('filters settings catalog when searching by keyword',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Enter search query
      final searchInput = find.byKey(const ValueKey('search_settings_input'));
      await tester.enterText(searchInput, 'crossfade');
      await tester.pumpAndSettle();

      // Should display matching results
      expect(find.text('MATCHING SETTINGS (2)'), findsOneWidget);
      expect(find.text('Crossfade on Track Change'), findsOneWidget);
      expect(find.text('Crossfade Length'), findsOneWidget);

      // Hero theme card should be hidden while searching
      expect(find.byKey(const ValueKey('theme_settings_tile')), findsNothing);
    });

    testWidgets('shows empty state when search finds no matches',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const ValueKey('search_settings_input'));
      await tester.enterText(searchInput, 'xyznonexistent123');
      await tester.pumpAndSettle();

      expect(find.text('No settings found for "xyznonexistent123"'),
          findsOneWidget);
    });

    testWidgets('clearing search query restores categorized categories',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final searchInput = find.byKey(const ValueKey('search_settings_input'));
      await tester.enterText(searchInput, 'dvc');
      await tester.pumpAndSettle();

      expect(find.text('Direct Volume Control (DVC)'), findsOneWidget);

      // Tap clear button in text field
      final clearButton = find.byTooltip('Clear text');
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Categorized cards restored
      expect(find.byKey(const ValueKey('theme_settings_tile')), findsOneWidget);
      expect(find.text('Audio Settings'), findsOneWidget);
    });
  });
}
