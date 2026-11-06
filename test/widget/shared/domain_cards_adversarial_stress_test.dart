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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Adversarial Stress Test 1: Long Titles, Multiline Strings & Durations', () {
    final extremeLongTitle = 'Extreme Title ' * 50; // 700 chars
    final extremeLongArtist = 'Very Long Artist Name ' * 30; // 660 chars
    final extremeLongAlbum = 'Super Long Album Title ' * 30; // 690 chars
    const multilineTitle = 'Title Line 1\nTitle Line 2\nTitle Line 3\nTitle Line 4';
    const multilineArtist = 'Artist Line 1\nArtist Line 2';

    testWidgets('TrackTile handles extremely long text and multiline strings without RenderFlex overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320.0, // Narrow compact phone width
              child: Column(
                children: [
                  TrackTile(
                    title: extremeLongTitle,
                    artist: extremeLongArtist,
                    album: extremeLongAlbum,
                    duration: const Duration(minutes: 3, seconds: 45),
                  ),
                  const SizedBox(height: 10),
                  const TrackTile(
                    title: multilineTitle,
                    artist: multilineArtist,
                    duration: Duration(minutes: 4, seconds: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify no assertion error or RenderFlex overflow
      expect(tester.takeException(), isNull);

      // Verify both title Text widgets use TextOverflow.ellipsis and maxLines == 1
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      final titleTexts = textWidgets.where((t) => t.data == extremeLongTitle || t.data == multilineTitle);
      for (final t in titleTexts) {
        expect(t.overflow, equals(TextOverflow.ellipsis));
        expect(t.maxLines, equals(1));
      }
    });

    testWidgets('TrackTile formats extreme durations (0:00, 10 hours, negative, null) safely without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300.0,
              child: Column(
                children: [
                  // Zero duration
                  TrackTile(
                    title: 'Zero Duration Track',
                    artist: 'Artist',
                    duration: Duration.zero,
                  ),
                  // 10+ hours duration
                  TrackTile(
                    title: '10 Hour Ambient Track',
                    artist: 'Artist',
                    duration: Duration(hours: 10, minutes: 25, seconds: 40),
                  ),
                  // Negative duration
                  TrackTile(
                    title: 'Negative Duration Track',
                    artist: 'Artist',
                    duration: Duration(seconds: -45),
                  ),
                  // Null duration
                  TrackTile(
                    title: 'Null Duration Track',
                    artist: 'Artist',
                    duration: null,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('0:00'), findsOneWidget);
      expect(find.text('625:40'), findsOneWidget); // 10h 25m = 625 mins
      expect(find.text('-0:45'), findsOneWidget);
    });

    testWidgets('AlbumCard handles extreme titles in both grid and list modes without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320.0,
              child: Column(
                children: [
                  AlbumCard(
                    title: extremeLongTitle,
                    artist: extremeLongArtist,
                    year: 2024,
                    trackCount: 999,
                    mode: AlbumCardMode.grid,
                    width: 140.0,
                  ),
                  const SizedBox(height: 10),
                  AlbumCard(
                    title: extremeLongTitle,
                    artist: extremeLongArtist,
                    year: 2024,
                    trackCount: 999,
                    mode: AlbumCardMode.list,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('ArtistCard handles extreme titles in both grid and list modes without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320.0,
              child: Column(
                children: [
                  ArtistCard(
                    name: extremeLongArtist,
                    trackCount: 99999,
                    albumCount: 9999,
                    mode: ArtistCardMode.list,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: 150.0,
                    child: ArtistCard(
                      name: extremeLongArtist,
                      trackCount: 99999,
                      albumCount: 9999,
                      mode: ArtistCardMode.grid,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('GenreCard handles extreme titles and huge track counts without overflow', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 160.0,
              child: GenreCard(
                title: extremeLongTitle,
                trackCount: 999999,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('999999 Tracks'), findsOneWidget);
    });
  });

  group('Adversarial Stress Test 2: Null & Missing Artwork / Fallback Avatars', () {
    testWidgets('TrackTile correctly displays fallbacks: music icon, track number, and volume up when isPlaying', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                // Fallback 1: null artwork and null trackNumber -> music note icon
                TrackTile(
                  title: 'Default Fallback',
                  artist: 'Artist',
                  artworkUri: null,
                  trackNumber: null,
                ),
                // Fallback 2: null artwork with trackNumber -> track number text
                TrackTile(
                  title: 'Track Number Fallback',
                  artist: 'Artist',
                  artworkUri: null,
                  trackNumber: 7,
                ),
                // Fallback 3: isPlaying true -> volume icon overrides
                TrackTile(
                  title: 'Playing Track',
                  artist: 'Artist',
                  artworkUri: null,
                  trackNumber: 7,
                  isPlaying: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('AlbumCard displays album icon fallback in both grid and list mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                AlbumCard(
                  title: 'Grid Album',
                  artist: 'Artist',
                  artworkUri: null,
                  mode: AlbumCardMode.grid,
                ),
                AlbumCard(
                  title: 'List Album',
                  artist: 'Artist',
                  artworkUri: null,
                  mode: AlbumCardMode.list,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.album), findsNWidgets(2));
    });

    testWidgets('ArtistCard displays person icon avatar fallback in both modes', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ArtistCard(
                  name: 'List Artist',
                  artworkUri: null,
                  mode: ArtistCardMode.list,
                ),
                ArtistCard(
                  name: 'Grid Artist',
                  artworkUri: null,
                  mode: ArtistCardMode.grid,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsNWidgets(2));
      expect(find.byIcon(Icons.person), findsNWidgets(2));
    });

    testWidgets('GenreCard gracefully handles null and empty gradientColors list with deterministic fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                GenreCard(
                  title: 'Rock',
                  gradientColors: null,
                ),
                GenreCard(
                  title: 'Jazz',
                  gradientColors: [],
                ),
                GenreCard(
                  title: 'Electronic',
                  gradientColors: [Colors.purple], // single color: fallback to curated
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Jazz'), findsOneWidget);
      expect(find.text('Electronic'), findsOneWidget);
    });
  });

  group('Adversarial Stress Test 3: AlbumCard Grid Aspect Ratio Scaling & Overflow Analysis', () {
    testWidgets('Empirical Failure: AlbumCard overflows in 2-column grid at documented childAspectRatio: 0.8 on 320dp', (tester) async {
      tester.view.physicalSize = const Size(320.0, 640.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      dynamic caughtException;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.80, // Documented in AlbumCard docstring (childAspectRatio: 0.8)
              ),
              itemCount: 2,
              itemBuilder: (context, index) {
                return AlbumCard(
                  title: 'Album #$index',
                  artist: 'Artist #$index',
                  year: 2024,
                  trackCount: 12,
                  mode: AlbumCardMode.grid,
                );
              },
            ),
          ),
        ),
      );

      caughtException = tester.takeException();
      // Verifies that at the claimed childAspectRatio: 0.8, an overflow occurs
      expect(caughtException, isNotNull);
      expect(caughtException.toString(), contains('A RenderFlex overflowed'));
    });

    testWidgets('Empirical Failure: AlbumCard overflows in 4-column grid at documented childAspectRatio: 0.8 on 800dp tablet', (tester) async {
      tester.view.physicalSize = const Size(800.0, 1000.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      dynamic caughtException;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.80, // Documented in AlbumCard docstring
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return AlbumCard(
                  title: 'Tablet Album #$index',
                  artist: 'Artist #$index',
                  year: 2024,
                  trackCount: 12,
                  mode: AlbumCardMode.grid,
                );
              },
            ),
          ),
        ),
      );

      caughtException = tester.takeException();
      expect(caughtException, isNotNull);
      expect(caughtException.toString(), contains('A RenderFlex overflowed'));
    });

    testWidgets('Empirical Boundary: AlbumCard renders with ZERO overflow when childAspectRatio <= 0.65', (tester) async {
      tester.view.physicalSize = const Size(320.0, 640.0);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
                childAspectRatio: 0.65, // Safe aspect ratio providing enough main-axis height
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                return AlbumCard(
                  title: 'Album #$index',
                  artist: 'Artist #$index',
                  year: 2024,
                  trackCount: 12,
                  mode: AlbumCardMode.grid,
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AlbumCard), findsNWidgets(4));
    });
  });

  group('Adversarial Stress Test 4: Rapid Consecutive Popup Menu Interactions', () {
    testWidgets('TrackTile popup menu handles all actions and rapid interactions', (tester) async {
      final selectedActions = <TrackTileMenuAction>[];
      bool playNextTriggered = false;
      bool addToPlaylistTriggered = false;

      const track = Track(
        id: 'stress-track-1',
        title: 'Stress Test Track',
        artist: 'Tester',
        duration: Duration(minutes: 3),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackTile.fromTrack(
              track: track,
              onMenuActionSelected: (action) => selectedActions.add(action),
              onPlayNext: () => playNextTriggered = true,
              onAddToPlaylist: () => addToPlaylistTriggered = true,
            ),
          ),
        ),
      );

      final moreButton = find.byIcon(Icons.more_vert);

      // 1. Select playNext
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play next'));
      await tester.pumpAndSettle();

      expect(selectedActions.last, equals(TrackTileMenuAction.playNext));
      expect(playNextTriggered, isTrue);

      // 2. Select addToPlaylist
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to playlist'));
      await tester.pumpAndSettle();

      expect(selectedActions.last, equals(TrackTileMenuAction.addToPlaylist));
      expect(addToPlaylistTriggered, isTrue);

      // 3. Select addToQueue
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to queue'));
      await tester.pumpAndSettle();

      expect(selectedActions.last, equals(TrackTileMenuAction.addToQueue));

      // 4. Select goToAlbum
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to album'));
      await tester.pumpAndSettle();

      expect(selectedActions.last, equals(TrackTileMenuAction.goToAlbum));

      // 5. Select goToArtist
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Go to artist'));
      await tester.pumpAndSettle();

      expect(selectedActions.last, equals(TrackTileMenuAction.goToArtist));

      // 6. Select share
      await tester.tap(moreButton);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();

      expect(selectedActions.last, equals(TrackTileMenuAction.share));

      // Verify no exceptions occurred during rapid sequence
      expect(tester.takeException(), isNull);
      expect(selectedActions.length, equals(6));
    });

    testWidgets('TrackTile popup menu does not crash when callbacks are null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackTile(
              title: 'No Callback Track',
              artist: 'Artist',
            ),
          ),
        ),
      );

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play next'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('TrackTile popup menu dismisses safely when tapping barrier', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackTile(
              title: 'Dismiss Test',
              artist: 'Artist',
            ),
          ),
        ),
      );

      final moreButton = find.byIcon(Icons.more_vert);
      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      expect(find.text('Play next'), findsOneWidget);

      // Tap outside menu (at top-left)
      await tester.tapAt(const Offset(10.0, 10.0));
      await tester.pumpAndSettle();

      expect(find.text('Play next'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Adversarial Stress Test 5: RepaintBoundary Encapsulation & Scrolling Performance', () {
    testWidgets('Every domain card widget has RepaintBoundary as root boundary', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: const [
                  TrackTile(title: 'T1', artist: 'A1'),
                  AlbumCard(title: 'Alb1', artist: 'Art1', mode: AlbumCardMode.grid),
                  AlbumCard(title: 'Alb2', artist: 'Art2', mode: AlbumCardMode.list),
                  ArtistCard(name: 'Art1', mode: ArtistCardMode.list),
                  ArtistCard(name: 'Art2', mode: ArtistCardMode.grid),
                  GenreCard(title: 'Gen1'),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify TrackTile has RepaintBoundary
      expect(
        find.descendant(of: find.byType(TrackTile), matching: find.byType(RepaintBoundary)),
        findsOneWidget,
      );

      // Verify AlbumCard has RepaintBoundary
      expect(
        find.descendant(of: find.byType(AlbumCard), matching: find.byType(RepaintBoundary)),
        findsNWidgets(2),
      );

      // Verify ArtistCard has RepaintBoundary
      expect(
        find.descendant(of: find.byType(ArtistCard), matching: find.byType(RepaintBoundary)),
        findsNWidgets(2),
      );

      // Verify GenreCard has RepaintBoundary
      expect(
        find.descendant(of: find.byType(GenreCard), matching: find.byType(RepaintBoundary)),
        findsOneWidget,
      );
    });

    testWidgets('ListView of 50 TrackTiles scrolls smoothly without exception or boundary leak', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 50,
              itemBuilder: (context, index) {
                return TrackTile(
                  title: 'Track #$index',
                  artist: 'Artist #$index',
                  duration: Duration(seconds: 120 + index),
                );
              },
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);

      // Fling scroll down
      await tester.fling(find.byType(ListView), const Offset(0.0, -500.0), 1000.0);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Fling scroll up
      await tester.fling(find.byType(ListView), const Offset(0.0, 500.0), 1000.0);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
