import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/extensions/build_context_x.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('BuildContextX Responsive Breakpoints', () {
    testWidgets('identifies phone portrait (<600dp)', (tester) async {
      tester.setPhonePortrait(); // 390x844
      late bool isPhone;
      late bool isTablet;
      late bool isDesktop;

      await tester.pumpApp(
        Builder(builder: (context) {
          isPhone = context.isPhone;
          isTablet = context.isTablet;
          isDesktop = context.isDesktop;
          return const SizedBox();
        }),
      );

      expect(isPhone, isTrue);
      expect(isTablet, isFalse);
      expect(isDesktop, isFalse);
    });

    testWidgets('identifies tablet (600–840dp)', (tester) async {
      tester.setDisplaySize(const Size(768, 1024)); // 768dp width
      late bool isPhone;
      late bool isTablet;
      late bool isDesktop;

      await tester.pumpApp(
        Builder(builder: (context) {
          isPhone = context.isPhone;
          isTablet = context.isTablet;
          isDesktop = context.isDesktop;
          return const SizedBox();
        }),
      );

      expect(isPhone, isFalse);
      expect(isTablet, isTrue);
      expect(isDesktop, isFalse);
    });

    testWidgets('identifies desktop (>840dp)', (tester) async {
      tester.setDesktop(); // 1440x900
      late bool isPhone;
      late bool isTablet;
      late bool isDesktop;

      await tester.pumpApp(
        Builder(builder: (context) {
          isPhone = context.isPhone;
          isTablet = context.isTablet;
          isDesktop = context.isDesktop;
          return const SizedBox();
        }),
      );

      expect(isPhone, isFalse);
      expect(isTablet, isFalse);
      expect(isDesktop, isTrue);
    });

    testWidgets('provides theme and media query helpers', (tester) async {
      await tester.pumpApp(
        Builder(builder: (context) {
          expect(context.theme, isNotNull);
          expect(context.colorScheme, isNotNull);
          expect(context.textTheme, isNotNull);
          expect(context.isDarkMode, isTrue);
          expect(context.screenWidth, greaterThan(0));
          expect(context.screenHeight, greaterThan(0));
          return const SizedBox();
        }),
      );
    });
  });
}
