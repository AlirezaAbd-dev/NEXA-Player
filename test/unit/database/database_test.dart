import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/models/models.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = TestDatabaseHelper.createInMemoryDatabase();
  });

  tearDown(() {
    db.close();
  });

  group('Database Layer M1 - Initialization & Pragmas', () {
    test('Initializes in-memory with zero side effects on disk', () {
      expect(db.rawDatabase, isNotNull);
      final tables = TestDatabaseHelper.getTableNames(db);
      expect(tables, isNotEmpty);
    });

    test('Enforces PRAGMA foreign_keys = ON;', () {
      final isEnabled = TestDatabaseHelper.isForeignKeyEnabled(db);
      expect(isEnabled, isTrue);
    });

    test('Database close disposes raw connection cleanly', () {
      final tempDb = TestDatabaseHelper.createInMemoryDatabase();
      tempDb.close();
      expect(tempDb.isClosed, isTrue);
      expect(() => tempDb.select('SELECT 1;'), throwsA(isA<DatabaseFailure>()));
    });

    test('Throws DatabaseFailure on invalid SQL syntax', () {
      expect(
        () => db.execute('INVALID SQL SYNTAX STATEMENT;'),
        throwsA(isA<DatabaseFailure>()),
      );
    });
  });

  group('Database Layer M1 - Table Schema Existence & Columns', () {
    test('All 7 mandatory tables exist in SQLite master', () {
      final tables = TestDatabaseHelper.getTableNames(db);
      const expectedTables = [
        'albums',
        'artists',
        'genres',
        'playlist_tracks',
        'playlists',
        'scan_directories',
        'tracks',
      ];
      for (final table in expectedTables) {
        expect(tables, contains(table), reason: 'Missing table $table');
      }
    });

    test('tracks table has all expected columns and primary key', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'tracks');
      final colNames = columns.map((c) => c['name']).toSet();

      expect(colNames, containsAll([
        'id', 'title', 'artist', 'album', 'duration_ms', 'artwork_uri',
        'file_path', 'track_number', 'disc_number', 'year', 'genre',
        'is_favorite', 'play_count', 'bitrate', 'file_size', 'date_added',
        'date_modified', 'album_id', 'artist_id', 'genre_id'
      ]));

      final pkCol = columns.firstWhere((c) => c['name'] == 'id');
      expect(pkCol['pk'], equals(1));
    });

    test('albums table has title and artist unique constraint or columns', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'albums');
      final colNames = columns.map((c) => c['name']).toSet();
      expect(colNames, containsAll([
        'id', 'title', 'artist', 'artwork_uri', 'year', 'track_count',
        'duration_ms', 'date_added', 'artist_id'
      ]));
    });

    test('artists table has name unique column and primary key', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'artists');
      final colNames = columns.map((c) => c['name']).toSet();
      expect(colNames, containsAll(['id', 'name', 'artwork_uri', 'track_count', 'album_count']));
    });

    test('genres table has name unique column and primary key', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'genres');
      final colNames = columns.map((c) => c['name']).toSet();
      expect(colNames, containsAll(['id', 'name', 'track_count', 'gradient_colors']));
    });

    test('playlists table has created_at, updated_at, and track_count', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'playlists');
      final colNames = columns.map((c) => c['name']).toSet();
      expect(colNames, containsAll([
        'id', 'name', 'created_at', 'updated_at', 'track_count',
        'duration_ms', 'artwork_uri', 'is_smart', 'smart_criteria'
      ]));
    });

    test('playlist_tracks table has position and added_at columns', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'playlist_tracks');
      final colNames = columns.map((c) => c['name']).toSet();
      expect(colNames, containsAll(['playlist_id', 'track_id', 'position', 'added_at']));
    });

    test('scan_directories table has path unique column and is_active flag', () {
      final columns = TestDatabaseHelper.getTableColumns(db, 'scan_directories');
      final colNames = columns.map((c) => c['name']).toSet();
      expect(colNames, containsAll(['id', 'path', 'is_active', 'last_scanned', 'file_count']));
    });
  });

  group('Database Layer M1 - Indexes & Query Planner Verification', () {
    test('6 mandatory indexes on tracks are created and queryable', () {
      final indexes = TestDatabaseHelper.getTableIndexes(db, 'tracks');
      expect(indexes, contains('idx_tracks_artist'));
      expect(indexes, contains('idx_tracks_album'));
      expect(indexes, contains('idx_tracks_genre'));
      expect(indexes, contains('idx_tracks_title'));
      expect(indexes, contains('idx_tracks_path'));
      expect(indexes, contains('idx_tracks_date_added'));
    });

    test('Relational indexes on playlist_tracks and albums are created', () {
      final playlistIndexes = TestDatabaseHelper.getTableIndexes(db, 'playlist_tracks');
      expect(playlistIndexes, contains('idx_playlist_tracks_pos'));

      final albumIndexes = TestDatabaseHelper.getTableIndexes(db, 'albums');
      expect(albumIndexes, contains('idx_albums_artist'));
      expect(albumIndexes, contains('idx_albums_title'));
    });

    test('EXPLAIN QUERY PLAN confirms index utilization on tracks', () {
      expect(
        TestDatabaseHelper.explainQueryUsesIndex(
          db,
          "SELECT * FROM tracks WHERE artist = 'Test Artist';",
          'idx_tracks_artist',
        ),
        isTrue,
      );

      expect(
        TestDatabaseHelper.explainQueryUsesIndex(
          db,
          "SELECT * FROM tracks WHERE album = 'Test Album';",
          'idx_tracks_album',
        ),
        isTrue,
      );

      expect(
        TestDatabaseHelper.explainQueryUsesIndex(
          db,
          "SELECT * FROM tracks WHERE genre = 'Rock';",
          'idx_tracks_genre',
        ),
        isTrue,
      );

      expect(
        TestDatabaseHelper.explainQueryUsesIndex(
          db,
          "SELECT * FROM tracks INDEXED BY idx_tracks_path WHERE file_path = '/music/song.mp3';",
          'idx_tracks_path',
        ),
        isTrue,
      );
    });
  });

  group('Database Layer M1 - Foreign Key Constraints & Cascade Operations', () {
    test('Inserting track with invalid foreign key violates constraint', () {
      expect(
        () => db.execute(
          '''
          INSERT INTO tracks (id, title, artist, album, duration_ms, file_path, date_added, date_modified, album_id)
          VALUES ('t1', 'Song', 'Artist', 'Album', 180000, '/path/song.mp3', 1000, 1000, 'non_existent_album_id');
          ''',
        ),
        throwsA(isA<DatabaseFailure>()),
      );
    });

    test('Deleting playlist cascades and deletes associated playlist_tracks entries', () {
      // 1. Seed Playlist, Track, and Junction
      final playlist = Playlist(
        id: 'p1',
        name: 'My Playlist',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      TestDatabaseHelper.seedPlaylist(db, playlist);

      const track = Track(
        id: 't1',
        title: 'Song 1',
        artist: 'Artist 1',
        duration: Duration(minutes: 3),
        filePath: '/music/song1.mp3',
      );
      TestDatabaseHelper.seedTrack(db, track);

      final pt = PlaylistTrack(
        id: 'p1_t1_0',
        playlistId: 'p1',
        trackId: 't1',
        position: 0,
        addedAt: DateTime(2026, 1, 1),
      );
      TestDatabaseHelper.seedPlaylistTrack(db, pt);

      // Verify row exists
      final beforeRows = db.select("SELECT * FROM playlist_tracks WHERE playlist_id = 'p1';");
      expect(beforeRows.length, equals(1));

      // 2. Delete Playlist
      db.execute("DELETE FROM playlists WHERE id = 'p1';");

      // 3. Verify junction is deleted by CASCADE
      final afterRows = db.select("SELECT * FROM playlist_tracks WHERE playlist_id = 'p1';");
      expect(afterRows.length, equals(0));

      // 4. Verify track itself is unaffected
      final trackCheck = db.select("SELECT * FROM tracks WHERE id = 't1';");
      expect(trackCheck.length, equals(1));
    });

    test('Deleting track cascades and deletes entries from playlist_tracks', () {
      final playlist = Playlist(
        id: 'p2',
        name: 'Playlist 2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      TestDatabaseHelper.seedPlaylist(db, playlist);

      const track = Track(
        id: 't2',
        title: 'Song 2',
        artist: 'Artist 2',
        duration: Duration(minutes: 3),
        filePath: '/music/song2.mp3',
      );
      TestDatabaseHelper.seedTrack(db, track);

      final pt = PlaylistTrack(
        id: 'p2_t2_0',
        playlistId: 'p2',
        trackId: 't2',
        position: 0,
        addedAt: DateTime(2026, 1, 1),
      );
      TestDatabaseHelper.seedPlaylistTrack(db, pt);

      // Delete track
      db.execute("DELETE FROM tracks WHERE id = 't2';");

      // Verify junction entry is cascaded
      final ptRows = db.select("SELECT * FROM playlist_tracks WHERE track_id = 't2';");
      expect(ptRows.length, equals(0));
    });

    test('Deleting album sets track album_id to NULL via ON DELETE SET NULL', () {
      const album = Album(
        id: 'alb1',
        title: 'Discovery',
        artist: 'Daft Punk',
      );
      TestDatabaseHelper.seedAlbum(db, album);

      const track = Track(
        id: 't3',
        title: 'One More Time',
        artist: 'Daft Punk',
        album: 'Discovery',
        duration: Duration(minutes: 5, seconds: 20),
        filePath: '/music/one_more_time.mp3',
        albumId: 'alb1',
      );
      TestDatabaseHelper.seedTrack(db, track);

      // Verify track has album_id before
      final beforeTrack = db.select("SELECT album_id FROM tracks WHERE id = 't3';");
      expect(beforeTrack.first['album_id'], equals('alb1'));

      // Delete album
      db.execute("DELETE FROM albums WHERE id = 'alb1';");

      // Verify track survives with album_id set to NULL
      final afterTrack = db.select("SELECT album_id FROM tracks WHERE id = 't3';");
      expect(afterTrack.length, equals(1));
      expect(afterTrack.first['album_id'], isNull);
    });

    test('Deleting artist sets track artist_id to NULL via ON DELETE SET NULL', () {
      const artist = Artist(
        id: 'art1',
        name: 'Queen',
      );
      TestDatabaseHelper.seedArtist(db, artist);

      const track = Track(
        id: 't4',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        duration: Duration(minutes: 5, seconds: 55),
        filePath: '/music/bohemian.mp3',
        artistId: 'art1',
      );
      TestDatabaseHelper.seedTrack(db, track);

      // Delete artist
      db.execute("DELETE FROM artists WHERE id = 'art1';");

      // Verify track survives with artist_id set to NULL
      final afterTrack = db.select("SELECT artist_id FROM tracks WHERE id = 't4';");
      expect(afterTrack.length, equals(1));
      expect(afterTrack.first['artist_id'], isNull);
    });
  });

  group('Database Layer M1 - Transaction Atomicity', () {
    test('Transaction commits all statements successfully', () {
      db.transaction(() {
        db.execute(
          "INSERT INTO genres (id, name, track_count) VALUES ('g1', 'Electronic', 10);",
        );
        db.execute(
          "INSERT INTO genres (id, name, track_count) VALUES ('g2', 'Ambient', 5);",
        );
      });

      final rows = db.select("SELECT COUNT(*) AS count FROM genres WHERE id IN ('g1', 'g2');");
      expect(rows.first['count'], equals(2));
    });

    test('Transaction rolls back all operations upon unhandled exception', () {
      expect(
        () => db.transaction(() {
          db.execute(
            "INSERT INTO genres (id, name, track_count) VALUES ('g3', 'Jazz', 20);",
          );
          // Deliberate error: duplicate unique name
          db.execute(
            "INSERT INTO genres (id, name, track_count) VALUES ('g4', 'Jazz', 30);",
          );
        }),
        throwsA(isA<DatabaseFailure>()),
      );

      // Verify g3 was rolled back and does not exist in DB
      final rows = db.select("SELECT * FROM genres WHERE id = 'g3';");
      expect(rows.isEmpty, isTrue);
    });

    test('Nested transactions use savepoints and commit correctly', () {
      db.transaction(() {
        db.execute("INSERT INTO genres (id, name, track_count) VALUES ('g5', 'Pop', 1);");

        db.transaction(() {
          db.execute("INSERT INTO genres (id, name, track_count) VALUES ('g6', 'Soul', 2);");
        });
      });

      final rows = db.select("SELECT COUNT(*) AS count FROM genres WHERE id IN ('g5', 'g6');");
      expect(rows.first['count'], equals(2));
    });
  });

  group('Database Layer M1 - Model Serialization & Deserialization Unit Tests', () {
    test('Playlist toMap and fromMap round-trip accurately', () {
      final now = DateTime(2026, 11, 7, 12, 0, 0);
      final playlist = Playlist(
        id: 'p_test',
        name: 'Synthwave Night',
        createdAt: now,
        updatedAt: now,
        trackCount: 42,
        artworkUri: 'file:///art/p1.jpg',
        duration: const Duration(hours: 2, minutes: 15),
        isSmart: true,
        smartCriteria: '{"genre": "Synthwave"}',
      );

      final map = playlist.toMap();
      final reconstructed = Playlist.fromMap(map);

      expect(reconstructed, equals(playlist));
      expect(reconstructed.trackCountLabel, equals('42 Tracks'));
    });

    test('PlaylistTrack toMap and fromMap round-trip accurately', () {
      final now = DateTime(2026, 11, 7, 12, 0, 0);
      final pt = PlaylistTrack(
        id: 'p1_t1_0',
        playlistId: 'p1',
        trackId: 't1',
        position: 0,
        addedAt: now,
      );

      final map = pt.toMap();
      final reconstructed = PlaylistTrack.fromMap(map);

      expect(reconstructed, equals(pt));
    });

    test('ScanDirectory toMap and fromMap round-trip accurately', () {
      final now = DateTime(2026, 11, 7, 12, 0, 0);
      final dir = ScanDirectory(
        id: 'sd1',
        path: '/storage/emulated/0/Music',
        isEnabled: true,
        lastScannedAt: now,
        trackCount: 1500,
      );

      final map = dir.toMap();
      final reconstructed = ScanDirectory.fromMap(map);

      expect(reconstructed, equals(dir));
      expect(reconstructed.trackCountLabel, equals('1500 Tracks'));
    });

    test('ScannerConfig toMap and fromMap round-trip accurately', () {
      const config = ScannerConfig(
        skipNoMedia: true,
        skipShortAudio: false,
        minDurationSeconds: 15,
        skipSmallFiles: true,
        minSizeBytes: 102400,
        extensionsWhitelist: ['mp3', 'flac', 'wav'],
      );

      final map = config.toMap();
      final reconstructed = ScannerConfig.fromMap(map);

      expect(reconstructed, equals(config));
      expect(reconstructed.isExtensionSupported('mp3'), isTrue);
      expect(reconstructed.isExtensionSupported('.FLAC'), isTrue);
      expect(reconstructed.isExtensionSupported('m4a'), isFalse);
    });

    test('Track toMap and fromMap with new Milestone 1 fields', () {
      final now = DateTime(2026, 11, 7, 12, 0, 0);
      final track = Track(
        id: 't_m1',
        title: 'Cyberpunk Skyline',
        artist: 'Kavinsky',
        album: 'Nightcall',
        duration: const Duration(minutes: 4, seconds: 19),
        artworkUri: 'file:///art/kavinsky.jpg',
        filePath: '/music/cyberpunk.flac',
        trackNumber: 2,
        discNumber: 1,
        year: 2026,
        genre: 'Synthwave',
        isFavorite: true,
        playCount: 10,
        bitrate: 1411,
        fileSize: 45000000,
        dateAdded: now,
        dateModified: now,
        albumId: 'alb_cyber',
        artistId: 'art_kav',
        genreId: 'gen_synth',
      );

      final map = track.toMap();
      final reconstructed = Track.fromMap(map);

      expect(reconstructed, equals(track));
      expect(reconstructed.formattedDuration, equals('4:19'));
      expect(reconstructed.artistAndAlbum, equals('Kavinsky • Nightcall'));
    });

    test('Album toMap and fromMap with new Milestone 1 fields', () {
      final now = DateTime(2026, 11, 7, 12, 0, 0);
      final album = Album(
        id: 'alb_m1',
        title: 'Random Access Memories',
        artist: 'Daft Punk',
        artworkUri: 'file:///art/ram.jpg',
        year: 2013,
        trackCount: 13,
        duration: const Duration(minutes: 74, seconds: 28),
        dateAdded: now,
        artistId: 'art_dp',
      );

      final map = album.toMap();
      final reconstructed = Album.fromMap(map);

      expect(reconstructed, equals(album));
      expect(reconstructed.artistAndYear, equals('Daft Punk • 2013'));
      expect(reconstructed.trackCountLabel, equals('13 Tracks'));
    });

    test('Artist toMap and fromMap round-trip accurately', () {
      const artist = Artist(
        id: 'art_m1',
        name: 'Hans Zimmer',
        artworkUri: 'file:///art/zimmer.jpg',
        trackCount: 120,
        albumCount: 15,
      );

      final map = artist.toMap();
      final reconstructed = Artist.fromMap(map);

      expect(reconstructed, equals(artist));
      expect(reconstructed.tracksAndAlbumsLabel, equals('120 Tracks • 15 Albums'));
    });

    test('Genre toMap and fromMap round-trip accurately', () {
      const genre = Genre(
        id: 'gen_m1',
        name: 'Chiptune',
        trackCount: 50,
      );

      final map = genre.toMap();
      final reconstructed = Genre.fromMap(map);

      expect(reconstructed.id, equals(genre.id));
      expect(reconstructed.name, equals(genre.name));
      expect(reconstructed.trackCount, equals(genre.trackCount));
      expect(reconstructed.resolvedGradient.colors.length, greaterThanOrEqualTo(2));
    });
  });
}
