import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/services/m3u_service.dart';
import 'package:nexa_player/features/playlists/domain/services/ringtone_service.dart';
import 'package:nexa_player/features/playlists/domain/services/share_service.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Provider exposing [IPlaylistsRepository].
final playlistsRepositoryProvider = Provider<IPlaylistsRepository>((ref) {
  return getIt<IPlaylistsRepository>();
});

/// Provider exposing [IM3uService].
final m3uServiceProvider = Provider<IM3uService>((ref) {
  return getIt<IM3uService>();
});

/// Provider exposing [ITagEditorService].
final tagEditorServiceProvider = Provider<ITagEditorService>((ref) {
  return getIt<ITagEditorService>();
});

/// Provider exposing [IRingtoneService].
final ringtoneServiceProvider = Provider<IRingtoneService>((ref) {
  return getIt<IRingtoneService>();
});

/// Provider exposing [IShareService].
final shareServiceProvider = Provider<IShareService>((ref) {
  return getIt<IShareService>();
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

  Future<void> reorderTrack(
    String playlistId,
    int oldIndex,
    int newIndex,
  ) async {
    final repo = ref.read(playlistsRepositoryProvider);
    final res = await repo.reorderPlaylistTracks(playlistId, oldIndex, newIndex);
    if (res.isSuccess) {
      ref.invalidate(playlistTracksProvider(playlistId));
    }
  }

  Future<void> importM3u(String name, String content) async {
    final m3u = ref.read(m3uServiceProvider);
    final res = await m3u.importM3u(name, content);
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
  if (playlistId.startsWith('smart_')) {
    final typeName = playlistId.substring(6);
    final smartType = SmartPlaylistType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => SmartPlaylistType.favorites,
    );
    return ref.watch(smartPlaylistTracksProvider(smartType).future);
  }

  final repo = ref.watch(playlistsRepositoryProvider);
  final res = await repo.getTracksForPlaylist(playlistId);
  return res.valueOrNull ?? [];
});

/// Provider exposing the list of smart playlists.
final smartPlaylistsProvider = Provider<List<SmartPlaylist>>((ref) {
  return SmartPlaylistType.values.map(SmartPlaylist.fromType).toList();
});

/// Provider fetching tracks dynamically for a [SmartPlaylistType].
final smartPlaylistTracksProvider =
    FutureProvider.family<List<Track>, SmartPlaylistType>((ref, type) async {
  final tracksRepo = getIt<ITracksRepository>();

  switch (type) {
    case SmartPlaylistType.recentlyAdded:
      final res = await tracksRepo.getAllTracks(
        sortBy: TrackSortBy.dateAdded,
        ascending: false,
      );
      return res.valueOrNull ?? [];

    case SmartPlaylistType.favorites:
      final res = await tracksRepo.getAllTracks();
      final all = res.valueOrNull ?? [];
      return all.where((t) => t.isFavorite).toList();

    case SmartPlaylistType.topRated:
      final res = await tracksRepo.getAllTracks(sortBy: TrackSortBy.title);
      final all = res.valueOrNull ?? [];
      // Prioritize favorites and high track number / demo tracks
      final favs = all.where((t) => t.isFavorite).toList();
      return favs.isNotEmpty ? favs : all.take(10).toList();

    case SmartPlaylistType.mostPlayed:
      final res = await tracksRepo.getAllTracks(
        sortBy: TrackSortBy.dateAdded,
        ascending: true,
      );
      return res.valueOrNull ?? [];
  }
});
