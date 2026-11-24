import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/features/scanner/data/media_scanner_service_impl.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:path/path.dart' as p;

Uint8List _fakeJpegBytes([int markerSeed = 0xAA]) {
  return Uint8List.fromList([
    0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
    0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, markerSeed,
    0xFF, 0xD9,
  ]);
}

Uint8List _fakePngBytes([int markerSeed = 0x55]) {
  return Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, markerSeed, 0x49, 0x45, 0x4E, 0x44,
  ]);
}

/// Builds a minimal ID3v2.3 MP3 payload containing TIT2, TPE1, TALB, and APIC.
Uint8List _buildId3Mp3({
  required String title,
  required Uint8List? imageBytes,
  String mime = 'image/jpeg',
  bool utf16Description = false,
}) {
  final frames = <int>[];

  void addTextFrame(String id, String text) {
    final encoded = [0x03, ...text.codeUnits]; // UTF-8
    frames.addAll(id.codeUnits);
    frames.addAll([
      (encoded.length >> 24) & 0xFF,
      (encoded.length >> 16) & 0xFF,
      (encoded.length >> 8) & 0xFF,
      encoded.length & 0xFF,
      0x00,
      0x00,
    ]);
    frames.addAll(encoded);
  }

  addTextFrame('TIT2', title);
  addTextFrame('TPE1', 'Test Artist');
  addTextFrame('TALB', 'Test Album');

  if (imageBytes != null) {
    final apicPayload = <int>[
      utf16Description ? 0x01 : 0x00,
      ...mime.codeUnits,
      0x00,
      0x03, // Front cover
      if (utf16Description) ...[0xFF, 0xFE, 0x41, 0x00, 0x00, 0x00] else ...[0x00],
      ...imageBytes,
    ];
    frames.addAll('APIC'.codeUnits);
    frames.addAll([
      (apicPayload.length >> 24) & 0xFF,
      (apicPayload.length >> 16) & 0xFF,
      (apicPayload.length >> 8) & 0xFF,
      apicPayload.length & 0xFF,
      0x00,
      0x00,
    ]);
    frames.addAll(apicPayload);
  }

  final tagSize = frames.length;
  final header = [
    0x49, 0x44, 0x33, // ID3
    0x03, 0x00, // v2.3
    0x00,
    (tagSize >> 21) & 0x7F,
    (tagSize >> 14) & 0x7F,
    (tagSize >> 7) & 0x7F,
    tagSize & 0x7F,
  ];

  return Uint8List.fromList([...header, ...frames, 0xFF, 0xFB, 0x90, 0x00]);
}

/// Builds a minimal FLAC header + METADATA_BLOCK_PICTURE (block type 6).
Uint8List _buildFlacWithPicture(Uint8List imageBytes) {
  final streamInfo = List<int>.filled(34, 0);
  // Encode sample rate = 44100 Hz cleanly at bytes 10..12 of STREAMINFO (offset 18..20 overall)
  const sampleRate = 44100;
  streamInfo[10] = (sampleRate >> 12) & 0xFF;
  streamInfo[11] = (sampleRate >> 4) & 0xFF;
  streamInfo[12] = (sampleRate & 0x0F) << 4;

  final mime = 'image/png'.codeUnits;
  final pictureBlock = <int>[
    0x00, 0x00, 0x00, 0x03, // Front cover
    0x00, 0x00, 0x00, mime.length,
    ...mime,
    0x00, 0x00, 0x00, 0x00, // description length = 0
    0x00, 0x00, 0x00, 0x64, // width 100
    0x00, 0x00, 0x00, 0x64, // height 100
    0x00, 0x00, 0x00, 0x18, // depth 24
    0x00, 0x00, 0x00, 0x00, // colors 0
    (imageBytes.length >> 24) & 0xFF,
    (imageBytes.length >> 16) & 0xFF,
    (imageBytes.length >> 8) & 0xFF,
    imageBytes.length & 0xFF,
    ...imageBytes,
  ];

  return Uint8List.fromList([
    0x66, 0x4C, 0x61, 0x43, // fLaC
    0x00, // not last, type 0 (STREAMINFO)
    0x00, 0x00, 34,
    ...streamInfo,
    0x86, // last = true, type 6 (PICTURE)
    (pictureBlock.length >> 16) & 0xFF,
    (pictureBlock.length >> 8) & 0xFF,
    pictureBlock.length & 0xFF,
    ...pictureBlock,
  ]);
}

