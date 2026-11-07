import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Sort options for album queries.
enum AlbumSortBy { title, artist, year }

/// Repository contract managing album queries and tracks contained within albums.
abstract interface class IAlbumsRepository {
  /// Fetches all albums, optionally filtered by [searchQuery] and sorted by [sortBy].
  Future<Result<List<Album>, DatabaseFailure>> getAllAlbums({
    AlbumSortBy sortBy = AlbumSortBy.title,
    bool ascending = true,
    String? searchQuery,
  });

  /// Fetches a single album by [id].
  Future<Result<Album?, DatabaseFailure>> getAlbumById(String id);

  /// Fetches all tracks associated with [albumId] ordered by disc/track number.
  Future<Result<List<Track>, DatabaseFailure>> getTracksForAlbum(String albumId);
}
