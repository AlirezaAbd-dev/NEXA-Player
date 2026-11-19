import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// Concrete implementation of [ITagEditorService] updating track tags in SQLite.
class TagEditorServiceImpl implements ITagEditorService {
  TagEditorServiceImpl(this.database);

  final IAppDatabase database;

  @override
  Future<Result<Track, Failure>> updateTrackMetadata(
    String trackId,
    EditableTrackMetadata metadata,
  ) async {
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
      database.transaction(() {
        // 1. Ensure artist exists
        database.execute('''
          INSERT INTO ${DatabaseSchema.tableArtists} (${DatabaseSchema.colId}, ${DatabaseSchema.colName})
          VALUES (?, ?)
          ON CONFLICT(${DatabaseSchema.colName}) DO NOTHING;
        ''', ['art_${artist.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}', artist]);

        // 2. Ensure album exists
        final effectiveAlbum = album.isEmpty ? 'Unknown Album' : album;
        database.execute('''
          INSERT INTO ${DatabaseSchema.tableAlbums} (
            ${DatabaseSchema.colId},
            ${DatabaseSchema.colTitle},
            ${DatabaseSchema.colAlbumArtist},
            ${DatabaseSchema.colAlbumYear}
          )
          VALUES (?, ?, ?, ?)
          ON CONFLICT(${DatabaseSchema.colTitle}, ${DatabaseSchema.colAlbumArtist}) DO UPDATE SET
            ${DatabaseSchema.colAlbumYear} = COALESCE(?, ${DatabaseSchema.colAlbumYear});
        ''', [
          'alb_${effectiveAlbum.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}',
          effectiveAlbum,
          artist,
          metadata.year,
          metadata.year,
        ]);

        // 3. Update track row
        database.execute('''
          UPDATE ${DatabaseSchema.tableTracks}
          SET ${DatabaseSchema.colTitle} = ?,
              ${DatabaseSchema.colTrackArtist} = ?,
              ${DatabaseSchema.colTrackAlbum} = ?,
              ${DatabaseSchema.colTrackGenre} = ?,
              ${DatabaseSchema.colTrackYear} = ?,
              ${DatabaseSchema.colTrackNumber} = ?
          WHERE ${DatabaseSchema.colId} = ?;
        ''', [
          title,
          artist,
          effectiveAlbum,
          metadata.genre,
          metadata.year,
          metadata.trackNumber,
          trackId,
        ]);
      });

      // 4. Fetch updated track
      final rows = database.select('''
        SELECT * FROM ${DatabaseSchema.tableTracks}
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [trackId]);

      if (rows.isEmpty) {
        return Result.failure(DatabaseFailure('Track $trackId not found after update'));
      }

      final updatedTrack = Track.fromMap(rows.first);
      return Result.success(updatedTrack);
    } catch (e, st) {
      return Result.failure(DatabaseFailure('Failed to update track metadata: $e', e, st));
    }
  }
}
