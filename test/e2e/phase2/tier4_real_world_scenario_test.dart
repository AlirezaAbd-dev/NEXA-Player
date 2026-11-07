import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/synthetic_audio_generator.dart';
import 'phase2_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 4: Real-World Scenarios — Media Scanner & Local Library', () {
    late TestAppDatabase db;
    late TestMediaScannerService scanner;
    late TestTracksRepository tracksRepo;
    late TestAlbumsRepository albumsRepo;
    late TestArtistsRepository artistsRepo;
    late TestGenresRepository genresRepo;
    late TestPlaylistsRepository playlistsRepo;
    late SyntheticLibraryBuilder libBuilder;

    setUp(() {
      db = TestAppDatabase.inMemory();
      scanner = TestMediaScannerService(database: db);
      tracksRepo = TestTracksRepository(db);
      albumsRepo = TestAlbumsRepository(db);
      artistsRepo = TestArtistsRepository(db);
      genresRepo = TestGenresRepository(db);
      playlistsRepo = TestPlaylistsRepository(db);
      libBuilder = SyntheticLibraryBuilder();
    });

    tearDown(() {
      scanner.dispose();
      db.close();
      libBuilder.dispose();
    });

    // ------------------------------------------------------------------------
    // Scenario 1: First Run Library Onboarding & Cold Scan Journey
    // ------------------------------------------------------------------------
    testWidgets('Scenario 1: Fresh cold launch onboarding, directory setup, full scan, and library inspection', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Generate realistic music library on disk
      libBuilder.addMp3('Synthwave/Neon/track1.mp3', title: 'Sunset Drive', artist: 'Lazerhawk', album: 'Neon', trackNumber: 1);
      libBuilder.addMp3('Synthwave/Neon/track2.mp3', title: 'Electric Dreams', artist: 'Lazerhawk', album: 'Neon', trackNumber: 2);
      libBuilder.addMp3('Synthwave/Retro/track3.mp3', title: 'Miami Nights', artist: 'Com Truise', album: 'Galactic', trackNumber: 1);
      libBuilder.addMp3('Rock/Classic/track4.mp3', title: 'Bohemian Song', artist: 'Queen Tribute', album: 'Rock Classics', trackNumber: 1);
      libBuilder.addFlac('Audiophile/Master/track5.flac', duration: const Duration(seconds: 45));

      // 2. Launch App (starts on Songs tab with 0 tracks)
      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 0,
      ));
      await tester.pumpAndSettle();

      expect(find.text('All Songs (0)'), findsOneWidget);

      // 3. User navigates to Settings tab to add music directory
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(E2EPhase2Keys.addFolderButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(E2EPhase2Keys.addFolderPathInput), libBuilder.path);
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderConfirmButton));
      await tester.pumpAndSettle();

      expect(find.text(libBuilder.path), findsOneWidget);

      // 4. User triggers Rescan
      await tester.tap(find.byKey(E2EPhase2Keys.rescanButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: completed'), findsOneWidget);
      expect(find.textContaining('5 / 5 files'), findsOneWidget);

      // 5. User switches to Songs Tab -> 5 tracks populated
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();

      expect(find.text('All Songs (5)'), findsOneWidget);
      expect(find.text('Sunset Drive'), findsOneWidget);
      expect(find.text('Miami Nights'), findsOneWidget);

      // 6. User switches to Albums Tab -> 4 normalized albums rendered
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();

      expect(find.text('Neon'), findsOneWidget);
      expect(find.text('Galactic'), findsOneWidget);
      expect(find.text('Rock Classics'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // Scenario 2: Playlist Curation & Track Ordering Journey
    // ------------------------------------------------------------------------
    testWidgets('Scenario 2: Creating playlist, adding ordered tracks, and managing playlist tracks', (tester) async {
      libBuilder.addMp3('t1.mp3', title: 'Intro Theme', artist: 'Artist A');
      libBuilder.addMp3('t2.mp3', title: 'Climax Beat', artist: 'Artist B');
      libBuilder.addMp3('t3.mp3', title: 'Outro Harmony', artist: 'Artist C');

      await scanner.scanDirectories([libBuilder.path]);

      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 3, // Playlists Tab
      ));
      await tester.pumpAndSettle();

      // 1. Create Playlist via FAB
      await tester.tap(find.byKey(E2EPhase2Keys.createPlaylistFab));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(E2EPhase2Keys.playlistNameInput), 'Chillout Sessions');
      await tester.tap(find.byKey(E2EPhase2Keys.playlistConfirmCreate));
      await tester.pumpAndSettle();

      expect(find.text('Chillout Sessions'), findsOneWidget);

      // 2. Add tracks to playlist in precise order
      final allPlaylists = (await playlistsRepo.getAllPlaylists()).valueOrNull!;
      final playlist = allPlaylists.firstWhere((p) => p.name == 'Chillout Sessions');
      final allTracks = (await tracksRepo.getAllTracks()).valueOrNull!;

      final introTrack = allTracks.firstWhere((t) => t.title == 'Intro Theme');
      final climaxTrack = allTracks.firstWhere((t) => t.title == 'Climax Beat');
      final outroTrack = allTracks.firstWhere((t) => t.title == 'Outro Harmony');

      await playlistsRepo.addTrackToPlaylist(playlist.id, introTrack.id);
      await playlistsRepo.addTrackToPlaylist(playlist.id, climaxTrack.id);
      await playlistsRepo.addTrackToPlaylist(playlist.id, outroTrack.id);

      // 3. Verify ordering
      var plTracks = (await playlistsRepo.getTracksForPlaylist(playlist.id)).valueOrNull!;
      expect(plTracks.length, equals(3));
      expect(plTracks[0].title, equals('Intro Theme'));
      expect(plTracks[1].title, equals('Climax Beat'));
      expect(plTracks[2].title, equals('Outro Harmony'));

      // 4. Remove climax track -> remaining tracks intact
      await playlistsRepo.removeTrackFromPlaylist(playlist.id, climaxTrack.id);
      plTracks = (await playlistsRepo.getTracksForPlaylist(playlist.id)).valueOrNull!;
      expect(plTracks.length, equals(2));
      expect(plTracks[0].title, equals('Intro Theme'));
      expect(plTracks[1].title, equals('Outro Harmony'));
    });

    // ------------------------------------------------------------------------
    // Scenario 3: Incremental Rescan & File System Synchronization Journey
    // ------------------------------------------------------------------------
    test('Scenario 3: Rescan detects added files and metadata edits without duplicate rows', () async {
      // 1. Initial State: 2 tracks
      libBuilder.addMp3('album1/track1.mp3', title: 'First Song', artist: 'Band X');
      libBuilder.addMp3('album1/track2.mp3', title: 'Second Song', artist: 'Band X');

      final initialScan = await scanner.scanDirectories([libBuilder.path]);
      expect(initialScan.valueOrNull?.insertedTracksCount, equals(2));
      expect((await tracksRepo.getAllTracks()).valueOrNull?.length, equals(2));

      // 2. User modifies file system: adds 2 new tracks, modifies title of track1
      libBuilder.addMp3('album1/track1.mp3', title: 'First Song (Remastered 2026)', artist: 'Band X');
      libBuilder.addMp3('album2/track3.mp3', title: 'Third Song', artist: 'Band Y');
      libBuilder.addMp3('album2/track4.mp3', title: 'Fourth Song', artist: 'Band Y');

      // 3. Rescan
      final secondScan = await scanner.scanDirectories([libBuilder.path]);
      expect(secondScan.isSuccess, isTrue);

      final totalTracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(totalTracks.length, equals(4), reason: 'Total tracks should be exactly 4 (no duplicates)');

      final updatedTrack = totalTracks.firstWhere((t) => t.filePath?.contains('track1.mp3') ?? false);
      expect(updatedTrack.title, equals('First Song (Remastered 2026)'));
    });

    // ------------------------------------------------------------------------
    // Scenario 4: Mixed & Messy Directory Ingestion Journey
    // ------------------------------------------------------------------------
    test('Scenario 4: Scanner gracefully filters messy directories with corrupt, hidden, and non-audio files', () async {
      // Valid audio files
      libBuilder.addMp3('valid1.mp3', title: 'Legit Track 1');
      libBuilder.addFlac('valid2.flac', duration: const Duration(seconds: 30));
      libBuilder.addWav('valid3.wav', duration: const Duration(seconds: 20));

      // Hidden folder (.nomedia)
      libBuilder.addNoMedia('secret_audio');
      libBuilder.addMp3('secret_audio/voice_memo.mp3', title: 'Private Memo');

      // Non-audio files
      libBuilder.addNonAudioFile('album_cover.jpg');
      libBuilder.addNonAudioFile('lyrics.txt');
      libBuilder.addNonAudioFile('notes.pdf');

      // Corrupt file
      libBuilder.addCorruptFile('bad_file.mp3');

      // 0-byte file
      final zeroFile = File('${libBuilder.path}/zero.mp3');
      zeroFile.writeAsBytesSync([]);

      // Short sound effect
      libBuilder.addMp3('sfx.mp3', title: 'Ding', duration: const Duration(seconds: 2));

      final result = await scanner.scanDirectories(
        [libBuilder.path],
        config: const ScannerConfig(minDurationSeconds: 5, minFileSizeBytes: 1024),
      );
      expect(result.isSuccess, isTrue);

      // Only 3 valid music files should be inserted into the database
      final libraryTracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(libraryTracks.length, equals(3));

      final titles = libraryTracks.map((t) => t.title).toSet();
      expect(titles, contains('Legit Track 1'));
      expect(titles, isNot(contains('Private Memo')));
      expect(titles, isNot(contains('Ding')));
    });

    // ------------------------------------------------------------------------
    // Scenario 5: Multilingual Search, Sorting & Deep Navigation Journey
    // ------------------------------------------------------------------------
    testWidgets('Scenario 5: Persian, Japanese, and English tracks searchable, sortable, and navigable', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      libBuilder.addMp3('en.mp3', title: 'Midnight Stargazer', artist: 'NEXA Lab', album: 'Global Beats');
      libBuilder.addMp3('fa.mp3', title: 'آهنگ بهاری دلنشین', artist: 'محمدرضا شجریان', album: 'نوا');
      libBuilder.addMp3('ja.mp3', title: '夜に駆ける', artist: 'YOASOBI', album: 'The Book');

      await scanner.scanDirectories([libBuilder.path]);

      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('All Songs (3)'), findsOneWidget);

      // 1. Search in Persian
      await tester.enterText(find.byKey(E2EPhase2Keys.searchField), 'بهاری');
      await tester.pumpAndSettle();

      expect(find.text('آهنگ بهاری دلنشین'), findsOneWidget);
      expect(find.text('Midnight Stargazer'), findsNothing);
      expect(find.text('夜に駆ける'), findsNothing);

      // 2. Clear search and navigate to Albums
      await tester.enterText(find.byKey(E2EPhase2Keys.searchField), '');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();

      expect(find.text('نوا'), findsOneWidget);
      expect(find.text('The Book'), findsOneWidget);
      expect(find.text('Global Beats'), findsOneWidget);

      // 3. Drill down into Persian album
      await tester.ensureVisible(find.text('نوا'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('نوا'));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EPhase2Keys.albumDetailScreen), findsOneWidget);
      expect(find.text('آهنگ بهاری دلنشین'), findsOneWidget);
    });
  });
}
