import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// Prepared scan entry parsed off the synchronous SQLite transaction.
class _PreparedScanItem {
  const _PreparedScanItem({
    required this.file,
    required this.fileSize,
    required this.meta,
    this.artworkUri,
  });

  final File file;
  final int fileSize;
  final ExtractedMetadata meta;
  final String? artworkUri;
}

/// Production implementation of [IMediaScannerService].
///
/// Recursively scans designated storage folders, extracts audio metadata & artwork,
/// and synchronizes the local SQLite database within an atomic transaction.
class MediaScannerServiceImpl implements IMediaScannerService {
  MediaScannerServiceImpl({
    required this.database,
    required this.metadataReader,
    this.artworkService,
  })  : _stateController = StreamController<ScannerState>.broadcast(),
        _state = const ScannerState();

  final IAppDatabase database;
  final IAudioMetadataReader metadataReader;
  final IArtworkResolutionService? artworkService;
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
      // 1. Android MediaStore Fast Indexer (discovering both internal storage & MicroSD)
      if (!kIsWeb && Platform.isAndroid) {
        try {
          final List<dynamic>? mediaStoreResults = await const MethodChannel('com.nexa.player/media_store')
              .invokeMethod<List<dynamic>>('queryMediaStoreAudio');
          if (mediaStoreResults != null && mediaStoreResults.isNotEmpty) {
            database.transaction(() {
              for (final item in mediaStoreResults) {
                if (item is Map) {
                  final filePath = item['file_path'] as String? ?? '';
                  if (filePath.isEmpty) continue;
                  final title = item['title'] as String? ?? 'Unknown Title';
                  final artist = item['artist'] as String? ?? 'Unknown Artist';
                  final album = item['album'] as String? ?? 'Unknown Album';
                  final durationMs = (item['duration_ms'] as num?)?.toInt() ?? 0;
                  final trackNumber = (item['track_number'] as num?)?.toInt() ?? 0;
                  final year = (item['year'] as num?)?.toInt() ?? 0;
                  final fileSize = (item['file_size'] as num?)?.toInt() ?? 0;
                  final trackId = 'trk_${filePath.hashCode.abs()}';
                  final artistId = 'art_${artist.hashCode.abs()}';
                  final albumKey = '${album}__$artist';
                  final albumId = 'alb_${albumKey.hashCode.abs()}';
                  final nowMs = DateTime.now().millisecondsSinceEpoch;

                  database.execute('''
                    INSERT INTO ${DatabaseSchema.tableArtists} (
                      ${DatabaseSchema.colId}, ${DatabaseSchema.colName}, ${DatabaseSchema.colTrackCount}, ${DatabaseSchema.colAlbumCount}
                    ) VALUES (?, ?, 1, 1)
                    ON CONFLICT(${DatabaseSchema.colName}) DO UPDATE SET
                      ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1;
                  ''', [artistId, artist]);

                  database.execute('''
                    INSERT INTO ${DatabaseSchema.tableAlbums} (
                      ${DatabaseSchema.colId}, ${DatabaseSchema.colTitle}, ${DatabaseSchema.colAlbumArtist},
                      ${DatabaseSchema.colAlbumYear}, ${DatabaseSchema.colTrackCount}
                    ) VALUES (?, ?, ?, ?, 1)
                    ON CONFLICT(${DatabaseSchema.colTitle}, ${DatabaseSchema.colAlbumArtist}) DO UPDATE SET
                      ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1;
                  ''', [albumId, album, artist, year]);

                  database.execute('''
                    INSERT INTO ${DatabaseSchema.tableTracks} (
                      ${DatabaseSchema.colId}, ${DatabaseSchema.colTitle}, ${DatabaseSchema.colTrackArtist},
                      ${DatabaseSchema.colTrackAlbum}, ${DatabaseSchema.colDurationMs}, ${DatabaseSchema.colTrackFilePath},
                      ${DatabaseSchema.colTrackNumber}, ${DatabaseSchema.colTrackYear}, ${DatabaseSchema.colFileSize},
                      ${DatabaseSchema.colDateAdded}
                    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    ON CONFLICT(${DatabaseSchema.colTrackFilePath}) DO UPDATE SET
                      ${DatabaseSchema.colTitle} = excluded.${DatabaseSchema.colTitle},
                      ${DatabaseSchema.colDurationMs} = excluded.${DatabaseSchema.colDurationMs};
                  ''', [
                    trackId, title, artist, album, durationMs, filePath, trackNumber, year, fileSize, nowMs
                  ]);
                }
              }
            });
          }
        } catch (e) {
          debugPrint('[MediaScanner] MediaStore query failed or not supported: $e');
        }
      }

