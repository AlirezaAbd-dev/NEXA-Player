import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/album_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/albums_tab_screen.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/album_card.dart';

void main() {
  const testAlbum = Album(
    id: 'alb-1',
    title: 'Random Access Memories',
    artist: 'Daft Punk',
    year: 2013,
    trackCount: 13,
  );

  const testTrack = Track(
    id: 'trk-1',
    title: 'Get Lucky',
    artist: 'Daft Punk',
    album: 'Random Access Memories',
    duration: Duration(minutes: 4, seconds: 8),
    filePath: '/music/get_lucky.flac',
  );

  Widget createSubject({
    required Widget child,
    List<Album> albums = const [testAlbum],
    List<Track> tracks = const [testTrack],
  }) {
    return ProviderScope(
      overrides: [
        albumsListProvider(null).overrideWith((ref) => Future.value(albums)),
        albumDetailTracksProvider(testAlbum.id).overrideWith((ref) => Future.value(tracks)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: child,
      ),
    );
  }

  group('AlbumCard', () {
    testWidgets('renders borderless in grid mode with 1:1 artwork sleeve and metadata', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: Scaffold(
            body: AlbumCard.fromAlbum(
              album: testAlbum,
              mode: AlbumCardMode.grid,
            ),
          ),
        ),
      );

      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('Daft Punk • 2013'), findsOneWidget);
      expect(find.text('13 Tracks'), findsOneWidget);
      expect(find.byIcon(Icons.album), findsOneWidget);
    });

    testWidgets('renders borderless in list mode', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: Scaffold(
            body: AlbumCard.fromAlbum(
              album: testAlbum,
              mode: AlbumCardMode.list,
            ),
          ),
        ),
      );

      expect(find.text('Random Access Memories'), findsOneWidget);
      expect(find.text('Daft Punk • 2013'), findsOneWidget);
      expect(find.text('13 tracks'), findsOneWidget);
    });
  });

  group('AlbumsTabScreen', () {
    testWidgets('renders grid view and supports density toggle', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: const AlbumsTabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.albumsGrid), findsOneWidget);
      expect(find.byKey(Phase2Keys.albumCard(testAlbum.id)), findsOneWidget);

      // Verify density action button exists
      final densityBtn = find.byTooltip('Grid density (2 columns)');
      expect(densityBtn, findsOneWidget);

      // Tap to toggle density
      await tester.tap(densityBtn);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Grid density (3 columns)'), findsOneWidget);
    });
  });

  group('AlbumDetailScreen', () {
    testWidgets('renders hero artwork with ShaderMask dissolve and track list', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: const AlbumDetailScreen(album: testAlbum),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.albumDetailScreen), findsOneWidget);
      expect(find.byKey(Phase2Keys.albumDetailBackButton), findsOneWidget);
      expect(find.byKey(Phase2Keys.albumDetailTrackList), findsOneWidget);
      expect(find.byKey(Phase2Keys.trackTile(testTrack.id)), findsOneWidget);

      // Check ShaderMask dissolve present
      expect(find.byType(ShaderMask), findsWidgets);

      // Check Action buttons
      expect(find.text('Play'), findsOneWidget);
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
    });
  });
}
