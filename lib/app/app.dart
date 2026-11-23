import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'router.dart';

/// Root application widget for NEXA Player.
///
/// Reactively rebuilds whenever [themeControllerProvider] updates, applying
/// the selected preset or custom HSL theme with dynamic dark/light brightness.
class NexaPlayerApp extends ConsumerWidget {
  const NexaPlayerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final systemBrightness = MediaQuery.platformBrightnessOf(context);

    final effectiveTheme = AppTheme.buildTheme(
      preset: themeState.preset,
      mode: themeState.themeMode,
      systemBrightness: systemBrightness,
      customPrimary: themeState.customTheme?.primaryColor,
      customSurface: themeState.customTheme?.surfaceColor,
      customBackground: themeState.customTheme?.scaffoldBackgroundColor,
      fontFamily: 'Roboto',
    );

    return MaterialApp.router(
      title: 'NEXA Player',
      debugShowCheckedModeBanner: false,
      theme: effectiveTheme,
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
