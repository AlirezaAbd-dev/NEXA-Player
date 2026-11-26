import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/presentation/widgets/hero_artwork_card.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  const track = Track(
    id: 'trk-layout',
    title: 'Layout Test Track',
    artist: 'Test Artist',
    album: 'Test Album',
    duration: Duration(minutes: 3),
  );

  testWidgets(
    'HeroArtworkCard renders distinct Standard, Vinyl, and Full-Art layouts',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: track,
                layoutMode: NowPlayingLayoutMode.standard,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('hero_artwork_standard')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_artwork_vinyl_disc')), findsNothing);
      expect(find.byKey(const ValueKey('hero_artwork_full_art')), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: track,
                layoutMode: NowPlayingLayoutMode.vinyl,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('hero_artwork_vinyl_disc')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_artwork_standard')), findsNothing);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroArtworkCard(
                track: track,
                layoutMode: NowPlayingLayoutMode.art,
              ),
            ),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('hero_artwork_full_art')), findsOneWidget);
      expect(find.byKey(const ValueKey('hero_artwork_vinyl_disc')), findsNothing);
    },
  );
}
