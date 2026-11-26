import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_playlists_repository.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_smart_playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  late AppDatabase db;
  late SqlitePlaylistsRepository playlistsRepo;
  late SqliteSmartPlaylistsRepository smartRepo;

  setUp(() async {
    db = TestDatabaseHelper.createInMemoryDatabase();
    playlistsRepo = SqlitePlaylistsRepository(db);
    smartRepo = SqliteSmartPlaylistsRepository(db);
  });

  tearDown(() async {
    if (!db.isClosed) {
      db.close();
    }
  });

  test('getAllPlaylists computes live track_count ignoring orphaned playlist_tracks', () async {
    const t1 = Track(
      id: 't1',
      title: 'Real Track',
      artist: 'Artist',
      duration: Duration(minutes: 3),
      filePath: '/music/real.mp3',
    );
    TestDatabaseHelper.seedTrack(db, t1);

    final created = await playlistsRepo.createPlaylist('Roadtrip');
    final playlist = created.valueOrNull!;
    await playlistsRepo.addTrackToPlaylist(playlist.id, t1.id);

    // Simulate stale cached track_count=99 and an orphaned playlist_tracks row
    db.execute(
      "UPDATE playlists SET track_count = 99 WHERE id = ?;",
      [playlist.id],
    );
    db.execute('PRAGMA foreign_keys = OFF;');
    db.execute(
      "INSERT INTO playlist_tracks (playlist_id, track_id, position, added_at) VALUES (?, 'missing-id', 2, 1000);",
      [playlist.id],
    );
    db.execute('PRAGMA foreign_keys = ON;');

    final all = await playlistsRepo.getAllPlaylists();
    expect(all.isSuccess, isTrue);
    expect(all.valueOrNull!.single.trackCount, 1);
  });

  test('SmartPlaylistType.favorites reflects tracks.is_favorite = 1', () async {
    const t1 = Track(
      id: 'fav-t1',
      title: 'Liked Song',
      artist: 'Artist',
      duration: Duration(minutes: 3),
      filePath: '/music/liked.mp3',
      isFavorite: true,
    );
    TestDatabaseHelper.seedTrack(db, t1);

    final res = await smartRepo.getTracksForSmartPlaylist(SmartPlaylistType.favorites);
    expect(res.isSuccess, isTrue);
    expect(res.valueOrNull!.map((t) => t.id), ['fav-t1']);
  });
}
