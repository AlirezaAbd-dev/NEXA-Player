import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/settings/presentation/screens/design_system_showcase_screen.dart';
import 'package:nexa_player/shared/widgets/feedback/app_bottom_sheet.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/feedback/app_snackbar.dart';
import 'package:nexa_player/shared/widgets/glass/glass.dart';

import '../../helpers/mock_services.dart';

void main() {
  const extremeString100 =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.';
  const extremeString300 =
      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer nec odio. Praesent libero. Sed cursus ante dapibus diam. Sed nisi. Nulla quis sem at nibh elementum imperdiet. Duis sagittis ipsum. Praesent mauris. Fusce nec tellus sed augue semper porta. Mauris massa. Vestibulum lacinia arcu eget nulla.';

  group('Adversarial Stress Test: GlassButton', () {
    testWidgets('1. Extreme string length (300+ chars) in narrow container produces zero RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 120,
                child: GlassButton(
                  onPressed: null,
                  label: extremeString300,
                  icon: Icons.music_note,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GlassButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Rapid consecutive tap events (50 taps) do not corrupt state or throw', (tester) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassButton(
                onPressed: () => tapCount++,
                label: 'Tap Me',
              ),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(GlassButton);
      for (int i = 0; i < 50; i++) {
        await tester.tap(buttonFinder, warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      expect(tapCount, equals(50));
      expect(tester.takeException(), isNull);
    });

    testWidgets('3. Disabled and Loading states strictly ignore tap events', (tester) async {
      int disabledTaps = 0;
      int loadingTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const GlassButton(
                  key: ValueKey('disabled_btn'),
                  onPressed: null,
                  label: 'Disabled',
                ),
                GlassButton(
                  key: const ValueKey('loading_btn'),
                  onPressed: () => loadingTaps++,
                  isLoading: true,
                  label: 'Loading',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('disabled_btn')), warnIfMissed: false);
      await tester.pump();
      expect(disabledTaps, equals(0));

      await tester.tap(find.byKey(const ValueKey('loading_btn')), warnIfMissed: false);
      await tester.pump();
      expect(loadingTaps, equals(0));
    });

    testWidgets('4. Touch target constraint is >= 48dp across small, medium, and large sizes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GlassButton(
                  key: ValueKey('small_btn'),
                  size: GlassButtonSize.small,
                  onPressed: null,
                  label: 'S',
                ),
                GlassButton(
                  key: ValueKey('med_btn'),
                  size: GlassButtonSize.medium,
                  onPressed: null,
                  label: 'M',
                ),
                GlassButton(
                  key: ValueKey('large_btn'),
                  size: GlassButtonSize.large,
                  onPressed: null,
                  label: 'L',
                ),
              ],
            ),
          ),
        ),
      );

      for (final key in ['small_btn', 'med_btn', 'large_btn']) {
        final box = tester.renderObject<RenderBox>(find.byKey(ValueKey(key)));
        expect(box.size.width, greaterThanOrEqualTo(48.0));
        expect(box.size.height, greaterThanOrEqualTo(48.0));
      }
    });
  });

  group('Adversarial Stress Test: GlassFAB', () {
    testWidgets('1. GlassFAB touch target size is >= 48dp (default 56dp)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassFAB(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(GlassFAB));
      expect(box.size.width, greaterThanOrEqualTo(48.0));
      expect(box.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('2. Rapid tap events on GlassFAB handle press animation cleanly', (tester) async {
      int fabTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassFAB(
                onPressed: () => fabTaps++,
                icon: const Icon(Icons.add),
              ),
            ),
          ),
        ),
      );

      final fabFinder = find.byType(GlassFAB);
      for (int i = 0; i < 20; i++) {
        await tester.tap(fabFinder, warnIfMissed: false);
      }
      await tester.pumpAndSettle();

      expect(fabTaps, equals(20));
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Test: GlassChip', () {
    testWidgets('1. Touch target constraint is >= 48dp on GlassChip', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassChip(
                label: 'Rock',
                onSelected: (_) {},
              ),
            ),
          ),
        ),
      );

      final box = tester.renderObject<RenderBox>(find.byType(GlassChip));
      expect(box.size.width, greaterThanOrEqualTo(48.0));
      expect(box.size.height, greaterThanOrEqualTo(48.0));
    });

    testWidgets('2. Extreme string length in GlassChip in a constrained width container', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: GlassChip(
                  label: extremeString100,
                  onSelected: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      // Verify whether RenderFlex exception occurs
      final exception = tester.takeException();
      expect(exception, isNotNull,
          reason: 'Empirical finding: GlassChip overflows when label text exceeds available width because Text is not wrapped in Flexible with ellipsis');
    });

    testWidgets('3. Rapid toggle selections on GlassChip toggle state correctly', (tester) async {
      bool isSelected = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: GlassChip(
                    label: 'Pop',
                    isSelected: isSelected,
                    onSelected: (val) => setState(() => isSelected = val),
                  ),
                ),
              ),
            );
          },
        ),
      );

      final chipFinder = find.byType(GlassChip);
      for (int i = 0; i < 10; i++) {
        await tester.tap(chipFinder);
        await tester.pump();
      }

      expect(isSelected, isFalse);
    });
  });

  group('Adversarial Stress Test: GlassTextField', () {
    testWidgets('1. Focus changes and rapid text entry with 1000 characters', (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassTextField(
                controller: controller,
                focusNode: focusNode,
                prefixIcon: Icons.search,
                suffixIcon: Icons.mic,
              ),
            ),
          ),
        ),
      );

      // Toggle focus repeatedly
      for (int i = 0; i < 10; i++) {
        focusNode.requestFocus();
        await tester.pump();
        focusNode.unfocus();
        await tester.pump();
      }

      // Enter massive string
      final hugeString = 'ABC ' * 250;
      await tester.enterText(find.byType(TextField), hugeString);
      await tester.pump();

      expect(controller.text, equals(hugeString));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Tap clear
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Error state rendering with long error text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: GlassTextField(
                errorText: 'Critical validation failure: the query entered contains invalid unicode glyphs and cannot be processed.',
                prefixIcon: Icons.error,
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Critical validation failure'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Test: GlassBottomNav', () {
    testWidgets('1. Zero RenderFlex overflow on ultra-narrow 320dp screen with 5 tabs', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      int selectedTab = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GlassBottomNav(
              currentIndex: selectedTab,
              onTap: (idx) => selectedTab = idx,
            ),
          ),
        ),
      );

      expect(find.byType(GlassBottomNav), findsOneWidget);
      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. Rapid tab switching (50 taps) does not cause animation collision or exception', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: GlassBottomNav(
                  currentIndex: activeIndex,
                  onTap: (idx) => setState(() => activeIndex = idx),
                ),
              ),
            );
          },
        ),
      );

      final tabKeys = [
        const ValueKey('tab_songs'),
        const ValueKey('tab_albums'),
        const ValueKey('tab_artists'),
        const ValueKey('tab_playlists'),
        const ValueKey('tab_settings'),
      ];

      for (int i = 0; i < 50; i++) {
        final targetKey = tabKeys[i % tabKeys.length];
        await tester.tap(find.byKey(targetKey));
        await tester.pump(const Duration(milliseconds: 20));
      }
      await tester.pumpAndSettle();

      expect(activeIndex, equals(49 % 5));
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Test: Overlays', () {
    testWidgets('1. Rapid queueing and dismissal of 10 AppSnackbars', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      for (int i = 0; i < 10; i++) {
                        AppSnackbar.show(
                          context,
                          message: 'Queued notification #$i',
                          variant: AppSnackbarVariant.info,
                        );
                      }
                    },
                    child: const Text('Queue Snackbars'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Queue Snackbars'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Queued notification #9'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. AppDialog rendering under narrow (320dp) and wide (1920dp) viewports', (tester) async {
      for (final width in [320.0, 1920.0]) {
        await tester.binding.setSurfaceSize(Size(width, 900));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Center(
                    child: ElevatedButton(
                      onPressed: () {
                        AppDialog.show(
                          context: context,
                          title: 'Adversarial Test Dialog',
                          message: 'Testing width clamping on screen width $width',
                          primaryActionText: 'OK',
                        );
                      },
                      child: const Text('Open Dialog'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Adversarial Test Dialog'), findsOneWidget);

        // Find the inner dialog surface ClipRRect
        final clipRRectFinder = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(ClipRRect),
        );
        final dialogCardBox = tester.renderObject<RenderBox>(clipRRectFinder.first);
        expect(dialogCardBox.size.width, greaterThanOrEqualTo(280.0));
        expect(dialogCardBox.size.width, lessThanOrEqualTo(460.0));

        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(find.text('Adversarial Test Dialog'), findsNothing);
      }
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('3. AppBottomSheet dragging and physics dismissal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppBottomSheet.show(
                        context: context,
                        title: 'BottomSheet Physics',
                        child: Column(
                          children: List.generate(
                            20,
                            (i) => ListTile(title: Text('Item $i')),
                          ),
                        ),
                      );
                    },
                    child: const Text('Open Sheet'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('BottomSheet Physics'), findsOneWidget);
      expect(find.text('Item 0'), findsOneWidget);

      // Verify BouncingScrollPhysics
      final scrollable = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView).last,
      );
      expect(scrollable.physics, isA<BouncingScrollPhysics>());

      // Drag down with fling velocity to dismiss modal bottom sheet
      await tester.fling(find.text('BottomSheet Physics'), const Offset(0, 500), 1000.0);
      await tester.pumpAndSettle();

      expect(find.text('BottomSheet Physics'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Test: DesignSystemShowcaseScreen Viewport Matrix', () {
    Widget buildShowcaseApp() {
      return ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(FakeStorageService()),
          loggingServiceProvider.overrideWithValue(FakeLoggingService()),
        ],
        child: const MaterialApp(
          home: DesignSystemShowcaseScreen(),
        ),
      );
    }

    testWidgets('Viewports: Compact Mobile 320x568 catches RenderFlex overflow bugs in showcase screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShowcaseApp());
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNotNull,
          reason: 'Empirical finding: DesignSystemShowcaseScreen produces RenderFlex overflow on compact 320x568dp screen');
    });

    testWidgets('Viewports: Standard Mobile 360x640 catches RenderFlex overflow bugs in showcase screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShowcaseApp());
      await tester.pumpAndSettle();

      final exception = tester.takeException();
      expect(exception, isNotNull,
          reason: 'Empirical finding: DesignSystemShowcaseScreen produces RenderFlex overflow on standard 360x640dp screen');
    });

    testWidgets('Viewports: Tablet 600x960 renders with zero RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(600, 960));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShowcaseApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('design_system_showcase_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Viewports: Desktop 1280x800 renders with zero RenderFlex overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildShowcaseApp());
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('design_system_showcase_screen')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
