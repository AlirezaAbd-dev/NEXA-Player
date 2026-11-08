import 'package:equatable/equatable.dart';
import '../../../../shared/models/track.dart';

/// Represents the active playback status of the audio engine.
enum PlaybackStatus {
  /// Audio engine is idle with no track loaded or stopped.
  idle,

  /// Preparing or resolving track audio stream.
  loading,

  /// Buffering stream packets for playback.
  buffering,

  /// Active audio output in progress.
  playing,

  /// Audio paused at current position.
  paused,

  /// Track playback reached natural end.
  completed,

  /// Playback encountered an unrecoverable error.
  error,
}

/// Queue progression and repetition behavior.
enum PlaybackMode {
  /// Play tracks sequentially in natural order and stop at the end.
  ordered,

  /// Shuffled randomized order avoiding immediate duplicate tracks.
  shuffle,

  /// Loop the currently active track continuously.
  repeatOne,

  /// Loop back to the beginning once the queue concludes.
  repeatAll;

  /// Returns whether this mode has repeating semantics.
  bool get isRepeating => this == PlaybackMode.repeatOne || this == PlaybackMode.repeatAll;

  /// Returns whether this mode is shuffled.
  bool get isShuffled => this == PlaybackMode.shuffle;
}

/// Immutable snapshot representing the active player state.
class PlaybackState extends Equatable {
  const PlaybackState({
    this.currentTrack,
    this.status = PlaybackStatus.idle,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.volume = 1.0,
    this.speed = 1.0,
    this.playbackMode = PlaybackMode.ordered,
    this.crossfadeDuration = Duration.zero,
    this.errorMessage,
  });

  /// The active track currently loaded in the player.
  final Track? currentTrack;

  /// The operational status of the playback engine.
  final PlaybackStatus status;

  /// Current playback elapsed position.
  final Duration position;

  /// Total duration of the current track.
  final Duration duration;

  /// Buffered audio stream duration.
  final Duration bufferedPosition;

  /// Volume level between 0.0 and 1.0.
  final double volume;

  /// Playback speed multiplier (0.5x to 2.0x).
  final double speed;

  /// Queue sequencing mode (ordered, shuffle, repeat).
  final PlaybackMode playbackMode;

  /// Crossfade transition duration between tracks.
  final Duration crossfadeDuration;

  /// Optional error description when [status] is [PlaybackStatus.error].
  final String? errorMessage;

  /// Whether audio is actively playing.
  bool get isPlaying => status == PlaybackStatus.playing;

  /// Whether the engine is loading or buffering.
  bool get isBuffering => status == PlaybackStatus.buffering || status == PlaybackStatus.loading;

  /// Whether playback is paused.
  bool get isPaused => status == PlaybackStatus.paused;

  /// Fractional progress between 0.0 and 1.0.
  double get progress {
    if (duration.inMilliseconds <= 0) return 0.0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  /// Remaining track duration.
  Duration get remainingDuration {
    final rem = duration - position;
    return rem.isNegative ? Duration.zero : rem;
  }

  /// Creates a copy with optionally replaced properties.
  PlaybackState copyWith({
    Track? currentTrack,
    bool clearCurrentTrack = false,
    PlaybackStatus? status,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? volume,
    double? speed,
    PlaybackMode? playbackMode,
    Duration? crossfadeDuration,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlaybackState(
      currentTrack: clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      volume: volume ?? this.volume,
      speed: speed ?? this.speed,
      playbackMode: playbackMode ?? this.playbackMode,
      crossfadeDuration: crossfadeDuration ?? this.crossfadeDuration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        currentTrack,
        status,
        position,
        duration,
        bufferedPosition,
        volume,
        speed,
        playbackMode,
        crossfadeDuration,
        errorMessage,
      ];
}
