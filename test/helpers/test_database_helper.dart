import 'package:nexa_player/shared/models/models.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Complete testing harness and SQLite inspection helper for hermetic unit tests.
class TestDatabaseHelper {
  /// Initializes a pristine, in-memory SQLite database populated with all
  /// 7 tables and 10 indexes with foreign keys strictly enabled.
  static AppDatabase createInMemoryDatabase() {
    return AppDatabase.inMemory();
  }

  /// Inspects sqlite_master and returns all user-defined table names.
  static List<String> getTableNames(IAppDatabase db) {
    final result = db.select(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%' ORDER BY name;",
    );
    return result.map((row) => row['name'] as String).toList();
  }

  /// Queries PRAGMA table_info to inspect column metadata.
  static List<Map<String, dynamic>> getTableColumns(IAppDatabase db, String tableName) {
    final result = db.select("PRAGMA table_info('$tableName');");
    return result.map((row) => {
      'cid': row['cid'],
      'name': row['name'] as String,
      'type': row['type'] as String,
      'notnull': row['notnull'] as int,
      'dflt_value': row['dflt_value'],
      'pk': row['pk'] as int,
    }).toList();
  }

  /// Queries PRAGMA index_list to obtain index names for a specific table.
  static List<String> getTableIndexes(IAppDatabase db, String tableName) {
    final result = db.select("PRAGMA index_list('$tableName');");
    return result.map((row) => row['name'] as String).toList();
  }

  /// Queries PRAGMA index_info to inspect columns referenced by an index.
  static List<String> getIndexColumns(IAppDatabase db, String indexName) {
    final result = db.select("PRAGMA index_info('$indexName');");
    return result.map((row) => row['name'] as String).toList();
  }

  /// Inspects foreign key constraints defined on [tableName].
  static List<Map<String, dynamic>> getForeignKeys(IAppDatabase db, String tableName) {
    final result = db.select("PRAGMA foreign_key_list('$tableName');");
    return result.map((row) => {
      'id': row['id'],
      'seq': row['seq'],
      'table': row['table'] as String,
      'from': row['from'] as String,
      'to': row['to'] as String,
      'on_update': row['on_update'] as String,
      'on_delete': row['on_delete'] as String,
    }).toList();
  }

  /// Verifies whether PRAGMA foreign_keys is currently active.
  static bool isForeignKeyEnabled(IAppDatabase db) {
    final result = db.select('PRAGMA foreign_keys;');
    if (result.isEmpty) return false;
    return (result.first.values.first as int) == 1;
  }

  /// Checks whether an SQL statement's EXPLAIN QUERY PLAN uses [indexName].
  static bool explainQueryUsesIndex(IAppDatabase db, String sql, String indexName) {
    final result = db.select('EXPLAIN QUERY PLAN $sql');
    return result.any((row) {
      final detail = (row['detail'] as String?) ?? '';
      return detail.contains(indexName);
    });
  }

  // --- Fixture Seeders ---

  static void seedArtist(IAppDatabase db, Artist artist) {
    db.execute(
      'INSERT INTO artists (id, name, artwork_uri, track_count, album_count) VALUES (?, ?, ?, ?, ?);',
      [artist.id, artist.name, artist.artworkUri, artist.trackCount, artist.albumCount],
    );
  }

  static void seedAlbum(IAppDatabase db, Album album) {
    db.execute(
      'INSERT INTO albums (id, title, artist, artwork_uri, year, track_count, duration_ms, date_added, artist_id) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);',
      [
        album.id,
        album.title,
        album.artist,
        album.artworkUri,
        album.year,
        album.trackCount,
        album.duration?.inMilliseconds ?? 0,
        album.dateAdded?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        album.artistId,
      ],
    );
  }

  static void seedGenre(IAppDatabase db, Genre genre) {
    db.execute(
      'INSERT INTO genres (id, name, track_count, gradient_colors) VALUES (?, ?, ?, ?);',
      [
        genre.id,
        genre.name,
        genre.trackCount,
        genre.gradientColors?.map((c) => c.value.toRadixString(16)).join(','),
      ],
    );
  }

  static void seedTrack(IAppDatabase db, Track track) {
    db.execute(
      '''
      INSERT INTO tracks (
        id, title, artist, album, duration_ms, artwork_uri, file_path,
        track_number, disc_number, year, genre, is_favorite, play_count,
        bitrate, file_size, date_added, date_modified, album_id, artist_id, genre_id
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        track.id,
        track.title,
        track.artist,
        track.album,
        track.duration.inMilliseconds,
        track.artworkUri,
        track.filePath,
        track.trackNumber,
        track.discNumber,
        track.year,
        track.genre,
        track.isFavorite ? 1 : 0,
        track.playCount,
        track.bitrate,
        track.fileSize,
        track.dateAdded?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        track.dateModified?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
        track.albumId,
        track.artistId,
        track.genreId,
      ],
    );
  }

  static void seedPlaylist(IAppDatabase db, Playlist playlist) {
    db.execute(
      '''
      INSERT INTO playlists (
        id, name, created_at, updated_at, track_count, duration_ms,
        artwork_uri, is_smart, smart_criteria
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''',
      [
        playlist.id,
        playlist.name,
        playlist.createdAt.millisecondsSinceEpoch,
        playlist.updatedAt.millisecondsSinceEpoch,
        playlist.trackCount,
        playlist.duration?.inMilliseconds ?? 0,
        playlist.artworkUri,
        playlist.isSmart ? 1 : 0,
        playlist.smartCriteria,
      ],
    );
  }

  static void seedPlaylistTrack(IAppDatabase db, PlaylistTrack playlistTrack) {
    db.execute(
      '''
      INSERT INTO playlist_tracks (playlist_id, track_id, position, added_at)
      VALUES (?, ?, ?, ?);
      ''',
      [
        playlistTrack.playlistId,
        playlistTrack.trackId,
        playlistTrack.position,
        playlistTrack.addedAt.millisecondsSinceEpoch,
      ],
    );
  }

  static void seedScanDirectory(IAppDatabase db, ScanDirectory dir) {
    db.execute(
      '''
      INSERT INTO scan_directories (id, path, is_active, last_scanned, file_count)
      VALUES (?, ?, ?, ?, ?);
      ''',
      [
        dir.id,
        dir.path,
        dir.isEnabled ? 1 : 0,
        dir.lastScannedAt?.millisecondsSinceEpoch,
        dir.trackCount,
      ],
    );
  }
}
