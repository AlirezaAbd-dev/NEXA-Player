import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/genres_repository.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// SQLite implementation of [IGenresRepository].
class SqliteGenresRepository implements IGenresRepository {
  SqliteGenresRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<Genre>, DatabaseFailure>> getAllGenres({
    String? searchQuery,
  }) async {
    try {
      var sql = 'SELECT * FROM ${DatabaseSchema.tableGenres}';
      final params = <Object?>[];

      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        sql += ' WHERE ${DatabaseSchema.colName} LIKE ?';
        params.add('%${searchQuery.trim()}%');
      }

      sql += ' ORDER BY ${DatabaseSchema.colName} COLLATE NOCASE ASC';

      final rows = database.select(sql, params);
      final genres = rows.map((r) => Genre.fromMap(r)).toList();
      return Result.success(genres);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query genres: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<Genre?, DatabaseFailure>> getGenreById(String id) async {
    try {
      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableGenres} WHERE ${DatabaseSchema.colId} = ?',
        [id],
      );
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(Genre.fromMap(rows.first));
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query genre by id: $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForGenre(
      String genreId) async {
    try {
      final genreRows = database.select(
        'SELECT ${DatabaseSchema.colName}, ${DatabaseSchema.colId} FROM ${DatabaseSchema.tableGenres} WHERE ${DatabaseSchema.colId} = ?',
        [genreId],
      );
      if (genreRows.isEmpty) return const Result.success([]);
      final genreName = genreRows.first[DatabaseSchema.colName] as String;

      final rows = database.select(
        'SELECT * FROM ${DatabaseSchema.tableTracks} '
        'WHERE ${DatabaseSchema.colGenreId} = ? OR ${DatabaseSchema.colTrackGenre} = ? '
        'ORDER BY ${DatabaseSchema.colTrackAlbum} ASC, ${DatabaseSchema.colTitle} ASC',
        [genreId, genreName],
      );
      final tracks = rows.map((r) => Track.fromMap(r)).toList();
      return Result.success(tracks);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to query tracks for genre: $e',
        e,
        st,
      ));
    }
  }
}
