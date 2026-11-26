import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/l10n/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../features/player/data/services/lockscreen_service.dart';
import '../features/player/presentation/providers/player_providers.dart';
import '../features/settings/presentation/providers/settings_providers.dart';
import '../l10n/generated/app_localizations.dart';
import 'router.dart';
import 'routes.dart';

/// Root application widget for NEXA Player.
///
/// Reactively rebuilds whenever [themeControllerProvider] updates, applying
/// the selected preset or custom HSL theme with dynamic dark/light brightness,
/// and opens [NowPlayingScreen] when the user taps the OS media notification.
class NexaPlayerApp extends ConsumerStatefulWidget {
  const NexaPlayerApp({super.key});

  @override
  ConsumerState<NexaPlayerApp> createState() => _NexaPlayerAppState();
}

class _NexaPlayerAppState extends ConsumerState<NexaPlayerApp> {
  StreamSubscription<bool>? _notificationClickSub;

  @override
  void initState() {
    super.initState();
    _notificationClickSub = AudioService.notificationClicked.listen((clicked) {
      if (!clicked || !mounted) return;
      final currentPath = appRouter.state.uri.path;
      if (currentPath != AppRoutes.player) {
        appRouter.push(AppRoutes.player);
      }
    });
    LockscreenService.registerOpenHandler(() {
      if (!mounted) return;
      final playerState = ref.read(playerNotifierProvider);
      if (playerState.currentTrack == null) return;
      final currentPath = appRouter.state.uri.path;
      if (currentPath != AppRoutes.lockscreen) {
        appRouter.push(AppRoutes.lockscreen);
      }
    });
  }

  @override
  void dispose() {
    LockscreenService.unregisterOpenHandler();
    _notificationClickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final localePref = ref.watch(localeControllerProvider);
    final lockscreenEnabled = ref.watch(
      notificationSettingsProvider.select((s) => s.lockScreenPlayer),
    );
    final isPlaying = ref.watch(isPlayingProvider);
    unawaited(
      LockscreenService.syncConfig(
        enabled: lockscreenEnabled,
        isPlaying: isPlaying,
      ),
    );
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    final effectiveTheme = AppTheme.buildTheme(
      preset: themeState.preset,
      mode: themeState.themeMode,
      systemBrightness: systemBrightness,
      customPrimary: themeState.customTheme?.primaryColor,
      customSurface: themeState.customTheme?.surfaceColor,
      customBackground: themeState.customTheme?.scaffoldBackgroundColor,
    );

    return MaterialApp.router(
      title: 'NEXA Player',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
      locale: localePref.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      localeResolutionCallback: resolveNexaLocale,
      routerConfig: appRouter,
      builder: (context, child) {
        return MediaQuery(
          // WCAG large text accessibility: ensure text scaling is clamped to safe bounds [0.85, 2.0]
          data: MediaQuery.of(context).copyWith(
            textScaler: MediaQuery.textScalerOf(context).clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 2.0,
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
