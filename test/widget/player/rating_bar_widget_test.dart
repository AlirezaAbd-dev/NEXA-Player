import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/presentation/widgets/rating_bar_widget.dart';

void main() {
  group('RatingBarWidget Tests', () {
    testWidgets('renders 5 star icons and initial rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RatingBarWidget(initialRating: 3),
          ),
        ),
      );

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
    });

    testWidgets('tapping on star updates rating and fires callback', (tester) async {
      int? updatedRating;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RatingBarWidget(
              initialRating: 2,
              onRatingChanged: (r) => updatedRating = r,
            ),
          ),
        ),
      );

      final fifthStar = find.byIcon(Icons.star_outline_rounded).last;
      await tester.tap(fifthStar);
      await tester.pump();

      expect(updatedRating, 5);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });
  });
}
