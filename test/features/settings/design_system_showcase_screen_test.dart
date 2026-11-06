import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/settings/presentation/screens/design_system_showcase_screen.dart';

import '../../helpers/mock_services.dart';

void main() {
  Widget buildTestScreen({Size screenSize = const Size(800, 1200)}) {
    return ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(FakeStorageService()),
        loggingServiceProvider.overrideWithValue(FakeLoggingService()),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: screenSize),
          child: const DesignSystemShowcaseScreen(),
        ),
      ),
    );
  }

  group('DesignSystemShowcaseScreen Widget Tests', () {
    testWidgets('renders root key, title, and all 7 design system sections', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('design_system_showcase_screen')), findsOneWidget);
      expect(find.text('Design System Showcase'), findsOneWidget);

      expect(find.text('1. Theme Engine & Mode Switcher'), findsOneWidget);
      expect(find.text('2. Spacing Scale Tokens'), findsOneWidget);
      expect(find.text('3. Typography Hierarchy'), findsOneWidget);
      expect(find.text('4. Glassmorphism Design Tokens'), findsOneWidget);
      expect(find.text('5. Base Glass Controls'), findsOneWidget);
    });

    testWidgets('theme mode switcher chips respond to user selection', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      final lightChip = find.byKey(const ValueKey('theme_mode_light'));
      final darkChip = find.byKey(const ValueKey('theme_mode_dark'));
      final systemChip = find.byKey(const ValueKey('theme_mode_system'));

      expect(lightChip, findsOneWidget);
      expect(darkChip, findsOneWidget);
      expect(systemChip, findsOneWidget);

      await tester.tap(lightChip);
      await tester.pumpAndSettle();

      await tester.tap(darkChip);
      await tester.pumpAndSettle();

      await tester.tap(systemChip);
      await tester.pumpAndSettle();
    });

    testWidgets('adapts to phone breakpoint (<600dp) without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(380, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen(screenSize: const Size(380, 800)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('design_system_showcase_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts to tablet and desktop breakpoint (>=600dp) without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 768));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen(screenSize: const Size(1024, 768)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('design_system_showcase_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('feedback overlay buttons trigger snackbar, dialog, and bottom sheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(900, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      // Scroll down to feedback section
      final feedbackText = find.text('7. Frosted Feedback Overlays');
      await tester.scrollUntilVisible(
        feedbackText,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(feedbackText, findsOneWidget);

      // 1. Test Snackbar Info trigger
      final snackbarBtn = find.byKey(const ValueKey('show_snackbar_info'));
      expect(snackbarBtn, findsOneWidget);
      await tester.tap(snackbarBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Track added to playback queue'), findsOneWidget);

      // 2. Test Dialog trigger
      final dialogBtn = find.byKey(const ValueKey('show_dialog_btn'));
      expect(dialogBtn, findsOneWidget);
      await tester.tap(dialogBtn);
      await tester.pumpAndSettle();

      expect(find.text('Equalizer Preset'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Equalizer Preset'), findsNothing);

      // 3. Test Bottom Sheet trigger
      final bottomSheetBtn = find.byKey(const ValueKey('show_bottom_sheet_btn'));
      expect(bottomSheetBtn, findsOneWidget);
      await tester.tap(bottomSheetBtn);
      await tester.pumpAndSettle();

      expect(find.text('Track Options'), findsOneWidget);
      expect(find.text('Add to Playlist'), findsOneWidget);
      await tester.tap(find.text('Add to Playlist'));
      await tester.pumpAndSettle();
      expect(find.text('Track Options'), findsNothing);
    });
  });
}
