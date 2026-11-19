import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Exposes the active [ILyricsService] singleton from service locator.
final lyricsServiceProvider = Provider<ILyricsService>((ref) {
  return getIt<ILyricsService>();
});

/// Fetches and caches lyrics for a specific [Track].
final trackLyricsProvider =
    FutureProvider.family<Lyrics?, Track>((ref, track) async {
  final service = ref.watch(lyricsServiceProvider);
  final res = await service.getLyricsForTrack(track);
  return res.valueOrNull;
});

/// Provides lyrics for the currently playing track.
final currentTrackLyricsProvider = FutureProvider<Lyrics?>((ref) async {
  final currentTrack = ref.watch(currentTrackProvider);
  if (currentTrack == null) return null;
  return ref.watch(trackLyricsProvider(currentTrack).future);
});

/// Computes the index of the active lyric line for current playback position.
final activeLyricIndexProvider = Provider<int>((ref) {
  final lyricsAsync = ref.watch(currentTrackLyricsProvider);
  final lyrics = lyricsAsync.valueOrNull;
  if (lyrics == null || !lyrics.isSynced || lyrics.lines.isEmpty) {
    return -1;
  }

  final playerState = ref.watch(playerNotifierProvider);
  final position = playerState.position;

  return lyrics.findActiveLineIndex(position);
});

/// Manages whether auto-scrolling to the active lyric line is enabled.
final lyricsAutoScrollEnabledProvider = StateProvider<bool>((ref) => true);

/// Notifier managing real-time offset adjustments for lyrics synchronization.
class LyricsOffsetNotifier extends StateNotifier<int> {
  LyricsOffsetNotifier(this.ref) : super(0);

  final Ref ref;

  void setOffset(int offsetMs) {
    state = offsetMs;
  }

  void adjust(int deltaMs) {
    state += deltaMs;
  }

  Future<void> saveOffsetForCurrentTrack() async {
    final track = ref.read(currentTrackProvider);
    if (track == null) return;

    final service = ref.read(lyricsServiceProvider);
    await service.updateOffset(track.id, state);
    ref.invalidate(trackLyricsProvider(track));
  }
}

/// Provider exposing [LyricsOffsetNotifier].
final lyricsOffsetNotifierProvider =
    StateNotifierProvider<LyricsOffsetNotifier, int>((ref) {
  return LyricsOffsetNotifier(ref);
});
