import 'package:equatable/equatable.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Aggregated cross-library search result containing matched entities across all domains.
class SearchResult extends Equatable {
  const SearchResult({
    required this.query,
    this.tracks = const [],
    this.albums = const [],
    this.artists = const [],
    this.playlists = const [],
    this.genres = const [],
  });

  /// Factory for an empty search result.
  factory SearchResult.empty([String query = '']) => SearchResult(query: query);

  /// Raw query string that produced this result.
  final String query;

  /// Matched audio tracks.
  final List<Track> tracks;

  /// Matched albums.
  final List<Album> albums;

  /// Matched artists.
  final List<Artist> artists;

  /// Matched user & system playlists.
  final List<Playlist> playlists;

  /// Matched musical genres.
  final List<Genre> genres;

  /// Whether no matches were found across any category.
  bool get isEmpty =>
      tracks.isEmpty &&
      albums.isEmpty &&
      artists.isEmpty &&
      playlists.isEmpty &&
      genres.isEmpty;

  /// Whether at least one match was found in any category.
  bool get isNotEmpty => !isEmpty;

  /// Total count of all matched items across all categories.
  int get totalCount =>
      tracks.length +
      albums.length +
      artists.length +
      playlists.length +
      genres.length;

  @override
  List<Object?> get props => [query, tracks, albums, artists, playlists, genres];
}
