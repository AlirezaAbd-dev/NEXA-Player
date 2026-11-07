import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// SQLite implementation of [IPlaylistsRepository].
class SqlitePlaylistsRepository implements IPlaylistsRepository {
  SqlitePlaylistsRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<Playlist>, DatabaseFailure>> getAllPlaylists() async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tablePlaylists} '
        'ORDER BY ${DatabaseSchema.colName} COLLATE NOCASE ASC',
      );
      final playlists = rows.map((r) => Playlist.fromMap(r)).toList();
      return Result.success(playlists);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query playlists: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<Playlist?, DatabaseFailure>> getPlaylistById(String id) async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tablePlaylists} WHERE ${DatabaseSchema.colId} = ?',
        [id],
      );
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(Playlist.fromMap(rows.first));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query playlist by id: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<Playlist, DatabaseFailure>> createPlaylist(
    String name, {
    String? description,
  }) async {
    try {
      final now = DateTime.now();
      final id = 'pl_${now.microsecondsSinceEpoch}';

      database.execute('''
        INSERT INTO ${DatabaseSchema.tablePlaylists} (
          ${DatabaseSchema.colId},
          ${DatabaseSchema.colName},
          ${DatabaseSchema.colDescription},
          ${DatabaseSchema.colCreatedAt},
          ${DatabaseSchema.colUpdatedAt},
          ${DatabaseSchema.colTrackCount}
        ) VALUES (?, ?, ?, ?, ?, 0);
      ''', [
        id,
        name,
        description,
        now.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch,
      ]);

      final playlist = Playlist(
        id: id,
        name: name,
        createdAt: now,
        updatedAt: now,
        trackCount: 0,
      );
      return Result.success(playlist);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to create playlist: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> deletePlaylist(
      String playlistId) async {
    try {
      database.execute(
        'DELETE FROM ${DatabaseSchema.tablePlaylists} WHERE ${DatabaseSchema.colId} = ?;',
        [playlistId],
      );
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to delete playlist: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      database.transaction(() {
        final countRows = database.select(
          'SELECT COUNT(*) as count FROM ${DatabaseSchema.tablePlaylistTracks} '
          'WHERE ${DatabaseSchema.colPlaylistId} = ?',
          [playlistId],
        );
        final nextPosition = ((countRows.first['count'] as int?) ?? 0) + 1;
        final nowMs = DateTime.now().millisecondsSinceEpoch;

        database.execute('''
          INSERT INTO ${DatabaseSchema.tablePlaylistTracks} (
            ${DatabaseSchema.colPlaylistId},
            ${DatabaseSchema.colTrackId},
            ${DatabaseSchema.colPosition},
            ${DatabaseSchema.colAddedAt}
          ) VALUES (?, ?, ?, ?);
        ''', [playlistId, trackId, nextPosition, nowMs]);

        database.execute('''
          UPDATE ${DatabaseSchema.tablePlaylists}
          SET ${DatabaseSchema.colTrackCount} = ${DatabaseSchema.colTrackCount} + 1,
              ${DatabaseSchema.colUpdatedAt} = ?
          WHERE ${DatabaseSchema.colId} = ?;
        ''', [nowMs, playlistId]);
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to add track to playlist: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    try {
      database.transaction(() {
        database.execute('''
          DELETE FROM ${DatabaseSchema.tablePlaylistTracks}
          WHERE ${DatabaseSchema.colPlaylistId} = ? AND ${DatabaseSchema.colTrackId} = ?;
        ''', [playlistId, trackId]);

        database.execute('''
          UPDATE ${DatabaseSchema.tablePlaylists}
          SET ${DatabaseSchema.colTrackCount} = (
            SELECT COUNT(*) FROM ${DatabaseSchema.tablePlaylistTracks}
            WHERE ${DatabaseSchema.colPlaylistId} = ?
          ),
          ${DatabaseSchema.colUpdatedAt} = ?
          WHERE ${DatabaseSchema.colId} = ?;
        ''', [playlistId, DateTime.now().millisecondsSinceEpoch, playlistId]);
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to remove track from playlist: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForPlaylist(
      String playlistId) async {
    try {
      final rows = database.select('''
        SELECT t.* FROM ${DatabaseSchema.tableTracks} t
        INNER JOIN ${DatabaseSchema.tablePlaylistTracks} pt
          ON t.${DatabaseSchema.colId} = pt.${DatabaseSchema.colTrackId}
        WHERE pt.${DatabaseSchema.colPlaylistId} = ?
        ORDER BY pt.${DatabaseSchema.colPosition} ASC;
      ''', [playlistId]);

      final tracks = rows.map((r) => Track.fromMap(r)).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query tracks for playlist: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<void, DatabaseFailure>> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    try {
      database.transaction(() {
        final rows = database.select('''
          SELECT ${DatabaseSchema.colTrackId} FROM ${DatabaseSchema.tablePlaylistTracks}
          WHERE ${DatabaseSchema.colPlaylistId} = ?
          ORDER BY ${DatabaseSchema.colPosition} ASC;
        ''', [playlistId]);

        final trackIds =
            rows.map((r) => r[DatabaseSchema.colTrackId] as String).toList();
        if (oldIndex < 0 || oldIndex >= trackIds.length) return;
        if (newIndex < 0 || newIndex >= trackIds.length) return;

        final item = trackIds.removeAt(oldIndex);
        trackIds.insert(newIndex, item);

        for (var i = 0; i < trackIds.length; i++) {
          database.execute('''
            UPDATE ${DatabaseSchema.tablePlaylistTracks}
            SET ${DatabaseSchema.colPosition} = ?
            WHERE ${DatabaseSchema.colPlaylistId} = ? AND ${DatabaseSchema.colTrackId} = ?;
          ''', [i + 1, playlistId, trackIds[i]]);
        }
      });
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to reorder playlist tracks: $e',
        e,
        st,
      ));
    }
  }
}
