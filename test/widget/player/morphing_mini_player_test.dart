import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/app/shell/mini_player_slot.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';

void main() {
  group('Morphing Borderless MiniPlayerSlot Widget Tests', () {
    testWidgets('renders borderless L3 pill with background progress wash (no bottom bar)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
            home: const Scaffold(
              body: MiniPlayerSlot(
                title: 'Instant Crush',
                artist: 'Daft Punk',
                progress: 0.65,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Instant Crush'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);

      // Verify bottom LinearProgressIndicator is completely removed in favor of tonal background wash
      expect(find.byType(LinearProgressIndicator), findsNothing);

      // Verify borderless container
      final container = tester.widget<Container>(
        find.byKey(MiniPlayerKeys.miniPlayerSlot),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull, reason: 'MiniPlayerSlot must be borderless');
      expect(decoration.gradient, isNotNull, reason: 'Must have tonal progress wash gradient');
      expect(decoration.boxShadow, isNotEmpty, reason: 'L3 floating pill must have diffuse shadow');
    });

    testWidgets('horizontal swipe left triggers onNext', (tester) async {
      var nextCalled = false;
      var prevCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
            home: Scaffold(
              body: MiniPlayerSlot(
                title: 'Get Lucky',
                artist: 'Daft Punk',
                onNext: () => nextCalled = true,
                onPrevious: () => prevCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe left by -80px (past threshold -60)
      await tester.drag(find.byKey(MiniPlayerKeys.miniPlayerSlot), const Offset(-80, 0));
      await tester.pumpAndSettle();

      expect(nextCalled, isTrue);
      expect(prevCalled, isFalse);
    });

    testWidgets('horizontal swipe right triggers onPrevious', (tester) async {
      var nextCalled = false;
      var prevCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
            home: Scaffold(
              body: MiniPlayerSlot(
                title: 'Get Lucky',
                artist: 'Daft Punk',
                onNext: () => nextCalled = true,
                onPrevious: () => prevCalled = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe right by 80px (past threshold 60)
      await tester.drag(find.byKey(MiniPlayerKeys.miniPlayerSlot), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(prevCalled, isTrue);
      expect(nextCalled, isFalse);
    });

    testWidgets('vertical drag upward triggers onTap / expansion', (tester) async {
      var expanded = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
            home: Scaffold(
              body: MiniPlayerSlot(
                title: 'Get Lucky',
                artist: 'Daft Punk',
                onTap: () => expanded = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Drag upward by -70px (past threshold -50)
      await tester.drag(find.byKey(MiniPlayerKeys.miniPlayerSlot), const Offset(0, -70));
      await tester.pumpAndSettle();

      expect(expanded, isTrue);
    });

    testWidgets('renders cleanly at compact 360dp width with zero overflows', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
            home: const Scaffold(
              body: MiniPlayerSlot(
                title: 'Extremely Long Track Title That Might Cause RenderFlex Overflow On Narrow Screens',
                artist: 'Extremely Long Artist Name feat. Guest Star And Philharmonic Orchestra',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure no exceptions or overflows occurred
      expect(tester.takeException(), isNull);
      expect(find.byKey(MiniPlayerKeys.miniPlayerSlot), findsOneWidget);
    });
  });
}
