import 'package:nexa_player/core/services/library/library_sync_bus.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/data/services/id3_tag_writer.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// Concrete implementation of [ITagEditorService] updating track tags and cover
/// artwork in SQLite (with Artist/Album re-grouping) and atomically in UTF-8
/// ID3v2.4 file tags when filesystem write permission permits.
class TagEditorServiceImpl implements ITagEditorService {
  TagEditorServiceImpl(
    this.database, {
    LibrarySyncBus? syncBus,
    Id3TagWriter? id3Writer,
  })  : _syncBus = syncBus,
        _id3Writer = id3Writer ?? const Id3TagWriter();

  final IAppDatabase database;
  final LibrarySyncBus? _syncBus;
  final Id3TagWriter _id3Writer;

  /// Non-blocking warning if SQLite succeeded but underlying file was read-only.
  String? lastFileWriteWarning;

  @override
  Future<Result<Track, Failure>> updateTrackMetadata(
    String trackId,
    EditableTrackMetadata metadata,
  ) async {
    lastFileWriteWarning = null;
    final title = metadata.title.trim();
    final artist = metadata.artist.trim();
    final album = metadata.album.trim();

    if (title.isEmpty) {
      return const Result.failure(ValidationFailure('Track title cannot be empty'));
    }
    if (artist.isEmpty) {
      return const Result.failure(ValidationFailure('Track artist cannot be empty'));
    }

    try {
      final existingRows = database.select('''
        SELECT * FROM ${DatabaseSchema.tableTracks}
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [trackId]);

      if (existingRows.isEmpty) {
        return Result.failure(DatabaseFailure('Track $trackId not found'));
      }

      final oldRow = existingRows.first;
      final oldArtistId = oldRow[DatabaseSchema.colArtistId] as String?;
      final oldAlbumId = oldRow[DatabaseSchema.colAlbumId] as String?;
      final filePath = oldRow[DatabaseSchema.colTrackFilePath] as String?;
      final oldArtworkUri = oldRow[DatabaseSchema.colArtworkUri] as String?;

      final effectiveAlbum = album.isEmpty ? 'Unknown Album' : album;
      final newArtistId = _slugId('art', artist);
      final newAlbumId = _slugId('alb', '${effectiveAlbum}_$artist');
      final effectiveComment =
          metadata.comment != null && metadata.comment!.trim().isNotEmpty
              ? metadata.comment!.trim()
              : null;
      final effectiveArtworkUri = metadata.clearArtwork
          ? null
          : (metadata.artworkUri ?? oldArtworkUri);

      database.transaction(() {
        // 1. Ensure target artist exists (reusing existing row matched by name if any)
        final existingArtist = database.select(
          'SELECT ${DatabaseSchema.colId} FROM ${DatabaseSchema.tableArtists} '
          'WHERE ${DatabaseSchema.colName} = ? LIMIT 1;',
          [artist],
        );
        final resolvedArtistId = existingArtist.isNotEmpty
            ? existingArtist.first[DatabaseSchema.colId] as String
            : newArtistId;

        if (existingArtist.isEmpty) {
          database.execute('''
            INSERT INTO ${DatabaseSchema.tableArtists} (${DatabaseSchema.colId}, ${DatabaseSchema.colName})
            VALUES (?, ?)
            ON CONFLICT(${DatabaseSchema.colName}) DO NOTHING;
          ''', [resolvedArtistId, artist]);
        }

        // 2. Ensure target album exists (reusing existing row matched by title+artist if any)
        final existingAlbum = database.select(
          'SELECT ${DatabaseSchema.colId} FROM ${DatabaseSchema.tableAlbums} '
          'WHERE ${DatabaseSchema.colTitle} = ? AND ${DatabaseSchema.colAlbumArtist} = ? LIMIT 1;',
          [effectiveAlbum, artist],
        );
        final resolvedAlbumId = existingAlbum.isNotEmpty
            ? existingAlbum.first[DatabaseSchema.colId] as String
            : newAlbumId;

        database.execute('''
          INSERT INTO ${DatabaseSchema.tableAlbums} (
            ${DatabaseSchema.colId},
            ${DatabaseSchema.colTitle},
            ${DatabaseSchema.colAlbumArtist},
            ${DatabaseSchema.colAlbumYear},
            ${DatabaseSchema.colArtworkUri}
          )
          VALUES (?, ?, ?, ?, ?)
          ON CONFLICT(${DatabaseSchema.colTitle}, ${DatabaseSchema.colAlbumArtist}) DO UPDATE SET
            ${DatabaseSchema.colAlbumYear} = COALESCE(?, ${DatabaseSchema.colAlbumYear}),
            ${DatabaseSchema.colArtworkUri} = COALESCE(?, ${DatabaseSchema.colArtworkUri});
        ''', [
          resolvedAlbumId,
          effectiveAlbum,
          artist,
          metadata.year,
          effectiveArtworkUri,
          metadata.year,
          metadata.artworkUri,
        ]);

        // 3. Update track row including comment, artworkUri, and relational foreign keys
        database.execute('''
          UPDATE ${DatabaseSchema.tableTracks}
          SET ${DatabaseSchema.colTitle} = ?,
              ${DatabaseSchema.colTrackArtist} = ?,
              ${DatabaseSchema.colTrackAlbum} = ?,
              ${DatabaseSchema.colTrackGenre} = ?,
              ${DatabaseSchema.colTrackYear} = ?,
              ${DatabaseSchema.colTrackNumber} = ?,
              ${DatabaseSchema.colComment} = ?,
              ${DatabaseSchema.colArtworkUri} = ?,
              ${DatabaseSchema.colArtistId} = ?,
              ${DatabaseSchema.colAlbumId} = ?
          WHERE ${DatabaseSchema.colId} = ?;
        ''', [
          title,
          artist,
          effectiveAlbum,
          metadata.genre?.trim().isNotEmpty == true
              ? metadata.genre!.trim()
              : null,
          metadata.year,
          metadata.trackNumber,
          effectiveComment,
          effectiveArtworkUri,
          resolvedArtistId,
          resolvedAlbumId,
          trackId,
        ]);

        // 4. Refresh track/album counts for old & new artists and albums
        for (final aid in {resolvedArtistId, if (oldArtistId != null) oldArtistId}) {
          database.execute('''
            UPDATE ${DatabaseSchema.tableArtists}
            SET ${DatabaseSchema.colTrackCount} = (
              SELECT COUNT(*) FROM ${DatabaseSchema.tableTracks}
              WHERE ${DatabaseSchema.colArtistId} = ?
            ),
            ${DatabaseSchema.colAlbumCount} = (
              SELECT COUNT(DISTINCT ${DatabaseSchema.colAlbumId})
              FROM ${DatabaseSchema.tableTracks}
              WHERE ${DatabaseSchema.colArtistId} = ?
            )
            WHERE ${DatabaseSchema.colId} = ?;
          ''', [aid, aid, aid]);
        }

        for (final albid in {resolvedAlbumId, if (oldAlbumId != null) oldAlbumId}) {
          database.execute('''
            UPDATE ${DatabaseSchema.tableAlbums}
            SET ${DatabaseSchema.colTrackCount} = (
              SELECT COUNT(*) FROM ${DatabaseSchema.tableTracks}
              WHERE ${DatabaseSchema.colAlbumId} = ?
            )
            WHERE ${DatabaseSchema.colId} = ?;
          ''', [albid, albid]);
        }
      });

      // 5. Fetch updated track
      final rows = database.select('''
        SELECT * FROM ${DatabaseSchema.tableTracks}
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [trackId]);

      if (rows.isEmpty) {
        return Result.failure(DatabaseFailure('Track $trackId not found after update'));
      }

      // 6. Best-effort atomic ID3v2.4 write back to audio file off DB lock
      if (filePath != null && filePath.isNotEmpty) {
        final writeRes = await _id3Writer.writeTags(
          filePath,
          metadata.copyWith(
            title: title,
            artist: artist,
            album: effectiveAlbum,
            comment: effectiveComment,
          ),
        );
        if (writeRes.status == Id3WriteStatus.readOnlyOrPermissionDenied) {
          lastFileWriteWarning =
              'Saved in library (audio file is read-only under Android Scoped Storage)';
        }
      }

      _syncBus?.notifyChanged();

      final updatedTrack = Track.fromMap(rows.first);
      return Result.success(updatedTrack);
    } catch (e, st) {
      return Result.failure(DatabaseFailure('Failed to update track metadata: $e', e, st));
    }
  }

  String _slugId(String prefix, String input) {
    final normalized = input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    if (normalized.isNotEmpty) {
      return '${prefix}_$normalized';
    }
    return '${prefix}_${input.hashCode}';
  }
}
