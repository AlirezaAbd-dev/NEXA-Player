import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/utils/contrast_validator.dart';
import 'package:nexa_player/features/themes/presentation/screens/theme_picker_screen.dart';
import 'package:nexa_player/features/themes/presentation/widgets/theme_preset_card.dart';
import '../../helpers/mock_services.dart';

void main() {
  group('ThemePicker & Daylight Contrast Audit Tests', () {
    Widget buildScreen({ThemePreset initialPreset = ThemePreset.midnightBlack}) {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          loggingServiceProvider.overrideWithValue(FakeLoggingService()),
        ],
        child: const MaterialApp(
          home: ThemePickerScreen(),
        ),
      );
    }

    testWidgets('Renders all 8 preset cards and custom card with live preview elements',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen());
      await tester.pumpAndSettle();

      // Find preset cards
      final presetCards = find.byType(ThemePresetCard);
      expect(presetCards, findsNWidgets(9));

      // Each preset card contains mini player preview elements (music note icon)
      expect(find.byIcon(Icons.music_note_rounded), findsNWidgets(9));
    });

    testWidgets('Unselected preset cards are strictly borderless (border == null)',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildScreen(initialPreset: ThemePreset.midnightBlack));
      await tester.pumpAndSettle();

      // Midnight black is selected -> has border for active selection contrast
      final midnightFinder = find.byKey(const ValueKey('theme_card_midnight_black'));
      expect(midnightFinder, findsOneWidget);

      final midnightCard = tester.widget<ThemePresetCard>(midnightFinder);
      expect(midnightCard.isSelected, isTrue);

      // Deep Space is unselected -> must be strictly borderless
      final deepSpaceFinder = find.byKey(const ValueKey('theme_card_deep_space'));
      expect(deepSpaceFinder, findsOneWidget);

      final deepSpaceCard = tester.widget<ThemePresetCard>(deepSpaceFinder);
      expect(deepSpaceCard.isSelected, isFalse);

      // Check AnimatedContainer decoration for unselected card
      final animContainers = find.descendant(
        of: deepSpaceFinder,
        matching: find.byType(AnimatedContainer),
      );
      expect(animContainers, findsOneWidget);
      final container = tester.widget<AnimatedContainer>(animContainers);
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull,
          reason: 'Unselected preset cards must not render any border');
    });

    test('Daylight preset colors strictly satisfy WCAG AA (>= 4.5:1) text contrast', () {
      const daylightSurface = Color(0xFFFFFFFF);
      const daylightBg = Color(0xFFF8FAFC);
      const daylightTitle = Color(0xFF0F172A);

      // Contrast against surface
      final contrastRatioSurface = ContrastValidator.calculateRatio(daylightTitle, daylightSurface);
      expect(contrastRatioSurface, greaterThanOrEqualTo(4.5),
          reason: 'Daylight title against surface must satisfy WCAG AA >= 4.5:1');

      // Contrast against background
      final contrastRatioBg = ContrastValidator.calculateRatio(daylightTitle, daylightBg);
      expect(contrastRatioBg, greaterThanOrEqualTo(4.5),
          reason: 'Daylight title against background must satisfy WCAG AA >= 4.5:1');

      // Clamping audit
      final clamped = ensureContrast(daylightTitle, daylightSurface, minRatio: 4.5);
      expect(clamped, equals(daylightTitle),
          reason: 'Already compliant daylight title should not require hue alteration');
    });
  });
}
