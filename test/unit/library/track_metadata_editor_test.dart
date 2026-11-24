import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/core/services/library/library_sync_bus.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_playlists_repository.dart';
import 'package:nexa_player/features/playlists/data/services/id3_tag_writer.dart';
import 'package:nexa_player/features/playlists/data/services/tag_editor_service_impl.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:path/path.dart' as p;

import '../../helpers/test_database_helper.dart';

class _ReadOnlyId3Writer extends Id3TagWriter {
  const _ReadOnlyId3Writer();

  @override
  Future<Id3WriteResult> writeTags(
    String filePath,
    EditableTrackMetadata metadata,
  ) async {
    return const Id3WriteResult(
      status: Id3WriteStatus.readOnlyOrPermissionDenied,
      errorMessage: 'EACCES: Read-only Scoped Storage volume',
    );
  }
}

void main() {
  late Directory tempDir;
  late AppDatabase db;

  final validJpegBytes = Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
    0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9,
  ]);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('nexa_tag_editor_test_');
    db = TestDatabaseHelper.createInMemoryDatabase();
  });

  tearDown(() async {
    if (!db.isClosed) {
      db.close();
    }
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('TrackMetadataEditor & Persistence', () {
    test(
      'editing Persian & English title/artist/album/genre/year/comment persists in SQLite and updates album/artist groupings',
      () async {
        const track = Track(
          id: 'trk-fa-1',
          title: 'Track 01',
          artist: 'Unknown Artist',
          album: 'Old Album',
          duration: Duration(minutes: 4, seconds: 12),
          filePath: '/storage/emulated/0/Music/nonexistent_sample.flac',
          trackNumber: 1,
        );
        TestDatabaseHelper.seedTrack(db, track);

        final syncBus = LibrarySyncBus();
        int syncEvents = 0;
        final sub = syncBus.stream.listen((_) => syncEvents++);

        final service = TagEditorServiceImpl(db, syncBus: syncBus);
        const metadata = EditableTrackMetadata(
          title: 'تصنیف مرغ سحر',
          artist: 'محمدرضا شجریان',
          album: 'بهار دلکش',
          genre: 'موسیقی سنتی',
          year: 1995,
          trackNumber: 2,
          comment: 'نسخه اصلی اجرای زنده - ۱۳۹۵',
        );

        final result = await service.updateTrackMetadata(track.id, metadata);
        expect(result.isSuccess, isTrue);

        final updated = result.valueOrNull!;
        expect(updated.title, 'تصنیف مرغ سحر');
        expect(updated.artist, 'محمدرضا شجریان');
        expect(updated.album, 'بهار دلکش');
        expect(updated.genre, 'موسیقی سنتی');
        expect(updated.year, 1995);
        expect(updated.trackNumber, 2);
        expect(updated.comment, 'نسخه اصلی اجرای زنده - ۱۳۹۵');

        final artistRows = db.select(
          'SELECT * FROM artists WHERE name = ?;',
          ['محمدرضا شجریان'],
        );
        expect(artistRows, hasLength(1));
        expect(artistRows.first['track_count'], 1);
        expect(artistRows.first['album_count'], 1);

        final albumRows = db.select(
          'SELECT * FROM albums WHERE title = ?;',
          ['بهار دلکش'],
        );
        expect(albumRows, hasLength(1));
        expect(albumRows.first['artist'], 'محمدرضا شجریان');
        expect(albumRows.first['track_count'], 1);

        await Future<void>.delayed(Duration.zero);
        expect(syncEvents, greaterThanOrEqualTo(1));
        await sub.cancel();
      },
    );

    test(
      'writes UTF-8 ID3v2.4 tags + APIC cover atomically to real MP3 file while preserving audio frames',
      () async {
        final mp3File = File(p.join(tempDir.path, 'sample.mp3'));
        final dummyMp3Payload = Uint8List.fromList([
          0xFF, 0xFB, 0x90, 0x64, 0x00, 0x11, 0x22, 0x33, 0x44, 0x55,
        ]);
        await mp3File.writeAsBytes(dummyMp3Payload, flush: true);

        final track = Track(
          id: 'trk-mp3-1',
          title: 'Old Song',
          artist: 'Old Artist',
          album: 'Old Album',
          duration: const Duration(minutes: 3),
          filePath: mp3File.path,
        );
        TestDatabaseHelper.seedTrack(db, track);

        final service = TagEditorServiceImpl(db);
        final metadata = EditableTrackMetadata(
          title: 'شبهای روشن',
          artist: 'همایون شجریان',
          album: 'آلبوم تازه',
          genre: 'Classic',
          year: 2024,
          trackNumber: 4,
          comment: 'Edited inside NEXA Player',
          artworkBytes: validJpegBytes,
        );

        final res = await service.updateTrackMetadata(track.id, metadata);
        expect(res.isSuccess, isTrue);
        expect(service.lastFileWriteWarning, isNull);

        final extracted =
            await const PureDartAudioMetadataReader().extract(mp3File);
        expect(extracted.title, 'شبهای روشن');
        expect(extracted.artist, 'همایون شجریان');
        expect(extracted.album, 'آلبوم تازه');
        expect(extracted.genre, 'Classic');
        expect(extracted.year, 2024);
        expect(extracted.artworkBytes, isNotNull);

        // Audio frame payload at the tail must still be intact
        final rewrittenBytes = await mp3File.readAsBytes();
        expect(
          rewrittenBytes.sublist(rewrittenBytes.length - dummyMp3Payload.length),
          equals(dummyMp3Payload),
        );
      },
    );

    test(
      'saves and resets custom cover override and falls back gracefully on read-only file errors',
      () async {
        final artworkService = ArtworkResolutionService(
          cacheDirectoryProvider: () async => tempDir,
          enableNativePlatformChannel: false,
        );

        const track = Track(
          id: 'trk-cover-1',
          title: 'Cover Track',
          artist: 'Artist',
          album: 'Album',
          duration: Duration(minutes: 2),
          filePath: '/readonly/sdcard/track.mp3',
        );
        TestDatabaseHelper.seedTrack(db, track);

        final savedOverride =
            await artworkService.saveCustomOverride(track.id, validJpegBytes);
        expect(savedOverride, isNotNull);
        expect(File(savedOverride!).existsSync(), isTrue);

        final readOnlyService = TagEditorServiceImpl(
          db,
          id3Writer: const _ReadOnlyId3Writer(),
        );
        final editRes = await readOnlyService.updateTrackMetadata(
          track.id,
          EditableTrackMetadata(
            title: 'Cover Track Edited',
            artist: 'Artist',
            album: 'Album',
            comment: 'Persisted even when file is read-only',
            artworkUri: savedOverride,
          ),
        );
        expect(editRes.isSuccess, isTrue);
        expect(editRes.valueOrNull!.artworkUri, savedOverride);
        expect(editRes.valueOrNull!.comment,
            'Persisted even when file is read-only');
        expect(readOnlyService.lastFileWriteWarning, isNotNull);

        // Reset custom cover
        await artworkService.clearCustomOverride(track.id);
        expect(File(savedOverride).existsSync(), isFalse);
        final resetRes = await readOnlyService.updateTrackMetadata(
          track.id,
          const EditableTrackMetadata(
            title: 'Cover Track Edited',
            artist: 'Artist',
            album: 'Album',
            clearArtwork: true,
          ),
        );
        expect(resetRes.isSuccess, isTrue);
        expect(resetRes.valueOrNull!.artworkUri, isNull);
      },
    );

    test(
      'SqlitePlaylistsRepository.addTrackToPlaylist prevents duplicate entries',
      () async {
        const track = Track(
          id: 'trk-pl-dup',
          title: 'Unique Song',
          artist: 'Artist',
          duration: Duration(minutes: 3),
          filePath: '/music/unique.mp3',
        );
        TestDatabaseHelper.seedTrack(db, track);

        final repo = SqlitePlaylistsRepository(db);
        final pl = (await repo.createPlaylist('Favorites Mix')).valueOrNull!;

        await repo.addTrackToPlaylist(pl.id, track.id);
        await repo.addTrackToPlaylist(pl.id, track.id);

        final tracks = (await repo.getTracksForPlaylist(pl.id)).valueOrNull!;
        expect(tracks, hasLength(1));
        final fetchedPl = (await repo.getPlaylistById(pl.id)).valueOrNull!;
        expect(fetchedPl.trackCount, 1);
      },
    );
  });
}
