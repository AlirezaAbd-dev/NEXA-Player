import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';

/// Queries dynamic SQLite-backed smart playlists (`Favorites`, `Recently Added`,
/// `Most Played`, `Recently Played`) with accurate sorting and limits.
abstract interface class ISmartPlaylistsRepository {
  /// Returns ordered tracks for [type]. [recentlyAddedLimit] defaults to 30.
  Future<Result<List<Track>, DatabaseFailure>> getTracksForSmartPlaylist(
    SmartPlaylistType type, {
    int recentlyAddedLimit = 30,
    int limit = 30,
  });

  /// Returns current track counts for all smart playlist types.
  Future<Result<Map<SmartPlaylistType, int>, DatabaseFailure>> getSmartPlaylistCounts({
    int recentlyAddedLimit = 30,
  });
}

class SqliteSmartPlaylistsRepository implements ISmartPlaylistsRepository {
  SqliteSmartPlaylistsRepository(this.database);

  final IAppDatabase database;

  @override
  Future<Result<List<Track>, DatabaseFailure>> getTracksForSmartPlaylist(
    SmartPlaylistType type, {
    int recentlyAddedLimit = 30,
    int limit = 30,
  }) async {
    try {
      final List<Row> rows;
      switch (type) {
        case SmartPlaylistType.favorites:
          rows = database.select('''
            SELECT * FROM ${DatabaseSchema.tableTracks}
            WHERE ${DatabaseSchema.colIsFavorite} = 1
            ORDER BY COALESCE(${DatabaseSchema.colFavoritedAt}, ${DatabaseSchema.colDateAdded}) DESC,
                     ${DatabaseSchema.colTitle} COLLATE NOCASE ASC;
          ''');
          break;
        case SmartPlaylistType.recentlyAdded:
          final safeLimit = recentlyAddedLimit.clamp(1, 200);
          rows = database.select('''
            SELECT * FROM ${DatabaseSchema.tableTracks}
            ORDER BY ${DatabaseSchema.colDateAdded} DESC, rowid DESC
            LIMIT ?;
          ''', [safeLimit]);
          break;
        case SmartPlaylistType.mostPlayed:
          final safeLimit = limit.clamp(1, 200);
          rows = database.select('''
            SELECT * FROM ${DatabaseSchema.tableTracks}
            WHERE ${DatabaseSchema.colPlayCount} > 0
            ORDER BY ${DatabaseSchema.colPlayCount} DESC,
                     COALESCE(${DatabaseSchema.colLastPlayedAt}, ${DatabaseSchema.colDateAdded}) DESC
            LIMIT ?;
          ''', [safeLimit]);
          break;
        case SmartPlaylistType.recentlyPlayed:
          final safeLimit = limit.clamp(1, 200);
          rows = database.select('''
            SELECT * FROM ${DatabaseSchema.tableTracks}
            WHERE ${DatabaseSchema.colLastPlayedAt} IS NOT NULL
            ORDER BY ${DatabaseSchema.colLastPlayedAt} DESC
            LIMIT ?;
          ''', [safeLimit]);
          break;
      }

      return Result.success(rows.map(Track.fromMap).toList());
    } catch (e, st) {
      return Result.failure(
        DatabaseFailure('Failed to query smart playlist ${type.name}: $e', e, st),
      );
    }
  }

  @override
  Future<Result<Map<SmartPlaylistType, int>, DatabaseFailure>> getSmartPlaylistCounts({
    int recentlyAddedLimit = 30,
  }) async {
    try {
      final counts = <SmartPlaylistType, int>{};
      for (final type in SmartPlaylistType.values) {
        final tracksRes = await getTracksForSmartPlaylist(
          type,
          recentlyAddedLimit: recentlyAddedLimit,
        );
        counts[type] = tracksRes.valueOrNull?.length ?? 0;
      }
      return Result.success(counts);
    } catch (e, st) {
      return Result.failure(
        DatabaseFailure('Failed to compute smart playlist counts: $e', e, st),
      );
    }
  }
}
