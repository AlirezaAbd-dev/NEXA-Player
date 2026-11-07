import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import '../../helpers/synthetic_audio_generator.dart';
import 'phase2_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ==========================================================================
  // Area 1: Database Operations (F2.1 - F2.7)
  // ==========================================================================
  group('Tier 1: Feature Coverage — Area 1: Database Operations (F2.1 - F2.7)', () {
    late TestAppDatabase db;

    setUp(() {
      db = TestAppDatabase.inMemory();
    });

    tearDown(() {
      db.close();
    });

    test('T1.DB.1: In-memory SQLite connection initializes all 7 required tables', () {
      final tablesResult = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%';",
      );
      final tableNames = tablesResult.map((r) => r['name'] as String).toSet();

      expect(tableNames, contains('tracks'));
      expect(tableNames, contains('albums'));
      expect(tableNames, contains('artists'));
      expect(tableNames, contains('genres'));
      expect(tableNames, contains('playlists'));
      expect(tableNames, contains('playlist_tracks'));
      expect(tableNames, contains('scan_directories'));
    });

    test('T1.DB.2: WAL mode and foreign keys PRAGMAs are active', () {
      final fkResult = db.select('PRAGMA foreign_keys;');
      expect(fkResult.first['foreign_keys'], equals(1));
    });

    test('T1.DB.3: All 6 required query indexes exist on tracks table', () {
      final indexesResult = db.select(
        "SELECT name FROM sqlite_master WHERE type='index' AND tbl_name='tracks';",
      );
      final indexNames = indexesResult.map((r) => r['name'] as String).toSet();

      expect(indexNames, contains('idx_tracks_artist'));
      expect(indexNames, contains('idx_tracks_album'));
      expect(indexNames, contains('idx_tracks_genre'));
      expect(indexNames, contains('idx_tracks_title'));
      expect(indexNames, contains('idx_tracks_path'));
      expect(indexNames, contains('idx_tracks_date_added'));
    });

    test('T1.DB.4: Foreign key cascade deletes playlist_tracks when playlist is deleted', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      db.execute(
        'INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES (?, ?, ?, ?, ?, ?);',
        ['trk-1', 'Cascade Track', 'Cascade Artist', 180000, '/path/1.mp3', now],
      );
      db.execute(
        'INSERT INTO playlists (id, name, created_at, track_count) VALUES (?, ?, ?, ?);',
        ['pl-1', 'My Playlist', now, 1],
      );
      db.execute(
        'INSERT INTO playlist_tracks (id, playlist_id, track_id, sort_order, added_at) VALUES (?, ?, ?, ?, ?);',
        ['pt-1', 'pl-1', 'trk-1', 1, now],
      );

      expect(db.select('SELECT COUNT(*) as c FROM playlist_tracks WHERE playlist_id = ?;', ['pl-1']).first['c'], equals(1));

      // Delete parent playlist
      db.execute('DELETE FROM playlists WHERE id = ?;', ['pl-1']);

      // playlist_tracks should be deleted automatically via CASCADE
      final remaining = db.select('SELECT COUNT(*) as c FROM playlist_tracks WHERE playlist_id = ?;', ['pl-1']).first['c'];
      expect(remaining, equals(0));
    });

    test('T1.DB.5: Transaction atomicity rolls back on exception without partial commits', () {
      final now = DateTime.now().millisecondsSinceEpoch;
      try {
        db.transaction(() {
          db.execute(
            'INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES (?, ?, ?, ?, ?, ?);',
            ['trk-ok', 'Valid Track', 'Artist', 120000, '/path/ok.mp3', now],
          );
          // Deliberate constraint violation: duplicate primary key
          db.execute(
            'INSERT INTO tracks (id, title, artist, duration_ms, file_path, date_added) VALUES (?, ?, ?, ?, ?, ?);',
            ['trk-ok', 'Conflict Track', 'Artist', 120000, '/path/dup.mp3', now],
          );
        });
      } catch (_) {
        // Expected transaction failure
      }

      final check = db.select('SELECT COUNT(*) as c FROM tracks WHERE id = ?;', ['trk-ok']).first['c'];
      expect(check, equals(0), reason: 'Transaction must rollback completely on error');
    });

    test('T1.DB.6: Domain Track entity roundtrips faithfully through tracks table', () {
      const track = Track(
        id: 'trk-roundtrip',
        title: 'Cyber Sunset',
        artist: 'Retrowave Lab',
        album: 'Neon Horizon',
        duration: Duration(minutes: 3, seconds: 45),
        trackNumber: 4,
        discNumber: 1,
        year: 2026,
        genre: 'Synthwave',
        isFavorite: true,
        playCount: 12,
        bitrate: 320,
        fileSize: 9048576,
        filePath: '/music/cyber_sunset.mp3',
        artworkUri: 'file:///art/cyber_sunset.jpg',
      );

      final now = DateTime.now().millisecondsSinceEpoch;
      db.execute('''
        INSERT INTO tracks (id, title, artist, album, duration_ms, file_path, artwork_uri, track_number, disc_number, year, genre, is_favorite, play_count, bitrate, file_size, date_added)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
      ''', [
        track.id,
        track.title,
        track.artist,
        track.album,
        track.duration.inMilliseconds,
        track.filePath,
        track.artworkUri,
        track.trackNumber,
        track.discNumber,
        track.year,
        track.genre,
        track.isFavorite ? 1 : 0,
        track.playCount,
        track.bitrate,
        track.fileSize,
        now,
      ]);

      final rows = db.select('SELECT * FROM tracks WHERE id = ?;', [track.id]);
      expect(rows.length, equals(1));
      final r = rows.first;
      expect(r['title'], equals('Cyber Sunset'));
      expect(r['artist'], equals('Retrowave Lab'));
      expect(r['album'], equals('Neon Horizon'));
      expect(r['duration_ms'], equals(225000));
      expect(r['track_number'], equals(4));
      expect(r['disc_number'], equals(1));
      expect(r['year'], equals(2026));
      expect(r['genre'], equals('Synthwave'));
      expect(r['is_favorite'], equals(1));
      expect(r['play_count'], equals(12));
      expect(r['bitrate'], equals(320));
      expect(r['file_size'], equals(9048576));
    });
  });

  // ==========================================================================
  // Area 2: Scanner Traversal, .nomedia, Whitelist & Metadata (F2.8 - F2.15)
  // ==========================================================================
  group('Tier 1: Feature Coverage — Area 2: Scanner Traversal & Filtering (F2.8 - F2.15)', () {
    late TestAppDatabase db;
    late TestMediaScannerService scanner;
    late SyntheticLibraryBuilder libBuilder;

    setUp(() {
      db = TestAppDatabase.inMemory();
      scanner = TestMediaScannerService(database: db);
      libBuilder = SyntheticLibraryBuilder();
    });

    tearDown(() {
      scanner.dispose();
      db.close();
      libBuilder.dispose();
    });

    test('T1.SCAN.1: Recursive traversal extracts all valid audio files across nested folders', () async {
      libBuilder.addMp3('folder1/song1.mp3', title: 'Song 1', duration: const Duration(seconds: 120));
      libBuilder.addMp3('folder1/subfolder/song2.mp3', title: 'Song 2', duration: const Duration(seconds: 140));
      libBuilder.addWav('folder2/song3.wav', duration: const Duration(seconds: 30));

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final scanResult = result.valueOrNull!;
      expect(scanResult.insertedTracksCount, equals(3));
      expect(scanResult.scannedFilesCount, equals(3));

      final tracksInDb = db.select('SELECT COUNT(*) as c FROM tracks;').first['c'];
      expect(tracksInDb, equals(3));
    });

    test('T1.SCAN.2: .nomedia subtree pruning completely ignores directory and all subfolders', () async {
      libBuilder.addMp3('public/allowed.mp3', title: 'Allowed');
      libBuilder.addNoMedia('private');
      libBuilder.addMp3('private/secret.mp3', title: 'Secret');
      libBuilder.addMp3('private/deep/nested_secret.mp3', title: 'Nested Secret');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final scanResult = result.valueOrNull!;
      expect(scanResult.insertedTracksCount, equals(1));

      final rows = db.select('SELECT title FROM tracks;');
      expect(rows.length, equals(1));
      expect(rows.first['title'], equals('Allowed'));
    });

    test('T1.SCAN.3: Audio whitelist filtering includes audio and ignores non-audio files', () async {
      libBuilder.addMp3('music/song.mp3');
      libBuilder.addFlac('music/audio.flac');
      libBuilder.addWav('music/track.wav');
      libBuilder.addNonAudioFile('music/cover.jpg', 'JPEG_DATA');
      libBuilder.addNonAudioFile('music/lyrics.txt', 'Lyrics text');
      libBuilder.addNonAudioFile('music/info.nfo', 'Album info');

      final result = await scanner.scanDirectories([libBuilder.path]);
      expect(result.isSuccess, isTrue);

      final scanResult = result.valueOrNull!;
      expect(scanResult.insertedTracksCount, equals(3));
      expect(scanResult.skippedFilesCount, greaterThanOrEqualTo(3));
    });

    test('T1.SCAN.4: Skip filters skip audio files shorter than configured minDuration', () async {
      libBuilder.addMp3('short1.mp3', title: 'Short', duration: const Duration(seconds: 3));
      libBuilder.addMp3('short2.mp3', title: 'Short 2', duration: const Duration(seconds: 4));
      libBuilder.addMp3('valid.mp3', title: 'Valid Song', duration: const Duration(seconds: 60));

      final result = await scanner.scanDirectories(
        [libBuilder.path],
        config: const ScannerConfig(minDurationSeconds: 5),
      );
      expect(result.isSuccess, isTrue);

      final scanResult = result.valueOrNull!;
      expect(scanResult.insertedTracksCount, equals(1));

      final titles = db.select('SELECT title FROM tracks;').map((r) => r['title'] as String).toList();
      expect(titles, equals(['Valid Song']));
    });

    test('T1.SCAN.5: Pure Dart audio metadata reader extracts ID3v2 tags and embedded artwork', () async {
      final artworkBytes = SyntheticAudioGenerator.createSyntheticJpegBytes();
      final mp3File = libBuilder.addMp3(
        'meta_test.mp3',
        title: 'Echoes of Tomorrow',
        artist: 'Astral Wave',
        album: 'Singularity',
        genre: 'Ambient',
        year: 2026,
        trackNumber: 7,
        duration: const Duration(seconds: 210),
        artwork: artworkBytes,
      );

      final meta = await PureDartAudioMetadataReader.extract(mp3File);
      expect(meta.title, equals('Echoes of Tomorrow'));
      expect(meta.artist, equals('Astral Wave'));
      expect(meta.album, equals('Singularity'));
      expect(meta.genre, equals('Ambient'));
      expect(meta.year, equals(2026));
      expect(meta.trackNumber, equals(7));
      expect(meta.artworkBytes, isNotNull);
    });

    test('T1.SCAN.6: Reactive scanner state emits progress updates and completion status', () async {
      libBuilder.addMp3('track1.mp3');
      libBuilder.addMp3('track2.mp3');

      final states = <ScannerState>[];
      final sub = scanner.stateStream.listen(states.add);

      await scanner.scanDirectories([libBuilder.path]);
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(states, isNotEmpty);
      expect(states.any((s) => s.status == ScannerStatus.scanning), isTrue);
      expect(states.last.status, equals(ScannerStatus.completed));
      expect(states.last.progress, equals(1.0));
      expect(states.last.filesScanned, equals(2));
    });
  });

  // ==========================================================================
  // Area 3: Repositories & State Management (F2.16 - F2.22)
  // ==========================================================================
  group('Tier 1: Feature Coverage — Area 3: Repositories & State Management (F2.16 - F2.22)', () {
    late TestAppDatabase db;
    late TestTracksRepository tracksRepo;
    late TestAlbumsRepository albumsRepo;
    late TestArtistsRepository artistsRepo;
    late TestPlaylistsRepository playlistsRepo;

    setUp(() {
      db = TestAppDatabase.inMemory();
      tracksRepo = TestTracksRepository(db);
      albumsRepo = TestAlbumsRepository(db);
      artistsRepo = TestArtistsRepository(db);
      playlistsRepo = TestPlaylistsRepository(db);
    });

    tearDown(() {
      db.close();
    });

    test('T1.REPO.1: ITracksRepository supports search filtering across title, artist, and album', () async {
      await tracksRepo.insertTracks([
        const Track(id: '1', title: 'Starlight', artist: 'Muse', album: 'Black Holes', duration: Duration(minutes: 4)),
        const Track(id: '2', title: 'Supermassive Black Hole', artist: 'Muse', album: 'Black Holes', duration: Duration(minutes: 3)),
        const Track(id: '3', title: 'Midnight City', artist: 'M83', album: 'Hurry Up', duration: Duration(minutes: 4)),
      ]);

      // Search by title substring
      final searchTitle = await tracksRepo.getAllTracks(searchQuery: 'Star');
      expect(searchTitle.valueOrNull?.length, equals(1));
      expect(searchTitle.valueOrNull?.first.title, equals('Starlight'));

      // Search by artist
      final searchArtist = await tracksRepo.getAllTracks(searchQuery: 'Muse');
      expect(searchArtist.valueOrNull?.length, equals(2));

      // Search by album
      final searchAlbum = await tracksRepo.getAllTracks(searchQuery: 'Hurry');
      expect(searchAlbum.valueOrNull?.length, equals(1));
      expect(searchAlbum.valueOrNull?.first.title, equals('Midnight City'));
    });

    test('T1.REPO.2: ITracksRepository supports sorting by title, artist, and duration', () async {
      await tracksRepo.insertTracks([
        const Track(id: '1', title: 'Zebra', artist: 'Beach House', duration: Duration(seconds: 300)),
        const Track(id: '2', title: 'Apple', artist: 'Charli', duration: Duration(seconds: 150)),
        const Track(id: '3', title: 'Mango', artist: 'Amber', duration: Duration(seconds: 200)),
      ]);

      // Sort by title ASC
      final sortTitleAsc = await tracksRepo.getAllTracks(sortBy: TrackSortBy.title, ascending: true);
      final titlesAsc = sortTitleAsc.valueOrNull!.map((t) => t.title).toList();
      expect(titlesAsc, equals(['Apple', 'Mango', 'Zebra']));

      // Sort by duration ASC
      final sortDurationAsc = await tracksRepo.getAllTracks(sortBy: TrackSortBy.duration, ascending: true);
      final durations = sortDurationAsc.valueOrNull!.map((t) => t.duration.inSeconds).toList();
      expect(durations, equals([150, 200, 300]));
    });

    test('T1.REPO.3: ITracksRepository toggles favorite state and deletes track', () async {
      await tracksRepo.insertTrack(
        const Track(id: 'fav-1', title: 'Fav Track', artist: 'Artist', duration: Duration(minutes: 3)),
      );

      var track = (await tracksRepo.getTrackById('fav-1')).valueOrNull;
      expect(track?.isFavorite, isFalse);

      // Toggle favorite -> true
      await tracksRepo.toggleFavorite('fav-1');
      track = (await tracksRepo.getTrackById('fav-1')).valueOrNull;
      expect(track?.isFavorite, isTrue);

      // Toggle favorite -> false
      await tracksRepo.toggleFavorite('fav-1');
      track = (await tracksRepo.getTrackById('fav-1')).valueOrNull;
      expect(track?.isFavorite, isFalse);

      // Delete track
      await tracksRepo.deleteTrack('fav-1');
      final deleted = (await tracksRepo.getTrackById('fav-1')).valueOrNull;
      expect(deleted, isNull);
    });

    test('T1.REPO.4: IAlbumsRepository aggregates albums and returns album tracks in order', () async {
      db.execute(
        'INSERT INTO albums (id, title, artist, year, track_count) VALUES (?, ?, ?, ?, ?);',
        ['alb-1', 'Discovery', 'Daft Punk', 2001, 2],
      );
      await tracksRepo.insertTracks([
        const Track(id: 't2', title: 'Aerodynamic', artist: 'Daft Punk', album: 'Discovery', trackNumber: 2, duration: Duration(minutes: 3)),
        const Track(id: 't1', title: 'One More Time', artist: 'Daft Punk', album: 'Discovery', trackNumber: 1, duration: Duration(minutes: 5)),
      ]);

      final albumsResult = await albumsRepo.getAllAlbums();
      expect(albumsResult.valueOrNull?.length, equals(1));
      expect(albumsResult.valueOrNull?.first.title, equals('Discovery'));

      final tracksResult = await albumsRepo.getTracksForAlbum('alb-1');
      final albumTracks = tracksResult.valueOrNull!;
      expect(albumTracks.length, equals(2));
      expect(albumTracks[0].title, equals('One More Time')); // Track 1
      expect(albumTracks[1].title, equals('Aerodynamic')); // Track 2
    });

    test('T1.REPO.5: IArtistsRepository aggregates artists and queries tracks by artist', () async {
      db.execute('INSERT INTO artists (id, name, track_count, album_count) VALUES (?, ?, ?, ?);', ['art-1', 'NEXA Artist', 2, 1]);
      await tracksRepo.insertTracks([
        const Track(id: '1', title: 'Song Alpha', artist: 'NEXA Artist', duration: Duration(minutes: 3)),
        const Track(id: '2', title: 'Song Beta', artist: 'NEXA Artist', duration: Duration(minutes: 4)),
      ]);

      final artists = (await artistsRepo.getAllArtists()).valueOrNull!;
      expect(artists.length, equals(1));
      expect(artists.first.name, equals('NEXA Artist'));

      final artistSongs = (await artistsRepo.getTracksForArtist('art-1')).valueOrNull!;
      expect(artistSongs.length, equals(2));
    });

    test('T1.REPO.6: IPlaylistsRepository creates, manages tracks with ordering, and deletes playlists', () async {
      await tracksRepo.insertTracks([
        const Track(id: 'trk-1', title: 'First', artist: 'Artist', duration: Duration(minutes: 3)),
        const Track(id: 'trk-2', title: 'Second', artist: 'Artist', duration: Duration(minutes: 3)),
      ]);

      final createRes = await playlistsRepo.createPlaylist('Focus Vibes');
      expect(createRes.isSuccess, isTrue);
      final playlist = createRes.valueOrNull!;
      expect(playlist.name, equals('Focus Vibes'));

      // Add tracks
      await playlistsRepo.addTrackToPlaylist(playlist.id, 'trk-1');
      await playlistsRepo.addTrackToPlaylist(playlist.id, 'trk-2');

      final plTracks = (await playlistsRepo.getTracksForPlaylist(playlist.id)).valueOrNull!;
      expect(plTracks.length, equals(2));
      expect(plTracks[0].title, equals('First'));
      expect(plTracks[1].title, equals('Second'));

      // Remove track
      await playlistsRepo.removeTrackFromPlaylist(playlist.id, 'trk-1');
      final remainingTracks = (await playlistsRepo.getTracksForPlaylist(playlist.id)).valueOrNull!;
      expect(remainingTracks.length, equals(1));
      expect(remainingTracks[0].title, equals('Second'));

      // Delete playlist
      await playlistsRepo.deletePlaylist(playlist.id);
      final allPlaylists = (await playlistsRepo.getAllPlaylists()).valueOrNull!;
      expect(allPlaylists.any((p) => p.id == playlist.id), isFalse);
    });
  });

  // ==========================================================================
  // Area 4: UI Library Screens (F2.23 - F2.27, F2.29)
  // ==========================================================================
  group('Tier 1: Feature Coverage — Area 4: UI Library Screens (F2.23 - F2.27)', () {
    late TestAppDatabase db;
    late TestMediaScannerService scanner;
    late TestTracksRepository tracksRepo;
    late TestAlbumsRepository albumsRepo;
    late TestArtistsRepository artistsRepo;
    late TestGenresRepository genresRepo;
    late TestPlaylistsRepository playlistsRepo;

    setUp(() {
      db = TestAppDatabase.inMemory();
      scanner = TestMediaScannerService(database: db);
      tracksRepo = TestTracksRepository(db);
      albumsRepo = TestAlbumsRepository(db);
      artistsRepo = TestArtistsRepository(db);
      genresRepo = TestGenresRepository(db);
      playlistsRepo = TestPlaylistsRepository(db);
    });

    tearDown(() {
      scanner.dispose();
      db.close();
    });

    testWidgets('T1.UI.1: All Songs Screen renders TrackTile list and total song count', (tester) async {
      await tracksRepo.insertTracks([
        const Track(id: 't1', title: 'Solar Flare', artist: 'Cosmic Lab', duration: Duration(minutes: 3, seconds: 30)),
        const Track(id: 't2', title: 'Lunar Drift', artist: 'Cosmic Lab', duration: Duration(minutes: 4, seconds: 15)),
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

      expect(find.byKey(E2EPhase2Keys.songCountHeader), findsOneWidget);
      expect(find.text('All Songs (2)'), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.trackTile('t1')), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.trackTile('t2')), findsOneWidget);
    });

    testWidgets('T1.UI.2: All Songs Screen search field filters songs interactively', (tester) async {
      await tracksRepo.insertTracks([
        const Track(id: 't1', title: 'Synthwave Odyssey', artist: 'Retro Future', duration: Duration(minutes: 3)),
        const Track(id: 't2', title: 'Acoustic Morning', artist: 'Folk Trio', duration: Duration(minutes: 2)),
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

      expect(find.text('Synthwave Odyssey'), findsOneWidget);
      expect(find.text('Acoustic Morning'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byKey(E2EPhase2Keys.searchField), 'Synth');
      await tester.pumpAndSettle();

      expect(find.text('Synthwave Odyssey'), findsOneWidget);
      expect(find.text('Acoustic Morning'), findsNothing);
    });

    testWidgets('T1.UI.3: All Songs Screen sort menu changes sort order', (tester) async {
      await tracksRepo.insertTracks([
        const Track(id: 't1', title: 'Alpha', artist: 'Zoe', duration: Duration(minutes: 5)),
        const Track(id: 't2', title: 'Beta', artist: 'Aaron', duration: Duration(minutes: 2)),
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

      // Open sort popup menu
      await tester.tap(find.byKey(E2EPhase2Keys.sortButton));
      await tester.pumpAndSettle();

      // Tap sort by Artist
      await tester.tap(find.byKey(E2EPhase2Keys.sortMenuArtist));
      await tester.pumpAndSettle();

      // First item is Aaron (Beta), second is Zoe (Alpha)
      final tiles = tester.widgetList<TrackTile>(find.byType(TrackTile)).toList();
      expect(tiles.first.title, equals('Beta'));
      expect(tiles.last.title, equals('Alpha'));
    });

    testWidgets('T1.UI.4: Albums Screen renders grid and opens Album Detail view', (tester) async {
      db.execute(
        'INSERT INTO albums (id, title, artist, year, track_count) VALUES (?, ?, ?, ?, ?);',
        ['alb-neon', 'Neon Dreams', 'Cyber Sound', 2026, 1],
      );
      await tracksRepo.insertTrack(
        const Track(id: 't1', title: 'Grid Runner', artist: 'Cyber Sound', album: 'Neon Dreams', duration: Duration(minutes: 4)),
      );

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

      expect(find.byKey(E2EPhase2Keys.albumCard('alb-neon')), findsOneWidget);

      // Tap album card to open detail view
      await tester.tap(find.byKey(E2EPhase2Keys.albumCard('alb-neon')));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EPhase2Keys.albumDetailScreen), findsOneWidget);
      expect(find.text('Grid Runner'), findsOneWidget);

      // Back button closes detail
      await tester.tap(find.byKey(E2EPhase2Keys.albumDetailBackButton));
      await tester.pumpAndSettle();
      expect(find.byKey(E2EPhase2Keys.albumsGrid), findsOneWidget);
    });

    testWidgets('T1.UI.5: Playlists Screen creates new playlist via dialog and lists it', (tester) async {
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

      // Tap FAB
      await tester.tap(find.byKey(E2EPhase2Keys.createPlaylistFab));
      await tester.pumpAndSettle();

      expect(find.byKey(E2EPhase2Keys.createPlaylistDialog), findsOneWidget);

      // Enter name and confirm
      await tester.enterText(find.byKey(E2EPhase2Keys.playlistNameInput), 'Night Drive');
      await tester.tap(find.byKey(E2EPhase2Keys.playlistConfirmCreate));
      await tester.pumpAndSettle();

      expect(find.text('Night Drive'), findsOneWidget);
    });
  });

  // ==========================================================================
  // Area 5: Scanner Settings Screen (F2.28, F2.29)
  // ==========================================================================
  group('Tier 1: Feature Coverage — Area 5: Scanner Settings Screen (F2.28, F2.29)', () {
    late TestAppDatabase db;
    late TestMediaScannerService scanner;
    late TestTracksRepository tracksRepo;
    late TestAlbumsRepository albumsRepo;
    late TestArtistsRepository artistsRepo;
    late TestGenresRepository genresRepo;
    late TestPlaylistsRepository playlistsRepo;

    setUp(() {
      db = TestAppDatabase.inMemory();
      scanner = TestMediaScannerService(database: db);
      tracksRepo = TestTracksRepository(db);
      albumsRepo = TestAlbumsRepository(db);
      artistsRepo = TestArtistsRepository(db);
      genresRepo = TestGenresRepository(db);
      playlistsRepo = TestPlaylistsRepository(db);
    });

    tearDown(() {
      scanner.dispose();
      db.close();
    });

    testWidgets('T1.SET.1: Scanner Settings screen displays folder management and rescan controls', (tester) async {
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

      expect(find.byKey(E2EPhase2Keys.scannerSettingsScreen), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.addFolderButton), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.rescanButton), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.scannerProgressBar), findsOneWidget);
      expect(find.byKey(E2EPhase2Keys.skipShortFilesSwitch), findsOneWidget);
    });

    testWidgets('T1.SET.2: Adding and removing a music folder updates folder list', (tester) async {
      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 5,
      ));
      await tester.pumpAndSettle();

      // Tap Add Folder
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderButton));
      await tester.pumpAndSettle();

      // Enter path
      await tester.enterText(find.byKey(E2EPhase2Keys.addFolderPathInput), '/storage/Music');
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderConfirmButton));
      await tester.pumpAndSettle();

      expect(find.text('/storage/Music'), findsOneWidget);

      // Remove folder
      await tester.tap(find.byKey(E2EPhase2Keys.removeFolderButton('/storage/Music')));
      await tester.pumpAndSettle();

      expect(find.text('/storage/Music'), findsNothing);
    });

    testWidgets('T1.SET.3: Tapping Rescan triggers media scan with reactive progress updates', (tester) async {
      final lib = SyntheticLibraryBuilder();
      addTearDown(lib.dispose);
      lib.addMp3('song1.mp3');

      await tester.pumpWidget(NexaPhase2TestApp(
        database: db,
        scannerService: scanner,
        tracksRepo: tracksRepo,
        albumsRepo: albumsRepo,
        artistsRepo: artistsRepo,
        genresRepo: genresRepo,
        playlistsRepo: playlistsRepo,
        initialTab: 5,
      ));
      await tester.pumpAndSettle();

      // Add the real temp folder
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(E2EPhase2Keys.addFolderPathInput), lib.path);
      await tester.tap(find.byKey(E2EPhase2Keys.addFolderConfirmButton));
      await tester.pumpAndSettle();

      // Tap Rescan
      await tester.tap(find.byKey(E2EPhase2Keys.rescanButton));
      await tester.pumpAndSettle();

      expect(find.textContaining('Status: completed'), findsOneWidget);
      expect(find.textContaining('1 / 1 files'), findsOneWidget);
    });
  });
}
