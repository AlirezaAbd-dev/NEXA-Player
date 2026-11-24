import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/artists_tab_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/folders_tab_screen.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/artist_card.dart';

void main() {
  const testArtist = Artist(
    id: 'art-1',
    name: 'Daft Punk',
    trackCount: 13,
    albumCount: 2,
  );

  const testTrack = Track(
    id: 'trk-1',
    title: 'One More Time',
    artist: 'Daft Punk',
    album: 'Discovery',
    duration: Duration(minutes: 5, seconds: 20),
    filePath: '/music/one_more_time.flac',
  );

  const testFolder = FolderNode(
    name: 'Electronic',
    path: '/music/Electronic',
    files: [
      FileNode(name: 'one_more_time.flac', path: '/music/Electronic/one_more_time.flac'),
    ],
    subFolders: [],
  );

  Widget createSubject({
    required Widget child,
    List<Artist> artists = const [testArtist],
    List<Track> tracks = const [testTrack],
    List<FolderNode> folders = const [testFolder],
  }) {
    return ProviderScope(
      overrides: [
        artistsListProvider(null).overrideWith((ref) => Future.value(artists)),
        artistDetailTracksProvider(testArtist.id).overrideWith((ref) => Future.value(tracks)),
        foldersTreeProvider(const []).overrideWith((ref) => Future.value(folders)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: child,
      ),
    );
  }

  group('ArtistCard', () {
    testWidgets('renders borderless in list mode', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: Scaffold(
            body: ArtistCard.fromArtist(
              artist: testArtist,
              mode: ArtistCardMode.list,
            ),
          ),
        ),
      );

      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('13 Tracks • 2 Albums'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('renders borderless in grid mode', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: Scaffold(
            body: ArtistCard.fromArtist(
              artist: testArtist,
              mode: ArtistCardMode.grid,
            ),
          ),
        ),
      );

      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('13 Tracks • 2 Albums'), findsOneWidget);
    });
  });

  group('ArtistsTabScreen & ArtistDetailScreen', () {
    testWidgets('navigates from artists tab to detail screen with ShaderMask and actions', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: const ArtistsTabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.artistsList), findsOneWidget);
      expect(find.byKey(Phase2Keys.artistCard(testArtist.id)), findsOneWidget);

      // Tap artist card to drill down
      await tester.tap(find.byKey(Phase2Keys.artistCard(testArtist.id)));
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.artistDetailScreen), findsOneWidget);
      expect(find.byKey(Phase2Keys.artistDetailBackButton), findsOneWidget);
      expect(find.byKey(Phase2Keys.artistDetailTrackList), findsOneWidget);
      expect(find.byKey(Phase2Keys.trackTile(testTrack.id)), findsOneWidget);

      expect(find.byType(ShaderMask), findsWidgets);
      expect(find.text('Play Top'), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });
  });

  group('FoldersTabScreen', () {
    testWidgets('renders folder nodes and file nodes with metadata tags', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: const FoldersTabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.foldersTreeView), findsOneWidget);
      expect(find.byKey(Phase2Keys.folderNode(testFolder.path)), findsOneWidget);
      expect(find.text('Electronic'), findsOneWidget);
      expect(find.byKey(Phase2Keys.fileNode(testFolder.files.first.path)), findsNothing);

      // Tap folder to enter and see tracks + FLAC extension tag
      await tester.tap(find.byKey(Phase2Keys.folderNode(testFolder.path)));
      await tester.pumpAndSettle();
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.byKey(Phase2Keys.fileNode(testFolder.files.first.path)), findsOneWidget);
    });
  });
}
