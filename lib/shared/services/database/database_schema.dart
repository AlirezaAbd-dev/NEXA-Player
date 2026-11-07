import 'package:sqlite3/sqlite3.dart';

/// Central database schema definition and migration manager for NEXA Player.
///
/// Defines all SQLite tables, columns, indexes, foreign key relationships,
/// pragmas, and initialization logic conforming to Requirement R1.
abstract final class DatabaseSchema {
  DatabaseSchema._();

  /// Current database schema version.
  static const int currentVersion = 1;

  // ---------------------------------------------------------------------------
  // Table Names
  // ---------------------------------------------------------------------------
  static const String tableTracks = 'tracks';
  static const String tableAlbums = 'albums';
  static const String tableArtists = 'artists';
  static const String tableGenres = 'genres';
  static const String tablePlaylists = 'playlists';
  static const String tablePlaylistTracks = 'playlist_tracks';
  static const String tableScanDirectories = 'scan_directories';

  // ---------------------------------------------------------------------------
  // Column Names: Common
  // ---------------------------------------------------------------------------
  static const String colId = 'id';
  static const String colTitle = 'title';
  static const String colName = 'name';
  static const String colArtworkUri = 'artwork_uri';
  static const String colTrackCount = 'track_count';
  static const String colDurationMs = 'duration_ms';
  static const String colDateAdded = 'date_added';

  // ---------------------------------------------------------------------------
  // Column Names: Tracks
  // ---------------------------------------------------------------------------
  static const String colTrackArtist = 'artist';
  static const String colTrackAlbum = 'album';
  static const String colTrackFilePath = 'file_path';
  static const String colTrackNumber = 'track_number';
  static const String colDiscNumber = 'disc_number';
  static const String colTrackYear = 'year';
  static const String colTrackGenre = 'genre';
  static const String colIsFavorite = 'is_favorite';
  static const String colPlayCount = 'play_count';
  static const String colBitrate = 'bitrate';
  static const String colFileSize = 'file_size';
  static const String colDateModified = 'date_modified';
  static const String colArtistId = 'artist_id';
  static const String colAlbumId = 'album_id';
  static const String colGenreId = 'genre_id';

  // ---------------------------------------------------------------------------
  // Column Names: Albums
  // ---------------------------------------------------------------------------
  static const String colAlbumArtist = 'artist';
  static const String colAlbumYear = 'year';

  // ---------------------------------------------------------------------------
  // Column Names: Artists
  // ---------------------------------------------------------------------------
  static const String colAlbumCount = 'album_count';

  // ---------------------------------------------------------------------------
  // Column Names: Genres
  // ---------------------------------------------------------------------------
  static const String colGradientColors = 'gradient_colors';

  // ---------------------------------------------------------------------------
  // Column Names: Playlists
  // ---------------------------------------------------------------------------
  static const String colDescription = 'description';
  static const String colCreatedAt = 'created_at';
  static const String colUpdatedAt = 'updated_at';
  static const String colIsSystem = 'is_system';
  static const String colIsSmart = 'is_smart';
  static const String colSmartCriteria = 'smart_criteria';

  // ---------------------------------------------------------------------------
  // Column Names: Playlist Tracks
  // ---------------------------------------------------------------------------
  static const String colPlaylistId = 'playlist_id';
  static const String colTrackId = 'track_id';
  static const String colPosition = 'position';
  static const String colAddedAt = 'added_at';

  // ---------------------------------------------------------------------------
  // Column Names: Scan Directories
  // ---------------------------------------------------------------------------
  static const String colPath = 'path';
  static const String colIsActive = 'is_active';
  static const String colLastScanned = 'last_scanned';
  static const String colFileCount = 'file_count';

  // ---------------------------------------------------------------------------
  // Pragmas
  // ---------------------------------------------------------------------------
  static const String pragmaForeignKeysOn = 'PRAGMA foreign_keys = ON;';
  static const String pragmaJournalModeWal = 'PRAGMA journal_mode = WAL;';
  static const String pragmaSynchronousNormal = 'PRAGMA synchronous = NORMAL;';
  static const String pragmaTempStoreMemory = 'PRAGMA temp_store = MEMORY;';
  static const String pragmaCacheSize64Mb = 'PRAGMA cache_size = -64000;';

  // ---------------------------------------------------------------------------
  // DDL: Create Tables
  // ---------------------------------------------------------------------------
  static const String createArtistsTable = '''
CREATE TABLE IF NOT EXISTS $tableArtists (
  $colId TEXT PRIMARY KEY NOT NULL,
  $colName TEXT NOT NULL UNIQUE,
  $colArtworkUri TEXT,
  $colTrackCount INTEGER NOT NULL DEFAULT 0,
  $colAlbumCount INTEGER NOT NULL DEFAULT 0
);''';

