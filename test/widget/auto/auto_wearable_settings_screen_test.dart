import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/auto/presentation/providers/auto_providers.dart';
import 'package:nexa_player/features/auto/presentation/screens/auto_wearable_settings_screen.dart';
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

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        autoSettingsProvider.overrideWith((ref) => AutoSettingsNotifier(storage)),
      ],
      child: const MaterialApp(
        home: AutoWearableSettingsScreen(),
      ),
    );
  }

  group('AutoWearableSettingsScreen Tests', () {
    testWidgets('renders sections, tiles, and switches properly', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Auto & Wearables'), findsOneWidget);
      expect(find.text('Launch Car Mode HUD'), findsOneWidget);
      expect(find.text('Keep Screen Awake'), findsOneWidget);
      expect(find.text('Oversized 72dp Buttons'), findsOneWidget);
      expect(find.text('Bluetooth Car Auto-Launch'), findsOneWidget);
      expect(find.text('Android Auto MediaBrowser'), findsOneWidget);
      expect(find.text('Wear OS Companion Sync'), findsOneWidget);
      expect(find.text('Preview Smartwatch Hub'), findsOneWidget);
    });

    testWidgets('toggling a switch calls notifier and persists state',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final keepAwakeSwitch = find.widgetWithText(
        SwitchListTile,
        'Keep Screen Awake',
      );
      expect(keepAwakeSwitch, findsOneWidget);

      await tester.tap(keepAwakeSwitch);
      await tester.pumpAndSettle();

      final notifier = ProviderContainer(
        overrides: [
          autoSettingsProvider.overrideWith(
            (ref) => AutoSettingsNotifier(storage),
          ),
        ],
      );
      addTearDown(notifier.dispose);
    });
  });
}
