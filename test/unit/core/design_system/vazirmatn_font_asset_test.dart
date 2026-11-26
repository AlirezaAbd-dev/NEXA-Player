import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

void main() {
  test('Vazirmatn font files exist in assets/fonts and are declared in pubspec.yaml', () {
    const expectedAssets = [
      'assets/fonts/Vazirmatn-Regular.ttf',
      'assets/fonts/Vazirmatn-Medium.ttf',
      'assets/fonts/Vazirmatn-Bold.ttf',
      'assets/fonts/Vazirmatn-ExtraBold.ttf',
    ];
    for (final path in expectedAssets) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing font asset: $path');
      expect(file.lengthSync(), greaterThan(50000));
    }

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('family: Vazirmatn'));
    for (final path in expectedAssets) {
      expect(pubspec, contains(path));
    }
    expect(AppTypography.persianFontFallback.first, equals('Vazirmatn'));
  });

  testWidgets('BidiText and AppTheme render Persian text with Vazirmatn font family',
      (tester) async {
    final theme = AppTheme.dark(fontFamily: 'Vazirmatn');
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: BidiText(
              'پخش‌کننده موسیقی نکسـا',
              style: AppTypography.titleLarge,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('پخش‌کننده موسیقی نکسـا'), findsOneWidget);
    final textWidget = tester.widget<Text>(find.text('پخش‌کننده موسیقی نکسـا'));
    expect(textWidget.style?.fontFamilyFallback, contains('Vazirmatn'));
  });
}
