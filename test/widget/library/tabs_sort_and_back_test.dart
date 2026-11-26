import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/library/domain/repositories/albums_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/artists_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/albums_tab_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/artists_tab_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/folders_tab_screen.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlists_tab_screen.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/widgets/lists/active_track_auto_scroller.dart';

void main() {
  testWidgets('ActiveTrackAutoScrollScope defaults bottomChipPadding to 12.0',
      (tester) async {
    const scope = ActiveTrackAutoScrollScope(
      trackIds: ['t1', 't2'],
      activeTrackId: 't1',
      builder: _emptyBuilder,
    );
    expect(scope.bottomChipPadding, 12.0);
  });

  testWidgets('FoldersTabScreen intercepts system back inside GoRouter',
      (tester) async {
    const folders = [
      FolderNode(
        path: '/music/Rock',
        name: 'Rock',
        subFolders: [
          FolderNode(
            path: '/music/Rock/Live',
            name: 'Live',
            files: [
              FileNode(
                path: '/music/Rock/Live/track.mp3',
                name: 'track.mp3',
                trackId: 't1',
              ),
            ],
          ),
        ],
      ),
    ];

    final router = GoRouter(
      initialLocation: '/folders',
      routes: [
        GoRoute(
          path: '/folders',
          builder: (_, __) => const FoldersTabScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersTreeProvider(const []).overrideWith((ref) => Future.value(folders)),
        ],
        child: MaterialApp.router(
          theme: AppTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap into Rock folder
    await tester.tap(find.byKey(Phase2Keys.folderNode('/music/Rock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('folder_navigate_up_btn')), findsOneWidget);

    // Simulate Android system Back via RootBackButtonDispatcher
    final handled = await router.routerDelegate.popRoute();
    await tester.pumpAndSettle();

    expect(handled, isTrue);
    expect(find.byKey(Phase2Keys.foldersTreeView), findsOneWidget);
    expect(find.byKey(const ValueKey('folder_navigate_up_btn')), findsNothing);
  });

  testWidgets('AlbumsTabScreen exposes Asc/Desc sort menu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final albumsAsc = [
      const Album(id: 'a1', title: 'Alpha', artist: 'Zed', year: 2020, trackCount: 5),
      const Album(id: 'a2', title: 'Beta', artist: 'Amy', year: 2022, trackCount: 8),
    ];
    final albumsDesc = albumsAsc.reversed.toList();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          albumsListProvider(null).overrideWith((ref) => Future.value(albumsAsc)),
          albumsListProvider(
            const AlbumQueryParams(sortBy: AlbumSortBy.title, ascending: false),
          ).overrideWith((ref) => Future.value(albumsDesc)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const AlbumsTabScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('albums_sort_btn')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('albums_sort_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Title'));
    await tester.pumpAndSettle();

    final firstLeft = tester.getTopLeft(find.text('Beta')).dx;
    final secondLeft = tester.getTopLeft(find.text('Alpha')).dx;
    expect(firstLeft, lessThan(secondLeft));
  });

  testWidgets('ArtistsTabScreen exposes Asc/Desc sort menu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const artistsAsc = [
      Artist(id: 'ar1', name: 'Adele', trackCount: 2, albumCount: 1),
      Artist(id: 'ar2', name: 'Zed', trackCount: 10, albumCount: 2),
    ];
    const artistsDesc = [
      Artist(id: 'ar2', name: 'Zed', trackCount: 10, albumCount: 2),
      Artist(id: 'ar1', name: 'Adele', trackCount: 2, albumCount: 1),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          artistsListProvider(null).overrideWith((ref) => Future.value(artistsAsc)),
          artistsListProvider(
            const ArtistQueryParams(sortBy: ArtistSortBy.name, ascending: false),
          ).overrideWith((ref) => Future.value(artistsDesc)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const ArtistsTabScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('artists_sort_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Zed')).dy,
      lessThan(tester.getTopLeft(find.text('Adele')).dy),
    );
  });

  testWidgets('PlaylistsTabScreen exposes Asc/Desc sort menu', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime(2025, 1, 1);
    final playlists = [
      Playlist(id: 'p1', name: 'Alpha', createdAt: now, updatedAt: now, trackCount: 1),
      Playlist(id: 'p2', name: 'Zeta', createdAt: now, updatedAt: now, trackCount: 9),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playlistsListNotifierProvider.overrideWith(
            () => _FakePlaylistsNotifier(playlists),
          ),
          smartPlaylistsProvider.overrideWithValue(const []),
          smartPlaylistTracksProvider(SmartPlaylistType.favorites)
              .overrideWith((ref) => Future.value(const [])),
        ],
        child: MaterialApp(
          theme: AppTheme.dark(),
          home: const PlaylistsTabScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('playlists_sort_btn')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Zeta')).dy,
      lessThan(tester.getTopLeft(find.text('Alpha')).dy),
    );
  });
}

class _FakePlaylistsNotifier extends PlaylistsNotifier {
  _FakePlaylistsNotifier(this._items);
  final List<Playlist> _items;

  @override
  Future<List<Playlist>> build() async => _items;
}

Widget _emptyBuilder(BuildContext context, ScrollController controller) {
  return ListView(controller: controller);
}
