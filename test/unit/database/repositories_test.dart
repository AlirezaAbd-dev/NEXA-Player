import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_albums_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_artists_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_folders_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_genres_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_tracks_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_playlists_repository.dart';
import 'package:nexa_player/features/scanner/data/repositories/sqlite_scan_directories_repository.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

void main() {
  group('SQLite Repositories Unit Tests', () {
    late IAppDatabase db;
    late SqliteTracksRepository tracksRepo;
    late SqliteAlbumsRepository albumsRepo;
    late SqliteArtistsRepository artistsRepo;
    late SqliteGenresRepository genresRepo;
    late SqlitePlaylistsRepository playlistsRepo;
    late SqliteScanDirectoriesRepository scanDirsRepo;
    late SqliteFoldersRepository foldersRepo;

    setUp(() {
      db = AppDatabase.inMemory();
      tracksRepo = SqliteTracksRepository(db);
      albumsRepo = SqliteAlbumsRepository(db);
      artistsRepo = SqliteArtistsRepository(db);
      genresRepo = SqliteGenresRepository(db);
      playlistsRepo = SqlitePlaylistsRepository(db);
      scanDirsRepo = SqliteScanDirectoriesRepository(db);
      foldersRepo = SqliteFoldersRepository(db);
    });

    tearDown(() {
      db.close();
    });

    group('SqliteTracksRepository', () {
      test('inserts, retrieves, sorts, and filters tracks correctly', () async {
        final t1 = Track(
          id: 'trk-1',
          title: 'Comfortably Numb',
          artist: 'Pink Floyd',
          album: 'The Wall',
          duration: const Duration(seconds: 382),
          filePath: '/music/pink_floyd/comfortably_numb.mp3',
          trackNumber: 6,
          dateAdded: DateTime.fromMillisecondsSinceEpoch(1000),
        );

        final t2 = Track(
          id: 'trk-2',
          title: 'Another Brick in the Wall',
          artist: 'Pink Floyd',
          album: 'The Wall',
          duration: const Duration(seconds: 239),
          filePath: '/music/pink_floyd/brick.mp3',
          trackNumber: 3,
          dateAdded: DateTime.fromMillisecondsSinceEpoch(2000),
        );

        final t3 = Track(
          id: 'trk-3',
          title: 'Time',
          artist: 'Pink Floyd',
          album: 'Dark Side of the Moon',
          duration: const Duration(seconds: 425),
          filePath: '/music/pink_floyd/time.mp3',
          trackNumber: 4,
          dateAdded: DateTime.fromMillisecondsSinceEpoch(3000),
        );

        await tracksRepo.insertTracks([t1, t2, t3]);

        // 1. Sort by title ascending
        final byTitle = await tracksRepo.getAllTracks(
          sortBy: TrackSortBy.title,
          ascending: true,
        );
        expect(byTitle.isSuccess, isTrue);
        final listTitle = byTitle.valueOrNull!;
        expect(listTitle.length, equals(3));
        expect(listTitle[0].title, equals('Another Brick in the Wall'));
        expect(listTitle[1].title, equals('Comfortably Numb'));
        expect(listTitle[2].title, equals('Time'));

        // 2. Sort by duration descending
        final byDur = await tracksRepo.getAllTracks(
          sortBy: TrackSortBy.duration,
          ascending: false,
        );
        final listDur = byDur.valueOrNull!;
        expect(listDur[0].title, equals('Time')); // 425s
        expect(listDur[1].title, equals('Comfortably Numb')); // 382s
        expect(listDur[2].title, equals('Another Brick in the Wall')); // 239s

        // 3. Search query
        final searched = await tracksRepo.getAllTracks(searchQuery: 'brick');
        expect(searched.valueOrNull!.length, equals(1));
        expect(searched.valueOrNull!.first.id, equals('trk-2'));

        // 4. Toggle favorite
        await tracksRepo.toggleFavorite('trk-1');
        final favTrack = await tracksRepo.getTrackById('trk-1');
        expect(favTrack.valueOrNull!.isFavorite, isTrue);

        await tracksRepo.toggleFavorite('trk-1');
        final unFavTrack = await tracksRepo.getTrackById('trk-1');
        expect(unFavTrack.valueOrNull!.isFavorite, isFalse);

        // 5. Increment play count
        await tracksRepo.incrementPlayCount('trk-1');
        final playedTrack = await tracksRepo.getTrackById('trk-1');
        expect(playedTrack.valueOrNull!.playCount, equals(1));

        // 6. Delete track
        await tracksRepo.deleteTrack('trk-3');
        final remaining = await tracksRepo.getAllTracks();
        expect(remaining.valueOrNull!.length, equals(2));
      });
    });

    group('SqliteAlbumsRepository & SqliteArtistsRepository & SqliteGenresRepository', () {
      test('queries albums, artists, genres and links to tracks', () async {
        db.execute('''
          INSERT INTO artists (id, name, track_count, album_count)
          VALUES ('art-1', 'Radiohead', 2, 1);
        ''');

        db.execute('''
          INSERT INTO albums (id, title, artist, artist_id, year, track_count)
          VALUES ('alb-1', 'OK Computer', 'Radiohead', 'art-1', 1997, 2);
        ''');

        db.execute('''
          INSERT INTO genres (id, name, track_count)
          VALUES ('gen-1', 'Alternative Rock', 2);
        ''');

        const t1 = Track(
          id: 'trk-1',
          title: 'Paranoid Android',
          artist: 'Radiohead',
          album: 'OK Computer',
          duration: Duration(seconds: 387),
          filePath: '/music/ok_computer/02_paranoid_android.mp3',
          artistId: 'art-1',
          albumId: 'alb-1',
          genreId: 'gen-1',
          genre: 'Alternative Rock',
        );

        const t2 = Track(
          id: 'trk-2',
          title: 'Karma Police',
          artist: 'Radiohead',
          album: 'OK Computer',
          duration: Duration(seconds: 264),
          filePath: '/music/ok_computer/06_karma_police.mp3',
          artistId: 'art-1',
          albumId: 'alb-1',
          genreId: 'gen-1',
          genre: 'Alternative Rock',
        );

        await tracksRepo.insertTracks([t1, t2]);

        // Album tests
        final albums = await albumsRepo.getAllAlbums();
        expect(albums.valueOrNull!.length, equals(1));
        expect(albums.valueOrNull!.first.title, equals('OK Computer'));

        final albumTracks = await albumsRepo.getTracksForAlbum('alb-1');
        expect(albumTracks.valueOrNull!.length, equals(2));

        // Artist tests
        final artists = await artistsRepo.getAllArtists();
        expect(artists.valueOrNull!.length, equals(1));
        expect(artists.valueOrNull!.first.name, equals('Radiohead'));

        final artistTracks = await artistsRepo.getTracksForArtist('art-1');
        expect(artistTracks.valueOrNull!.length, equals(2));

        // Genre tests
        final genres = await genresRepo.getAllGenres();
        expect(genres.valueOrNull!.length, equals(1));
        expect(genres.valueOrNull!.first.name, equals('Alternative Rock'));

        final genreTracks = await genresRepo.getTracksForGenre('gen-1');
        expect(genreTracks.valueOrNull!.length, equals(2));
      });
    });

    group('SqlitePlaylistsRepository', () {
      test('creates playlist, adds tracks, reorders, and deletes', () async {
        const t1 = Track(
          id: 't-1',
          title: 'Track One',
          artist: 'Artist',
          duration: Duration(seconds: 100),
          filePath: '/t1.mp3',
        );
        const t2 = Track(
          id: 't-2',
          title: 'Track Two',
          artist: 'Artist',
          duration: Duration(seconds: 200),
          filePath: '/t2.mp3',
        );
        await tracksRepo.insertTracks([t1, t2]);

        // 1. Create Playlist
        final createRes = await playlistsRepo.createPlaylist('Road Trip');
        expect(createRes.isSuccess, isTrue);
        final playlist = createRes.valueOrNull!;
        expect(playlist.name, equals('Road Trip'));

        // 2. Add Tracks
        await playlistsRepo.addTrackToPlaylist(playlist.id, 't-1');
        await playlistsRepo.addTrackToPlaylist(playlist.id, 't-2');

        final tracks = await playlistsRepo.getTracksForPlaylist(playlist.id);
        expect(tracks.valueOrNull!.length, equals(2));
        expect(tracks.valueOrNull![0].id, equals('t-1'));
        expect(tracks.valueOrNull![1].id, equals('t-2'));

        // 3. Reorder Tracks
        await playlistsRepo.reorderPlaylistTracks(playlist.id, 0, 1);
        final reordered = await playlistsRepo.getTracksForPlaylist(playlist.id);
        expect(reordered.valueOrNull![0].id, equals('t-2'));
        expect(reordered.valueOrNull![1].id, equals('t-1'));

        // 4. Remove Track
        await playlistsRepo.removeTrackFromPlaylist(playlist.id, 't-1');
        final afterRemoval = await playlistsRepo.getTracksForPlaylist(playlist.id);
        expect(afterRemoval.valueOrNull!.length, equals(1));
        expect(afterRemoval.valueOrNull!.first.id, equals('t-2'));

        // 5. Delete Playlist (cascades cleanly)
        await playlistsRepo.deletePlaylist(playlist.id);
        final playlists = await playlistsRepo.getAllPlaylists();
        expect(playlists.valueOrNull!.isEmpty, isTrue);
      });
    });

    group('SqliteScanDirectoriesRepository', () {
      test('manages scan directories', () async {
        final added = await scanDirsRepo.addDirectory('/storage/music');
        expect(added.isSuccess, isTrue);

        final list = await scanDirsRepo.getDirectories();
        expect(list.valueOrNull!.length, equals(1));
        expect(list.valueOrNull!.first.path, equals('/storage/music'));
        expect(list.valueOrNull!.first.isEnabled, isTrue);

        await scanDirsRepo.toggleActive(added.valueOrNull!.id, false);
        final updated = await scanDirsRepo.getDirectories();
        expect(updated.valueOrNull!.first.isEnabled, isFalse);

        await scanDirsRepo.removeDirectory('/storage/music');
        final empty = await scanDirsRepo.getDirectories();
        expect(empty.valueOrNull!.isEmpty, isTrue);
      });
    });

    group('SqliteFoldersRepository', () {
      test('constructs folder-tree from tracks', () async {
        const t1 = Track(
          id: 'trk-1',
          title: 'Track A',
          artist: 'Artist',
          duration: Duration(seconds: 100),
          filePath: '/home/music/rock/song_a.mp3',
        );
        const t2 = Track(
          id: 'trk-2',
          title: 'Track B',
          artist: 'Artist',
          duration: Duration(seconds: 100),
          filePath: '/home/music/pop/song_b.mp3',
        );
        await tracksRepo.insertTracks([t1, t2]);

        final tree = await foldersRepo.getFoldersTree(const []);
        expect(tree.isSuccess, isTrue);
        final nodes = tree.valueOrNull!;
        expect(nodes.length, equals(2));
        expect(nodes.any((n) => n.name == 'rock'), isTrue);
        expect(nodes.any((n) => n.name == 'pop'), isTrue);
      });
    });
  });
}
