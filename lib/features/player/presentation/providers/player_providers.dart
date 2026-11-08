import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/models/track.dart';
import '../../../library/domain/repositories/tracks_repository.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/services/audio_engine.dart';
import '../../domain/services/playback_queue.dart';
import '../../domain/services/sleep_timer_service.dart';
import 'player_notifier.dart';

/// Exposes the active [IAudioEngine] instance from dependency injection.
final audioEngineProvider = Provider<IAudioEngine>((ref) {
  return getIt<IAudioEngine>();
});

/// Exposes the active [IPlaybackQueue] instance from dependency injection.
final playbackQueueProvider = Provider<IPlaybackQueue>((ref) {
  return getIt<IPlaybackQueue>();
});

/// Exposes the active [ISleepTimerService] instance from dependency injection.
final sleepTimerServiceProvider = Provider<ISleepTimerService>((ref) {
  return getIt<ISleepTimerService>();
});

/// Stream provider for real-time queue state updates.
final playbackQueueStateStreamProvider = StreamProvider<PlaybackQueueState>((ref) {
  final queue = ref.watch(playbackQueueProvider);
  return queue.queueStream;
});

/// Stream provider for remaining sleep timer duration.
final sleepTimerRemainingProvider = StreamProvider<Duration?>((ref) {
  final timer = ref.watch(sleepTimerServiceProvider);
  return timer.remainingStream;
});

/// Main PlayerNotifier provider governing active player state and controls.
final playerNotifierProvider =
    StateNotifierProvider<PlayerNotifier, PlaybackState>((ref) {
  final engine = ref.watch(audioEngineProvider);
  final queue = ref.watch(playbackQueueProvider);
  final sleepTimer = ref.watch(sleepTimerServiceProvider);
  final tracksRepo = getIt.isRegistered<ITracksRepository>()
      ? getIt<ITracksRepository>()
      : null;

  return PlayerNotifier(
    engine: engine,
    queue: queue,
    sleepTimer: sleepTimer,
    tracksRepository: tracksRepo,
  );
});

/// Selected provider for currently playing track.
final currentTrackProvider = Provider<Track?>((ref) {
  return ref.watch(playerNotifierProvider.select((s) => s.currentTrack));
});

/// Selected provider for whether audio is actively playing.
final isPlayingProvider = Provider<bool>((ref) {
  return ref.watch(playerNotifierProvider.select((s) => s.isPlaying));
});

/// Selected provider for current playback progress ratio (0.0 to 1.0).
final playbackProgressProvider = Provider<double>((ref) {
  return ref.watch(playerNotifierProvider.select((s) => s.progress));
});

/// Selected provider for playback mode.
final playbackModeProvider = Provider<PlaybackMode>((ref) {
  return ref.watch(playerNotifierProvider.select((s) => s.playbackMode));
});
