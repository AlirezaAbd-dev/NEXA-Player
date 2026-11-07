import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/album_card.dart';
import 'package:nexa_player/shared/widgets/cards/artist_card.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';
import 'package:nexa_player/shared/widgets/glass/glass_fab.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';
import 'package:sqlite3/sqlite3.dart' as sq;

// ============================================================================
// 1. Semantic Keys for Phase 2 Opaque-Box Testing
// ============================================================================

abstract final class E2EPhase2Keys {
  // Navigation & Shell
  static const Key tabSongs = ValueKey('tab_songs');
  static const Key tabAlbums = ValueKey('tab_albums');
  static const Key tabArtists = ValueKey('tab_artists');
  static const Key tabPlaylists = ValueKey('tab_playlists');
  static const Key tabFolders = ValueKey('tab_folders');
  static const Key tabSettings = ValueKey('tab_settings');

  // All Songs Screen
  static const Key searchField = ValueKey('songs_search_field');
  static const Key sortButton = ValueKey('songs_sort_button');
  static const Key sortMenuTitle = ValueKey('sort_menu_title');
  static const Key sortMenuArtist = ValueKey('sort_menu_artist');
  static const Key sortMenuDuration = ValueKey('sort_menu_duration');
  static const Key sortMenuDateAdded = ValueKey('sort_menu_date_added');
  static const Key allSongsList = ValueKey('all_songs_list');
  static const Key songCountHeader = ValueKey('song_count_header');
  static Key trackTile(String trackId) => ValueKey('track_tile_$trackId');
  static Key trackFavoriteToggle(String trackId) => ValueKey('track_fav_$trackId');

  // Albums Screen & Detail
  static const Key albumsGrid = ValueKey('albums_grid');
  static Key albumCard(String albumId) => ValueKey('album_card_$albumId');
  static const Key albumDetailScreen = ValueKey('album_detail_screen');
  static const Key albumDetailBackButton = ValueKey('album_detail_back');
  static const Key albumDetailTrackList = ValueKey('album_detail_track_list');

  // Artists Screen & Detail
  static const Key artistsList = ValueKey('artists_list');
  static Key artistCard(String artistId) => ValueKey('artist_card_$artistId');
  static const Key artistDetailScreen = ValueKey('artist_detail_screen');
  static const Key artistDetailBackButton = ValueKey('artist_detail_back');
  static const Key artistDetailTrackList = ValueKey('artist_detail_track_list');

  // Playlists Screen & Dialogs
  static const Key playlistsList = ValueKey('playlists_list');
  static const Key createPlaylistFab = ValueKey('create_playlist_fab');
  static const Key createPlaylistDialog = ValueKey('create_playlist_dialog');
  static const Key playlistNameInput = ValueKey('playlist_name_input');
  static const Key playlistConfirmCreate = ValueKey('playlist_confirm_create');
  static Key playlistItem(String playlistId) => ValueKey('playlist_item_$playlistId');
  static Key playlistDeleteButton(String playlistId) => ValueKey('playlist_delete_$playlistId');
  static const Key confirmDeletePlaylistButton = ValueKey('confirm_delete_playlist');

  // Folders Screen
  static const Key foldersTreeView = ValueKey('folders_tree_view');
  static Key folderNode(String folderPath) => ValueKey('folder_node_$folderPath');
  static Key fileNode(String filePath) => ValueKey('file_node_$filePath');

  // Scanner Settings Screen
  static const Key scannerSettingsScreen = ValueKey('scanner_settings_screen');
  static const Key scannerFolderList = ValueKey('scanner_folder_list');
  static const Key addFolderButton = ValueKey('add_folder_button');
  static const Key addFolderPathInput = ValueKey('add_folder_path_input');
  static const Key addFolderConfirmButton = ValueKey('add_folder_confirm');
  static Key removeFolderButton(String path) => ValueKey('remove_folder_$path');
  static const Key rescanButton = ValueKey('rescan_button');
  static const Key scannerProgressBar = ValueKey('scanner_progress_bar');
  static const Key scannerStatusText = ValueKey('scanner_status_text');
  static const Key skipShortFilesSwitch = ValueKey('skip_short_files_switch');
  static const Key minDurationSlider = ValueKey('min_duration_slider');
}

// ============================================================================
// 2. Domain Models & Failures
// ============================================================================

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, [super.cause, super.stackTrace]);
}

class Genre extends Equatable {
  const Genre({
    required this.id,
    required this.name,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final int trackCount;

  @override
  List<Object?> get props => [id, name, trackCount];
}

class ScannerFailure extends Failure {
  const ScannerFailure(super.message, [super.cause, super.stackTrace]);
}

enum TrackSortBy { title, artist, dateAdded, duration }
enum AlbumSortBy { title, artist, year }
enum ArtistSortBy { name, trackCount }

class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final int trackCount;

  Playlist copyWith({String? id, String? name, DateTime? createdAt, int? trackCount}) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt, trackCount];
}

class PlaylistTrack extends Equatable {
  const PlaylistTrack({
    required this.id,
    required this.playlistId,
    required this.trackId,
    required this.sortOrder,
    required this.addedAt,
  });

  final String id;
  final String playlistId;
  final String trackId;
  final int sortOrder;
  final DateTime addedAt;

  @override
  List<Object?> get props => [id, playlistId, trackId, sortOrder, addedAt];
}

class ScanDirectory extends Equatable {
  const ScanDirectory({
    required this.id,
    required this.path,
    this.isEnabled = true,
    required this.addedAt,
    this.lastScannedAt,
  });

  final String id;
  final String path;
  final bool isEnabled;
  final DateTime addedAt;
  final DateTime? lastScannedAt;

  @override
  List<Object?> get props => [id, path, isEnabled, addedAt, lastScannedAt];
}

class ScannerConfig extends Equatable {
  const ScannerConfig({
    this.minDurationSeconds = 5,
    this.minFileSizeBytes = 1024,
    this.audioExtensionsWhitelist = const ['mp3', 'flac', 'm4a', 'wav', 'ogg', 'aac', 'opus'],
    this.skipNoMedia = true,
  });

  final int minDurationSeconds;
  final int minFileSizeBytes;
  final List<String> audioExtensionsWhitelist;
  final bool skipNoMedia;

  @override
  List<Object?> get props => [
        minDurationSeconds,
        minFileSizeBytes,
        audioExtensionsWhitelist,
        skipNoMedia,
      ];
}

