import 'dart:async';
import 'package:equatable/equatable.dart';
import '../../../../shared/models/track.dart';
import '../entities/playback_state.dart';

/// Immutable state snapshot of the active playback queue.
class PlaybackQueueState extends Equatable {
  const PlaybackQueueState({
    this.tracks = const [],
    this.originalTracks = const [],
    this.currentIndex = -1,
    this.mode = PlaybackMode.ordered,
  });

  /// Currently active sequence of tracks (may be shuffled).
  final List<Track> tracks;

  /// Original sequential ordering before any shuffle transformations.
  final List<Track> originalTracks;

  /// Index of the currently active track in [tracks].
  final int currentIndex;

  /// Queue iteration mode.
  final PlaybackMode mode;

  /// Currently playing track, or null if the queue is empty or index invalid.
  Track? get currentTrack {
    if (currentIndex >= 0 && currentIndex < tracks.length) {
      return tracks[currentIndex];
    }
    return null;
  }

  /// Whether there is a subsequent track in queue or if repetition allows looping.
  bool get hasNext {
    if (tracks.isEmpty) return false;
    if (mode == PlaybackMode.repeatOne || mode == PlaybackMode.repeatAll) return true;
    return currentIndex < tracks.length - 1;
  }

  /// Whether there is a preceding track in queue or if repeat-all allows wrapping.
  bool get hasPrevious {
    if (tracks.isEmpty) return false;
    if (mode == PlaybackMode.repeatAll) return true;
    return currentIndex > 0;
  }

  /// The next upcoming track, or null if queue end is reached without repetition.
  Track? get nextTrack {
    if (tracks.isEmpty) return null;
    if (mode == PlaybackMode.repeatOne) return currentTrack;
    final nextIndex = currentIndex + 1;
    if (nextIndex < tracks.length) return tracks[nextIndex];
    if (mode == PlaybackMode.repeatAll) return tracks.first;
    return null;
  }

  /// The previous track, or null if at beginning without repeat-all.
  Track? get previousTrack {
    if (tracks.isEmpty) return null;
    if (mode == PlaybackMode.repeatOne) return currentTrack;
    final prevIndex = currentIndex - 1;
    if (prevIndex >= 0) return tracks[prevIndex];
    if (mode == PlaybackMode.repeatAll) return tracks.last;
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
  }) {
    return PlaybackQueueState(
      tracks: tracks ?? this.tracks,
      originalTracks: originalTracks ?? this.originalTracks,
      currentIndex: currentIndex ?? this.currentIndex,
      mode: mode ?? this.mode,
    );
  }

  @override
  List<Object?> get props => [tracks, originalTracks, currentIndex, mode];
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
  });

  /// Updates queue playback mode (ordered, shuffle, repeat).
  void setMode(PlaybackMode mode);

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

  /// Removes track at [index] from the queue.
  void removeAt(int index);

  /// Reorders track from [oldIndex] to [newIndex] (drag-and-drop support).
  void reorder(int oldIndex, int newIndex);

  /// Clears the queue and resets index.
  void clear();

  /// Disposes internal streams and resources.
  void dispose();
}
