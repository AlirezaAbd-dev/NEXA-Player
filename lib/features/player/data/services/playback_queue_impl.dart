import 'dart:async';
import 'dart:math';
import '../../../../shared/models/track.dart';
import '../../domain/entities/playback_state.dart';
import '../../domain/entities/queue_context.dart';
import '../../domain/services/playback_queue.dart';

/// Concrete implementation of [IPlaybackQueue] with Fisher-Yates shuffling
/// and seamless index preservation.
class PlaybackQueueImpl implements IPlaybackQueue {
  PlaybackQueueImpl({
    Random? random,
  }) : _random = random ?? Random();

  final Random _random;
  final _controller = StreamController<PlaybackQueueState>.broadcast(sync: true);

  PlaybackQueueState _state = const PlaybackQueueState();

  @override
  PlaybackQueueState get state => _state;

  @override
  Stream<PlaybackQueueState> get queueStream => _controller.stream;

  void _emit(PlaybackQueueState newState) {
    _state = newState;
    if (!_controller.isClosed) {
      _controller.add(_state);
    }
  }

  @override
  void setQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    PlaybackMode? mode,
    NexaRepeatMode? repeatMode,
    bool? isShuffled,
    QueueContext? queueContext,
  }) {
    final activeRepeatMode = repeatMode ??
        (mode != null && mode != PlaybackMode.shuffle
            ? NexaRepeatMode.fromLegacyPlaybackMode(mode)
            : _state.repeatMode);
    final activeShuffled = isShuffled ??
        (mode != null ? mode == PlaybackMode.shuffle : _state.isShuffled);
    final activeLegacyMode =
        activeRepeatMode.toLegacyPlaybackMode(isShuffled: activeShuffled);
    final original = List<Track>.from(tracks);

    final nextVersion = _state.queueVersion + 1;

    if (original.isEmpty) {
      _emit(PlaybackQueueState(
        tracks: const [],
        originalTracks: const [],
        currentIndex: -1,
        mode: activeLegacyMode,
        repeatMode: activeRepeatMode,
        isShuffled: activeShuffled,
        queueContext: queueContext,
        queueVersion: nextVersion,
      ));
      return;
    }

    final clampedInitial = initialIndex.clamp(0, original.length - 1);
    final selectedTrack = original[clampedInitial];

    if (activeShuffled) {
      final shuffled = _createShuffledList(original, keepFirst: selectedTrack);
      _emit(PlaybackQueueState(
        tracks: shuffled,
        originalTracks: original,
        currentIndex: 0,
        mode: activeLegacyMode,
        repeatMode: activeRepeatMode,
        isShuffled: true,
        queueContext: queueContext,
        queueVersion: nextVersion,
      ));
    } else {
      _emit(PlaybackQueueState(
        tracks: original,
        originalTracks: original,
        currentIndex: clampedInitial,
        mode: activeLegacyMode,
        repeatMode: activeRepeatMode,
        isShuffled: false,
        queueContext: queueContext,
        queueVersion: nextVersion,
      ));
    }
  }

  @override
  void setMode(PlaybackMode mode) {
    if (mode == PlaybackMode.shuffle) {
      setShuffle(true);
      return;
    }
    if (mode == PlaybackMode.repeatOne) {
      if (_state.isShuffled) {
        _applyShuffleAndRepeat(
          isShuffled: false,
          repeatMode: NexaRepeatMode.repeatSelectedTrack,
        );
      } else {
        setRepeatMode(NexaRepeatMode.repeatSelectedTrack);
      }
      return;
    }
    if (mode == PlaybackMode.repeatAll) {
      if (_state.isShuffled) {
        _applyShuffleAndRepeat(
          isShuffled: false,
          repeatMode: NexaRepeatMode.repeatList,
        );
      } else {
        setRepeatMode(NexaRepeatMode.repeatList);
      }
      return;
    }
    // PlaybackMode.ordered
    if (_state.isShuffled) {
      setShuffle(false);
    } else {
      setRepeatMode(NexaRepeatMode.stopOnLastTrack);
    }
  }

  @override
  void setRepeatMode(NexaRepeatMode repeatMode) {
    if (repeatMode == _state.repeatMode &&
        _state.mode ==
            repeatMode.toLegacyPlaybackMode(isShuffled: _state.isShuffled)) {
      return;
    }
    _emit(_state.copyWith(
      repeatMode: repeatMode,
      mode: repeatMode.toLegacyPlaybackMode(isShuffled: _state.isShuffled),
    ));
  }

  @override
  void setShuffle(bool enabled) {
    _applyShuffleAndRepeat(
      isShuffled: enabled,
      repeatMode: _state.repeatMode,
    );
  }

  void _applyShuffleAndRepeat({
    required bool isShuffled,
    required NexaRepeatMode repeatMode,
  }) {
    final legacyMode =
        repeatMode.toLegacyPlaybackMode(isShuffled: isShuffled);

    if (isShuffled == _state.isShuffled && repeatMode == _state.repeatMode) {
      if (_state.mode != legacyMode) {
        _emit(_state.copyWith(mode: legacyMode));
      }
      return;
    }

    final current = _state.currentTrack;
    if (isShuffled && !_state.isShuffled) {
      if (_state.originalTracks.isNotEmpty) {
        final shuffled =
            _createShuffledList(_state.originalTracks, keepFirst: current);
        _emit(_state.copyWith(
          tracks: shuffled,
          currentIndex: 0,
          isShuffled: true,
          repeatMode: repeatMode,
          mode: legacyMode,
        ));
        return;
      }
    } else if (!isShuffled && _state.isShuffled) {
      final restored = List<Track>.from(_state.originalTracks);
      var restoredIndex = restored.isEmpty ? -1 : 0;
      if (current != null && restored.isNotEmpty) {
        final idx = restored.indexWhere((t) => t.id == current.id);
        if (idx != -1) restoredIndex = idx;
      }
      _emit(_state.copyWith(
        tracks: restored,
        currentIndex: restoredIndex,
        isShuffled: false,
        repeatMode: repeatMode,
        mode: legacyMode,
      ));
      return;
    }

    _emit(_state.copyWith(
      isShuffled: isShuffled,
      repeatMode: repeatMode,
      mode: legacyMode,
    ));
  }

  @override
  Track? next() {
    if (_state.tracks.isEmpty) return null;

    if (_state.repeatMode == NexaRepeatMode.repeatSelectedTrack) {
      return _state.currentTrack;
    }

    final nextIndex = _state.currentIndex + 1;
    if (nextIndex < _state.tracks.length) {
      _emit(_state.copyWith(currentIndex: nextIndex));
      return _state.currentTrack;
    }

    if (_state.repeatMode == NexaRepeatMode.repeatList) {
      _emit(_state.copyWith(currentIndex: 0));
      return _state.currentTrack;
    }

    // Reached list end: stopOnLastTrack or nextList* modes return null so
    // PlayerNotifier can either stop or jump to the next collection.
    return null;
  }

  @override
  Track? previous() {
    if (_state.tracks.isEmpty) return null;

    if (_state.repeatMode == NexaRepeatMode.repeatSelectedTrack) {
      return _state.currentTrack;
    }

    final prevIndex = _state.currentIndex - 1;
    if (prevIndex >= 0) {
      _emit(_state.copyWith(currentIndex: prevIndex));
      return _state.currentTrack;
    }

    if (_state.repeatMode == NexaRepeatMode.repeatList) {
      final lastIndex = _state.tracks.length - 1;
      _emit(_state.copyWith(currentIndex: lastIndex));
      return _state.currentTrack;
    }

    return null;
  }

  @override
  Track? skipToIndex(int index) {
    if (index < 0 || index >= _state.tracks.length) return null;
    _emit(_state.copyWith(currentIndex: index));
    return _state.currentTrack;
  }

  @override
  void addTrack(Track track) {
    final updatedTracks = List<Track>.from(_state.tracks)..add(track);
    final updatedOriginal = List<Track>.from(_state.originalTracks)..add(track);
    final newIndex = _state.currentIndex == -1 ? 0 : _state.currentIndex;

    _emit(_state.copyWith(
      tracks: updatedTracks,
      originalTracks: updatedOriginal,
      currentIndex: newIndex,
    ));
  }

  @override
  void addNext(Track track) {
    final updatedTracks = List<Track>.from(_state.tracks);
    final updatedOriginal = List<Track>.from(_state.originalTracks);

    if (_state.currentIndex == -1 || updatedTracks.isEmpty) {
      addTrack(track);
      return;
    }

    final insertIdx = _state.currentIndex + 1;
    updatedTracks.insert(insertIdx, track);
    updatedOriginal.add(track);

    _emit(_state.copyWith(
      tracks: updatedTracks,
      originalTracks: updatedOriginal,
    ));
  }

  @override
  void removeAt(int index) {
    if (index < 0 || index >= _state.tracks.length) return;

    final targetTrack = _state.tracks[index];
    final updatedTracks = List<Track>.from(_state.tracks)..removeAt(index);
    final updatedOriginal = List<Track>.from(_state.originalTracks)
      ..removeWhere((t) => t.id == targetTrack.id);

    int newIndex = _state.currentIndex;
    if (updatedTracks.isEmpty) {
      newIndex = -1;
    } else if (index < _state.currentIndex) {
      newIndex = _state.currentIndex - 1;
    } else if (newIndex >= updatedTracks.length) {
      newIndex = updatedTracks.length - 1;
    }

    _emit(_state.copyWith(
      tracks: updatedTracks,
      originalTracks: updatedOriginal,
      currentIndex: newIndex,
    ));
  }

  @override
  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _state.tracks.length) return;
    if (newIndex < 0 || newIndex > _state.tracks.length) return;

    final updatedTracks = List<Track>.from(_state.tracks);
    final effectiveNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = updatedTracks.removeAt(oldIndex);
    updatedTracks.insert(effectiveNewIndex, item);

    int updatedCurrentIndex = _state.currentIndex;
    if (_state.currentIndex == oldIndex) {
      updatedCurrentIndex = effectiveNewIndex;
    } else if (oldIndex < _state.currentIndex && effectiveNewIndex >= _state.currentIndex) {
      updatedCurrentIndex--;
    } else if (oldIndex > _state.currentIndex && effectiveNewIndex <= _state.currentIndex) {
      updatedCurrentIndex++;
    }

    _emit(_state.copyWith(
      tracks: updatedTracks,
      currentIndex: updatedCurrentIndex,
    ));
  }

  @override
  void updateTrack(Track updatedTrack) {
    bool changed = false;
    final nextTracks = _state.tracks.map((t) {
      if (t.id == updatedTrack.id) {
        changed = true;
        return updatedTrack;
      }
      return t;
    }).toList();
    final nextOriginal = _state.originalTracks.map((t) {
      if (t.id == updatedTrack.id) {
        changed = true;
        return updatedTrack;
      }
      return t;
    }).toList();
    if (!changed) return;
    _emit(_state.copyWith(
      tracks: nextTracks,
      originalTracks: nextOriginal,
    ));
  }

  @override
  void clear() {
    _emit(PlaybackQueueState(
      tracks: const [],
      originalTracks: const [],
      currentIndex: -1,
      mode: _state.mode,
      repeatMode: _state.repeatMode,
      isShuffled: _state.isShuffled,
      queueVersion: _state.queueVersion + 1,
    ));
  }

  @override
  void dispose() {
    _controller.close();
  }

  List<Track> _createShuffledList(List<Track> source, {Track? keepFirst}) {
    final list = List<Track>.from(source);
    if (keepFirst != null) {
      list.removeWhere((t) => t.id == keepFirst.id);
    }

    // Fisher-Yates shuffle
    for (int i = list.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = list[i];
      list[i] = list[j];
      list[j] = temp;
    }

    if (keepFirst != null) {
      list.insert(0, keepFirst);
    }
    return list;
  }
}
