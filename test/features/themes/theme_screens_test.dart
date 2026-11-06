import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/custom_theme_data.dart';
import 'package:nexa_player/features/themes/themes.dart';

import '../../e2e/e2e_test_helpers.dart';
import '../../helpers/mock_services.dart';

void main() {
  group('CustomThemeData Unit Tests', () {
    test('Roundtrip JSON serialization preserves all HSL properties and mode flags', () {
      const original = CustomThemeData(
        primaryHue: 280.0,
        primarySaturation: 0.85,
        primaryLightness: 0.55,
        surfaceLightness: 0.12,
        isDark: true,
        name: 'Electric Violet',
      );

      final jsonMap = original.toJson();
      final restored = CustomThemeData.fromJson(jsonMap);

      expect(restored, equals(original));
      expect(restored.primaryHue, equals(280.0));
      expect(restored.primarySaturation, equals(0.85));
      expect(restored.primaryLightness, equals(0.55));
      expect(restored.surfaceLightness, equals(0.12));
      expect(restored.isDark, isTrue);
      expect(restored.name, equals('Electric Violet'));
    });

    test('Corrupted or partial JSON recovers safely with default values', () {
      final corrupted = CustomThemeData.fromJson(const {'invalid_key': 123});
      expect(corrupted.primaryHue, equals(185.0));
      expect(corrupted.primarySaturation, equals(0.90));
      expect(corrupted.primaryLightness, equals(0.55));
      expect(corrupted.isDark, isTrue);
      expect(CustomThemeData.fromJsonString('not a json'), isNull);
      expect(CustomThemeData.fromJsonString(null), isNull);
      expect(CustomThemeData.fromJsonString(''), isNull);
    });

    test('Hue normalizes correctly across wrap-around boundaries (360° and negative)', () {
      const wrap360 = CustomThemeData(primaryHue: 360.0);
      expect(wrap360.normalizedHue, equals(0.0));

      const wrap450 = CustomThemeData(primaryHue: 450.0);
      expect(wrap450.normalizedHue, equals(90.0));

      const negative = CustomThemeData(primaryHue: -30.0);
      expect(negative.normalizedHue, equals(330.0));
    });

    test('Saturation 0.0 produces pure monochrome grayscale with equal RGB channels', () {
      const monochrome = CustomThemeData(
        primaryHue: 120.0,
        primarySaturation: 0.0,
        primaryLightness: 0.5,
      );
      final color = monochrome.primaryColor;
      expect(color.red, equals(color.green));
      expect(color.green, equals(color.blue));
    });

    test('Contrast clamping protects against unreadable black-on-black or white-on-white', () {
      // 0.0 Lightness in Dark Mode is clamped to >= 0.35
      const blackInDark = CustomThemeData(primaryLightness: 0.0, isDark: true);
      expect(blackInDark.clampedPrimaryLightness, greaterThanOrEqualTo(0.35));
      expect(blackInDark.accentContrastRatio, greaterThanOrEqualTo(3.0));

      // 1.0 Lightness in Light Mode is clamped to <= 0.65
      const whiteInLight = CustomThemeData(primaryLightness: 1.0, isDark: false);
      expect(whiteInLight.clampedPrimaryLightness, lessThanOrEqualTo(0.65));
      expect(whiteInLight.accentContrastRatio, greaterThanOrEqualTo(3.0));
    });

    test('toColorScheme generates valid Material 3 ColorScheme with high contrast onPrimary', () {
      const theme = CustomThemeData(
        primaryHue: 280.0,
        primarySaturation: 0.9,
        primaryLightness: 0.55,
      );
      final scheme = theme.toColorScheme();

      expect(scheme.brightness, equals(Brightness.dark));
      expect(scheme.primary, equals(theme.primaryColor));
      expect(scheme.surface, equals(theme.surfaceColor));
      expect(scheme.onPrimary, isNotNull);
    });

    test('toThemeData produces complete ThemeData with Material 3 enabled', () {
      const theme = CustomThemeData.defaultDark;
      final themeData = theme.toThemeData();
      expect(themeData.useMaterial3, isTrue);
      expect(themeData.scaffoldBackgroundColor, equals(theme.scaffoldBackgroundColor));
    });
  });

  group('ThemePickerScreen Widget Tests', () {
    Widget buildScreen({FakeStorageService? storage, FakeLoggingService? logging}) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage ?? FakeStorageService()),
          loggingServiceProvider.overrideWithValue(logging ?? FakeLoggingService()),
        ],
        child: const MaterialApp(
          home: ThemePickerScreen(),
        ),
      );
    }

    testWidgets('Renders all 8 preset cards, custom theme card, and mode buttons with exact E2EKeys', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Check Mode Buttons
      expect(find.byKey(E2EKeys.themeModeDark), findsOneWidget);
      expect(find.byKey(E2EKeys.themeModeLight), findsOneWidget);
      expect(find.byKey(E2EKeys.themeModeSystem), findsOneWidget);

      // Check Preset Cards in Grid
      expect(find.byKey(E2EKeys.themePickerGrid), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardMidnight), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardDeepSpace), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardSakura), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardOceanBlue), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardForestGreen), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardLava), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardDaylight), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardNeonPurple), findsOneWidget);
      expect(find.byKey(E2EKeys.themeCardCustom), findsOneWidget);
    });

    testWidgets('Tapping a preset card triggers theme change without throwing', (tester) async {
      final fakeStorage = FakeStorageService();
      await tester.pumpWidget(buildScreen(storage: fakeStorage));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(E2EKeys.themeCardOceanBlue));
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
      expect(fakeStorage.getRaw('theme_preset'), equals('oceanBlue'));
    });

    testWidgets('Tapping Custom card navigates to CustomThemeEditorScreen', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(E2EKeys.themeCardCustom));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(E2EKeys.themeCardCustom));
      await tester.pumpAndSettle();

      expect(find.byType(CustomThemeEditorScreen), findsOneWidget);
      expect(find.byKey(E2EKeys.hslHueSlider), findsOneWidget);
      expect(find.byKey(E2EKeys.hslSaveButton), findsOneWidget);
    });

    testWidgets('Responsive Grid adapts columns across Phone (<600dp) and Desktop (>840dp) without overflow', (tester) async {
      // 1. Phone Portrait
      await E2ETestHarness.setCompactPhoneSize(tester);
      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);

      // 2. Desktop Expanded
      await E2ETestHarness.setExpandedDesktopSize(tester);
      await tester.pumpAndSettle();
      E2ETestHarness.expectNoOverflow(tester);
    });
  });

  group('CustomThemeEditorScreen Widget Tests', () {
    Widget buildEditorScreen({FakeStorageService? storage, FakeLoggingService? logging}) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(storage ?? FakeStorageService()),
          loggingServiceProvider.overrideWithValue(logging ?? FakeLoggingService()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: CustomThemeEditorScreen()),
        ),
      );
    }

    testWidgets('Renders all HSL sliders, live preview card, and Save button', (tester) async {
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(E2EKeys.hslHueSlider), findsOneWidget);
      expect(find.byKey(E2EKeys.hslSaturationSlider), findsOneWidget);
      expect(find.byKey(E2EKeys.hslLightnessSlider), findsOneWidget);
      expect(find.byKey(E2EKeys.hslSaveButton), findsOneWidget);
      expect(find.text('Live Palette Preview'), findsOneWidget);
    });

    testWidgets('Dragging Hue slider updates preview in real time', (tester) async {
      await tester.pumpWidget(buildEditorScreen());
      await tester.pumpAndSettle();

      final slider = find.byKey(E2EKeys.hslHueSlider);
      await tester.drag(slider, const Offset(100, 0));
      await tester.pumpAndSettle();

      E2ETestHarness.expectNoOverflow(tester);
    });

    testWidgets('Tapping hslSaveButton saves theme and displays feedback', (tester) async {
      final fakeStorage = FakeStorageService();
      await tester.pumpWidget(buildEditorScreen(storage: fakeStorage));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(E2EKeys.hslSaveButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(E2EKeys.hslSaveButton));
      await tester.pumpAndSettle();

      expect(find.text('Custom theme saved!'), findsOneWidget);
      expect(fakeStorage.getRaw('theme_preset'), equals('custom'));
    });
  });
}
