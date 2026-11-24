import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/shared/widgets/inputs/nexa_search_bar.dart';

void main() {
  testWidgets(
    'NexaSearchBar preserves borderless rounded clipping, updates NexaSurfaceTokens.l1 & contrast, and prevents inner rectangle overflow on live theme switch',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(() {
        controller.dispose();
        focusNode.dispose();
      });

      final activeTheme = ValueNotifier<ThemeData>(
        AppTheme.buildTheme(
          preset: ThemePreset.midnightBlack,
          mode: ThemeMode.dark,
        ),
      );
      addTearDown(activeTheme.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeData>(
          valueListenable: activeTheme,
          builder: (context, theme, _) => MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    NexaSearchBar(
                      controller: controller,
                      focusNode: focusNode,
                      hintText: 'Search songs, artists...',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      void assertSearchBarIntact(ThemeData expectedTheme) {
        expect(tester.takeException(), isNull);

        // Must wrap inside ClipRRect to guarantee children cannot bleed past radius
        expect(find.byType(ClipRRect), findsWidgets);

        final textField = tester.widget<TextField>(find.byType(TextField));
        final dec = textField.decoration!;
        // Explicitly disables Material's filled inner rectangle & outline borders
        expect(dec.filled, isFalse);
        expect(dec.border, equals(InputBorder.none));
        expect(dec.enabledBorder, equals(InputBorder.none));
        expect(dec.focusedBorder, equals(InputBorder.none));
        expect(dec.disabledBorder, equals(InputBorder.none));

        // Ensure text style stays bound to live theme onSurface
        expect(
          textField.style?.color,
          equals(expectedTheme.colorScheme.onSurface),
        );

        // Ensure AnimatedContainer matches active theme L1 surface token
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer),
        );
        final decoration = container.decoration as BoxDecoration;
        final expectedL1 =
            expectedTheme.extension<NexaSurfaceTokens>()!.level1;
        if (focusNode.hasFocus) {
          expect(
            decoration.color,
            equals(
              Color.alphaBlend(
                expectedTheme.colorScheme.primary.withOpacity(0.06),
                expectedL1,
              ),
            ),
          );
        } else {
          expect(decoration.color, equals(expectedL1));
        }

        // Verify TextField rect stays strictly inside NexaSearchBar outer rect
        final outerRect = tester.getRect(find.byType(NexaSearchBar));
        final inputRect = tester.getRect(find.byType(TextField));
        expect(inputRect.left, greaterThanOrEqualTo(outerRect.left));
        expect(inputRect.right, lessThanOrEqualTo(outerRect.right));
        expect(inputRect.top, greaterThanOrEqualTo(outerRect.top));
        expect(inputRect.bottom, lessThanOrEqualTo(outerRect.bottom));
      }

      // 1. Unfocused & Focused under Midnight Black (OLED)
      assertSearchBarIntact(activeTheme.value);
      await tester.tap(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'شجریان');
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      assertSearchBarIntact(activeTheme.value);

      // 2. Switch dynamically while FOCUSED to Daylight (Light mode)
      activeTheme.value = AppTheme.buildTheme(
        preset: ThemePreset.daylight,
        mode: ThemeMode.light,
      );
      await tester.pumpAndSettle();
      assertSearchBarIntact(activeTheme.value);

      // 3. Switch dynamically while FOCUSED to Sakura
      activeTheme.value = AppTheme.buildTheme(
        preset: ThemePreset.sakura,
        mode: ThemeMode.light,
      );
      await tester.pumpAndSettle();
      assertSearchBarIntact(activeTheme.value);

      // 4. Switch dynamically to Custom HSL dark theme
      activeTheme.value = AppTheme.buildTheme(
        preset: ThemePreset.custom,
        mode: ThemeMode.dark,
        customPrimary: const Color(0xFFFF6B6B),
      );
      await tester.pumpAndSettle();
      assertSearchBarIntact(activeTheme.value);

      // 5. Unfocus and re-check
      focusNode.unfocus();
      await tester.pumpAndSettle();
      assertSearchBarIntact(activeTheme.value);
    },
  );
}
