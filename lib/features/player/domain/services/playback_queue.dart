import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../../../shared/models/track.dart';
import '../entities/playback_state.dart';
import '../entities/queue_context.dart';

/// Immutable state snapshot of the active playback queue.
class PlaybackQueueState extends Equatable {
  const PlaybackQueueState({
    this.tracks = const [],
    this.originalTracks = const [],
    this.currentIndex = -1,
    this.mode = PlaybackMode.ordered,
    this.repeatMode = NexaRepeatMode.stopOnLastTrack,
    this.isShuffled = false,
    this.queueContext,
    this.queueVersion = 0,
    this.playNextIds = const {},
  });

  /// Currently active sequence of tracks (may be shuffled).
  final List<Track> tracks;

  /// Original sequential ordering before any shuffle transformations.
  final List<Track> originalTracks;

  /// Index of the currently active track in [tracks].
  final int currentIndex;

  /// Legacy queue iteration mode view.
  final PlaybackMode mode;

  /// Decoupled Stellio 5-mode repeat setting.
  final NexaRepeatMode repeatMode;

  /// Decoupled shuffle toggle state.
  final bool isShuffled;

  /// Optional metadata identifying the originating library list/folder/album.
  final QueueContext? queueContext;

  /// Monotonically incremented revision counter whenever the active queue is replaced or cleared.
  final int queueVersion;

  /// Track IDs explicitly queued via "Play Next" for subtle "Up Next" badge rendering.
  final Set<String> playNextIds;

  /// Currently playing track, or null if the queue is empty or index invalid.
  Track? get currentTrack {
    if (currentIndex >= 0 && currentIndex < tracks.length) {
      return tracks[currentIndex];
    }
    return null;
  }

  /// Whether there is a subsequent track inside this queue without jumping lists.
  bool get hasNext {
    if (tracks.isEmpty) return false;
    if (repeatMode == NexaRepeatMode.repeatSelectedTrack ||
        repeatMode == NexaRepeatMode.repeatList) {
      return true;
    }
    return currentIndex < tracks.length - 1;
  }

  /// Whether there is a preceding track inside this queue without jumping lists.
  bool get hasPrevious {
    if (tracks.isEmpty) return false;
    if (repeatMode == NexaRepeatMode.repeatList) return true;
    return currentIndex > 0;
  }

  /// The next upcoming track in this queue, or null if list boundary reached.
  Track? get nextTrack {
    if (tracks.isEmpty) return null;
    if (repeatMode == NexaRepeatMode.repeatSelectedTrack) return currentTrack;
    final nextIndex = currentIndex + 1;
    if (nextIndex < tracks.length) return tracks[nextIndex];
    if (repeatMode == NexaRepeatMode.repeatList) return tracks.first;
    return null;
  }

  /// The previous track in this queue, or null if list start reached.
  Track? get previousTrack {
    if (tracks.isEmpty) return null;
    if (repeatMode == NexaRepeatMode.repeatSelectedTrack) return currentTrack;
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) return tracks[prevIndex];
    if (repeatMode == NexaRepeatMode.repeatList) return tracks.last;
    return null;
  }

  /// Number of tracks in the active queue.
  int get length => tracks.length;

  /// Whether the queue contains zero tracks.
  bool get isEmpty => tracks.isEmpty;

  /// Whether the queue contains one or more tracks.
  bool get isNotEmpty => tracks.isNotEmpty;

  /// Returns a copy with specified fields replaced.
  PlaybackQueueState copyWith({
    List<Track>? tracks,
    List<Track>? originalTracks,
    int? currentIndex,
    PlaybackMode? mode,
    NexaRepeatMode? repeatMode,
    bool? isShuffled,
    QueueContext? queueContext,
    bool clearQueueContext = false,
    int? queueVersion,
    Set<String>? playNextIds,
  }) {
    return PlaybackQueueState(
      tracks: tracks ?? this.tracks,
      originalTracks: originalTracks ?? this.originalTracks,
      currentIndex: currentIndex ?? this.currentIndex,
      mode: mode ?? this.mode,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
      queueContext:
          clearQueueContext ? null : (queueContext ?? this.queueContext),
      queueVersion: queueVersion ?? this.queueVersion,
      playNextIds: playNextIds ?? this.playNextIds,
    );
  }

  @override
  List<Object?> get props => [
        tracks,
        originalTracks,
        currentIndex,
        mode,
        repeatMode,
        isShuffled,
        queueContext,
        queueVersion,
        playNextIds,
      ];
}

/// Interface for queue sequencing, shuffle algorithms, and track management.
abstract class IPlaybackQueue {
  /// Current queue state snapshot.
  PlaybackQueueState get state;

  /// Stream of state updates whenever the queue or index changes.
  Stream<PlaybackQueueState> get queueStream;

  /// Replaces the current queue with [tracks] and selects [initialIndex].
  void setQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    PlaybackMode? mode,
    NexaRepeatMode? repeatMode,
    bool? isShuffled,
    QueueContext? queueContext,
  });

  /// Updates queue playback mode (legacy ordered, shuffle, repeat).
  void setMode(PlaybackMode mode);

  /// Updates the Stellio 5-mode repeat setting without disturbing shuffle or current track.
  void setRepeatMode(NexaRepeatMode repeatMode);

  /// Updates shuffle state independently without altering [repeatMode].
  void setShuffle(bool enabled);

  /// Advances to the next track according to current mode, or returns null.
  Track? next();

  /// Moves back to the previous track according to current mode, or returns null.
  Track? previous();

  /// Skips directly to track at [index].
  Track? skipToIndex(int index);

  /// Appends [track] to the end of the queue.
  void addTrack(Track track);

  /// Inserts [track] immediately following the currently active track.
  void addNext(Track track);

  /// Inserts [track] at a specific [index] (used by undo actions).
  void insertTrackAt(int index, Track track);

  /// Removes all tracks queued after [PlaybackQueueState.currentIndex].
  void clearUpNext();

  /// Removes track at [index] from the queue.
  void removeAt(int index);

  /// Reorders track from [oldIndex] to [newIndex] (drag-and-drop support).
  void reorder(int oldIndex, int newIndex);

  /// Replaces matching track entries with [updatedTrack] in-place.
  void updateTrack(Track updatedTrack);

  /// Clears the queue and resets index.
  void clear();

  /// Disposes internal streams and resources.
  void dispose();
}
