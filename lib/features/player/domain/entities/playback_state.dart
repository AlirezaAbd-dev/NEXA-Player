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

/// Queue progression and repetition behavior (legacy compatibility enum).
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

/// Stellio-inspired 5-mode repeat & cross-list continuation policy.
enum NexaRepeatMode {
  /// Play the current list through its last track and then stop.
  stopOnLastTrack,

  /// Loop within the current list indefinitely.
  repeatList,

  /// Loop the currently selected track continuously.
  repeatSelectedTrack,

  /// Advance across subsequent lists/folders/albums and stop after the last list.
  nextListStopOnLast,

  /// Advance across subsequent lists/folders/albums and wrap to the first list.
  nextListRepeatFirst;

  /// Display title used in pickers and accessibility tooltips.
  String get label {
    switch (this) {
      case NexaRepeatMode.stopOnLastTrack:
        return 'Stop on last track in a list';
      case NexaRepeatMode.repeatList:
        return 'Repeat a list';
      case NexaRepeatMode.repeatSelectedTrack:
        return 'Repeat selected track';
      case NexaRepeatMode.nextListStopOnLast:
        return 'Jump to next list: stop on last';
      case NexaRepeatMode.nextListRepeatFirst:
        return 'Jump to next list: repeat first';
    }
  }

  /// Compact badge label for transient Now Playing pill toast.
  String get shortLabel {
    switch (this) {
      case NexaRepeatMode.stopOnLastTrack:
        return 'Stop on last track';
      case NexaRepeatMode.repeatList:
        return 'Repeat list';
      case NexaRepeatMode.repeatSelectedTrack:
        return 'Repeat selected track';
      case NexaRepeatMode.nextListStopOnLast:
        return 'Next list · Stop on last';
      case NexaRepeatMode.nextListRepeatFirst:
        return 'Next list · Repeat first';
    }
  }

  /// Detailed helper text shown in the 5-mode bottom sheet picker.
  String get description {
    switch (this) {
      case NexaRepeatMode.stopOnLastTrack:
        return 'Plays to the end of the active list, then stops';
      case NexaRepeatMode.repeatList:
        return 'Loops back to track 1 when the current list finishes';
      case NexaRepeatMode.repeatSelectedTrack:
        return 'Loops the current track endlessly until changed';
      case NexaRepeatMode.nextListStopOnLast:
        return 'Jumps to the next folder/album/playlist and stops at the final list';
      case NexaRepeatMode.nextListRepeatFirst:
        return 'Jumps through every list continuously and wraps to the first list';
    }
  }

  /// Whether any repeat/continuation behavior beyond single-list stop is active.
  bool get isRepeating => this != NexaRepeatMode.stopOnLastTrack;

  /// Whether end-of-list transitions cross into neighboring collections.
  bool get jumpsToNextList =>
      this == NexaRepeatMode.nextListStopOnLast ||
      this == NexaRepeatMode.nextListRepeatFirst;

  /// Returns the next mode in the 5-step cycle order.
  NexaRepeatMode get nextMode {
    const modes = NexaRepeatMode.values;
    return modes[(index + 1) % modes.length];
  }

  /// Stable string key for persistence in [IStorageService].
  String get storageValue => name;

  /// Restores [NexaRepeatMode] from stored string, falling back safely.
  static NexaRepeatMode fromStorage(String? value) {
    if (value == null || value.isEmpty) return NexaRepeatMode.stopOnLastTrack;
    for (final mode in NexaRepeatMode.values) {
      if (mode.name == value) return mode;
    }
    // Backwards compatibility with legacy PlaybackMode names
    switch (value) {
      case 'repeatOne':
        return NexaRepeatMode.repeatSelectedTrack;
      case 'repeatAll':
        return NexaRepeatMode.repeatList;
      case 'ordered':
      default:
        return NexaRepeatMode.stopOnLastTrack;
    }
  }

  /// Maps this Stellio repeat mode + shuffle flag to legacy [PlaybackMode].
  PlaybackMode toLegacyPlaybackMode({required bool isShuffled}) {
    if (this == NexaRepeatMode.repeatSelectedTrack) {
      return PlaybackMode.repeatOne;
    }
    if (isShuffled) {
      return PlaybackMode.shuffle;
    }
    if (this == NexaRepeatMode.repeatList ||
        this == NexaRepeatMode.nextListRepeatFirst) {
      return PlaybackMode.repeatAll;
    }
    return PlaybackMode.ordered;
  }

  /// Maps a legacy [PlaybackMode] into the closest [NexaRepeatMode].
  static NexaRepeatMode fromLegacyPlaybackMode(PlaybackMode mode) {
    switch (mode) {
      case PlaybackMode.repeatOne:
        return NexaRepeatMode.repeatSelectedTrack;
      case PlaybackMode.repeatAll:
        return NexaRepeatMode.repeatList;
      case PlaybackMode.ordered:
      case PlaybackMode.shuffle:
        return NexaRepeatMode.stopOnLastTrack;
    }
  }
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
    this.repeatMode = NexaRepeatMode.stopOnLastTrack,
    this.isShuffled = false,
    this.queueVersion = 0,
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

  /// Queue sequencing mode (legacy compatibility view).
  final PlaybackMode playbackMode;

  /// Stellio-style 5-mode repeat & cross-list continuation setting.
  final NexaRepeatMode repeatMode;

  /// Independent shuffle state preserved across repeat mode changes.
  final bool isShuffled;

  /// Queue revision ID synchronized with [PlaybackQueueState.queueVersion].
  final int queueVersion;

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
    NexaRepeatMode? repeatMode,
    bool? isShuffled,
    int? queueVersion,
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
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
      queueVersion: queueVersion ?? this.queueVersion,
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
        repeatMode,
        isShuffled,
        queueVersion,
        crossfadeDuration,
        errorMessage,
      ];
}
