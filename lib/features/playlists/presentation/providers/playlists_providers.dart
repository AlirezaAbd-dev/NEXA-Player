import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Provider exposing [IPlaylistsRepository].
final playlistsRepositoryProvider = Provider<IPlaylistsRepository>((ref) {
  return getIt<IPlaylistsRepository>();
});

/// Async notifier managing the list of playlists.
class PlaylistsNotifier extends AsyncNotifier<List<Playlist>> {
  @override
  FutureOr<List<Playlist>> build() async {
    final repo = ref.watch(playlistsRepositoryProvider);
    final res = await repo.getAllPlaylists();
    return res.valueOrNull ?? [];
  }

  Future<void> createPlaylist(String name, {String? description}) async {
    final repo = ref.read(playlistsRepositoryProvider);
    final res = await repo.createPlaylist(name, description: description);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    final repo = ref.read(playlistsRepositoryProvider);
    final res = await repo.deletePlaylist(playlistId);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }

  Future<void> addTrack(String playlistId, String trackId) async {
    final repo = ref.read(playlistsRepositoryProvider);
    final res = await repo.addTrackToPlaylist(playlistId, trackId);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }

  Future<void> removeTrack(String playlistId, String trackId) async {
    final repo = ref.read(playlistsRepositoryProvider);
    final res = await repo.removeTrackFromPlaylist(playlistId, trackId);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }
}

/// Provider exposing [PlaylistsNotifier].
final playlistsListNotifierProvider =
    AsyncNotifierProvider<PlaylistsNotifier, List<Playlist>>(
  PlaylistsNotifier.new,
);

/// Provider fetching ordered tracks in a specific playlist.
final playlistTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, playlistId) async {
  final repo = ref.watch(playlistsRepositoryProvider);
  final res = await repo.getTracksForPlaylist(playlistId);
  return res.valueOrNull ?? [];
});
