import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Sort options for artist queries.
enum ArtistSortBy { name, trackCount }

/// Repository contract managing artist queries and tracks by artist.
abstract interface class IArtistsRepository {
  /// Fetches all artists, optionally filtered by [searchQuery] and sorted by [sortBy].
  Future<Result<List<Artist>, DatabaseFailure>> getAllArtists({
    ArtistSortBy sortBy = ArtistSortBy.name,
    bool ascending = true,
    String? searchQuery,
  });

  /// Fetches a single artist by [id].
  Future<Result<Artist?, DatabaseFailure>> getArtistById(String id);

  /// Fetches all tracks associated with [artistId] ordered by title.
  Future<Result<List<Track>, DatabaseFailure>> getTracksForArtist(String artistId);
}
