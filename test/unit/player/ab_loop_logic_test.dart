import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/data/datasources/track_bookmark_dao.dart';
import 'package:nexa_player/features/player/domain/models/track_bookmark.dart';
import '../../helpers/mock_services.dart';

void main() {
  group('TrackBookmark Model & DAO Unit Tests', () {
    test('TrackBookmark serializes to and from JSON correctly', () {
      final bookmark = TrackBookmark(
        id: 'bm_1',
        trackId: 'track_123',
        position: const Duration(minutes: 1, seconds: 45),
        label: 'Solo Start',
        colorValue: 0xFFFF4081,
        createdAt: DateTime(2026, 11, 23, 10, 0, 0),
      );

      final json = bookmark.toJson();
      final restored = TrackBookmark.fromJson(json);

      expect(restored, equals(bookmark));
      expect(restored.position.inSeconds, equals(105));
      expect(restored.label, equals('Solo Start'));
    });

    test('TrackBookmarkDao performs CRUD operations persistently', () async {
      final fakeStorage = FakeStorageService();
      final dao = TrackBookmarkDao(fakeStorage);

      // Initially empty
      final initial = await dao.getBookmarks('track_1');
      expect(initial, isEmpty);

      // Add two bookmarks
      final b1 = TrackBookmark(
        id: '1',
        trackId: 'track_1',
        position: const Duration(seconds: 30),
        label: 'A',
        createdAt: DateTime.now(),
      );
      final b2 = TrackBookmark(
        id: '2',
        trackId: 'track_1',
        position: const Duration(seconds: 60),
        label: 'B',
        createdAt: DateTime.now(),
      );

      await dao.addBookmark(b1);
      await dao.addBookmark(b2);

      final fetched = await dao.getBookmarks('track_1');
      expect(fetched.length, equals(2));
      expect(fetched.first.id, equals('1'));
      expect(fetched.last.id, equals('2'));

      // Remove bookmark 1
      await dao.removeBookmark('track_1', '1');
      final afterRemove = await dao.getBookmarks('track_1');
      expect(afterRemove.length, equals(1));
      expect(afterRemove.first.id, equals('2'));

      // Clear
      await dao.clearBookmarks('track_1');
      final cleared = await dao.getBookmarks('track_1');
      expect(cleared, isEmpty);
    });
  });

  group('ABLoopRange Domain Logic Tests', () {
    test('isValid requires start < end and at least 300ms loop length', () {
      const empty = ABLoopRange(trackId: 't1');
      expect(empty.isValid, isFalse);

      const onlyStart = ABLoopRange(
        trackId: 't1',
        start: Duration(seconds: 10),
      );
      expect(onlyStart.isValid, isFalse);

      const reversed = ABLoopRange(
        trackId: 't1',
        start: Duration(seconds: 20),
        end: Duration(seconds: 10),
      );
      expect(reversed.isValid, isFalse);

      const tooShort = ABLoopRange(
        trackId: 't1',
        start: Duration(milliseconds: 1000),
        end: Duration(milliseconds: 1100), // 100ms < 300ms
      );
      expect(tooShort.isValid, isFalse);

      const valid = ABLoopRange(
        trackId: 't1',
        start: Duration(seconds: 10),
        end: Duration(seconds: 25),
        isEnabled: true,
      );
      expect(valid.isValid, isTrue);
      expect(valid.loopDuration.inSeconds, equals(15));
    });

    test('shouldWrap and checkPosition correctly wrap loop boundary', () {
      const loop = ABLoopRange(
        trackId: 't1',
        start: Duration(seconds: 10),
        end: Duration(seconds: 20),
        isEnabled: true,
      );

      // Before loop end: no wrap
      expect(loop.shouldWrap(const Duration(seconds: 15)), isFalse);
      expect(loop.checkPosition(const Duration(seconds: 15)), equals(const Duration(seconds: 15)));

      // At or past loop end: wraps to start
      expect(loop.shouldWrap(const Duration(seconds: 20)), isTrue);
      expect(loop.checkPosition(const Duration(seconds: 20)), equals(const Duration(seconds: 10)));

      expect(loop.shouldWrap(const Duration(seconds: 25)), isTrue);
      expect(loop.checkPosition(const Duration(seconds: 25)), equals(const Duration(seconds: 10)));
    });

    test('ABLoopNotifier sets pins and auto-swaps if end is before start', () {
      final notifier = ABLoopNotifier();
      notifier.setTrack('test_track');

      notifier.setPinA(const Duration(seconds: 30));
      expect(notifier.state.start, equals(const Duration(seconds: 30)));
      expect(notifier.state.isValid, isFalse);

      // Set Pin B earlier than Pin A -> should automatically swap
      notifier.setPinB(const Duration(seconds: 10));
      expect(notifier.state.start, equals(const Duration(seconds: 10)));
      expect(notifier.state.end, equals(const Duration(seconds: 30)));
      expect(notifier.state.isValid, isTrue);
      expect(notifier.state.isEnabled, isTrue);

      // Toggle enabled
      notifier.toggleEnabled();
      expect(notifier.state.isEnabled, isFalse);

      // Clear
      notifier.clear();
      expect(notifier.state.start, isNull);
      expect(notifier.state.end, isNull);
    });
  });
}
