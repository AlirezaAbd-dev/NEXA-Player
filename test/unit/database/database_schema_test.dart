import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  group('DatabaseSchema In-Memory Unit Tests', () {
    late Database db;

    setUp(() {
      db = sqlite3.openInMemory();
      DatabaseSchema.initializeDatabase(db, isInMemory: true);
    });

    tearDown(() {
      db.dispose();
    });

    test('All 7 tables are created successfully', () {
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type='table';")
          .map((row) => row['name'] as String)
          .toSet();

      expect(tables, contains(DatabaseSchema.tableTracks));
      expect(tables, contains(DatabaseSchema.tableAlbums));
      expect(tables, contains(DatabaseSchema.tableArtists));
      expect(tables, contains(DatabaseSchema.tableGenres));
      expect(tables, contains(DatabaseSchema.tablePlaylists));
      expect(tables, contains(DatabaseSchema.tablePlaylistTracks));
      expect(tables, contains(DatabaseSchema.tableScanDirectories));
    });

    test('All 6 mandatory R1 indexes and auxiliary indexes exist', () {
      final indexes = db
          .select("SELECT name FROM sqlite_master WHERE type='index';")
          .map((row) => row['name'] as String)
          .toSet();

      // 6 Mandatory
      expect(indexes, contains('idx_tracks_artist'));
      expect(indexes, contains('idx_tracks_album'));
      expect(indexes, contains('idx_tracks_genre'));
      expect(indexes, contains('idx_tracks_title'));
      expect(indexes, contains('idx_tracks_path'));
      expect(indexes, contains('idx_tracks_date_added'));

      // Auxiliary
      expect(indexes, contains('idx_albums_artist'));
      expect(indexes, contains('idx_albums_title'));
      expect(indexes, contains('idx_artists_name'));
      expect(indexes, contains('idx_playlist_tracks_pos'));
    });

    test('Foreign key enforcement is active', () {
      final fkResult = db.select('PRAGMA foreign_keys;');
      expect(fkResult.first.values.first, equals(1));
    });

    test('user_version is set to currentVersion', () {
      expect(db.userVersion, equals(DatabaseSchema.currentVersion));
    });

    test('Playlist tracks cascade deletion on playlist delete', () {
      // 1. Insert a track and a playlist
      db.execute(
        "INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES ('t1', 'Song 1', 'Artist 1', 180000, '/path/song1.mp3', 1000);",
      );
      db.execute(
        "INSERT INTO playlists (id, name, created_at, updated_at) VALUES ('p1', 'My Playlist', 1000, 1000);",
      );
      db.execute(
        "INSERT INTO playlist_tracks (playlist_id, track_id, position, added_at) VALUES ('p1', 't1', 0, 1000);",
      );

      // Verify insertion
      expect(db.select("SELECT * FROM playlist_tracks WHERE playlist_id='p1';").length, equals(1));

      // 2. Delete playlist
      db.execute("DELETE FROM playlists WHERE id='p1';");

      // Verify cascade
      expect(db.select("SELECT * FROM playlist_tracks WHERE playlist_id='p1';").isEmpty, isTrue);
      // Track must still exist
      expect(db.select("SELECT * FROM tracks WHERE id='t1';").length, equals(1));
    });

    test('Track metadata relationships SET NULL on parent entity delete', () {
      db.execute("INSERT INTO artists (id, name) VALUES ('art1', 'Daft Punk');");
      db.execute("INSERT INTO albums (id, title, artist, artist_id) VALUES ('alb1', 'Discovery', 'Daft Punk', 'art1');");
      db.execute(
        "INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added, artist_id, album_id) VALUES ('t1', 'One More Time', 'Daft Punk', 320000, '/music/omt.mp3', 1000, 'art1', 'alb1');",
      );

      // Delete artist
      db.execute("DELETE FROM artists WHERE id='art1';");

      // Track's artist_id should be null, but track persists
      final track = db.select("SELECT artist_id, album_id FROM tracks WHERE id='t1';").first;
      expect(track['artist_id'], isNull);
      expect(track['album_id'], equals('alb1'));

      // Album's artist_id should be null, but album persists
      final album = db.select("SELECT artist_id FROM albums WHERE id='alb1';").first;
      expect(album['artist_id'], isNull);
    });

    test('Unique constraints prevent duplicate insertions', () {
      db.execute(
        "INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES ('t1', 'Song 1', 'Artist 1', 180000, '/path/song1.mp3', 1000);",
      );

      // Attempt duplicate file_path
      expect(
        () => db.execute(
          "INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES ('t2', 'Song 2', 'Artist 2', 200000, '/path/song1.mp3', 2000);",
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('dropAll drops all tables', () {
      DatabaseSchema.dropAll(db);
      final tables = db
          .select("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';")
          .map((row) => row['name'] as String)
          .toList();
      expect(tables, isEmpty);
    });
  });
}