void main() {
  group('PureDartAudioMetadataReader Cover Extraction', () {
    const reader = PureDartAudioMetadataReader();

    test('strips ID3v2 APIC envelope cleanly for ISO-8859-1 and UTF-16 descriptions', () {
      final jpg = _fakeJpegBytes(0x11);
      final mp3Iso = _buildId3Mp3(title: 'Song A', imageBytes: jpg);
      final metaIso = reader.extractBytes(mp3Iso, 'fallback');
      expect(metaIso.artworkBytes, isNotNull);
      expect(PureDartAudioMetadataReader.hasValidImageSignature(metaIso.artworkBytes!), isTrue);
      expect(metaIso.artworkBytes, equals(jpg));

      final png = _fakePngBytes(0x22);
      final mp3Utf16 = _buildId3Mp3(
        title: 'Song B',
        imageBytes: png,
        mime: 'image/png',
        utf16Description: true,
      );
      final metaUtf16 = reader.extractBytes(mp3Utf16, 'fallback');
      expect(metaUtf16.artworkBytes, equals(png));
    });

    test('extracts FLAC METADATA_BLOCK_PICTURE cleanly', () {
      final png = _fakePngBytes(0x33);
      final flac = _buildFlacWithPicture(png);
      final meta = reader.extractBytes(flac, 'Flac Track');
      expect(meta.artworkBytes, equals(png));
    });

    test('rejects corrupted non-image APIC bytes safely', () {
      final corrupt = Uint8List.fromList([0x00, 0x11, 0x22, 0x33, 0x44, 0x55]);
      final mp3Corrupt = _buildId3Mp3(title: 'Corrupt', imageBytes: corrupt);
      final meta = reader.extractBytes(mp3Corrupt, 'fallback');
      expect(meta.artworkBytes, isNull);
    });
  });

  group('ArtworkResolutionService Priority, Disk Cache & Fallback', () {
    late Directory tempRoot;
    late Directory albumDir;
    late ArtworkResolutionService service;

    setUp(() async {
      tempRoot = await Directory.systemTemp.createTemp('nexa_art_test_');
      albumDir = Directory(p.join(tempRoot.path, 'music_album'));
      await albumDir.create(recursive: true);

      service = ArtworkResolutionService(
        cacheDirectoryProvider: () async =>
            Directory(p.join(tempRoot.path, 'cache')),
        enableNativePlatformChannel: false,
      );
    });

    tearDown(() async {
      if (await tempRoot.exists()) {
        await tempRoot.delete(recursive: true);
      }
    });

    test('Priority order: Custom Override > Embedded > Folder Cover > Null Fallback', () async {
      final embeddedJpg = _fakeJpegBytes(0x41);
      final folderPng = _fakePngBytes(0x42);
      final overrideJpg = _fakeJpegBytes(0x43);

      final mp3Path = p.join(albumDir.path, 'track1.mp3');
      await File(mp3Path).writeAsBytes(
        _buildId3Mp3(title: 'Track 1', imageBytes: embeddedJpg),
      );
      await File(p.join(albumDir.path, 'Cover.PNG')).writeAsBytes(folderPng);

      const track = Track(
        id: 'trk-prio-1',
        title: 'Track 1',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        filePath: null,
      );
      final trackWithFile = Track(
        id: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        duration: track.duration,
        filePath: mp3Path,
      );

      // 1. Default preferEmbedded picks embedded JPEG and writes to cache
      final embeddedResolved = await service.resolveTrackArtwork(trackWithFile);
      expect(embeddedResolved, isNotNull);
      expect(await File(embeddedResolved!).readAsBytes(), equals(embeddedJpg));

      // 2. When no disk cache & preferFolderAndDownloaded is chosen, folder cover wins
      await service.clearCache();
      final folderPreferred = await service.resolveTrackArtwork(
        trackWithFile,
        preference: ArtworkSourcePreference.preferFolderAndDownloaded,
      );
      expect(folderPreferred, isNotNull);
      expect(await File(folderPreferred!).readAsBytes(), equals(folderPng));

      // 3. Custom Override always overrides both embedded & cached disk file
      final overridePath = await service.saveCustomOverride(
        trackWithFile.id,
        overrideJpg,
      );
      expect(overridePath, isNotNull);
      final overrideResolved = await service.resolveTrackArtwork(trackWithFile);
      expect(overrideResolved, equals(overridePath));
      expect(await File(overrideResolved!).readAsBytes(), equals(overrideJpg));

      // 4. Clearing override falls back cleanly to cached/embedded
      await service.clearCustomOverride(trackWithFile.id);
      final afterClearOverride = await service.resolveTrackArtwork(trackWithFile);
      expect(afterClearOverride, isNot(equals(overridePath)));
    });

    test('Falls back from corrupted folder image to null without throwing', () async {
      final noArtMp3 = p.join(albumDir.path, 'no_art.mp3');
      await File(noArtMp3).writeAsBytes(
        _buildId3Mp3(title: 'Plain', imageBytes: null),
      );
      // Corrupt cover.jpg in folder
      await File(p.join(albumDir.path, 'cover.jpg'))
          .writeAsBytes([0x01, 0x02, 0x03, 0x04, 0x05]);

      final resolved = await service.resolveTrackArtwork(
        Track(
          id: 'trk-corrupt',
          title: 'Plain',
          artist: 'Artist',
          album: 'Album',
          duration: const Duration(minutes: 2),
          filePath: noArtMp3,
        ),
      );
      expect(resolved, isNull);
    });

    test('Supports cache hit without re-invoking native extractor & clearCache purges files', () async {
      var nativeCalls = 0;
      final cachedService = ArtworkResolutionService(
        cacheDirectoryProvider: () async =>
            Directory(p.join(tempRoot.path, 'cache_hit')),
        enableNativePlatformChannel: false,
        nativeExtractor: ({
          required filePath,
          required outputPath,
          albumId,
          maxSize = 512,
          preferEmbedded = true,
        }) async {
          nativeCalls++;
          await File(outputPath).writeAsBytes(_fakeJpegBytes(0x77));
          return outputPath;
        },
      );

      final track = Track(
        id: 'trk-hit',
        title: 'Hit Track',
        artist: 'Artist',
        album: 'Hit Album',
        duration: const Duration(minutes: 3),
        filePath: p.join(albumDir.path, 'hit.mp3'),
      );

      final first = await cachedService.resolveTrackArtwork(track);
      final second = await cachedService.resolveTrackArtwork(track);
      expect(first, isNotNull);
      expect(second, equals(first));
      expect(nativeCalls, 1);

      await cachedService.clearCache();
      expect(await File(first!).exists(), isFalse);

      final third = await cachedService.resolveTrackArtwork(track);
      expect(third, isNotNull);
      expect(nativeCalls, 2);
    });

    test('resolveAlbumArtwork resolves from album tracks when album.artworkUri is null', () async {
      final jpg = _fakeJpegBytes(0x66);
      final trackPath = p.join(albumDir.path, 'album_song.mp3');
      await File(trackPath).writeAsBytes(
        _buildId3Mp3(title: 'Album Song', imageBytes: jpg),
      );

      const album = Album(
        id: 'alb-1',
        title: 'Real Cover Album',
        artist: 'Artist',
        trackCount: 1,
      );
      final track = Track(
        id: 'trk-alb-1',
        title: 'Album Song',
        artist: 'Artist',
        album: 'Real Cover Album',
        duration: const Duration(minutes: 3),
        filePath: trackPath,
        albumId: 'alb-1',
      );

      final art = await service.resolveAlbumArtwork(album, tracks: [track]);
      expect(art, isNotNull);
      expect(await File(art!).exists(), isTrue);
    });

    test('MediaScannerServiceImpl extracts embedded artwork to cache and stores artwork_uri in SQLite', () async {
      final db = AppDatabase.inMemory();
      addTearDown(db.close);

      final jpg = _fakeJpegBytes(0x88);
      final audioPath = p.join(albumDir.path, 'scanned.mp3');
      await File(audioPath).writeAsBytes(
        _buildId3Mp3(title: 'Scanned Song', imageBytes: jpg),
      );

      final scanner = MediaScannerServiceImpl(
        database: db,
        metadataReader: const PureDartAudioMetadataReader(),
        artworkService: service,
      );

      final res = await scanner.scanDirectories(
        [albumDir.path],
        config: const ScannerConfig(skipShortAudio: false, skipSmallFiles: false),
      );
      expect(res.isSuccess, isTrue);

      final trackRows = db.select('SELECT artwork_uri FROM tracks');
      final albumRows = db.select('SELECT artwork_uri FROM albums');
      expect(trackRows.first['artwork_uri'], isNotNull);
      expect(albumRows.first['artwork_uri'], isNotNull);
      expect(
        await File(trackRows.first['artwork_uri'] as String).exists(),
        isTrue,
      );
    });
  });

  group('NexaArtworkImage Widget Rendering', () {
    testWidgets('renders local file image cleanly without crashing when GetIt is empty', (tester) async {
      final dir = Directory.systemTemp.createTempSync('nexa_widget_art_');
      addTearDown(() {
        if (dir.existsSync()) dir.deleteSync(recursive: true);
      });
      final imgFile = File(p.join(dir.path, 'cover.png'));
      imgFile.writeAsBytesSync(_fakePngBytes());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NexaArtworkImage(
              artworkUri: imgFile.path,
              width: 48,
              height: 48,
              fallbackBuilder: (_) => const Icon(Icons.music_note),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(Image), findsOneWidget);
    });
  });
}
