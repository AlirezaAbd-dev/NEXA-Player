import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Sort options for track querying.
enum TrackSortBy { title, artist, dateAdded, duration }

/// Repository contract managing audio track retrieval, searching, and metadata updates.
abstract interface class ITracksRepository {
  /// Fetches all tracks matching the optional [searchQuery], ordered by [sortBy] and [ascending].
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  });

  /// Fetches a single track by [id]. Returns null in result if not found.
  Future<Result<Track?, DatabaseFailure>> getTrackById(String id);

  /// Toggles the favorite status of the track identified by [trackId].
  Future<Result<void, DatabaseFailure>> toggleFavorite(String trackId);

  /// Increments play count for the given [trackId].
  Future<Result<void, DatabaseFailure>> incrementPlayCount(String trackId);

  /// Deletes a track record from the database.
  Future<Result<void, DatabaseFailure>> deleteTrack(String trackId);

  /// Inserts a new track or updates if file path already exists.
  Future<Result<void, DatabaseFailure>> insertTrack(Track track);

  /// Batch inserts or updates tracks.
  Future<Result<void, DatabaseFailure>> insertTracks(List<Track> tracks);
}
