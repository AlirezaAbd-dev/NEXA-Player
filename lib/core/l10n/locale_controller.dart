import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';
import 'package:nexa_player/l10n/generated/app_localizations_en.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

/// Supported language preference modes for NEXA Player.
enum AppLocalePreference {
  system('system'),
  en('en'),
  fa('fa');

  const AppLocalePreference(this.code);
  final String code;

  Locale? get locale => switch (this) {
        AppLocalePreference.system => null,
        AppLocalePreference.en => const Locale('en'),
        AppLocalePreference.fa => const Locale('fa'),
      };

  static AppLocalePreference fromCode(String? code) => switch (code) {
        'en' => AppLocalePreference.en,
        'fa' => AppLocalePreference.fa,
        _ => AppLocalePreference.system,
      };
}

/// Manages the active [AppLocalePreference], defaulting to [AppLocalePreference.system]
/// so the app follows the device's system language out of the box.
class LocaleController extends StateNotifier<AppLocalePreference> {
  LocaleController([this._storage])
      : super(
          AppLocalePreference.fromCode(
            _storage?.getString(StorageKeys.appLocale).valueOrNull,
          ),
        );

  final IStorageService? _storage;

  Future<void> setLocalePreference(AppLocalePreference pref) async {
    state = pref;
    await _storage?.setString(StorageKeys.appLocale, pref.code);
  }
}

/// Global Riverpod provider for the user's selected [AppLocalePreference].
final localeControllerProvider =
    StateNotifierProvider<LocaleController, AppLocalePreference>((ref) {
  final storage =
      getIt.isRegistered<IStorageService>() ? getIt<IStorageService>() : null;
  return LocaleController(storage);
});

/// Resolves the device's system locale to either Persian (`fa`) or English (`en`).
Locale resolveNexaLocale(
  Locale? deviceLocale,
  Iterable<Locale> supportedLocales,
) {
  if (deviceLocale != null &&
      deviceLocale.languageCode.toLowerCase() == 'fa') {
    return const Locale('fa');
  }
  return const Locale('en');
}

/// Returns `0.0` in RTL layouts so Persian/Arabic cursive ligatures stay
/// cleanly joined, while preserving typographic tracking in LTR layouts.
double effectiveLetterSpacing(BuildContext context, double ltrSpacing) =>
    Directionality.of(context) == TextDirection.rtl ? 0.0 : ltrSpacing;

/// Safe localization accessor on [BuildContext] with English fallback for
/// isolated widget tests that pump a screen without [AppLocalizations.delegate].
extension NexaL10nContext on BuildContext {
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? AppLocalizationsEn();
}
