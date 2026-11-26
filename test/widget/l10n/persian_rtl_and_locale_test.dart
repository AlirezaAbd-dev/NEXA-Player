import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/artists_tab_screen.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/presentation/providers/settings_providers.dart';
import 'package:nexa_player/features/settings/presentation/screens/settings_hub_screen.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/widgets/glass/nexa_floating_nav_dock.dart';
import 'package:nexa_player/shared/widgets/lists/active_track_auto_scroller.dart';
import '../../helpers/mock_services.dart';

void main() {
  test('LocaleController defaults to system and resolveNexaLocale resolves fa/en', () {
    final controller = LocaleController();
    expect(controller.state, AppLocalePreference.system);
    expect(controller.state.locale, isNull);

    expect(
      resolveNexaLocale(const Locale('fa', 'IR'), AppLocalizations.supportedLocales),
      const Locale('fa'),
    );
    expect(
      resolveNexaLocale(const Locale('en', 'US'), AppLocalizations.supportedLocales),
      const Locale('en'),
    );
    expect(
      resolveNexaLocale(const Locale('de', 'DE'), AppLocalizations.supportedLocales),
      const Locale('en'),
    );
  });

  testWidgets('Persian (fa) locale activates TextDirection.rtl and renders localized UI',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeStorage = FakeStorageService();
    final settingsService = SettingsServiceImpl(fakeStorage);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(fakeStorage),
          loggingServiceProvider.overrideWithValue(FakeLoggingService()),
          settingsServiceProvider.overrideWithValue(settingsService),
          localeControllerProvider.overrideWith(
            (ref) => LocaleController(fakeStorage)
              ..setLocalePreference(AppLocalePreference.fa),
          ),
          artistsListProvider(null).overrideWith(
            (ref) => Future.value(const [
              Artist(id: 'a1', name: 'شجریان', trackCount: 5, albumCount: 1),
            ]),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final pref = ref.watch(localeControllerProvider);
            return MaterialApp(
              theme: AppTheme.dark(),
              locale: pref.locale,
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              localeResolutionCallback: resolveNexaLocale,
              home: const SettingsHubScreen(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final dir = Directionality.of(tester.element(find.byType(SettingsHubScreen)));
    expect(dir, TextDirection.rtl);
    expect(find.text('تنظیمات'), findsOneWidget);
    expect(find.text('زبان برنامه'), findsOneWidget);

    // Open language picker and switch to English
    await tester.tap(find.byKey(const ValueKey('language_settings_tile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('English').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    final dirAfter = Directionality.of(tester.element(find.byType(SettingsHubScreen)));
    expect(dirAfter, TextDirection.ltr);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('ActiveTrackAutoScrollScope and ArtistsTabScreen render cleanly in RTL',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artistsListProvider(null).overrideWith(
            (ref) => Future.value(const [
              Artist(id: 'a1', name: 'شجریان', trackCount: 5, albumCount: 1),
            ]),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          locale: const Locale('fa'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: ActiveTrackAutoScrollScope(
            trackIds: List.generate(30, (i) => 't$i'),
            activeTrackId: 't25',
            builder: (_, controller) => const ArtistsTabScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(Directionality.of(tester.element(find.byType(ArtistsTabScreen))), TextDirection.rtl);
    expect(find.text('هنرمندان'), findsWidgets);
  });

  testWidgets('effectiveLetterSpacing zeroes tracking in RTL and preserves in LTR',
      (tester) async {
    late double ltrSpacing;
    late double rtlSpacing;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (ctx) {
            ltrSpacing = effectiveLetterSpacing(ctx, 1.2);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(ltrSpacing, 1.2);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Builder(
          builder: (ctx) {
            rtlSpacing = effectiveLetterSpacing(ctx, 1.2);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(rtlSpacing, 0.0);
  });

  testWidgets('NexaFloatingNavDock respects RTL directionality on horizontal swipe',
      (tester) async {
    int tappedIndex = -1;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: NexaFloatingNavDock(
            currentIndex: 0,
            onTap: (idx) => tappedIndex = idx,
          ),
        ),
      ),
    );
    // In RTL, dragging right advances to index 1.
    await tester.fling(
      find.byType(NexaFloatingNavDock),
      const Offset(200, 0),
      1000,
    );
    await tester.pump();
    expect(tappedIndex, 1);
  });
}
