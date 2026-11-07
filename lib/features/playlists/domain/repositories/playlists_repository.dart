import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Repository contract managing playlists and ordered playlist tracks.
abstract interface class IPlaylistsRepository {
  /// Fetches all playlists ordered alphabetically.
  Future<Result<List<Playlist>, DatabaseFailure>> getAllPlaylists();

  /// Fetches a single playlist by [id].
  Future<Result<Playlist?, DatabaseFailure>> getPlaylistById(String id);

  /// Creates a new playlist with the given [name] and optional [description].
  Future<Result<Playlist, DatabaseFailure>> createPlaylist(
    String name, {
    String? description,
  });

  /// Deletes a playlist by [playlistId], cascading removal of its track links.
  Future<Result<void, DatabaseFailure>> deletePlaylist(String playlistId);

  /// Appends [trackId] to the end of the playlist identified by [playlistId].
  Future<Result<void, DatabaseFailure>> addTrackToPlaylist(
    String playlistId,
    String trackId,
  );

  /// Removes [trackId] from [playlistId] and recalculates positions.
  Future<Result<void, DatabaseFailure>> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  );

  /// Fetches all tracks in [playlistId] in their customized sort order.
  Future<Result<List<Track>, DatabaseFailure>> getTracksForPlaylist(
    String playlistId,
  );

  /// Reorders track position within [playlistId].
  Future<Result<void, DatabaseFailure>> reorderPlaylistTracks(
    String playlistId,
    int oldIndex,
    int newIndex,
  );
}
