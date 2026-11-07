import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Repository contract managing genre queries and tracks by genre.
abstract interface class IGenresRepository {
  /// Fetches all genres, optionally filtered by [searchQuery].
  Future<Result<List<Genre>, DatabaseFailure>> getAllGenres({String? searchQuery});

  /// Fetches a single genre by [id].
  Future<Result<Genre?, DatabaseFailure>> getGenreById(String id);

  /// Fetches all tracks associated with [genreId] ordered by title.
  Future<Result<List<Track>, DatabaseFailure>> getTracksForGenre(String genreId);
}