      // 2. Non-blocking Asynchronous Directory Traversal with .nomedia pruning & whitelist filtering
      for (final dirPath in directoryPaths) {
        if (_stopped) break;
        final dir = Directory(dirPath);
        if (!dir.existsSync()) {
          errors.add('Directory not accessible: $dirPath');
          continue;
        }

        await _traverseDirectoryAsync(dir, effectiveConfig, discoveredFiles, skippedFiles, errors);
      }

      final totalFound = discoveredFiles.length;
      if (totalFound == 0 && errors.isNotEmpty) {
        final isPermission = errors.any((e) => e.toLowerCase().contains('permission'));
        final status = isPermission ? ScannerStatus.permissionDenied : ScannerStatus.error;
        _updateState(_state.copyWith(
          status: status,
          errorMessage: errors.first,
        ));
        return Result.failure(ScannerFailure(
          errors.join('; '),
          errors,
        ));
      }
      _updateState(_state.copyWith(filesFound: totalFound));

      var insertedCount = 0;
      var scannedCount = 0;
      final preparedItems = <_PreparedScanItem>[];

      // 2a. Async pre-extraction pass (parses tags and caches cover art off SQLite lock)
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
          final fileSize = await file.length();
          if (effectiveConfig.skipSmallFiles &&
              fileSize < effectiveConfig.minSizeBytes) {
            skippedFiles.add(file.path);
            continue;
          }

          final bytes = await file.readAsBytes();
          final fallbackTitle = file.uri.pathSegments.last.split('.').first;
          final meta = metadataReader.extractBytes(bytes, fallbackTitle);

          if (effectiveConfig.skipShortAudio &&
              meta.duration.inSeconds < effectiveConfig.minDurationSeconds) {
            skippedFiles.add(file.path);
            continue;
          }

          String? resolvedArtworkUri;
          final artService = artworkService;
          if (artService != null) {
            final trackId = 'trk_${file.path.hashCode.abs()}';
            if (meta.artworkBytes != null && meta.artworkBytes!.isNotEmpty) {
              resolvedArtworkUri = await artService.cacheExtractedBytes(
                '${trackId}_alb_${'${meta.artist}__${meta.album}'.hashCode.abs()}',
                meta.artworkBytes!,
              );
            }
            resolvedArtworkUri ??= await artService.resolveTrackArtwork(
              Track(
                id: trackId,
                title: meta.title,
                artist: meta.artist,
                album: meta.album,
                duration: meta.duration,
                filePath: file.path,
                fileSize: fileSize,
              ),
            );
          }

