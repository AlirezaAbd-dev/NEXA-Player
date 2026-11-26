import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';
import 'package:nexa_player/shared/widgets/typography/marquee_text.dart';

void main() {
  testWidgets('MarqueeText renders static BidiText when text fits within width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: MarqueeText('Short Title'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BidiText), findsOneWidget);
    expect(find.text('Short Title'), findsOneWidget);
  });

  testWidgets('MarqueeText scrolls horizontally when text overflows in LTR and RTL', (tester) async {
    const longTitle =
        'A Very Long Symphonic Track Title That Definitely Overflows The Narrow Viewport Width';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 160,
            child: MarqueeText(
              longTitle,
              pauseDuration: Duration(milliseconds: 100),
              velocity: 120.0,
            ),
          ),
        ),
      ),
    );

    // Wait for postFrameCallback + initial pause, then advance animation frames
    await tester.pump();
    final initialLeft = tester.getTopLeft(find.text(longTitle).first).dx;
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    final scrolledLeft = tester.getTopLeft(find.text(longTitle).first).dx;

    expect(scrolledLeft, lessThan(initialLeft));

    // Verify RTL Persian title scrolls cleanly in the opposite direction
    const longPersian =
        'یک عنوان بسیار طولانی فارسی برای آزمایش حرکت افقی متن در حالت راست به چپ';
    await tester.pumpWidget(
      const MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: SizedBox(
              width: 160,
              child: MarqueeText(
                longPersian,
                pauseDuration: Duration(milliseconds: 100),
                velocity: 120.0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final rtlInitialRight = tester.getTopRight(find.text(longPersian).first).dx;
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 300));
    final rtlScrolledRight = tester.getTopRight(find.text(longPersian).first).dx;

    expect(rtlScrolledRight, greaterThan(rtlInitialRight));
  });
}