  static const String createAlbumsTable = '''
CREATE TABLE IF NOT EXISTS $tableAlbums (
  $colId TEXT PRIMARY KEY NOT NULL,
  $colTitle TEXT NOT NULL,
  $colAlbumArtist TEXT NOT NULL,
  $colArtistId TEXT,
  $colArtworkUri TEXT,
  $colAlbumYear INTEGER,
  $colTrackCount INTEGER NOT NULL DEFAULT 0,
  $colDurationMs INTEGER NOT NULL DEFAULT 0,
  $colDateAdded INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY ($colArtistId) REFERENCES $tableArtists ($colId) ON DELETE SET NULL,
  UNIQUE($colTitle, $colAlbumArtist)
);''';

  static const String createGenresTable = '''
CREATE TABLE IF NOT EXISTS $tableGenres (
  $colId TEXT PRIMARY KEY NOT NULL,
  $colName TEXT NOT NULL UNIQUE,
  $colTrackCount INTEGER NOT NULL DEFAULT 0,
  $colGradientColors TEXT
);''';

  static const String createTracksTable = '''
CREATE TABLE IF NOT EXISTS $tableTracks (
  $colId TEXT PRIMARY KEY NOT NULL,
  $colTitle TEXT NOT NULL,
  $colTrackArtist TEXT NOT NULL,
  $colTrackAlbum TEXT NOT NULL DEFAULT '',
  $colDurationMs INTEGER NOT NULL,
  $colArtworkUri TEXT,
  $colTrackFilePath TEXT NOT NULL UNIQUE,
  $colTrackNumber INTEGER,
  $colDiscNumber INTEGER,
  $colTrackYear INTEGER,
  $colTrackGenre TEXT,
  $colIsFavorite INTEGER NOT NULL DEFAULT 0,
  $colPlayCount INTEGER NOT NULL DEFAULT 0,
  $colBitrate INTEGER,
  $colFileSize INTEGER,
  $colDateAdded INTEGER NOT NULL,
  $colDateModified INTEGER NOT NULL DEFAULT 0,
  $colArtistId TEXT,
  $colAlbumId TEXT,
  $colGenreId TEXT,
  FOREIGN KEY ($colArtistId) REFERENCES $tableArtists ($colId) ON DELETE SET NULL,
  FOREIGN KEY ($colAlbumId) REFERENCES $tableAlbums ($colId) ON DELETE SET NULL,
  FOREIGN KEY ($colGenreId) REFERENCES $tableGenres ($colId) ON DELETE SET NULL
);''';

  static const String createPlaylistsTable = '''
CREATE TABLE IF NOT EXISTS $tablePlaylists (
  $colId TEXT PRIMARY KEY NOT NULL,
  $colName TEXT NOT NULL,
  $colDescription TEXT,
  $colArtworkUri TEXT,
  $colCreatedAt INTEGER NOT NULL,
  $colUpdatedAt INTEGER NOT NULL,
  $colTrackCount INTEGER NOT NULL DEFAULT 0,
  $colDurationMs INTEGER NOT NULL DEFAULT 0,
  $colIsSystem INTEGER NOT NULL DEFAULT 0,
  $colIsSmart INTEGER NOT NULL DEFAULT 0,
  $colSmartCriteria TEXT
);''';

  static const String createPlaylistTracksTable = '''
CREATE TABLE IF NOT EXISTS $tablePlaylistTracks (
  $colPlaylistId TEXT NOT NULL,
  $colTrackId TEXT NOT NULL,
  $colPosition INTEGER NOT NULL,
  $colAddedAt INTEGER NOT NULL,
  PRIMARY KEY ($colPlaylistId, $colTrackId, $colPosition),
  FOREIGN KEY ($colPlaylistId) REFERENCES $tablePlaylists ($colId) ON DELETE CASCADE,
  FOREIGN KEY ($colTrackId) REFERENCES $tableTracks ($colId) ON DELETE CASCADE
);''';

  static const String createScanDirectoriesTable = '''
CREATE TABLE IF NOT EXISTS $tableScanDirectories (
  $colId TEXT PRIMARY KEY NOT NULL,
  $colPath TEXT NOT NULL UNIQUE,
  $colIsActive INTEGER NOT NULL DEFAULT 1,
  $colLastScanned INTEGER,
  $colFileCount INTEGER NOT NULL DEFAULT 0
);''';

  /// Ordered list of all CREATE TABLE DDL queries.
  ///
  /// Parents are created before children to satisfy initial foreign key definitions.
  static const List<String> allCreateTables = [
    createArtistsTable,
    createAlbumsTable,
    createGenresTable,
    createTracksTable,
    createPlaylistsTable,
    createPlaylistTracksTable,
    createScanDirectoriesTable,
  ];

