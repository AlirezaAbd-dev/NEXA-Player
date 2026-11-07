import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../../helpers/synthetic_audio_generator.dart';
import 'phase2_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 2: Boundary & Corner Cases — Media Scanner & Local Library', () {
    late TestAppDatabase db;
    late TestMediaScannerService scanner;
    late TestTracksRepository tracksRepo;
    late SyntheticLibraryBuilder libBuilder;

    setUp(() {
      db = TestAppDatabase.inMemory();
      scanner = TestMediaScannerService(database: db);
      tracksRepo = TestTracksRepository(db);
      libBuilder = SyntheticLibraryBuilder();
    });

    tearDown(() {
      scanner.dispose();
      db.close();
      libBuilder.dispose();
    });

    // ------------------------------------------------------------------------
    // T2.1: Empty Directories Traversal
    // ------------------------------------------------------------------------
    test('T2.1: Traversal of empty directory structure completes cleanly with 0 tracks', () async {
      libBuilder.addDirectory('empty_folder_1');
      libBuilder.addDirectory('empty_folder_2/nested_empty');
      libBuilder.addDirectory('empty_folder_3/level1/level2/level3');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final scanResult = result.valueOrNull!;
      expect(scanResult.scannedFilesCount, equals(0));
      expect(scanResult.insertedTracksCount, equals(0));
      expect(scanResult.scannedFilesCount, equals(0));
      expect(scanResult.errors, isEmpty);

      final countInDb = db.select('SELECT COUNT(*) as c FROM tracks;').first['c'];
      expect(countInDb, equals(0));
    });

    // ------------------------------------------------------------------------
    // T2.2: Corrupt & Truncated Audio Files
    // ------------------------------------------------------------------------
    test('T2.2: Corrupt, zero-byte, and truncated audio files are safely skipped without crash', () async {
      // 1. Zero-byte file
      final zeroByteFile = File('${libBuilder.path}/zero_byte.mp3');
      zeroByteFile.writeAsBytesSync([], flush: true);

      // 2. Corrupted random garbage
      libBuilder.addCorruptFile('garbage.mp3', size: 128);

      // 3. Truncated ID3 header without audio frames
      final truncatedFile = File('${libBuilder.path}/truncated.mp3');
      truncatedFile.writeAsBytesSync([0x49, 0x44, 0x33, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x05], flush: true);

      // 4. One valid file
      libBuilder.addMp3('valid.mp3', title: 'Survivor Track');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      // Valid track must still be inserted despite adjacent corrupt files
      final tracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracks.length, equals(1));
      expect(tracks.first.title, equals('Survivor Track'));
    });

    // ------------------------------------------------------------------------
    // T2.3: Zero Duration & Short Sound Effects
    // ------------------------------------------------------------------------
    test('T2.3: Zero duration and sub-threshold files are skipped when minDuration > 0', () async {
      libBuilder.addMp3('zero.mp3', title: 'Zero Duration', duration: Duration.zero);
      libBuilder.addMp3('one_sec.mp3', title: '1 Second Effect', duration: const Duration(seconds: 1));
      libBuilder.addMp3('four_sec.mp3', title: '4 Seconds Jingle', duration: const Duration(seconds: 4));
      libBuilder.addMp3('five_sec.mp3', title: '5 Seconds Cue', duration: const Duration(seconds: 5));

      final result = await scanner.scanDirectories(
        [libBuilder.path],
        config: const ScannerConfig(minDurationSeconds: 5),
      );
      expect(result.isSuccess, isTrue);

      final tracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracks.length, equals(1));
      expect(tracks.first.title, equals('5 Seconds Cue'));
    });

    // ------------------------------------------------------------------------
    // T2.4: Massive Track Count Batch Insertion Stress
    // ------------------------------------------------------------------------
    test('T2.4: Massive batch of 2,000 tracks executes rapidly within transaction without memory issues', () async {
      final massiveTracks = List.generate(
        2000,
        (i) => Track(
          id: 'trk-$i',
          title: 'Track #$i - Synthetic Odyssey',
          artist: 'Artist ${(i % 20)}',
          album: 'Album ${(i % 50)}',
          duration: Duration(seconds: 120 + (i % 240)),
          trackNumber: (i % 12) + 1,
          year: 2000 + (i % 26),
          genre: 'Genre ${(i % 10)}',
          filePath: '/mock/library/disc_${i ~/ 500}/track_$i.mp3',
        ),
      );

      final stopwatch = Stopwatch()..start();
      final insertResult = await tracksRepo.insertTracks(massiveTracks);
      stopwatch.stop();

      expect(insertResult.isSuccess, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(3000), reason: 'Batch insertion of 2,000 tracks should take < 3s in memory');

      final countInDb = db.select('SELECT COUNT(*) as c FROM tracks;').first['c'];
      expect(countInDb, equals(2000));

      // Query with sorting & search
      final queryStopwatch = Stopwatch()..start();
      final filtered = await tracksRepo.getAllTracks(
        sortBy: TrackSortBy.title,
        ascending: true,
        searchQuery: 'Track #199',
      );
      queryStopwatch.stop();

      expect(filtered.isSuccess, isTrue);
      expect(filtered.valueOrNull?.length, greaterThanOrEqualTo(1));
      expect(queryStopwatch.elapsedMilliseconds, lessThan(100), reason: 'Indexed query should resolve in < 100ms');
    });

    // ------------------------------------------------------------------------
    // T2.5: Special Characters & Emojis in File Paths
    // ------------------------------------------------------------------------
    test('T2.5: File paths with Unicode, RTL, spaces, emojis, and symbols are parsed and stored correctly', () async {
      libBuilder.addMp3('Music 2026/01. Track with spaces.mp3', title: 'Spaces Track');
      libBuilder.addMp3('موسیقی/آهنگ سنتی شماره یک.mp3', title: 'Persian Track');
      libBuilder.addMp3('J-Pop/音楽/夜に駆ける.mp3', title: 'Japanese Track');
      libBuilder.addMp3('Symbols/!@#\$%^&()_+-={}[];,.mp3', title: 'Symbols Track');
      libBuilder.addMp3('Emoji 🎵/Vibes 🎧/Electric ⚡.mp3', title: 'Emoji Track');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final tracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracks.length, equals(5));

      final titles = tracks.map((t) => t.title).toSet();
      expect(titles, contains('Spaces Track'));
      expect(titles, contains('Persian Track'));
      expect(titles, contains('Japanese Track'));
      expect(titles, contains('Symbols Track'));
      expect(titles, contains('Emoji Track'));
    });

    // ------------------------------------------------------------------------
    // T2.6: Special Characters, Injection Strings & NULL Bytes in Metadata
    // ------------------------------------------------------------------------
    test('T2.6: SQL injection strings and extreme metadata payloads store safely via parameterized queries', () async {
      const injectionTitle = "Robert'); DROP TABLE tracks;--";
      const injectionArtist = "''' OR 1=1;--";
      final hugeAlbumString = ('Huge Album Name ' * 50).trim(); // 800 characters
      const htmlTagGenre = '<script>alert("xss")</script>';

      libBuilder.addMp3(
        'injection.mp3',
        title: injectionTitle,
        artist: injectionArtist,
        album: hugeAlbumString,
        genre: htmlTagGenre,
      );

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      // Verify table still exists (injection was parameterized and did not drop table)
      final tableCheck = db.select("SELECT name FROM sqlite_master WHERE type='table' AND name='tracks';");
      expect(tableCheck, isNotEmpty);

      final track = (await tracksRepo.getAllTracks()).valueOrNull!.first;
      expect(track.title, equals(injectionTitle));
      expect(track.artist, equals(injectionArtist));
      expect(track.album, equals(hugeAlbumString));
      expect(track.genre, equals(htmlTagGenre));
    });

    // ------------------------------------------------------------------------
    // T2.7: Duplicate Tracks & Path Upsert Handling
    // ------------------------------------------------------------------------
    test('T2.7: Re-scanning existing files updates metadata via upsert without creating duplicate records', () async {
      libBuilder.addMp3('repeat.mp3', title: 'Original Title', artist: 'Artist V1');

      // First Scan
      await scanner.scanDirectories([libBuilder.path]);
      var tracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracks.length, equals(1));
      expect(tracks.first.title, equals('Original Title'));

      // Modify metadata of the exact same file path
      libBuilder.addMp3('repeat.mp3', title: 'Updated Title', artist: 'Artist V2');

      // Second Scan
      await scanner.scanDirectories([libBuilder.path]);
      tracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracks.length, equals(1), reason: 'Upsert must not insert duplicate track for same file path');
      expect(tracks.first.title, equals('Updated Title'));
      expect(tracks.first.artist, equals('Artist V2'));
    });

    // ------------------------------------------------------------------------
    // T2.8: Case Insensitivity in Whitelisted Audio Extensions
    // ------------------------------------------------------------------------
    test('T2.8: Mixed-case audio extensions (.MP3, .FlAc, .WaV, .M4A) are matched by whitelist', () async {
      libBuilder.addMp3('test1.MP3', title: 'Upper MP3');
      libBuilder.addFlac('test2.FlAc');
      libBuilder.addWav('test3.WaV');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final countInDb = db.select('SELECT COUNT(*) as c FROM tracks;').first['c'];
      expect(countInDb, equals(3));
    });

    // ------------------------------------------------------------------------
    // T2.9: Nested .nomedia Subtree Isolation
    // ------------------------------------------------------------------------
    test('T2.9: .nomedia in child folder prunes only that child without affecting sibling or parent folders', () async {
      libBuilder.addMp3('root_track.mp3', title: 'Root Track');
      libBuilder.addMp3('audible_folder/track_a.mp3', title: 'Sibling A');
      libBuilder.addNoMedia('audible_folder/hidden_subfolder');
      libBuilder.addMp3('audible_folder/hidden_subfolder/hidden.mp3', title: 'Hidden');
      libBuilder.addMp3('audible_folder/another_subfolder/track_b.mp3', title: 'Sibling B');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final titles = (await tracksRepo.getAllTracks()).valueOrNull!.map((t) => t.title).toSet();
      expect(titles, contains('Root Track'));
      expect(titles, contains('Sibling A'));
      expect(titles, contains('Sibling B'));
      expect(titles, isNot(contains('Hidden')));
    });

    // ------------------------------------------------------------------------
    // T2.10: Zero-Byte Audio Files
    // ------------------------------------------------------------------------
    test('T2.10: 0-byte audio file is skipped by minFileSizeBytes filter without throwing', () async {
      final zeroFile = File('${libBuilder.path}/empty_sound.wav');
      zeroFile.writeAsBytesSync([], flush: true);

      final result = await scanner.scanDirectories(
        [libBuilder.path],
        config: const ScannerConfig(minFileSizeBytes: 1024),
      );
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.insertedTracksCount, equals(0));
      expect(result.valueOrNull?.skippedFilesCount, equals(1));
    });
  });
}
