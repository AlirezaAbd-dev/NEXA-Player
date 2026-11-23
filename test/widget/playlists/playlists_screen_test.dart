import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlists_tab_screen.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

class _FakePlaylistsNotifier extends PlaylistsNotifier {
  _FakePlaylistsNotifier(this._initial);
  final List<Playlist> _initial;

  @override
  Future<List<Playlist>> build() async => _initial;
}

void main() {
  final testPlaylist = Playlist(
    id: 'pl-1',
    name: 'Synthwave Night',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    trackCount: 5,
  );

  const testTrack = Track(
    id: 'trk-1',
    title: 'Resonance',
    artist: 'HOME',
    album: 'Odyssey',
    duration: Duration(minutes: 3, seconds: 32),
    filePath: '/music/resonance.flac',
  );

  Widget createSubject({
    required Widget child,
    List<Playlist> playlists = const [],
    List<Track> tracks = const [testTrack],
  }) {
    return ProviderScope(
      overrides: [
        playlistsListNotifierProvider.overrideWith(() => _FakePlaylistsNotifier(playlists)),
        playlistTracksProvider(testPlaylist.id).overrideWith((ref) => Future.value(tracks)),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: child,
      ),
    );
  }

  group('PlaylistsTabScreen', () {
    testWidgets('renders smart playlists and user playlists', (tester) async {
      await tester.pumpWidget(
        createSubject(
          playlists: [testPlaylist],
          child: const PlaylistsTabScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SMART PLAYLISTS'), findsOneWidget);
      expect(find.text('MY PLAYLISTS'), findsOneWidget);
      expect(find.byKey(Phase2Keys.playlistsList), findsOneWidget);
      expect(find.byKey(Phase2Keys.playlistItem(testPlaylist.id)), findsOneWidget);
      expect(find.byKey(Phase2Keys.createPlaylistFab), findsOneWidget);

      // Verify FAB opens create playlist dialog
      await tester.tap(find.byKey(Phase2Keys.createPlaylistFab));
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.createPlaylistDialog), findsOneWidget);
      expect(find.byKey(Phase2Keys.playlistNameInput), findsOneWidget);
      expect(find.byKey(Phase2Keys.playlistConfirmCreate), findsOneWidget);
    });
  });

  group('PlaylistDetailScreen', () {
    testWidgets('renders borderless header, play all, shuffle and track items', (tester) async {
      await tester.pumpWidget(
        createSubject(
          child: PlaylistDetailScreen(playlist: testPlaylist),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Synthwave Night'), findsWidgets);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.text('Resonance'), findsOneWidget);
    });
  });
}
