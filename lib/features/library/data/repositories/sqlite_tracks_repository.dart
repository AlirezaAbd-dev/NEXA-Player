import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// SQLite implementation of [ITracksRepository].
class SqliteTracksRepository implements ITracksRepository {
  SqliteTracksRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async {
    try {
      final orderClause = switch (sortBy) {
        TrackSortBy.title => '${DatabaseSchema.colTitle} COLLATE NOCASE',
        TrackSortBy.artist => '${DatabaseSchema.colTrackArtist} COLLATE NOCASE',
        TrackSortBy.dateAdded => DatabaseSchema.colDateAdded,
        TrackSortBy.duration => DatabaseSchema.colDurationMs,
      };
      final dir = ascending ? 'ASC' : 'DESC';

      var sql = 'SELECT * FROM ${DatabaseSchema.tableTracks}';
      final params = <Object?>[];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE ${DatabaseSchema.colTitle} LIKE ? '
            'OR ${DatabaseSchema.colTrackArtist} LIKE ? '
            'OR ${DatabaseSchema.colTrackAlbum} LIKE ?';
        final queryParam = '%${searchQuery.trim()}%';
        params.addAll([queryParam, queryParam, queryParam]);
      }

      sql += ' ORDER BY $orderClause $dir';

      final rows = database.select(sql, params);
      final tracks = rows.map((r) => Track.fromMap(r)).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query tracks: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id) async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableTracks} WHERE ${DatabaseSchema.colId} = ?',
        [id],
      );
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(Track.fromMap(rows.first));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query track by id: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId) async {
    try {
      database.execute('''
        UPDATE ${DatabaseSchema.tableTracks}
        SET ${DatabaseSchema.colIsFavorite} = CASE WHEN ${DatabaseSchema.colIsFavorite} = 1 THEN 0 ELSE 1 END
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [trackId]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to toggle favorite: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> incrementPlayCount(String trackId) async {
    try {
      database.execute('''
        UPDATE ${DatabaseSchema.tableTracks}
        SET ${DatabaseSchema.colPlayCount} = ${DatabaseSchema.colPlayCount} + 1
        WHERE ${DatabaseSchema.colId} = ?;
      ''', [trackId]);
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to increment play count: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId) async {
    try {
      database.execute(
        'DELETE FROM ${DatabaseSchema.tableTracks} WHERE ${DatabaseSchema.colId} = ?;',
        [trackId],
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to delete track: $e',
        e,
        st,
      ));
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
              ${DatabaseSchema.colIsFavorite},
              ${DatabaseSchema.colPlayCount},
              ${DatabaseSchema.colBitrate},
              ${DatabaseSchema.colFileSize},
              ${DatabaseSchema.colDateAdded},
              ${DatabaseSchema.colDateModified},
              ${DatabaseSchema.colArtistId},
              ${DatabaseSchema.colAlbumId},
              ${DatabaseSchema.colGenreId}
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(${DatabaseSchema.colTrackFilePath}) DO UPDATE SET
              ${DatabaseSchema.colTitle} = excluded.${DatabaseSchema.colTitle},
              ${DatabaseSchema.colTrackArtist} = excluded.${DatabaseSchema.colTrackArtist},
              ${DatabaseSchema.colTrackAlbum} = excluded.${DatabaseSchema.colTrackAlbum},
              ${DatabaseSchema.colDurationMs} = excluded.${DatabaseSchema.colDurationMs},
              ${DatabaseSchema.colTrackNumber} = excluded.${DatabaseSchema.colTrackNumber},
              ${DatabaseSchema.colDiscNumber} = excluded.${DatabaseSchema.colDiscNumber},
              ${DatabaseSchema.colTrackYear} = excluded.${DatabaseSchema.colTrackYear},
              ${DatabaseSchema.colTrackGenre} = excluded.${DatabaseSchema.colTrackGenre},
              ${DatabaseSchema.colIsFavorite} = excluded.${DatabaseSchema.colIsFavorite},
              ${DatabaseSchema.colBitrate} = excluded.${DatabaseSchema.colBitrate},
              ${DatabaseSchema.colFileSize} = excluded.${DatabaseSchema.colFileSize};
          ''', [
            track.id,
            track.title,
            track.artist,
            track.album,
            track.duration.inMilliseconds,
            track.filePath ?? '/mock/${track.id}.mp3',
            track.trackNumber,
            track.discNumber,
            track.year,
            track.genre,
            track.isFavorite ? 1 : 0,
            track.playCount,
            track.bitrate,
            track.fileSize,
            track.dateAdded?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            track.dateModified?.millisecondsSinceEpoch ??
                DateTime.now().millisecondsSinceEpoch,
            track.artistId,
            track.albumId,
            track.genreId,
          ]);
        }
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to insert tracks: $e',
        e,
        st,
      ));
    }
  }
}
