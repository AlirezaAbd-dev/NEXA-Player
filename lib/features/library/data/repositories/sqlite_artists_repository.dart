import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/artists_repository.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// SQLite implementation of [IArtistsRepository].
class SqliteArtistsRepository implements IArtistsRepository {
  SqliteArtistsRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<Artist>, DatabaseFailure>> getAllArtists({
    ArtistSortBy sortBy = ArtistSortBy.name,
    bool ascending = true,
    String? searchQuery,
  }) async {
    try {
      final orderClause = switch (sortBy) {
        ArtistSortBy.name => '${DatabaseSchema.colName} COLLATE NOCASE',
        ArtistSortBy.trackCount => DatabaseSchema.colTrackCount,
      };
      final dir = ascending ? 'ASC' : 'DESC';

      var sql = 'SELECT * FROM ${DatabaseSchema.tableArtists}';
      final params = <Object?>[];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE ${DatabaseSchema.colName} LIKE ?';
        params.add('%${searchQuery.trim()}%');
      }

      sql += ' ORDER BY $orderClause $dir';

      final rows = database.select(sql, params);
      final artists = rows.map((r) => Artist.fromMap(r)).toList();
      return Result.success(artists);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query artists: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<Artist?, DatabaseFailure>> getArtistById(String id) async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableArtists} WHERE ${DatabaseSchema.colId} = ?',
        [id],
      );
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(Artist.fromMap(rows.first));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query artist by id: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForArtist(
      String artistId) async {
    try {
      final artistRows = database.select(
        'SELECT ${DatabaseSchema.colName}, ${DatabaseSchema.colId} FROM ${DatabaseSchema.tableArtists} WHERE ${DatabaseSchema.colId} = ?',
        [artistId],
      );
      if (artistRows.isEmpty) return const Result.success([]);
      final artistName = artistRows.first[DatabaseSchema.colName] as String;

      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableTracks} '
        'WHERE ${DatabaseSchema.colArtistId} = ? OR ${DatabaseSchema.colTrackArtist} = ? '
        'ORDER BY ${DatabaseSchema.colTrackAlbum} ASC, ${DatabaseSchema.colTitle} ASC',
        [artistId, artistName],
      );
      final tracks = rows.map((r) => Track.fromMap(r)).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query tracks for artist: $e',
        e,
        st,
      ));
    }
  }
}
