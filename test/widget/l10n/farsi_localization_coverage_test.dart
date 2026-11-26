import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_state.dart';
import 'package:nexa_player/features/settings/domain/models/audio_settings.dart';
import 'package:nexa_player/features/settings/domain/services/settings_service.dart';
import 'package:nexa_player/features/settings/presentation/providers/settings_providers.dart';
import 'package:nexa_player/features/settings/presentation/screens/settings_hub_screen.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';

class _FakeThemeController extends ThemeController {
  @override
  ThemeState build() => ThemeState.initial;
}

class _FakeLocaleController extends StateNotifier<AppLocalePreference>
    implements LocaleController {
  _FakeLocaleController() : super(AppLocalePreference.fa);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeSettingsService implements ISettingsService {
  @override
  Future<AudioSettings> getAudioSettings() async => const AudioSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'SettingsHubScreen renders localized Persian titles and subtitles in fa locale',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            themeControllerProvider.overrideWith(_FakeThemeController.new),
            localeControllerProvider.overrideWith((ref) => _FakeLocaleController()),
            settingsServiceProvider.overrideWithValue(_FakeSettingsService()),
            settingsSearchResultsProvider.overrideWith((ref) => const []),
          ],
          child: const MaterialApp(
            locale: Locale('fa'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: SettingsHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('تنظیمات'), findsOneWidget);
      expect(find.text('ویجت‌های صفحه اصلی و حالت شب'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(find.text('ویژوالایزر و طیف صدا'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('درباره نِکسا'),
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('درباره نِکسا'), findsOneWidget);
    },
  );
}
