import 'dart:convert';

import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/search/domain/models/search_result.dart';
import 'package:nexa_player/features/search/domain/models/search_result_category.dart';
import 'package:nexa_player/features/search/domain/repositories/search_repository.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

/// SQLite-backed implementation of [ISearchRepository].
///
/// Executes prioritized, indexed queries across tracks, albums, artists, genres, and playlists,
/// ranking exact prefix matches above inner substring matches.
class SqliteSearchRepository implements ISearchRepository {
  SqliteSearchRepository({
    required this.database,
    required this.storage,
  });

  final IAppDatabase database;
  final IStorageService storage;

  static const int _maxRecentSearches = 15;

  @override
  Future<Result<SearchResult, DatabaseFailure>> search({
    required String query,
    SearchResultCategory category = SearchResultCategory.all,
    int limitPerCategory = 25,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Result.success(SearchResult.empty(query));
    }

    try {
      final likeTerm = '%$trimmed%';
      final prefixTerm = '$trimmed%';

      var tracks = <Track>[];
      var albums = <Album>[];
      var artists = <Artist>[];
      var playlists = <Playlist>[];
      var genres = <Genre>[];

      // 1. Search Tracks
      if (category == SearchResultCategory.all || category == SearchResultCategory.tracks) {
        final rows = database.select(
          '''
          SELECT * FROM ${DatabaseSchema.tableTracks}
          WHERE ${DatabaseSchema.colTitle} LIKE ?
             OR ${DatabaseSchema.colTrackArtist} LIKE ?
             OR ${DatabaseSchema.colTrackAlbum} LIKE ?
             OR ${DatabaseSchema.colTrackGenre} LIKE ?
          ORDER BY
            CASE
              WHEN lower(${DatabaseSchema.colTitle}) LIKE lower(?) THEN 0
              WHEN lower(${DatabaseSchema.colTrackArtist}) LIKE lower(?) THEN 1
              WHEN lower(${DatabaseSchema.colTrackAlbum}) LIKE lower(?) THEN 2
              ELSE 3
            END,
            ${DatabaseSchema.colTitle} COLLATE NOCASE ASC
          LIMIT ?
          ''',
          [likeTerm, likeTerm, likeTerm, likeTerm, prefixTerm, prefixTerm, prefixTerm, limitPerCategory],
        );
        tracks = rows.map((r) => Track.fromMap(r)).toList();
      }

      // 2. Search Albums
      if (category == SearchResultCategory.all || category == SearchResultCategory.albums) {
        final rows = database.select(
          '''
          SELECT * FROM ${DatabaseSchema.tableAlbums}
          WHERE ${DatabaseSchema.colTitle} LIKE ?
             OR ${DatabaseSchema.colAlbumArtist} LIKE ?
          ORDER BY
            CASE
              WHEN lower(${DatabaseSchema.colTitle}) LIKE lower(?) THEN 0
              WHEN lower(${DatabaseSchema.colAlbumArtist}) LIKE lower(?) THEN 1
              ELSE 2
            END,
            ${DatabaseSchema.colTitle} COLLATE NOCASE ASC
          LIMIT ?
          ''',
          [likeTerm, likeTerm, prefixTerm, prefixTerm, limitPerCategory],
        );
        albums = rows.map((r) => Album.fromMap(r)).toList();
      }

      // 3. Search Artists
      if (category == SearchResultCategory.all || category == SearchResultCategory.artists) {
        final rows = database.select(
          '''
          SELECT * FROM ${DatabaseSchema.tableArtists}
          WHERE ${DatabaseSchema.colName} LIKE ?
          ORDER BY
            CASE
              WHEN lower(${DatabaseSchema.colName}) LIKE lower(?) THEN 0
              ELSE 1
            END,
            ${DatabaseSchema.colName} COLLATE NOCASE ASC
          LIMIT ?
          ''',
          [likeTerm, prefixTerm, limitPerCategory],
        );
        artists = rows.map((r) => Artist.fromMap(r)).toList();
      }

      // 4. Search Playlists
      if (category == SearchResultCategory.all || category == SearchResultCategory.playlists) {
        final rows = database.select(
          '''
          SELECT * FROM ${DatabaseSchema.tablePlaylists}
          WHERE ${DatabaseSchema.colName} LIKE ?
             OR (${DatabaseSchema.colDescription} IS NOT NULL AND ${DatabaseSchema.colDescription} LIKE ?)
          ORDER BY
            CASE
              WHEN lower(${DatabaseSchema.colName}) LIKE lower(?) THEN 0
              ELSE 1
            END,
            ${DatabaseSchema.colName} COLLATE NOCASE ASC
          LIMIT ?
          ''',
          [likeTerm, likeTerm, prefixTerm, limitPerCategory],
        );
        playlists = rows.map((r) => Playlist.fromMap(r)).toList();
      }

      // 5. Search Genres
      if (category == SearchResultCategory.all || category == SearchResultCategory.genres) {
        final rows = database.select(
          '''
          SELECT * FROM ${DatabaseSchema.tableGenres}
          WHERE ${DatabaseSchema.colName} LIKE ?
          ORDER BY
            CASE
              WHEN lower(${DatabaseSchema.colName}) LIKE lower(?) THEN 0
              ELSE 1
            END,
            ${DatabaseSchema.colName} COLLATE NOCASE ASC
          LIMIT ?
          ''',
          [likeTerm, prefixTerm, limitPerCategory],
        );
        genres = rows.map((r) => Genre.fromMap(r)).toList();
      }

      final result = SearchResult(
        query: trimmed,
        tracks: tracks,
        albums: albums,
        artists: artists,
        playlists: playlists,
        genres: genres,
      );

      return Result.success(result);
    } catch (e, st) {
      return Result.failure(DatabaseFailure(
        'Failed to execute search for "$query": $e',
        e,
        st,
      ));
    }
  }

  @override
  Future<List<String>> getRecentSearches() async {
    final result = storage.getString(StorageKeys.recentSearches);
    if (result.isFailure || result.valueOrNull == null || result.valueOrNull!.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(result.valueOrNull!) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final current = await getRecentSearches();
    final updated = [trimmed, ...current.where((q) => q.toLowerCase() != trimmed.toLowerCase())];
    if (updated.length > _maxRecentSearches) {
      updated.removeRange(_maxRecentSearches, updated.length);
    }

    await storage.setString(StorageKeys.recentSearches, jsonEncode(updated));
  }

  @override
  Future<void> removeRecentSearch(String query) async {
    final current = await getRecentSearches();
    final updated = current.where((q) => q != query).toList();
    await storage.setString(StorageKeys.recentSearches, jsonEncode(updated));
  }

  @override
  Future<void> clearRecentSearches() async {
    await storage.remove(StorageKeys.recentSearches);
  }
}
