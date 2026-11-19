import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/presentation/screens/privacy_storage_settings_screen.dart';
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
          child: PrivacyStorageSettingsScreen(),
        ),
      ),
    );
  }

  group('PrivacyStorageSettingsScreen Widget Tests', () {
    testWidgets('renders all privacy, backup, and reset sections',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Storage'), findsOneWidget);
      expect(find.text('PRIVACY & DIAGNOSTICS'), findsOneWidget);
      expect(find.text('BACKUP & RESTORE'), findsOneWidget);
      expect(find.text('HISTORY & FACTORY RESET'), findsOneWidget);

      expect(find.text('Anonymous Crash Reporting'), findsOneWidget);
      expect(find.text('Telemetry & Usage Diagnostics'), findsOneWidget);
      expect(find.text('Export Settings (JSON)'), findsOneWidget);
      expect(find.text('Import Settings (JSON)'), findsOneWidget);
      expect(find.text('Clear Search History'), findsOneWidget);
      expect(find.text('Reset Settings to Factory Defaults'), findsOneWidget);
    });

    testWidgets('tapping export settings opens preview dialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Export Settings (JSON)'));
      await tester.pumpAndSettle();

      expect(find.text('Copy to Clipboard'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Copy to Clipboard'), findsNothing);
    });

    testWidgets('tapping reset defaults opens confirmation dialog',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Settings to Factory Defaults'));
      await tester.pumpAndSettle();

      expect(find.text('Reset All Settings?'), findsOneWidget);
      expect(find.text('Reset Defaults'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset All Settings?'), findsNothing);
    });
  });
}
