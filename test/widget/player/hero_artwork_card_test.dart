import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/presentation/widgets/hero_artwork_card.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  group('HeroArtworkCard Widget Tests', () {
    const testTrack = Track(
      id: 'trk-hero',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      year: 2011,
      genre: 'Synthwave',
      bitrate: 320000,
      filePath: '/storage/Music/Midnight City.mp3',
    );

    testWidgets('renders front artwork with vinyl rings', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: testTrack,
                isPlaying: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(HeroArtworkCard), findsOneWidget);
      expect(find.text('TECHNICAL DETAILS'), findsNothing);
    });

    testWidgets('long press triggers 3D flip revealing technical metadata card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: testTrack,
                isPlaying: false,
              ),
            ),
          ),
        ),
      );

      final heroFinder = find.byType(HeroArtworkCard);
      await tester.longPress(heroFinder);
      await tester.pumpAndSettle();

      expect(find.text('TECHNICAL DETAILS'), findsOneWidget);
      expect(find.text('2011'), findsOneWidget);
      expect(find.text('Synthwave'), findsOneWidget);
      expect(find.text('320 kbps'), findsOneWidget);
      expect(find.text('Tap anywhere to flip back'), findsOneWidget);

      // Tap to flip back
      await tester.tap(heroFinder);
      await tester.pumpAndSettle();
      expect(find.text('TECHNICAL DETAILS'), findsNothing);
    });

    testWidgets('horizontal swipe left triggers onSwipeLeft (skip next)', (tester) async {
      bool swipedLeft = false;
      bool swipedRight = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: testTrack,
                onSwipeLeft: () => swipedLeft = true,
                onSwipeRight: () => swipedRight = true,
              ),
            ),
          ),
        ),
      );

      final heroFinder = find.byType(HeroArtworkCard);
      await tester.drag(heroFinder, const Offset(-120, 0));
      await tester.pump();

      expect(swipedLeft, isTrue);
      expect(swipedRight, isFalse);
    });

    testWidgets('horizontal swipe right triggers onSwipeRight (skip previous)', (tester) async {
      bool swipedLeft = false;
      bool swipedRight = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: testTrack,
                onSwipeLeft: () => swipedLeft = true,
                onSwipeRight: () => swipedRight = true,
              ),
            ),
          ),
        ),
      );

      final heroFinder = find.byType(HeroArtworkCard);
      await tester.drag(heroFinder, const Offset(120, 0));
      await tester.pump();

      expect(swipedRight, isTrue);
      expect(swipedLeft, isFalse);
    });
  });
}
