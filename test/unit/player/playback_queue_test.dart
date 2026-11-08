import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  group('PlaybackQueueImpl Tests', () {
    late PlaybackQueueImpl queue;

    final testTracks = List.generate(
      5,
      (i) => Track(
        id: 'track-$i',
        title: 'Track $i',
        artist: 'Artist $i',
        album: 'Album $i',
        duration: Duration(minutes: 3 + i),
      ),
    );

    setUp(() {
      queue = PlaybackQueueImpl(random: Random(42));
    });

    tearDown(() {
      queue.dispose();
    });

    test('initial state is empty with index -1', () {
      expect(queue.state.tracks, isEmpty);
      expect(queue.state.currentIndex, -1);
      expect(queue.state.currentTrack, isNull);
      expect(queue.state.hasNext, isFalse);
      expect(queue.state.hasPrevious, isFalse);
    });

    test('setQueue populates tracks and selects initialIndex', () {
      queue.setQueue(testTracks, initialIndex: 2);

      expect(queue.state.tracks.length, 5);
      expect(queue.state.currentIndex, 2);
      expect(queue.state.currentTrack?.id, 'track-2');
      expect(queue.state.hasNext, isTrue);
      expect(queue.state.hasPrevious, isTrue);
    });

    test('next and previous traverse sequentially in ordered mode', () {
      queue.setQueue(testTracks, initialIndex: 0);

      expect(queue.next()?.id, 'track-1');
      expect(queue.state.currentIndex, 1);

      expect(queue.next()?.id, 'track-2');
      expect(queue.state.currentIndex, 2);

      expect(queue.previous()?.id, 'track-1');
      expect(queue.state.currentIndex, 1);
    });

    test('ordered mode stops at queue boundaries without wrapping', () {
      queue.setQueue(testTracks, initialIndex: 4);

      expect(queue.state.hasNext, isFalse);
      expect(queue.next(), isNull);
      expect(queue.state.currentIndex, 4);

      queue.skipToIndex(0);
      expect(queue.state.hasPrevious, isFalse);
      expect(queue.previous(), isNull);
      expect(queue.state.currentIndex, 0);
    });

    test('repeatAll mode loops endlessly between boundaries', () {
      queue.setQueue(testTracks, initialIndex: 4, mode: PlaybackMode.repeatAll);

      expect(queue.state.hasNext, isTrue);
      expect(queue.next()?.id, 'track-0');
      expect(queue.state.currentIndex, 0);

      expect(queue.state.hasPrevious, isTrue);
      expect(queue.previous()?.id, 'track-4');
      expect(queue.state.currentIndex, 4);
    });

    test('repeatOne mode retains current track indefinitely', () {
      queue.setQueue(testTracks, initialIndex: 2, mode: PlaybackMode.repeatOne);

      expect(queue.next()?.id, 'track-2');
      expect(queue.state.currentIndex, 2);
      expect(queue.previous()?.id, 'track-2');
      expect(queue.state.currentIndex, 2);
    });

    test('shuffle mode keeps active track first and randomizes remainder', () {
      queue.setQueue(testTracks, initialIndex: 3, mode: PlaybackMode.shuffle);

      expect(queue.state.tracks.first.id, 'track-3');
      expect(queue.state.currentIndex, 0);
      expect(queue.state.tracks.length, 5);

      // Verify all tracks present
      final ids = queue.state.tracks.map((t) => t.id).toSet();
      expect(ids.length, 5);
    });

    test('switching between shuffle and ordered restores original order and position', () {
      queue.setQueue(testTracks, initialIndex: 2);
      expect(queue.state.currentTrack?.id, 'track-2');

      queue.setMode(PlaybackMode.shuffle);
      expect(queue.state.mode, PlaybackMode.shuffle);
      expect(queue.state.currentTrack?.id, 'track-2');
      expect(queue.state.currentIndex, 0);

      queue.setMode(PlaybackMode.ordered);
      expect(queue.state.mode, PlaybackMode.ordered);
      expect(queue.state.currentTrack?.id, 'track-2');
      expect(queue.state.currentIndex, 2);
      expect(queue.state.tracks, equals(testTracks));
    });

    test('addTrack appends to end of queue', () {
      queue.setQueue(testTracks);
      const newTrack = Track(
        id: 'track-new',
        title: 'New Track',
        artist: 'Artist',
        duration: Duration(minutes: 4),
      );

      queue.addTrack(newTrack);
      expect(queue.state.tracks.length, 6);
      expect(queue.state.tracks.last.id, 'track-new');
    });

    test('addNext inserts immediately after active track', () {
      queue.setQueue(testTracks, initialIndex: 1);
      const nextTrack = Track(
        id: 'track-inserted',
        title: 'Play Next',
        artist: 'Artist',
        duration: Duration(minutes: 3),
      );

      queue.addNext(nextTrack);
      expect(queue.state.tracks[2].id, 'track-inserted');
      expect(queue.state.currentIndex, 1);
    });

    test('removeAt removes track and adjusts index correctly', () {
      queue.setQueue(testTracks, initialIndex: 3);

      // Remove item before current
      queue.removeAt(0);
      expect(queue.state.tracks.length, 4);
      expect(queue.state.currentIndex, 2);
      expect(queue.state.currentTrack?.id, 'track-3');

      // Remove current item
      queue.removeAt(2);
      expect(queue.state.tracks.length, 3);
      expect(queue.state.currentIndex, 2);
      expect(queue.state.currentTrack?.id, 'track-4');
    });

    test('reorder cleanly changes track position and tracks active index', () {
      queue.setQueue(testTracks, initialIndex: 2); // 'track-2'

      // Move item 0 to position 4
      queue.reorder(0, 4);
      expect(queue.state.tracks[3].id, 'track-0');
      expect(queue.state.currentTrack?.id, 'track-2');
      expect(queue.state.currentIndex, 1);
    });

    test('clear resets queue completely', () {
      queue.setQueue(testTracks);
      queue.clear();

      expect(queue.state.tracks, isEmpty);
      expect(queue.state.currentIndex, -1);
      expect(queue.state.currentTrack, isNull);
    });
  });
}
