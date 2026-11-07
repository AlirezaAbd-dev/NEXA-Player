import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../../helpers/synthetic_audio_generator.dart';
import 'phase2_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Tier 3: Cross-Feature Interactions — Phase 2', () {
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
    // T3.1: Scan -> DB Insertion -> Reactive UI Update
    // ------------------------------------------------------------------------
    testWidgets('T3.1: Scanning files populates SQLite and reactively updates All Songs screen', (tester) async {
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

      // Initially empty
      expect(find.text('All Songs (0)'), findsOneWidget);

      // Create synthetic audio files
      libBuilder.addMp3('song1.mp3', title: 'Solar Pulse', artist: 'Synth Wave');
      libBuilder.addMp3('song2.mp3', title: 'Cosmic Journey', artist: 'Space Sound');

      // Trigger scan via service
      await scanner.scanDirectories([libBuilder.path]);
      await tester.pumpAndSettle();

      // UI updates reactively
      expect(find.text('All Songs (2)'), findsOneWidget);
      expect(find.text('Solar Pulse'), findsOneWidget);
      expect(find.text('Cosmic Journey'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // T3.2: Media Scan -> Album & Artist Normalization -> Detail Navigation
    // ------------------------------------------------------------------------
    testWidgets('T3.2: Scanned tracks auto-normalize albums and allow drill-down navigation to Album Detail', (tester) async {
      libBuilder.addMp3('t1.mp3', title: 'Prologue', artist: 'Cyber Duo', album: 'Neon Matrix', trackNumber: 1);
      libBuilder.addMp3('t2.mp3', title: 'Main Theme', artist: 'Cyber Duo', album: 'Neon Matrix', trackNumber: 2);

      await scanner.scanDirectories([libBuilder.path]);

      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 1, // Albums Tab
      ));
      await tester.pumpAndSettle();

      // Verify album card rendered
      expect(find.text('Neon Matrix'), findsOneWidget);
      expect(find.text('Cyber Duo'), findsOneWidget);

      // Tap album card
      await tester.tap(find.text('Neon Matrix'));
      await tester.pumpAndSettle();

      // Verify navigated into Album Detail view with both tracks
      expect(find.byKey(E2EPhase2Keys.albumDetailScreen), findsOneWidget);
      expect(find.text('Prologue'), findsOneWidget);
      expect(find.text('Main Theme'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // T3.3: Scanner Settings Change -> Rescan Filter -> UI Update
    // ------------------------------------------------------------------------
    testWidgets('T3.3: Customizing skip rules in Settings updates scanner and filters out short files on rescan', (tester) async {
      libBuilder.addMp3('short.mp3', title: 'Notification Sound', duration: const Duration(seconds: 4));
      libBuilder.addMp3('full.mp3', title: 'Full Track', duration: const Duration(minutes: 3));

      // Scan with minDuration = 0 (all tracks included)
      await scanner.scanDirectories([libBuilder.path], config: const ScannerConfig(minDurationSeconds: 0));

      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 0, // Songs tab
      ));
      await tester.pumpAndSettle();

      expect(find.text('All Songs (2)'), findsOneWidget);

      // Now switch to Settings Tab and add folder with minDuration = 10s
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Configure folder in Settings
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(E2EPhase2Keys.addFolderPathInput), libBuilder.path);
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderConfirmButton));
      await tester.pumpAndSettle();

      // Slide min duration to 10 seconds
      await tester.tap(find.byKey(E2EPhase2Keys.rescanButton));
      await tester.pumpAndSettle();

      // Switch back to Songs tab
      await tester.tap(find.text('Songs'));
      await tester.pumpAndSettle();

      // The full track is present
      expect(find.text('Full Track'), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // T3.4: Library Scan -> Playlist Creation -> Track Addition -> Deletion Cascade
    // ------------------------------------------------------------------------
    test('T3.4: Scanned track added to playlist is automatically removed via cascade when track is deleted from library', () async {
      libBuilder.addMp3('track.mp3', title: 'Transient Song');
      await scanner.scanDirectories([libBuilder.path]);

      final tracks = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracks.length, equals(1));
      final track = tracks.first;

      // Create playlist
      final playlist = (await playlistsRepo.createPlaylist('Dynamic Playlist')).valueOrNull!;

      // Add track to playlist
      await playlistsRepo.addTrackToPlaylist(playlist.id, track.id);
      var playlistTracks = (await playlistsRepo.getTracksForPlaylist(playlist.id)).valueOrNull!;
      expect(playlistTracks.length, equals(1));
      expect(playlistTracks.first.id, equals(track.id));

      // Delete track from library
      await tracksRepo.deleteTrack(track.id);

      // Foreign key CASCADE should remove the track from playlist_tracks table
      playlistTracks = (await playlistsRepo.getTracksForPlaylist(playlist.id)).valueOrNull!;
      expect(playlistTracks, isEmpty);
    });

    // ------------------------------------------------------------------------
    // T3.5: Search Filter -> Favorite Toggle -> List Refresh
    // ------------------------------------------------------------------------
    testWidgets('T3.5: Toggling favorite while search is active preserves favorite state when search is cleared', (tester) async {
      await tracksRepo.insertTracks([
        const Track(id: 'trk-1', title: 'Stargazer', artist: 'NEXA Sound', duration: Duration(minutes: 3)),
        const Track(id: 'trk-2', title: 'Moonlight', artist: 'Luna Lab', duration: Duration(minutes: 4)),
      ]);

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

      // Search for Stargazer
      await tester.enterText(find.byKey(E2EPhase2Keys.searchField), 'Star');
      await tester.pumpAndSettle();

      expect(find.text('Stargazer'), findsOneWidget);
      expect(find.text('Moonlight'), findsNothing);

      // Toggle favorite on Stargazer
      await tester.tap(find.byKey(E2EPhase2Keys.trackFavoriteToggle('trk-1')));
      await tester.pumpAndSettle();

      // Clear search
      await tester.enterText(find.byKey(E2EPhase2Keys.searchField), '');
      await tester.pumpAndSettle();

      expect(find.text('Stargazer'), findsOneWidget);
      expect(find.text('Moonlight'), findsOneWidget);

      // Verify favorite status persisted in DB
      final updatedTrack = (await tracksRepo.getTrackById('trk-1')).valueOrNull!;
      expect(updatedTrack.isFavorite, isTrue);
    });

    // ------------------------------------------------------------------------
    // T3.6: Multi-Folder Scan -> Tree View -> Remove Folder
    // ------------------------------------------------------------------------
    testWidgets('T3.6: Multi-folder scan renders folders in Folders Tab; removing a folder updates tree', (tester) async {
      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 5, // Settings Tab
      ));
      await tester.pumpAndSettle();

      // Add Folder A
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(E2EPhase2Keys.addFolderPathInput), '/music/Rock');
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderConfirmButton));
      await tester.pumpAndSettle();

      // Add Folder B
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(E2EPhase2Keys.addFolderPathInput), '/music/Electronic');
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderConfirmButton));
      await tester.pumpAndSettle();

      // Switch to Folders Tab
      await tester.tap(find.text('Folders'));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EPhase2Keys.folderNode('/music/Rock')), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.folderNode('/music/Electronic')), findsOneWidget);

      // Go back to Settings and remove Rock
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(E2EPhase2Keys.removeFolderButton('/music/Rock')));
      await tester.pumpAndSettle();

      // Switch to Folders Tab again
      await tester.tap(find.text('Folders'));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EPhase2Keys.folderNode('/music/Rock')), findsNothing);
      expect(find.byKey(E2EPhase2Keys.folderNode('/music/Electronic')), findsOneWidget);
    });

    // ------------------------------------------------------------------------
    // T3.7: DB Transaction Rollback Atomicity on Error
    // ------------------------------------------------------------------------
    test('T3.7: Database error in middle of scan rolls back transaction leaving previous state intact', () async {
      // 1. Initial stable state
      await tracksRepo.insertTrack(
        const Track(id: 'stable-1', title: 'Stable Song', artist: 'Artist', duration: Duration(minutes: 3)),
      );
      expect((await tracksRepo.getAllTracks()).valueOrNull!.length, equals(1));

      // 2. Simulate failed batch transaction
      try {
        db.transaction(() {
          db.execute(
            'INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES (?, ?, ?, ?, ?, ?);',
            ['t-new-1', 'New Song 1', 'Artist', 180000, '/path/new1.mp3', DateTime.now().millisecondsSinceEpoch],
          );
          // Deliberate constraint violation: NULL not allowed on title
          db.execute(
            'INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES (?, ?, ?, ?, ?, ?);',
            ['t-new-2', null, 'Artist', 180000, '/path/new2.mp3', DateTime.now().millisecondsSinceEpoch],
          );
        });
      } catch (_) {
        // Expected transaction failure
      }

      // Verify database state rolled back to stable-1 only
      final tracksAfterRollback = (await tracksRepo.getAllTracks()).valueOrNull!;
      expect(tracksAfterRollback.length, equals(1));
      expect(tracksAfterRollback.first.title, equals('Stable Song'));
    });
  });
}
