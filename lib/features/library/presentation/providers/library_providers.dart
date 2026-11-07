import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/library/domain/repositories/albums_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/artists_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/genres_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/genre.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Provider exposing [ITracksRepository].
final tracksRepositoryProvider = Provider<ITracksRepository>((ref) {
  return getIt<ITracksRepository>();
});

/// Provider exposing [IAlbumsRepository].
final albumsRepositoryProvider = Provider<IAlbumsRepository>((ref) {
  return getIt<IAlbumsRepository>();
});

/// Provider exposing [IArtistsRepository].
final artistsRepositoryProvider = Provider<IArtistsRepository>((ref) {
  return getIt<IArtistsRepository>();
});

/// Provider exposing [IGenresRepository].
final genresRepositoryProvider = Provider<IGenresRepository>((ref) {
  return getIt<IGenresRepository>();
});

/// Provider exposing [IFoldersRepository].
final foldersRepositoryProvider = Provider<IFoldersRepository>((ref) {
  return getIt<IFoldersRepository>();
});

/// Query parameter container for track filtering and sorting.
class TrackQueryParams {
  const TrackQueryParams({
    this.sortBy = TrackSortBy.title,
    this.ascending = true,
    this.searchQuery,
  });

  final TrackSortBy sortBy;
  final bool ascending;
  final String? searchQuery;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackQueryParams &&
          runtimeType == other.runtimeType &&
          sortBy == other.sortBy &&
          ascending == other.ascending &&
          searchQuery == other.searchQuery;

  @override
  int get hashCode =>
      sortBy.hashCode ^ ascending.hashCode ^ (searchQuery?.hashCode ?? 0);
}

/// Provider fetching tracks dynamically with query parameters.
final tracksListProvider =
    FutureProvider.family<List<Track>, TrackQueryParams>((ref, params) async {
  final repo = ref.watch(tracksRepositoryProvider);
  final result = await repo.getAllTracks(
    sortBy: params.sortBy,
    ascending: params.ascending,
    searchQuery: params.searchQuery,
  );
  return result.valueOrNull ?? [];
});

/// Provider fetching all albums.
final albumsListProvider =
    FutureProvider.family<List<Album>, String?>((ref, searchQuery) async {
  final repo = ref.watch(albumsRepositoryProvider);
  final result = await repo.getAllAlbums(searchQuery: searchQuery);
  return result.valueOrNull ?? [];
});

/// Provider fetching tracks for a specific album.
final albumDetailTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, albumId) async {
  final repo = ref.watch(albumsRepositoryProvider);
  final result = await repo.getTracksForAlbum(albumId);
  return result.valueOrNull ?? [];
});

/// Provider fetching all artists.
final artistsListProvider =
    FutureProvider.family<List<Artist>, String?>((ref, searchQuery) async {
  final repo = ref.watch(artistsRepositoryProvider);
  final result = await repo.getAllArtists(searchQuery: searchQuery);
  return result.valueOrNull ?? [];
});

/// Provider fetching tracks for a specific artist.
final artistDetailTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, artistId) async {
  final repo = ref.watch(artistsRepositoryProvider);
  final result = await repo.getTracksForArtist(artistId);
  return result.valueOrNull ?? [];
});

/// Provider fetching all genres.
final genresListProvider =
    FutureProvider.family<List<Genre>, String?>((ref, searchQuery) async {
  final repo = ref.watch(genresRepositoryProvider);
  final result = await repo.getAllGenres(searchQuery: searchQuery);
  return result.valueOrNull ?? [];
});

/// Provider fetching tracks for a specific genre.
final genreDetailTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, genreId) async {
  final repo = ref.watch(genresRepositoryProvider);
  final result = await repo.getTracksForGenre(genreId);
  return result.valueOrNull ?? [];
});

/// Provider fetching folder hierarchy.
final foldersTreeProvider =
    FutureProvider.family<List<FolderNode>, List<String>>((ref, rootPaths) async {
  final repo = ref.watch(foldersRepositoryProvider);
  final result = await repo.getFoldersTree(rootPaths);
  return result.valueOrNull ?? [];
});
