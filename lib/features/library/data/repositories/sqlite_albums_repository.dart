import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/albums_repository.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// SQLite implementation of [IAlbumsRepository].
class SqliteAlbumsRepository implements IAlbumsRepository {
  SqliteAlbumsRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<Album>, DatabaseFailure>> getAllAlbums({
    AlbumSortBy sortBy = AlbumSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async {
    try {
      final orderClause = switch (sortBy) {
        AlbumSortBy.title => '${DatabaseSchema.colTitle} COLLATE NOCASE',
        AlbumSortBy.artist => '${DatabaseSchema.colAlbumArtist} COLLATE NOCASE',
        AlbumSortBy.year => DatabaseSchema.colAlbumYear,
      };
      final dir = ascending ? 'ASC' : 'DESC';

      var sql = 'SELECT * FROM ${DatabaseSchema.tableAlbums}';
      final params = <Object?>[];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE ${DatabaseSchema.colTitle} LIKE ? '
            'OR ${DatabaseSchema.colAlbumArtist} LIKE ?';
        final queryParam = '%${searchQuery.trim()}%';
        params.addAll([queryParam, queryParam]);
      }

      sql += ' ORDER BY $orderClause $dir';

      final rows = database.select(sql, params);
      final albums = rows.map((r) => Album.fromMap(r)).toList();
      return Result.success(albums);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query albums: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<Album?, DatabaseFailure>> getAlbumById(String id) async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableAlbums} WHERE ${DatabaseSchema.colId} = ?',
        [id],
      );
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(Album.fromMap(rows.first));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query album by id: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForAlbum(
      String albumId) async {
    try {
      final albumRows = database.select(
        'SELECT ${DatabaseSchema.colTitle}, ${DatabaseSchema.colId} FROM ${DatabaseSchema.tableAlbums} WHERE ${DatabaseSchema.colId} = ?',
        [albumId],
      );
      if (albumRows.isEmpty) return const Result.success([]);
      final albumTitle = albumRows.first[DatabaseSchema.colTitle] as String;

      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableTracks} '
        'WHERE ${DatabaseSchema.colAlbumId} = ? OR ${DatabaseSchema.colTrackAlbum} = ? '
        'ORDER BY ${DatabaseSchema.colDiscNumber} ASC, ${DatabaseSchema.colTrackNumber} ASC, ${DatabaseSchema.colTitle} ASC',
        [albumId, albumTitle],
      );
      final tracks = rows.map((r) => Track.fromMap(r)).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query tracks for album: $e',
        e,
        st,
      ));
    }
  }
}