  // ---------------------------------------------------------------------------
  // DDL: Indexes (6 Mandatory R1 Indexes + Auxiliary Indexes)
  // ---------------------------------------------------------------------------
  static const String idxTracksArtist =
      'CREATE INDEX IF NOT EXISTS idx_tracks_artist ON $tableTracks($colTrackArtist);';
  static const String idxTracksAlbum =
      'CREATE INDEX IF NOT EXISTS idx_tracks_album ON $tableTracks($colTrackAlbum);';
  static const String idxTracksGenre =
      'CREATE INDEX IF NOT EXISTS idx_tracks_genre ON $tableTracks($colTrackGenre);';
  static const String idxTracksTitle =
      'CREATE INDEX IF NOT EXISTS idx_tracks_title ON $tableTracks($colTitle);';
  static const String idxTracksPath =
      'CREATE INDEX IF NOT EXISTS idx_tracks_path ON $tableTracks($colTrackFilePath);';
  static const String idxTracksDateAdded =
      'CREATE INDEX IF NOT EXISTS idx_tracks_date_added ON $tableTracks($colDateAdded);';

  /// The 6 mandatory indexes explicitly required by Requirement R1.
  static const List<String> mandatoryIndexes = [
    idxTracksArtist,
    idxTracksAlbum,
    idxTracksGenre,
    idxTracksTitle,
    idxTracksPath,
    idxTracksDateAdded,
  ];

  static const String idxAlbumsArtist =
      'CREATE INDEX IF NOT EXISTS idx_albums_artist ON $tableAlbums($colAlbumArtist);';
  static const String idxAlbumsTitle =
      'CREATE INDEX IF NOT EXISTS idx_albums_title ON $tableAlbums($colTitle);';
  static const String idxArtistsName =
      'CREATE INDEX IF NOT EXISTS idx_artists_name ON $tableArtists($colName);';
  static const String idxPlaylistTracksPos =
      'CREATE INDEX IF NOT EXISTS idx_playlist_tracks_pos ON $tablePlaylistTracks($colPlaylistId, $colPosition);';

  /// Additional performance indexes for relational lookups and ordering.
  static const List<String> auxiliaryIndexes = [
    idxAlbumsArtist,
    idxAlbumsTitle,
    idxArtistsName,
    idxPlaylistTracksPos,
  ];

  /// All database indexes combined.
  static const List<String> allIndexes = [
    ...mandatoryIndexes,
    ...auxiliaryIndexes,
  ];

  // ---------------------------------------------------------------------------
  // Execution & Lifecycle Helpers
  // ---------------------------------------------------------------------------

  /// Configures engine PRAGMAs for concurrency and relational integrity.
  ///
  /// Should be called immediately upon opening a SQLite database.
  static void configurePragmas(Database db, {bool isInMemory = false}) {
    db.execute(pragmaForeignKeysOn);

    if (!isInMemory) {
      db.execute(pragmaJournalModeWal);
    }

    db.execute(pragmaSynchronousNormal);
    db.execute(pragmaTempStoreMemory);
    db.execute(pragmaCacheSize64Mb);
  }

  /// Initializes the complete schema, creating tables and indexes.
  ///
  /// Checks `user_version` and performs migrations if needed.
  static void initializeDatabase(Database db, {bool isInMemory = false}) {
    configurePragmas(db, isInMemory: isInMemory);

    final currentVer = db.userVersion;

    if (currentVer == 0) {
      createSchema(db);
      db.userVersion = currentVersion;
    } else if (currentVer < currentVersion) {
      onUpgrade(db, currentVer, currentVersion);
      db.userVersion = currentVersion;
    }
  }

  /// Executes DDL to create all tables and indexes.
  static void createSchema(Database db) {
    for (final ddl in allCreateTables) {
      db.execute(ddl);
    }
    for (final ddl in allIndexes) {
      db.execute(ddl);
    }
  }

  /// Alias for [createSchema].
  static void createTables(Database db) => createSchema(db);

  /// Handles schema migrations between versions.
  static void onUpgrade(Database db, int oldVersion, int newVersion) {
    // Version 1 is the baseline schema. Future version upgrades will be added here.
  }

  /// Drops all tables in reverse dependency order. Useful for test teardowns.
  static void dropAll(Database db) {
    db.execute('PRAGMA foreign_keys = OFF;');
    db.execute('DROP TABLE IF EXISTS $tablePlaylistTracks;');
    db.execute('DROP TABLE IF EXISTS $tableTracks;');
    db.execute('DROP TABLE IF EXISTS $tableAlbums;');
    db.execute('DROP TABLE IF EXISTS $tableArtists;');
    db.execute('DROP TABLE IF EXISTS $tableGenres;');
    db.execute('DROP TABLE IF EXISTS $tablePlaylists;');
    db.execute('DROP TABLE IF EXISTS $tableScanDirectories;');
    db.execute('PRAGMA foreign_keys = ON;');
  }
}
