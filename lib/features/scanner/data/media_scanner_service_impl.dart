import 'dart:async';
import 'dart:io';

import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// Production implementation of [IMediaScannerService].
///
/// Recursively scans designated storage folders, extracts audio metadata,
/// and synchronizes the local SQLite database within an atomic transaction.
class MediaScannerServiceImpl implements IMediaScannerService {
  MediaScannerServiceImpl({
    required this.database,
    required this.metadataReader,
  })  : _stateController = StreamController<ScannerState>.broadcast(),
        _state = const ScannerState();

  final IAppDatabase database;
  final IAudioMetadataReader metadataReader;
  final StreamController<ScannerState> _stateController;
  ScannerState _state;
  bool _stopped = false;

  @override
  Stream<ScannerState> get stateStream => _stateController.stream;

  @override
  ScannerState get currentState => _state;

  void _updateState(ScannerState newState) {
    _state = newState;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
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

    _updateState(const ScannerState(
      status: ScannerStatus.scanning,
      progress: 0.0,
      filesScanned: 0,
      filesFound: 0,
    ));

    final discoveredFiles = <File>[];
    final skippedFiles = <String>[];
    final errors = <String>[];

    try {
      // 1. Recursive Directory Traversal with .nomedia pruning & whitelist filtering
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

      // 2. Batch Processing & Database Upsert within an atomic transaction
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
            if (effectiveConfig.skipSmallFiles &&
                fileSize < effectiveConfig.minSizeBytes) {
              skippedFiles.add(file.path);
              continue;
            }

            final bytes = file.readAsBytesSync();
            final fallbackTitle =
                file.uri.pathSegments.last.split('.').first;
            final meta = metadataReader.extractBytes(bytes, fallbackTitle);

            if (effectiveConfig.skipShortAudio &&
                meta.duration.inSeconds < effectiveConfig.minDurationSeconds) {
              skippedFiles.add(file.path);
              continue;
            }

            final trackId = 'trk_${file.path.hashCode.abs()}';
            final artistId = 'art_${meta.artist.hashCode.abs()}';
            final albumKey = '${meta.album}__${meta.artist}';
            final albumId = 'alb_${albumKey.hashCode.abs()}';
            final genreId = meta.genre != null && meta.genre!.isNotEmpty
                ? 'gen_${meta.genre.hashCode.abs()}'
                : null;
            final nowMs = DateTime.now().millisecondsSinceEpoch;

            // 2a. Upsert Artist
            database.execute('''
              INSERT INTO ${DatabaseSchema.tableArtists} (
                ${DatabaseSchema.colId},
                ${DatabaseSchema.colName},
                ${DatabaseSchema.colTrackCount},
                ${DatabaseSchema.colAlbumCount}
              ) VALUES (?, ?, 1, 1)
              ON CONFLICT(${DatabaseSchema.colName}) DO UPDATE SET
                ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1;
            ''', [artistId, meta.artist]);

            // 2b. Upsert Album
            database.execute('''
              INSERT INTO ${DatabaseSchema.tableAlbums} (
                ${DatabaseSchema.colId},
                ${DatabaseSchema.colTitle},
                ${DatabaseSchema.colAlbumArtist},
                ${DatabaseSchema.colArtistId},
                ${DatabaseSchema.colAlbumYear},
                ${DatabaseSchema.colTrackCount},
                ${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colDateAdded}
              ) VALUES (?, ?, ?, ?, ?, 1, ?, ?)
              ON CONFLICT(${DatabaseSchema.colTitle}, ${DatabaseSchema.colAlbumArtist}) DO UPDATE SET
                ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1,
                ${DatabaseSchema.colDurationMs} = ${DatabaseSchema.colDurationMs} + excluded.${DatabaseSchema.colDurationMs};
            ''', [
              albumId,
              meta.album,
              meta.artist,
              artistId,
              meta.year,
              meta.duration.inMilliseconds,
              nowMs,
            ]);

            // 2c. Upsert Genre (if present)
            if (genreId != null && meta.genre != null) {
              database.execute('''
                INSERT INTO ${DatabaseSchema.tableGenres} (
                  ${DatabaseSchema.colId},
                  ${DatabaseSchema.colName},
                  ${DatabaseSchema.colTrackCount}
                ) VALUES (?, ?, 1)
                ON CONFLICT(${DatabaseSchema.colName}) DO UPDATE SET
                  ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1;
              ''', [genreId, meta.genre]);
            }

            // 2d. Upsert Track
            database.execute('''
              INSERT INTO ${DatabaseSchema.tableTracks} (
                ${DatabaseSchema.colId},
                ${DatabaseSchema.colTitle},
                ${DatabaseSchema.colTrackArtist},
                ${DatabaseSchema.colTrackAlbum},
                ${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colTrackFilePath},
                ${DatabaseSchema.colTrackNumber},
                ${DatabaseSchema.colDiscNumber},
                ${DatabaseSchema.colTrackYear},
                ${DatabaseSchema.colTrackGenre},
                ${DatabaseSchema.colBitrate},
                ${DatabaseSchema.colFileSize},
                ${DatabaseSchema.colDateAdded},
                ${DatabaseSchema.colArtistId},
                ${DatabaseSchema.colAlbumId},
                ${DatabaseSchema.colGenreId}
              ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ON CONFLICT(${DatabaseSchema.colTrackFilePath}) DO UPDATE SET
                ${DatabaseSchema.colTitle} = excluded.${DatabaseSchema.colTitle},
                ${DatabaseSchema.colTrackArtist} = excluded.${DatabaseSchema.colTrackArtist},
                ${DatabaseSchema.colTrackAlbum} = excluded.${DatabaseSchema.colTrackAlbum},
                ${DatabaseSchema.colDurationMs} = excluded.${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colTrackNumber} = excluded.${DatabaseSchema.colTrackNumber},
                ${DatabaseSchema.colDiscNumber} = excluded.${DatabaseSchema.colDiscNumber},
                ${DatabaseSchema.colTrackYear} = excluded.${DatabaseSchema.colTrackYear},
                ${DatabaseSchema.colTrackGenre} = excluded.${DatabaseSchema.colTrackGenre},
                ${DatabaseSchema.colBitrate} = excluded.${DatabaseSchema.colBitrate},
                ${DatabaseSchema.colFileSize} = excluded.${DatabaseSchema.colFileSize},
                ${DatabaseSchema.colArtistId} = excluded.${DatabaseSchema.colArtistId},
                ${DatabaseSchema.colAlbumId} = excluded.${DatabaseSchema.colAlbumId},
                ${DatabaseSchema.colGenreId} = excluded.${DatabaseSchema.colGenreId};
            ''', [
              trackId,
              meta.title,
              meta.artist,
              meta.album,
              meta.duration.inMilliseconds,
              file.path,
              meta.trackNumber,
              meta.discNumber,
              meta.year,
              meta.genre,
              meta.bitrate,
              fileSize,
              nowMs,
              artistId,
              albumId,
              genreId,
            ]);

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
    } catch (e, st) {
      _updateState(_state.copyWith(
        status: ScannerStatus.error,
        errorMessage: e.toString(),
      ));
      return Result.failure(ScannerFailure(
        'Scanner failure: $e',
        e,
        st,
      ));
    }
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
        return; // Skip entire folder and descendants
      }
    }

    try {
      final entities = dir.listSync(followLinks: false);
      for (final entity in entities) {
        if (entity is Directory) {
          _traverseDirectory(entity, config, discovered, skipped);
        } else if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (config.isExtensionSupported(ext)) {
            discovered.add(entity);
          } else {
            skipped.add(entity.path);
          }
        }
      }
    } catch (_) {
      // Unreadable or permission restricted directory
    }
  }

  void dispose() {
    _stateController.close();
  }
}
