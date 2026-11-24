import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_smart_playlists_repository.dart';
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

/// Provider exposing [ISmartPlaylistsRepository].
final smartPlaylistsRepositoryProvider =
    Provider<ISmartPlaylistsRepository?>((ref) {
  return getIt.isRegistered<ISmartPlaylistsRepository>()
      ? getIt<ISmartPlaylistsRepository>()
      : null;
});

/// Configurable cap (default 30; options 20 / 30 / 50) for the "Recently Added" smart playlist.
final recentlyAddedLimitProvider = StateProvider<int>((ref) => 30);

/// Reactive provider fetching ordered tracks in a specific user or smart playlist.
final playlistTracksProvider =
    FutureProvider.family<List<Track>, String>((ref, playlistId) async {
  ref.watch(librarySyncRevisionProvider);
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

/// Provider fetching tracks dynamically for a [SmartPlaylistType] from SQLite.
final smartPlaylistTracksProvider =
    FutureProvider.family<List<Track>, SmartPlaylistType>((ref, type) async {
  ref.watch(librarySyncRevisionProvider);
  final recentlyAddedLimit = ref.watch(recentlyAddedLimitProvider);
  final smartRepo = ref.watch(smartPlaylistsRepositoryProvider);
  if (smartRepo != null) {
    final res = await smartRepo.getTracksForSmartPlaylist(
      type,
      recentlyAddedLimit: recentlyAddedLimit,
    );
    return res.valueOrNull ?? [];
  }

  final tracksRepo = getIt<ITracksRepository>();
  switch (type) {
    case SmartPlaylistType.recentlyAdded:
      final res = await tracksRepo.getAllTracks(
        sortBy: TrackSortBy.dateAdded,
        ascending: false,
      );
      return (res.valueOrNull ?? []).take(recentlyAddedLimit).toList();

    case SmartPlaylistType.favorites:
      final res = await tracksRepo.getAllTracks();
      return (res.valueOrNull ?? []).where((t) => t.isFavorite).toList();

    case SmartPlaylistType.mostPlayed:
      final res = await tracksRepo.getAllTracks();
      final played = (res.valueOrNull ?? []).where((t) => t.playCount > 0).toList()
        ..sort((a, b) => b.playCount.compareTo(a.playCount));
      return played.take(30).toList();

    case SmartPlaylistType.recentlyPlayed:
      final res = await tracksRepo.getAllTracks();
      final played = (res.valueOrNull ?? []).where((t) => t.playCount > 0).toList();
      return played.take(30).toList();
  }
});
