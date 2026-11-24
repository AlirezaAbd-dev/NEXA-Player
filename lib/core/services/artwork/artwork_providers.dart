import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../di/injection.dart';
import '../../../features/library/domain/repositories/albums_repository.dart';
import '../../../features/library/domain/repositories/tracks_repository.dart';
import '../../../features/playlists/presentation/providers/playlists_providers.dart';
import '../../../shared/models/album.dart';
import '../../../shared/models/track.dart';
import 'artwork_resolution_service.dart';

/// Exposes the singleton [IArtworkResolutionService] safely with an in-process fallback.
final artworkResolutionServiceProvider =
    Provider<IArtworkResolutionService>((ref) {
  if (getIt.isRegistered<IArtworkResolutionService>()) {
    return getIt<IArtworkResolutionService>();
  }
  return ArtworkResolutionService();
});

/// Lazily resolves a displayable local/cached cover path for [track].
final resolvedTrackArtworkProvider =
    FutureProvider.family<String?, Track>((ref, track) async {
  final service = ref.watch(artworkResolutionServiceProvider);
  return service.resolveTrackArtwork(track);
});

/// Lazily resolves a displayable cover path for [album], consulting its tracks if needed.
final resolvedAlbumArtworkProvider =
    FutureProvider.family<String?, Album>((ref, album) async {
  final service = ref.watch(artworkResolutionServiceProvider);
  List<Track> albumTracks = const [];
  if (getIt.isRegistered<IAlbumsRepository>()) {
    final res = await getIt<IAlbumsRepository>().getTracksForAlbum(album.id);
    albumTracks = res.valueOrNull ?? const [];
  } else if (getIt.isRegistered<ITracksRepository>()) {
    final res = await getIt<ITracksRepository>().getAllTracks();
    albumTracks = (res.valueOrNull ?? const [])
        .where((t) => t.albumId == album.id || t.album == album.title)
        .toList();
  }
  return service.resolveAlbumArtwork(album, tracks: albumTracks);
});

/// Resolves up to 4 unique cover artwork paths for a playlist's 2x2 collage thumbnail.
final playlistCollageArtworkProvider =
    FutureProvider.family<List<String>, String>((ref, playlistId) async {
  final tracks = await ref.watch(playlistTracksProvider(playlistId).future);
  final service = ref.watch(artworkResolutionServiceProvider);
  final covers = <String>[];
  final seen = <String>{};

  for (final track in tracks) {
    if (covers.length >= 4) break;
    final art = await service.resolveTrackArtwork(track, maxSize: 256);
    if (art != null && art.isNotEmpty && seen.add(art)) {
      covers.add(art);
    }
  }
  return covers;
});
