import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpAppExtension on WidgetTester {
  /// Pumps a widget wrapped in [ProviderScope], [MaterialApp], and [Scaffold].
  Future<void> pumpApp(
    Widget widget, {
    List<Override> overrides = const [],
    ThemeData? theme,
    ThemeMode themeMode = ThemeMode.system,
    NavigatorObserver? navigatorObserver,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme ?? ThemeData.dark(useMaterial3: true),
          themeMode: themeMode,
          navigatorObservers: [
            if (navigatorObserver != null) navigatorObserver,
          ],
          home: Scaffold(body: widget),
        ),
      ),
    );
    await pump();
  }

  /// Pumps a router application with [ProviderScope].
  Future<void> pumpRouterApp(
    RouterConfig<Object> routerConfig, {
    List<Override> overrides = const [],
    ThemeData? theme,
  }) async {
    await pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: theme ?? ThemeData.dark(useMaterial3: true),
          routerConfig: routerConfig,
        ),
      ),
    );
    await pumpAndSettle();
  }

  /// Sets the simulated screen viewport size and ensures it is reset after test execution.
  void setDisplaySize(Size size, {double devicePixelRatio = 1.0}) {
    view.physicalSize = size;
    view.devicePixelRatio = devicePixelRatio;
    addTearDown(() {
      view.resetPhysicalSize();
      view.resetDevicePixelRatio();
    });
  }

  /// Phone portrait breakpoint (<600dp width)
  void setPhonePortrait() => setDisplaySize(const Size(390, 844));

  /// Phone landscape / tablet breakpoint (600–840dp width)
  void setPhoneLandscape() => setDisplaySize(const Size(844, 390));

  /// Tablet breakpoint (e.g., 820x1180)
  void setTablet() => setDisplaySize(const Size(820, 1180));

  /// Desktop breakpoint (>840dp width)
  void setDesktop() => setDisplaySize(const Size(1440, 900));
}
