import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/playlists/data/services/tag_editor_service_impl.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  late AppDatabase db;
  late TagEditorServiceImpl tagEditorService;

  setUp(() {
    db = TestDatabaseHelper.createInMemoryDatabase();
    tagEditorService = TagEditorServiceImpl(db);
  });

  tearDown(() {
    db.close();
  });

  const initialTrack = Track(
    id: 'track-edit-1',
    title: 'Original Title',
    artist: 'Original Artist',
    album: 'Original Album',
    duration: Duration(seconds: 200),
    filePath: '/music/original.mp3',
    year: 2020,
    genre: 'Rock',
    trackNumber: 1,
  );

  group('TagEditorServiceImpl', () {
    test('updates track metadata, creating new artist and album records', () async {
      TestDatabaseHelper.seedTrack(db, initialTrack);

      const metadata = EditableTrackMetadata(
        title: 'Updated Title',
        artist: 'New Artist',
        album: 'New Album',
        genre: 'Electronic',
        year: 2024,
        trackNumber: 5,
      );

      final result = await tagEditorService.updateTrackMetadata(initialTrack.id, metadata);

      expect(result.isSuccess, isTrue);
      final updatedTrack = result.valueOrNull!;
      expect(updatedTrack.title, equals('Updated Title'));
      expect(updatedTrack.artist, equals('New Artist'));
      expect(updatedTrack.album, equals('New Album'));
      expect(updatedTrack.genre, equals('Electronic'));
      expect(updatedTrack.year, equals(2024));
      expect(updatedTrack.trackNumber, equals(5));

      // Verify artists table row was created
      final artistRows = db.select('SELECT * FROM artists WHERE name = ?', ['New Artist']);
      expect(artistRows, isNotEmpty);

      // Verify albums table row was created
      final albumRows = db.select('SELECT * FROM albums WHERE title = ?', ['New Album']);
      expect(albumRows, isNotEmpty);
      expect(albumRows.first['artist'], equals('New Artist'));
      expect(albumRows.first['year'], equals(2024));
    });

    test('rejects empty title with ValidationFailure', () async {
      TestDatabaseHelper.seedTrack(db, initialTrack);

      const metadata = EditableTrackMetadata(
        title: '   ',
        artist: 'Some Artist',
        album: 'Some Album',
      );

      final result = await tagEditorService.updateTrackMetadata(initialTrack.id, metadata);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Track title cannot be empty'));
    });

    test('rejects empty artist with ValidationFailure', () async {
      TestDatabaseHelper.seedTrack(db, initialTrack);

      const metadata = EditableTrackMetadata(
        title: 'Valid Title',
        artist: '',
        album: 'Some Album',
      );

      final result = await tagEditorService.updateTrackMetadata(initialTrack.id, metadata);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Track artist cannot be empty'));
    });

    test('returns failure when track id does not exist', () async {
      const metadata = EditableTrackMetadata(
        title: 'Valid Title',
        artist: 'Valid Artist',
        album: 'Valid Album',
      );

      final result = await tagEditorService.updateTrackMetadata('non-existent-id', metadata);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('not found'));
    });
  });
}