enum ScannerStatus { idle, scanning, completed, error }

class ScannerState extends Equatable {
  const ScannerState({
    this.status = ScannerStatus.idle,
    this.progress = 0.0,
    this.filesScanned = 0,
    this.filesFound = 0,
    this.currentFile,
    this.errorMessage,
  });

  final ScannerStatus status;
  final double progress; // 0.0 to 1.0
  final int filesScanned;
  final int filesFound;
  final String? currentFile;
  final String? errorMessage;

  ScannerState copyWith({
    ScannerStatus? status,
    double? progress,
    int? filesScanned,
    int? filesFound,
    String? currentFile,
    String? errorMessage,
  }) {
    return ScannerState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filesScanned: filesScanned ?? this.filesScanned,
      filesFound: filesFound ?? this.filesFound,
      currentFile: currentFile ?? this.currentFile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, progress, filesScanned, filesFound, currentFile, errorMessage];
}

class ScanResult extends Equatable {
  const ScanResult({
    required this.scannedFilesCount,
    required this.insertedTracksCount,
    required this.skippedFilesCount,
    required this.duration,
    this.errors = const [],
  });

  final int scannedFilesCount;
  final int insertedTracksCount;
  final int skippedFilesCount;
  final Duration duration;
  final List<String> errors;

  @override
  List<Object?> get props => [scannedFilesCount, insertedTracksCount, skippedFilesCount, duration, errors];
}

// ============================================================================
// 3. Database Layer Contracts & In-Memory Implementation
// ============================================================================

abstract interface class IAppDatabase {
  sq.Database get rawDatabase;
  void execute(String sql, [List<Object?> parameters = const []]);
  sq.ResultSet select(String sql, [List<Object?> parameters = const []]);
  void transaction(void Function() action);
  void close();
}

class TestAppDatabase implements IAppDatabase {
  TestAppDatabase._(this._db);

  final sq.Database _db;

  static TestAppDatabase inMemory() {
    final db = sq.sqlite3.openInMemory();
    final appDb = TestAppDatabase._(db);
    appDb._initialize();
    return appDb;
  }

