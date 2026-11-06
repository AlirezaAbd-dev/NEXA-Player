import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/album_card.dart';
import 'package:nexa_player/shared/widgets/cards/artist_card.dart';
import 'package:nexa_player/shared/widgets/cards/genre_card.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';

void main() {
  group('TrackTile Widget Tests', () {
    const testTrack = Track(
      id: 'track-101',
      title: 'Glass Reflection',
      artist: 'Aura',
      album: 'Prism',
      duration: Duration(minutes: 3, seconds: 45),
      trackNumber: 3,
      isFavorite: true,
    );

    testWidgets('renders track title, artist, album, duration, and RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackTile(
              title: 'Midnight Echo',
              artist: 'Neon Wave',
              album: 'Synthetic Dreams',
              duration: Duration(minutes: 4, seconds: 12),
            ),
          ),
        ),
      );

      expect(find.text('Midnight Echo'), findsOneWidget);
      expect(find.textContaining('Neon Wave'), findsOneWidget);
      expect(find.textContaining('Synthetic Dreams'), findsOneWidget);
      expect(find.text('4:12'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('constructs correctly from Track domain entity via TrackTile.fromTrack', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackTile.fromTrack(track: testTrack),
          ),
        ),
      );

      expect(find.text('Glass Reflection'), findsOneWidget);
      expect(find.textContaining('Aura'), findsOneWidget);
      expect(find.textContaining('Prism'), findsOneWidget);
      expect(find.text('3:45'), findsOneWidget);
    });

    testWidgets('triggers onTap and onLongPress callbacks', (tester) async {
      bool tapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackTile(
              title: 'Echoes',
              artist: 'Pink Floyd',
              onTap: () => tapped = true,
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Echoes'));
      await tester.pump();
      expect(tapped, isTrue);

      await tester.longPress(find.text('Echoes'));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('more button opens popup menu and triggers action selection', (tester) async {
      TrackTileMenuAction? selectedAction;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackTile.fromTrack(
              track: testTrack,
              onMenuActionSelected: (action) => selectedAction = action,
            ),
          ),
        ),
      );

      final moreButton = find.byIcon(Icons.more_vert);
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Popup menu items should now be visible
      expect(find.text('Play next'), findsOneWidget);
      expect(find.text('Add to queue'), findsOneWidget);

      await tester.tap(find.text('Play next'));
      await tester.pumpAndSettle();

      expect(selectedAction, equals(TrackTileMenuAction.playNext));
    });

    testWidgets('triggers custom onMorePressed callback when provided', (tester) async {
      bool morePressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackTile(
              title: 'Track',
              artist: 'Artist',
              onMorePressed: () => morePressed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      expect(morePressed, isTrue);
    });
  });

  group('AlbumCard Widget Tests', () {
    const testAlbum = Album(
      id: 'alb-202',
      title: 'Currents',
      artist: 'Tame Impala',
      year: 2015,
      trackCount: 13,
    );

    testWidgets('renders grid mode with title, artist, year, track count, and RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AlbumCard(
              title: 'Random Access Memories',
              artist: 'Daft Punk',
              year: 2013,
              trackCount: 13,
              mode: AlbumCardMode.grid,
            ),
          ),
        ),
      );

      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('Daft Punk • 2013'), findsOneWidget);
      expect(find.text('13 Tracks'), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders list mode with AlbumCard.fromAlbum', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumCard.fromAlbum(
              album: testAlbum,
              mode: AlbumCardMode.list,
            ),
          ),
        ),
      );

      expect(find.text('Currents'), findsOneWidget);
      expect(find.text('Tame Impala • 2015'), findsOneWidget);
    });

    testWidgets('triggers onTap and onPlayTap callbacks in list mode', (tester) async {
      bool tapped = false;
      bool playTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AlbumCard.fromAlbum(
              album: testAlbum,
              mode: AlbumCardMode.list,
              onTap: () => tapped = true,
              onPlayTap: () => playTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Currents'));
      await tester.pump();
      expect(tapped, isTrue);

      final playButton = find.byIcon(Icons.play_circle_filled_rounded);
      expect(playButton, findsOneWidget);
      await tester.tap(playButton);
      await tester.pump();
      expect(playTapped, isTrue);
    });
  });

  group('ArtistCard Widget Tests', () {
    const testArtist = Artist(
      id: 'art-303',
      name: 'Radiohead',
      trackCount: 85,
      albumCount: 9,
    );

    testWidgets('renders list mode with circular avatar, name, counts, and RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ArtistCard(
              name: 'Pink Floyd',
              trackCount: 120,
              albumCount: 15,
              mode: ArtistCardMode.list,
            ),
          ),
        ),
      );

      expect(find.text('Pink Floyd'), findsOneWidget);
      expect(find.text('120 Tracks • 15 Albums'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('renders grid mode with ArtistCard.fromArtist', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ArtistCard.fromArtist(
              artist: testArtist,
              mode: ArtistCardMode.grid,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Radiohead'), findsOneWidget);
      expect(find.text('85 Tracks • 9 Albums'), findsOneWidget);

      await tester.tap(find.text('Radiohead'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  group('GenreCard Widget Tests', () {
    const testGenre = Genre(
      id: 'gen-404',
      name: 'Synthwave',
      trackCount: 42,
      gradientColors: [Color(0xFF8A2387), Color(0xFFE94057)],
    );

    testWidgets('renders title, track count badge, musical watermark, and RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: GenreCard(
              title: 'Lo-Fi Chill',
              trackCount: 30,
              icon: Icons.headphones_rounded,
            ),
          ),
        ),
      );

      expect(find.text('Lo-Fi Chill'), findsOneWidget);
      expect(find.text('30 Tracks'), findsOneWidget);
      expect(find.byIcon(Icons.headphones_rounded), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);
    });

    testWidgets('constructs via GenreCard.fromGenre and triggers onTap', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GenreCard.fromGenre(
              genre: testGenre,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Synthwave'), findsOneWidget);
      expect(find.text('42 Tracks'), findsOneWidget);

      await tester.tap(find.text('Synthwave'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