          preparedItems.add(
            _PreparedScanItem(
              file: file,
              fileSize: fileSize,
              meta: meta,
              artworkUri: resolvedArtworkUri,
            ),
          );
        } catch (e) {
          errors.add('Failed to parse ${file.path}: $e');
        }
      }

      // 2b. Database Upsert within a fast atomic transaction
      database.transaction(() {
        for (final item in preparedItems) {
          if (_stopped) break;
          final file = item.file;
          final fileSize = item.fileSize;
          final meta = item.meta;
          final resolvedArtworkUri = item.artworkUri;

          try {
            final trackId = 'trk_${file.path.hashCode.abs()}';
            final artistId = 'art_${meta.artist.hashCode.abs()}';
            final albumKey = '${meta.album}__${meta.artist}';
            final albumId = 'alb_${albumKey.hashCode.abs()}';
            final genreId = meta.genre != null && meta.genre!.isNotEmpty
                ? 'gen_${meta.genre.hashCode.abs()}'
                : null;
            final nowMs = DateTime.now().millisecondsSinceEpoch;

            // 2c. Upsert Artist
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

            // 2d. Upsert Album (persisting first valid artwork_uri if present)
            database.execute('''
              INSERT INTO ${DatabaseSchema.tableAlbums} (
                ${DatabaseSchema.colId},
                ${DatabaseSchema.colTitle},
                ${DatabaseSchema.colAlbumArtist},
                ${DatabaseSchema.colArtistId},
                ${DatabaseSchema.colAlbumYear},
                ${DatabaseSchema.colArtworkUri},
                ${DatabaseSchema.colTrackCount},
                ${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colDateAdded}
              ) VALUES (?, ?, ?, ?, ?, ?, 1, ?, ?)
              ON CONFLICT(${DatabaseSchema.colTitle}, ${DatabaseSchema.colAlbumArtist}) DO UPDATE SET
                ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1,
                ${DatabaseSchema.colDurationMs} = ${DatabaseSchema.colDurationMs} + excluded.${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colArtworkUri} = COALESCE(${DatabaseSchema.colArtworkUri}, excluded.${DatabaseSchema.colArtworkUri});
            ''', [
              albumId,
              meta.album,
              meta.artist,
              artistId,
              meta.year,
              resolvedArtworkUri,
              meta.duration.inMilliseconds,
              nowMs,
            ]);

            // 2e. Upsert Genre (if present)
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

            // 2f. Upsert Track
            database.execute('''
              INSERT INTO ${DatabaseSchema.tableTracks} (
                ${DatabaseSchema.colId},
                ${DatabaseSchema.colTitle},
                ${DatabaseSchema.colTrackArtist},
                ${DatabaseSchema.colTrackAlbum},
                ${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colArtworkUri},
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
              ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
              ON CONFLICT(${DatabaseSchema.colTrackFilePath}) DO UPDATE SET
                ${DatabaseSchema.colTitle} = excluded.${DatabaseSchema.colTitle},
                ${DatabaseSchema.colTrackArtist} = excluded.${DatabaseSchema.colTrackArtist},
                ${DatabaseSchema.colTrackAlbum} = excluded.${DatabaseSchema.colTrackAlbum},
                ${DatabaseSchema.colDurationMs} = excluded.${DatabaseSchema.colDurationMs},
                ${DatabaseSchema.colArtworkUri} = COALESCE(excluded.${DatabaseSchema.colArtworkUri}, ${DatabaseSchema.colArtworkUri}),
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
              resolvedArtworkUri,
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
            errors.add('Failed to insert ${file.path}: $e');
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

  Future<void> _traverseDirectoryAsync(
    Directory dir,
    ScannerConfig config,
    List<File> discovered,
    List<String> skipped,
    List<String> errors,
  ) async {
    if (config.skipNoMedia) {
      final noMedia = File('${dir.path}/.nomedia');
      if (await noMedia.exists()) {
        skipped.add(dir.path);
        return; // Skip entire folder and descendants
      }
    }

    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (_stopped) break;
        if (entity is Directory) {
          await _traverseDirectoryAsync(entity, config, discovered, skipped, errors);
        } else if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (config.isExtensionSupported(ext)) {
            discovered.add(entity);
          } else {
            skipped.add(entity.path);
          }
        }
      }
    } catch (e) {
      // Unreadable or permission restricted directory
      if (e is FileSystemException &&
          (e.osError?.errorCode == 13 || e.message.toLowerCase().contains('permission'))) {
        errors.add('Permission denied accessing ${dir.path}: $e');
      } else {
        errors.add('Access restricted for ${dir.path}: $e');
      }
    }
  }

  void dispose() {
    _stateController.close();
  }
}