  void _initialize() {
    // Configure PRAGMAs
    _db.execute('PRAGMA foreign_keys = ON;');
    _db.execute('PRAGMA journal_mode = WAL;');

    // 1. Tracks Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS tracks (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        album TEXT,
        duration_ms INTEGER NOT NULL,
        artwork_uri TEXT,
        file_path TEXT NOT NULL UNIQUE,
        track_number INTEGER,
        disc_number INTEGER,
        year INTEGER,
        genre TEXT,
        is_favorite INTEGER NOT NULL DEFAULT 0,
        play_count INTEGER NOT NULL DEFAULT 0,
        bitrate INTEGER,
        file_size INTEGER,
        date_added INTEGER NOT NULL
      );
    ''');

    // 2. Albums Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS albums (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        artist TEXT NOT NULL,
        artwork_uri TEXT,
        year INTEGER,
        track_count INTEGER DEFAULT 0
      );
    ''');

    // 3. Artists Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS artists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        track_count INTEGER DEFAULT 0,
        album_count INTEGER DEFAULT 0
      );
    ''');

    // 4. Genres Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS genres (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        track_count INTEGER DEFAULT 0
      );
    ''');

    // 5. Playlists Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS playlists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        track_count INTEGER DEFAULT 0
      );
    ''');

    // 6. Playlist Tracks Table (with cascade integrity)
    _db.execute('''
      CREATE TABLE IF NOT EXISTS playlist_tracks (
        id TEXT PRIMARY KEY,
        playlist_id TEXT NOT NULL,
        track_id TEXT NOT NULL,
        sort_order INTEGER NOT NULL,
        added_at INTEGER NOT NULL,
        FOREIGN KEY (playlist_id) REFERENCES playlists (id) ON DELETE CASCADE,
        FOREIGN KEY (track_id) REFERENCES tracks (id) ON DELETE CASCADE
      );
    ''');

    // 7. Scan Directories Table
    _db.execute('''
      CREATE TABLE IF NOT EXISTS scan_directories (
        id TEXT PRIMARY KEY,
        path TEXT NOT NULL UNIQUE,
        is_enabled INTEGER NOT NULL DEFAULT 1,
        added_at INTEGER NOT NULL,
        last_scanned_at INTEGER
      );
    ''');

    // Query Indexes
    _db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_artist ON tracks (artist);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_album ON tracks (album);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_genre ON tracks (genre);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_title ON tracks (title);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_path ON tracks (file_path);');
    _db.execute('CREATE INDEX IF NOT EXISTS idx_tracks_date_added ON tracks (date_added);');
  }

  @override
  sq.Database get rawDatabase => _db;

  @override
  void execute(String sql, [List<Object?> parameters = const []]) {
    _db.execute(sql, parameters);
  }

  @override
  sq.ResultSet select(String sql, [List<Object?> parameters = const []]) {
    return _db.select(sql, parameters);
  }

  @override
  void transaction(void Function() action) {
    _db.execute('BEGIN TRANSACTION;');
    try {
      action();
      _db.execute('COMMIT;');
    } catch (_) {
      _db.execute('ROLLBACK;');
      rethrow;
    }
  }

  @override
  void close() {
    _db.dispose();
  }
}

// ============================================================================
// 4. Pure Dart Audio Metadata Extractor
// ============================================================================

class ExtractedMetadata {
  const ExtractedMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.year,
    this.trackNumber,
    this.genre,
    this.bitrate,
    this.artworkBytes,
  });

  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int? year;
  final int? trackNumber;
  final String? genre;
  final int? bitrate;
  final Uint8List? artworkBytes;
}

class PureDartAudioMetadataReader {
  static Future<ExtractedMetadata> extract(File file) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 10) {
      throw const FormatException('File too short to be valid audio');
    }
    final ext = file.path.split('.').last.toLowerCase();
    final fallbackTitle = file.uri.pathSegments.last.replaceAll('.$ext', '');
    return extractBytes(bytes, fallbackTitle);
  }

  static ExtractedMetadata extractBytes(Uint8List bytes, String fallbackTitle) {
    if (bytes.length >= 10 && bytes[0] == 0x49 && bytes[1] == 0x44 && bytes[2] == 0x33) {
      return _parseId3v2(bytes, fallbackTitle);
    }
    if (bytes.length >= 44 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) {
      return _parseWav(bytes, fallbackTitle);
    }
    if (bytes.length >= 42 &&
        bytes[0] == 0x66 && bytes[1] == 0x4C && bytes[2] == 0x61 && bytes[3] == 0x43) {
      return _parseFlac(bytes, fallbackTitle);
    }
    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      duration: const Duration(seconds: 180),
      bitrate: 320,
    );
  }

  static ExtractedMetadata _parseId3v2(Uint8List bytes, String fallbackTitle) {
    var title = fallbackTitle;
    var artist = 'Unknown Artist';
    var album = 'Unknown Album';
    var duration = const Duration(seconds: 180);
    String? genre;
    int? year;
    int? trackNumber;
    Uint8List? artwork;

    try {
      final tagSize = ((bytes[6] & 0x7F) << 21) |
          ((bytes[7] & 0x7F) << 14) |
          ((bytes[8] & 0x7F) << 7) |
          (bytes[9] & 0x7F);

      var offset = 10;
      final maxOffset = (10 + tagSize).clamp(10, bytes.length);

      while (offset + 10 <= maxOffset) {
        if (bytes[offset] == 0) break; // Padding
        final frameId = ascii.decode(bytes.sublist(offset, offset + 4), allowInvalid: true);
        final frameSize = (bytes[offset + 4] << 24) |
            (bytes[offset + 5] << 16) |
            (bytes[offset + 6] << 8) |
            bytes[offset + 7];

        offset += 10;
        if (frameSize <= 0 || offset + frameSize > bytes.length) break;

        final frameData = bytes.sublist(offset, offset + frameSize);
        offset += frameSize;

        if (frameData.isEmpty) continue;
        final encoding = frameData[0];
        final textData = frameData.sublist(1);
        final text = (encoding == 0x03)
            ? utf8.decode(textData, allowMalformed: true).trim()
            : ascii.decode(textData, allowInvalid: true).trim();

        switch (frameId) {
          case 'TIT2':
            if (text.isNotEmpty) title = text;
            break;
          case 'TPE1':
            if (text.isNotEmpty) artist = text;
            break;
          case 'TALB':
            if (text.isNotEmpty) album = text;
            break;
          case 'TCON':
            if (text.isNotEmpty) genre = text;
            break;
          case 'TYER':
          case 'TDRC':
            year = int.tryParse(text);
            break;
          case 'TRCK':
            final clean = text.split('/').first;
            trackNumber = int.tryParse(clean);
            break;
          case 'TLEN':
            final ms = int.tryParse(text);
            if (ms != null) {
              duration = Duration(milliseconds: ms);
            }
            break;
          case 'APIC':
            if (frameData.length > 5) {
              artwork = frameData;
            }
            break;
        }
      }
    } catch (_) {
      // Return whatever was parsed
    }

    return ExtractedMetadata(
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      year: year,
      trackNumber: trackNumber,
      genre: genre,
      bitrate: 320,
      artworkBytes: artwork,
    );
  }

  static ExtractedMetadata _parseWav(Uint8List bytes, String fallbackTitle) {
    final byteRate = bytes[28] | (bytes[29] << 8) | (bytes[30] << 16) | (bytes[31] << 24);
    final dataSize = bytes.length - 44;
    final durationSeconds = byteRate > 0 ? (dataSize / byteRate).round() : 5;
    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'WAV Artist',
      album: 'WAV Album',
      duration: Duration(seconds: durationSeconds.clamp(1, 3600)),
      bitrate: (byteRate * 8) ~/ 1000,
    );
  }

  static ExtractedMetadata _parseFlac(Uint8List bytes, String fallbackTitle) {
    // Read sample rate & total samples from STREAMINFO
    final sampleRate = (bytes[18] << 12) | (bytes[19] << 4) | ((bytes[20] & 0xF0) >> 4);
    final totalSamples = ((bytes[21] & 0x0F) << 32) |
        (bytes[22] << 24) |
        (bytes[23] << 16) |
        (bytes[24] << 8) |
        bytes[25];
    final durationSeconds = sampleRate > 0 ? (totalSamples / sampleRate).round() : 10;

    return ExtractedMetadata(
      title: fallbackTitle,
      artist: 'FLAC Artist',
      album: 'FLAC Album',
      duration: Duration(seconds: durationSeconds.clamp(1, 7200)),
      bitrate: 1411,
    );
  }
}

// ============================================================================
// 5. Media Scanner Service & Implementation
// ============================================================================

abstract interface class IMediaScannerService {
  Stream<ScannerState> get stateStream;
  ScannerState get currentState;
  Future<Result<ScanResult, ScannerFailure>> scanDirectories(
    List<String> directoryPaths, {
    ScannerConfig? config,
  });
  void stopScan();
}

class TestMediaScannerService implements IMediaScannerService {
  TestMediaScannerService({required this.database})
      : _stateController = StreamController<ScannerState>.broadcast(),
        _state = const ScannerState();

  final IAppDatabase database;
  final StreamController<ScannerState> _stateController;
  ScannerState _state;
  bool _stopped = false;

  @override
  Stream<ScannerState> get stateStream => _stateController.stream;

  @override
  ScannerState get currentState => _state;

  void _updateState(ScannerState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  @override
  void stopScan() {
    _stopped = true;
  }

  @override
  Future<Result<ScanResult, ScannerFailure>> scanDirectories(
    List<String> directoryPaths, {
    ScannerConfig? config,
  }) async {
    _stopped = false;
    final effectiveConfig = config ?? const ScannerConfig();
    final stopwatch = Stopwatch()..start();

    _updateState(const ScannerState(status: ScannerStatus.scanning, progress: 0.0));

    final discoveredFiles = <File>[];
    final skippedFiles = <String>[];
    final errors = <String>[];

    // 1. Recursive Traversal with .nomedia pruning & whitelist filtering
    for (final dirPath in directoryPaths) {
      if (_stopped) break;
      final dir = Directory(dirPath);
      if (!dir.existsSync()) continue;

      _traverseDirectory(dir, effectiveConfig, discoveredFiles, skippedFiles);
    }

    final totalFound = discoveredFiles.length;
    _updateState(_state.copyWith(filesFound: totalFound));

    var insertedCount = 0;
    var scannedCount = 0;

    // 2. Batch Processing & Database Upsert
    database.transaction(() {
      for (var i = 0; i < totalFound; i++) {
        if (_stopped) break;
        final file = discoveredFiles[i];
        scannedCount++;

        _updateState(_state.copyWith(
          progress: totalFound > 0 ? scannedCount / totalFound : 1.0,
          filesScanned: scannedCount,
          currentFile: file.path,
        ));

        try {
          final fileSize = file.lengthSync();
          if (fileSize < effectiveConfig.minFileSizeBytes) {
            skippedFiles.add(file.path);
            continue;
          }

          final bytes = file.readAsBytesSync();
          final meta = PureDartAudioMetadataReader.extractBytes(
            bytes,
            file.uri.pathSegments.last.split('.').first,
          );

          if (meta.duration.inSeconds < effectiveConfig.minDurationSeconds) {
            skippedFiles.add(file.path);
            continue;
          }

          final trackId = 'trk_${file.path.hashCode.abs()}';
          final albumId = 'alb_${meta.album.hashCode.abs()}';
          final artistId = 'art_${meta.artist.hashCode.abs()}';
          final genreId = meta.genre != null ? 'gen_${meta.genre.hashCode.abs()}' : null;
          final dateAdded = DateTime.now().millisecondsSinceEpoch;

          // Upsert track
          database.execute('''
            INSERT INTO tracks (id, title, artist, album, duration_ms, file_path, track_number, year, genre, bitrate, file_size, date_added)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(file_path) DO UPDATE SET
              title = excluded.title,
              artist = excluded.artist,
              album = excluded.album,
              duration_ms = excluded.duration_ms,
              track_number = excluded.track_number,
              year = excluded.year,
              genre = excluded.genre,
              bitrate = excluded.bitrate,
              file_size = excluded.file_size;
          ''', [
            trackId,
            meta.title,
            meta.artist,
            meta.album,
            meta.duration.inMilliseconds,
            file.path,
            meta.trackNumber,
            meta.year,
            meta.genre,
            meta.bitrate,
            fileSize,
            dateAdded,
          ]);

          // Upsert album
          database.execute('''
            INSERT INTO albums (id, title, artist, year, track_count)
            VALUES (?, ?, ?, ?, 1)
            ON CONFLICT(id) DO UPDATE SET track_count = track_count + 1;
          ''', [albumId, meta.album, meta.artist, meta.year]);

          // Upsert artist
          database.execute('''
            INSERT INTO artists (id, name, track_count, album_count)
            VALUES (?, ?, 1, 1)
            ON CONFLICT(name) DO UPDATE SET track_count = track_count + 1;
          ''', [artistId, meta.artist]);

          // Upsert genre
          if (genreId != null && meta.genre != null) {
            database.execute('''
              INSERT INTO genres (id, name, track_count)
              VALUES (?, ?, 1)
              ON CONFLICT(name) DO UPDATE SET track_count = track_count + 1;
            ''', [genreId, meta.genre]);
          }

          insertedCount++;
        } catch (e) {
          errors.add('Failed to parse ${file.path}: $e');
        }
      }
    });

    stopwatch.stop();

    final result = ScanResult(
      scannedFilesCount: scannedCount,
      insertedTracksCount: insertedCount,
      skippedFilesCount: skippedFiles.length,
      duration: stopwatch.elapsed,
      errors: errors,
    );

    _updateState(_state.copyWith(
      status: ScannerStatus.completed,
      progress: 1.0,
      filesScanned: scannedCount,
    ));

    return Result.success(result);
  }

  void _traverseDirectory(
    Directory dir,
    ScannerConfig config,
    List<File> discovered,
    List<String> skipped,
  ) {
    if (config.skipNoMedia) {
      final noMedia = File('${dir.path}/.nomedia');
      if (noMedia.existsSync()) {
        skipped.add(dir.path);
        return; // Prune entire subtree immediately
      }
    }

    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is Directory) {
          _traverseDirectory(entity, config, discovered, skipped);
        } else if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (config.audioExtensionsWhitelist.contains(ext)) {
            discovered.add(entity);
          } else {
            skipped.add(entity.path);
          }
        }
      }
    } catch (_) {
      // Permission or I/O error
    }
  }

  void dispose() {
    _stateController.close();
  }
}

// ============================================================================
// 6. Domain Repository Interfaces & Concrete SQLite Implementations
// ============================================================================

abstract interface class ITracksRepository {
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  });
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id);
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId);
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId);
  Future<Result<void, DatabaseFailure>> insertTrack(Track track);
  Future<Result<void, DatabaseFailure>> insertTracks(List<Track> tracks);
}

abstract interface class IAlbumsRepository {
  Future<Result<List<Album>, DatabaseFailure>> getAllAlbums({
    AlbumSortBy sortBy = AlbumSortBy.title,
    bool ascending = true,
    String? searchQuery,
  });
  Future<Result<List<Track>, DatabaseFailure>> getTracksForAlbum(String albumId);
}

abstract interface class IArtistsRepository {
  Future<Result<List<Artist>, DatabaseFailure>> getAllArtists({
    ArtistSortBy sortBy = ArtistSortBy.name,
    bool ascending = true,
    String? searchQuery,
  });
  Future<Result<List<Track>, DatabaseFailure>> getTracksForArtist(String artistId);
}

abstract interface class IGenresRepository {
  Future<Result<List<Genre>, DatabaseFailure>> getAllGenres({String? searchQuery});
  Future<Result<List<Track>, DatabaseFailure>> getTracksForGenre(String genreId);
}

abstract interface class IPlaylistsRepository {
  Future<Result<List<Playlist>, DatabaseFailure>> getAllPlaylists();
  Future<Result<Playlist, DatabaseFailure>> createPlaylist(String name);
  Future<Result<void, DatabaseFailure>> deletePlaylist(String playlistId);
  Future<Result<void, DatabaseFailure>> addTrackToPlaylist(String playlistId, String trackId);
  Future<Result<void, DatabaseFailure>> removeTrackFromPlaylist(String playlistId, String trackId);
  Future<Result<List<Track>, DatabaseFailure>> getTracksForPlaylist(String playlistId);
}

class TestTracksRepository implements ITracksRepository {
  TestTracksRepository(this.database);
  final IAppDatabase database;

  @override
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async {
    try {
      final orderClause = switch (sortBy) {
        TrackSortBy.title => 'title COLLATE NOCASE',
        TrackSortBy.artist => 'artist COLLATE NOCASE',
        TrackSortBy.dateAdded => 'date_added',
        TrackSortBy.duration => 'duration_ms',
      };
      final dir = ascending ? 'ASC' : 'DESC';

      String sql = 'SELECT * FROM tracks';
      final params = <Object?>[];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE title LIKE ? OR artist LIKE ? OR album LIKE ?';
        final queryParam = '%${searchQuery.trim()}%';
        params.addAll([queryParam, queryParam, queryParam]);
      }

      sql += ' ORDER BY $orderClause $dir';

      final rows = database.select(sql, params);
      final tracks = rows.map(_rowToTrack).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id) async {
    try {
      final rows = database.select('SELECT * FROM tracks WHERE id = ?', [id]);
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(_rowToTrack(rows.first));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId) async {
    try {
      database.execute('''
        UPDATE tracks SET is_favorite = CASE WHEN is_favorite = 1 THEN 0 ELSE 1 END
        WHERE id = ?;
      ''', [trackId]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId) async {
    try {
      database.execute('DELETE FROM tracks WHERE id = ?;', [trackId]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> insertTrack(Track track) async {
    return insertTracks([track]);
  }

  @override
  Future<Result<void, DatabaseFailure>> insertTracks(List<Track> tracks) async {
    try {
      database.transaction(() {
        for (final track in tracks) {
          database.execute('''
            INSERT INTO tracks (id, title, artist, album, duration_ms, file_path, track_number, year, genre, is_favorite, date_added)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(file_path) DO UPDATE SET
              title = excluded.title,
              artist = excluded.artist,
              album = excluded.album,
              duration_ms = excluded.duration_ms;
          ''', [
            track.id,
            track.title,
            track.artist,
            track.album,
            track.duration.inMilliseconds,
            track.filePath ?? '/mock/${track.id}.mp3',
            track.trackNumber,
            track.year,
            track.genre,
            track.isFavorite ? 1 : 0,
            DateTime.now().millisecondsSinceEpoch,
          ]);
        }
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  Track _rowToTrack(sq.Row row) {
    return Track(
      id: row['id'] as String,
      title: row['title'] as String,
      artist: row['artist'] as String,
      album: (row['album'] as String?) ?? '',
      duration: Duration(milliseconds: row['duration_ms'] as int),
      artworkUri: row['artwork_uri'] as String?,
      filePath: row['file_path'] as String?,
      trackNumber: row['track_number'] as int?,
      discNumber: row['disc_number'] as int?,
      year: row['year'] as int?,
      genre: row['genre'] as String?,
      isFavorite: (row['is_favorite'] as int) == 1,
      playCount: (row['play_count'] as int?) ?? 0,
      bitrate: row['bitrate'] as int?,
      fileSize: row['file_size'] as int?,
    );
  }
}

class TestAlbumsRepository implements IAlbumsRepository {
  TestAlbumsRepository(this.database);
  final IAppDatabase database;

  @override
  Future<Result<List<Album>, DatabaseFailure>> getAllAlbums({
    AlbumSortBy sortBy = AlbumSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async {
    try {
      final orderClause = switch (sortBy) {
        AlbumSortBy.title => 'title COLLATE NOCASE',
        AlbumSortBy.artist => 'artist COLLATE NOCASE',
        AlbumSortBy.year => 'year',
      };
      final dir = ascending ? 'ASC' : 'DESC';

      String sql = 'SELECT * FROM albums';
      final params = <Object?>[];
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE title LIKE ? OR artist LIKE ?';
        final q = '%${searchQuery.trim()}%';
        params.addAll([q, q]);
      }
      sql += ' ORDER BY $orderClause $dir';

      final rows = database.select(sql, params);
      final albums = rows.map((r) => Album(
        id: r['id'] as String,
        title: r['title'] as String,
        artist: r['artist'] as String,
        artworkUri: r['artwork_uri'] as String?,
        year: r['year'] as int?,
        trackCount: (r['track_count'] as int?) ?? 0,
      )).toList();
      return Result.success(albums);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForAlbum(String albumId) async {
    try {
      final albumRows = database.select('SELECT title FROM albums WHERE id = ?', [albumId]);
      if (albumRows.isEmpty) return const Result.success([]);
      final albumTitle = albumRows.first['title'] as String;

      final rows = database.select(
        'SELECT * FROM tracks WHERE album = ? ORDER BY track_number ASC, title ASC',
        [albumTitle],
      );
      final tracks = rows.map((row) => Track(
        id: row['id'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String,
        album: (row['album'] as String?) ?? '',
        duration: Duration(milliseconds: row['duration_ms'] as int),
        trackNumber: row['track_number'] as int?,
        year: row['year'] as int?,
      )).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }
}

class TestArtistsRepository implements IArtistsRepository {
  TestArtistsRepository(this.database);
  final IAppDatabase database;

  @override
  Future<Result<List<Artist>, DatabaseFailure>> getAllArtists({
    ArtistSortBy sortBy = ArtistSortBy.name,
    bool ascending = true,
    String? searchQuery,
  }) async {
    try {
      final orderClause = switch (sortBy) {
        ArtistSortBy.name => 'name COLLATE NOCASE',
        ArtistSortBy.trackCount => 'track_count',
      };
      final dir = ascending ? 'ASC' : 'DESC';

      String sql = 'SELECT * FROM artists';
      final params = <Object?>[];
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE name LIKE ?';
        params.add('%${searchQuery.trim()}%');
      }
      sql += ' ORDER BY $orderClause $dir';

      final rows = database.select(sql, params);
      final artists = rows.map((r) => Artist(
        id: r['id'] as String,
        name: r['name'] as String,
        trackCount: (r['track_count'] as int?) ?? 0,
        albumCount: (r['album_count'] as int?) ?? 0,
      )).toList();
      return Result.success(artists);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForArtist(String artistId) async {
    try {
      final artistRows = database.select('SELECT name FROM artists WHERE id = ?', [artistId]);
      if (artistRows.isEmpty) return const Result.success([]);
      final artistName = artistRows.first['name'] as String;

      final rows = database.select(
        'SELECT * FROM tracks WHERE artist = ? ORDER BY title ASC',
        [artistName],
      );
      final tracks = rows.map((row) => Track(
        id: row['id'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String,
        album: (row['album'] as String?) ?? '',
        duration: Duration(milliseconds: row['duration_ms'] as int),
      )).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }
}

class TestGenresRepository implements IGenresRepository {
  TestGenresRepository(this.database);
  final IAppDatabase database;

  @override
  Future<Result<List<Genre>, DatabaseFailure>> getAllGenres({String? searchQuery}) async {
    try {
      String sql = 'SELECT * FROM genres';
      final params = <Object?>[];
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE name LIKE ?';
        params.add('%${searchQuery.trim()}%');
      }
      sql += ' ORDER BY name COLLATE NOCASE ASC';

      final rows = database.select(sql, params);
      final genres = rows.map((r) => Genre(
        id: r['id'] as String,
        name: r['name'] as String,
        trackCount: (r['track_count'] as int?) ?? 0,
      )).toList();
      return Result.success(genres);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForGenre(String genreId) async {
    try {
      final genreRows = database.select('SELECT name FROM genres WHERE id = ?', [genreId]);
      if (genreRows.isEmpty) return const Result.success([]);
      final genreName = genreRows.first['name'] as String;

      final rows = database.select(
        'SELECT * FROM tracks WHERE genre = ? ORDER BY title ASC',
        [genreName],
      );
      final tracks = rows.map((row) => Track(
        id: row['id'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String,
        album: (row['album'] as String?) ?? '',
        duration: Duration(milliseconds: row['duration_ms'] as int),
      )).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }
}

class TestPlaylistsRepository implements IPlaylistsRepository {
  TestPlaylistsRepository(this.database);
  final IAppDatabase database;

  @override
  Future<Result<List<Playlist>, DatabaseFailure>> getAllPlaylists() async {
    try {
      final rows = database.select('SELECT * FROM playlists ORDER BY name COLLATE NOCASE ASC');
      final playlists = rows.map((r) => Playlist(
        id: r['id'] as String,
        name: r['name'] as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int),
        trackCount: (r['track_count'] as int?) ?? 0,
      )).toList();
      return Result.success(playlists);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<Playlist, DatabaseFailure>> createPlaylist(String name) async {
    try {
      final id = 'pl_${DateTime.now().microsecondsSinceEpoch}';
      final now = DateTime.now();
      database.execute('''
        INSERT INTO playlists (id, name, created_at, track_count)
        VALUES (?, ?, ?, 0);
      ''', [id, name, now.millisecondsSinceEpoch]);
      return Result.success(Playlist(id: id, name: name, createdAt: now, trackCount: 0));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> deletePlaylist(String playlistId) async {
    try {
      database.execute('DELETE FROM playlists WHERE id = ?;', [playlistId]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> addTrackToPlaylist(String playlistId, String trackId) async {
    try {
      database.transaction(() {
        final countRows = database.select(
          'SELECT COUNT(*) as count FROM playlist_tracks WHERE playlist_id = ?',
          [playlistId],
        );
        final nextOrder = (countRows.first['count'] as int) + 1;
        final ptId = 'pt_${DateTime.now().microsecondsSinceEpoch}';

        database.execute('''
          INSERT INTO playlist_tracks (id, playlist_id, track_id, sort_order, added_at)
          VALUES (?, ?, ?, ?, ?);
        ''', [ptId, playlistId, trackId, nextOrder, DateTime.now().millisecondsSinceEpoch]);

        database.execute('''
          UPDATE playlists SET track_count = track_count + 1 WHERE id = ?;
        ''', [playlistId]);
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> removeTrackFromPlaylist(String playlistId, String trackId) async {
    try {
      database.transaction(() {
        database.execute('''
          DELETE FROM playlist_tracks WHERE playlist_id = ? AND track_id = ?;
        ''', [playlistId, trackId]);

        database.execute('''
          UPDATE playlists SET track_count = (
            SELECT COUNT(*) FROM playlist_tracks WHERE playlist_id = ?
          ) WHERE id = ?;
        ''', [playlistId, playlistId]);
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForPlaylist(String playlistId) async {
    try {
      final rows = database.select('''
        SELECT t.* FROM tracks t
        INNER JOIN playlist_tracks pt ON t.id = pt.track_id
        WHERE pt.playlist_id = ?
        ORDER BY pt.sort_order ASC;
      ''', [playlistId]);

      final tracks = rows.map((row) => Track(
        id: row['id'] as String,
        title: row['title'] as String,
        artist: row['artist'] as String,
        album: (row['album'] as String?) ?? '',
        duration: Duration(milliseconds: row['duration_ms'] as int),
        trackNumber: row['track_number'] as int?,
        year: row['year'] as int?,
      )).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(e.toString(), e, st));
    }
  }
}

// ============================================================================
// 7. Nexa Phase 2 Interactive Test App
// ============================================================================

class NexaPhase2TestApp extends StatefulWidget {
  const NexaPhase2TestApp({
    super.key,
    required this.database,
    required this.scannerService,
    required this.tracksRepo,
    required this.albumsRepo,
    required this.artistsRepo,
    required this.genresRepo,
    required this.playlistsRepo,
    this.initialTab = 0,
  });

  final IAppDatabase database;
  final IMediaScannerService scannerService;
  final ITracksRepository tracksRepo;
  final IAlbumsRepository albumsRepo;
  final IArtistsRepository artistsRepo;
  final IGenresRepository genresRepo;
  final IPlaylistsRepository playlistsRepo;
  final int initialTab;

  @override
  State<NexaPhase2TestApp> createState() => NexaPhase2TestAppState();
}

class NexaPhase2TestAppState extends State<NexaPhase2TestApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late int _currentTab;
  String? _selectedAlbumId;
  String? _selectedArtistId;

  // Search & Filter State
  final _searchController = TextEditingController();
  TrackSortBy _sortBy = TrackSortBy.title;
  bool _sortAsc = true;

  // Scanner Settings State
  final List<String> _scanDirectories = [];
  bool _skipShortFiles = true;
  double _minDuration = 5.0;

  // Cached data lists
  List<Track> _tracks = [];
  List<Album> _albums = [];
  List<Artist> _artists = [];
  List<Playlist> _playlists = [];
  List<Track> _subTracks = [];

  StreamSubscription<ScannerState>? _scannerSub;
  ScannerState _scannerState = const ScannerState();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _scannerSub = widget.scannerService.stateStream.listen((state) {
      setState(() {
        _scannerState = state;
      });
      if (state.status == ScannerStatus.completed) {
        refreshAll();
      }
    });
    refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scannerSub?.cancel();
    super.dispose();
  }

  Future<void> refreshAll() async {
    final trks = await widget.tracksRepo.getAllTracks(
      sortBy: _sortBy,
      ascending: _sortAsc,
      searchQuery: _searchController.text,
    );
    final albs = await widget.albumsRepo.getAllAlbums();
    final arts = await widget.artistsRepo.getAllArtists();
    final pls = await widget.playlistsRepo.getAllPlaylists();

    setState(() {
      _tracks = trks.valueOrNull ?? [];
      _albums = albs.valueOrNull ?? [];
      _artists = arts.valueOrNull ?? [];
      _playlists = pls.valueOrNull ?? [];
    });
  }

  void selectTab(int index) {
    setState(() {
      _currentTab = index;
      _selectedAlbumId = null;
      _selectedArtistId = null;
    });
    refreshAll();
  }

  void addScanDirectory(String path) {
    setState(() {
      if (!_scanDirectories.contains(path)) {
        _scanDirectories.add(path);
      }
    });
  }

  void removeScanDirectory(String path) {
    setState(() {
      _scanDirectories.remove(path);
    });
  }

  Future<void> triggerRescan() async {
    await widget.scannerService.scanDirectories(
      _scanDirectories,
      config: ScannerConfig(
        minDurationSeconds: _skipShortFiles ? _minDuration.round() : 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF0B0F19),
        ),
      ),
      home: Scaffold(
        body: _selectedAlbumId != null
            ? _buildAlbumDetailScreen()
            : _selectedArtistId != null
                ? _buildArtistDetailScreen()
                : _buildTabBody(),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentTab,
          onDestinationSelected: selectTab,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.music_note), label: 'Songs'),
            NavigationDestination(icon: Icon(Icons.album), label: 'Albums'),
            NavigationDestination(icon: Icon(Icons.person), label: 'Artists'),
            NavigationDestination(icon: Icon(Icons.playlist_play), label: 'Playlists'),
            NavigationDestination(icon: Icon(Icons.folder), label: 'Folders'),
            NavigationDestination(icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_currentTab) {
      case 0:
        return _buildSongsScreen();
      case 1:
        return _buildAlbumsScreen();
      case 2:
        return _buildArtistsScreen();
      case 3:
        return _buildPlaylistsScreen();
      case 4:
        return _buildFoldersScreen();
      case 5:
        return _buildScannerSettingsScreen();
      default:
        return _buildSongsScreen();
    }
  }

  // --- 1. All Songs Screen ---
  Widget _buildSongsScreen() {
    return Scaffold(
      appBar: GlassAppBar(
        titleText: 'Songs',
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<TrackSortBy>(
            key: E2EPhase2Keys.sortButton,
            icon: const Icon(Icons.sort_rounded),
            onSelected: (sort) {
              setState(() {
                if (_sortBy == sort) {
                  _sortAsc = !_sortAsc;
                } else {
                  _sortBy = sort;
                  _sortAsc = true;
                }
              });
              refreshAll();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                key: E2EPhase2Keys.sortMenuTitle,
                value: TrackSortBy.title,
                child: Text('Sort by Title'),
              ),
              const PopupMenuItem(
                key: E2EPhase2Keys.sortMenuArtist,
                value: TrackSortBy.artist,
                child: Text('Sort by Artist'),
              ),
              const PopupMenuItem(
                key: E2EPhase2Keys.sortMenuDuration,
                value: TrackSortBy.duration,
                child: Text('Sort by Duration'),
              ),
              const PopupMenuItem(
                key: E2EPhase2Keys.sortMenuDateAdded,
                value: TrackSortBy.dateAdded,
                child: Text('Sort by Date Added'),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        key: E2EPhase2Keys.allSongsList,
        padding: const EdgeInsets.all(16.0),
        children: [
          GlassTextField(
            key: E2EPhase2Keys.searchField,
            controller: _searchController,
            hintText: 'Search songs, artists, albums...',
            prefixIcon: Icons.search,
            onChanged: (_) => refreshAll(),
          ),
          const SizedBox(height: 16),
          Text(
            'All Songs (${_tracks.length})',
            key: E2EPhase2Keys.songCountHeader,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._tracks.map((track) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: TrackTile(
                  key: E2EPhase2Keys.trackTile(track.id),
                  title: track.title,
                  artist: track.artist,
                  duration: track.duration,
                  isFavorite: track.isFavorite,
                  trailing: IconButton(
                    key: E2EPhase2Keys.trackFavoriteToggle(track.id),
                    icon: Icon(
                      track.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: track.isFavorite ? Colors.redAccent : Colors.grey,
                    ),
                    onPressed: () async {
                      await widget.tracksRepo.toggleFavorite(track.id);
                      refreshAll();
                    },
                  ),
                ),
              )),
        ],
      ),
    );
  }

  // --- 2. Albums Screen & Detail ---
  Widget _buildAlbumsScreen() {
    return Scaffold(
      appBar: const GlassAppBar(titleText: 'Albums', automaticallyImplyLeading: false),
      body: GridView.builder(
        key: E2EPhase2Keys.albumsGrid,
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: _albums.length,
        itemBuilder: (context, index) {
          final album = _albums[index];
          return AlbumCard(
            key: E2EPhase2Keys.albumCard(album.id),
            title: album.title,
            artist: album.artist,
            onTap: () async {
              final trks = await widget.albumsRepo.getTracksForAlbum(album.id);
              setState(() {
                _selectedAlbumId = album.id;
                _subTracks = trks.valueOrNull ?? [];
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildAlbumDetailScreen() {
    final album = _albums.firstWhere((a) => a.id == _selectedAlbumId);
    return Scaffold(
      key: E2EPhase2Keys.albumDetailScreen,
      appBar: AppBar(
        title: Text(album.title),
        leading: IconButton(
          key: E2EPhase2Keys.albumDetailBackButton,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedAlbumId = null),
        ),
      ),
      body: ListView(
        key: E2EPhase2Keys.albumDetailTrackList,
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('${album.artist} • ${album.year ?? ''} • ${_subTracks.length} tracks'),
          const SizedBox(height: 16),
          ..._subTracks.map((t) => ListTile(
                title: Text(t.title),
                subtitle: Text(t.artist),
                trailing: Text('${t.duration.inMinutes}:${(t.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
              )),
        ],
      ),
    );
  }

  // --- 3. Artists Screen & Detail ---
  Widget _buildArtistsScreen() {
    return Scaffold(
      appBar: const GlassAppBar(titleText: 'Artists', automaticallyImplyLeading: false),
      body: ListView.builder(
        key: E2EPhase2Keys.artistsList,
        padding: const EdgeInsets.all(16.0),
        itemCount: _artists.length,
        itemBuilder: (context, index) {
          final artist = _artists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ArtistCard(
              key: E2EPhase2Keys.artistCard(artist.id),
              name: artist.name,
              trackCount: artist.trackCount,
              onTap: () async {
                final trks = await widget.artistsRepo.getTracksForArtist(artist.id);
                setState(() {
                  _selectedArtistId = artist.id;
                  _subTracks = trks.valueOrNull ?? [];
                });
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildArtistDetailScreen() {
    final artist = _artists.firstWhere((a) => a.id == _selectedArtistId);
    return Scaffold(
      key: E2EPhase2Keys.artistDetailScreen,
      appBar: AppBar(
        title: Text(artist.name),
        leading: IconButton(
          key: E2EPhase2Keys.artistDetailBackButton,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => setState(() => _selectedArtistId = null),
        ),
      ),
      body: ListView(
        key: E2EPhase2Keys.artistDetailTrackList,
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('${artist.name} • ${_subTracks.length} tracks'),
          const SizedBox(height: 16),
          ..._subTracks.map((t) => ListTile(
                title: Text(t.title),
                subtitle: Text(t.album),
                trailing: Text('${t.duration.inMinutes}:${(t.duration.inSeconds % 60).toString().padLeft(2, '0')}'),
              )),
        ],
      ),
    );
  }

  // --- 4. Playlists Screen ---
  Widget _buildPlaylistsScreen() {
    return Scaffold(
      appBar: const GlassAppBar(titleText: 'Playlists', automaticallyImplyLeading: false),
      floatingActionButton: GlassFAB(
        key: E2EPhase2Keys.createPlaylistFab,
        icon: const Icon(Icons.add),
        label: const Text('New Playlist'),
        onPressed: _showCreatePlaylistDialog,
      ),
      body: ListView.builder(
        key: E2EPhase2Keys.playlistsList,
        padding: const EdgeInsets.all(16.0),
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          final pl = _playlists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: GlassCard(
              key: E2EPhase2Keys.playlistItem(pl.id),
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.playlist_play, size: 36, color: Color(0xFF00E5FF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pl.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('${pl.trackCount} tracks', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    key: E2EPhase2Keys.playlistDeleteButton(pl.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      await widget.playlistsRepo.deletePlaylist(pl.id);
                      refreshAll();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (dialogCtx) => AlertDialog(
        key: E2EPhase2Keys.createPlaylistDialog,
        title: const Text('Create Playlist'),
        content: TextField(
          key: E2EPhase2Keys.playlistNameInput,
          controller: controller,
          decoration: const InputDecoration(hintText: 'Playlist Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            key: E2EPhase2Keys.playlistConfirmCreate,
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await widget.playlistsRepo.createPlaylist(controller.text.trim());
                Navigator.pop(dialogCtx);
                refreshAll();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // --- 5. Folders Screen ---
  Widget _buildFoldersScreen() {
    return Scaffold(
      appBar: const GlassAppBar(titleText: 'Folders Tree', automaticallyImplyLeading: false),
      body: ListView(
        key: E2EPhase2Keys.foldersTreeView,
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Scan Roots & Hierarchies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          ..._scanDirectories.map((dir) => ListTile(
                key: E2EPhase2Keys.folderNode(dir),
                leading: const Icon(Icons.folder, color: Color(0xFF00E5FF)),
                title: Text(dir),
                subtitle: const Text('Active Music Folder'),
              )),
          if (_scanDirectories.isEmpty)
            const Text('No scan directories configured. Add music folders in Settings.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  // --- 6. Scanner Settings Screen ---
  Widget _buildScannerSettingsScreen() {
    return Scaffold(
      key: E2EPhase2Keys.scannerSettingsScreen,
      appBar: const GlassAppBar(titleText: 'Scanner Settings', automaticallyImplyLeading: false),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text('Scan Directories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Column(
            key: E2EPhase2Keys.scannerFolderList,
            children: _scanDirectories.map((d) => ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(d),
              trailing: IconButton(
                key: E2EPhase2Keys.removeFolderButton(d),
                icon: const Icon(Icons.close, color: Colors.redAccent),
                onPressed: () => removeScanDirectory(d),
              ),
            )).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  key: E2EPhase2Keys.addFolderButton,
                  label: 'Add Folder',
                  icon: Icons.add,
                  onPressed: _showAddFolderDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassButton(
                  key: E2EPhase2Keys.rescanButton,
                  label: 'Rescan Library',
                  icon: Icons.refresh,
                  onPressed: triggerRescan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Scan Progress', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            key: E2EPhase2Keys.scannerProgressBar,
            value: _scannerState.progress,
            backgroundColor: Colors.white12,
            valueColor: const AlwaysStoppedAnimation(Color(0xFF00E5FF)),
          ),
          const SizedBox(height: 8),
          Text(
            'Status: ${_scannerState.status.name} (${_scannerState.filesScanned} / ${_scannerState.filesFound} files)',
            key: E2EPhase2Keys.scannerStatusText,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text('Skip Rules Customization', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          SwitchListTile(
            key: E2EPhase2Keys.skipShortFilesSwitch,
            title: const Text('Skip Short Audio Files (< min duration)'),
            value: _skipShortFiles,
            onChanged: (val) => setState(() => _skipShortFiles = val),
          ),
          Text('Minimum Duration: ${_minDuration.toInt()} seconds'),
          Slider(
            key: E2EPhase2Keys.minDurationSlider,
            value: _minDuration,
            min: 1.0,
            max: 30.0,
            divisions: 29,
            onChanged: (val) => setState(() => _minDuration = val),
          ),
        ],
      ),
    );
  }

  void _showAddFolderDialog() {
    final controller = TextEditingController();
    showDialog<void>(
      context: navigatorKey.currentContext!,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Music Folder'),
        content: TextField(
          key: E2EPhase2Keys.addFolderPathInput,
          controller: controller,
          decoration: const InputDecoration(hintText: '/path/to/music'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          ElevatedButton(
            key: E2EPhase2Keys.addFolderConfirmButton,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                addScanDirectory(controller.text.trim());
                Navigator.pop(dialogCtx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
