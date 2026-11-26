import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/search/data/repositories/sqlite_search_repository.dart';
import 'package:nexa_player/features/search/domain/models/search_result_category.dart';
import 'package:nexa_player/shared/models/models.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import '../../helpers/test_database_helper.dart';

class InMemoryStorageService implements IStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Result<bool?, StorageFailure> getBool(String key) => Result.success(_data[key] as bool?);

  @override
  Result<String?, StorageFailure> getString(String key) => Result.success(_data[key] as String?);

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    _data.remove(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _data.clear();
    return const Result.success(null);
  }
}

void main() {
  late AppDatabase db;
  late InMemoryStorageService storage;
  late SqliteSearchRepository repository;

  setUp(() {
    db = TestDatabaseHelper.createInMemoryDatabase();
    storage = InMemoryStorageService();
    repository = SqliteSearchRepository(database: db, storage: storage);
  });

  tearDown(() {
    db.close();
  });

  const testTrack1 = Track(
    id: 'trk-1',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(seconds: 230),
    filePath: '/music/starboy.mp3',
    genre: 'R&B',
  );

  const testTrack2 = Track(
    id: 'trk-2',
    title: 'I Feel It Coming',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(seconds: 269),
    filePath: '/music/feel_it.mp3',
    genre: 'Pop',
  );

  const testTrack3 = Track(
    id: 'trk-3',
    title: 'Midnight City',
    artist: 'M83',
    album: 'Hurry Up, We\'re Dreaming',
    duration: Duration(seconds: 243),
    filePath: '/music/midnight.mp3',
    genre: 'Electronic',
  );

  const testAlbum1 = Album(
    id: 'alb-1',
    title: 'Starboy',
    artist: 'The Weeknd',
    year: 2016,
    trackCount: 18,
  );

  const testAlbum2 = Album(
    id: 'alb-2',
    title: 'Hurry Up, We\'re Dreaming',
    artist: 'M83',
    year: 2011,
    trackCount: 22,
  );

  const testArtist1 = Artist(
    id: 'art-1',
    name: 'The Weeknd',
    trackCount: 18,
    albumCount: 1,
  );

  const testArtist2 = Artist(
    id: 'art-2',
    name: 'M83',
    trackCount: 22,
    albumCount: 1,
  );

  const testGenre1 = Genre(
    id: 'gnr-1',
    name: 'Electronic',
    trackCount: 22,
  );

  group('SqliteSearchRepository - Search Queries', () {
    test('returns empty search result when query is empty or whitespace', () async {
      final res = await repository.search(query: '   ');
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull!.isEmpty, isTrue);
      expect(res.valueOrNull!.totalCount, equals(0));
    });

    test('searches across tracks matching title, artist, or album', () async {
      TestDatabaseHelper.seedArtist(db, testArtist1);
      TestDatabaseHelper.seedArtist(db, testArtist2);
      TestDatabaseHelper.seedAlbum(db, testAlbum1);
      TestDatabaseHelper.seedAlbum(db, testAlbum2);
      TestDatabaseHelper.seedTrack(db, testTrack1);
      TestDatabaseHelper.seedTrack(db, testTrack2);
      TestDatabaseHelper.seedTrack(db, testTrack3);

      // Search by artist name
      final artistSearch = await repository.search(query: 'Weeknd');
      expect(artistSearch.isSuccess, isTrue);
      final artistResult = artistSearch.valueOrNull!;
      expect(artistResult.tracks.length, equals(2));
      expect(artistResult.artists.any((a) => a.name == 'The Weeknd'), isTrue);

      // Search by track title
      final titleSearch = await repository.search(query: 'Midnight');
      expect(titleSearch.isSuccess, isTrue);
      final titleResult = titleSearch.valueOrNull!;
      expect(titleResult.tracks.length, equals(1));
      expect(titleResult.tracks.first.title, equals('Midnight City'));
    });

    test('ranks exact prefix matches ahead of substring matches', () async {
      const prefixTrack = Track(
        id: 'trk-pre',
        title: 'Star',
        artist: 'Artist A',
        duration: Duration(seconds: 120),
        filePath: '/music/star.mp3',
      );
      const innerTrack = Track(
        id: 'trk-in',
        title: 'All Star Track',
        artist: 'Artist B',
        duration: Duration(seconds: 120),
        filePath: '/music/all_star.mp3',
      );

      TestDatabaseHelper.seedTrack(db, innerTrack);
      TestDatabaseHelper.seedTrack(db, prefixTrack);

      final res = await repository.search(query: 'Star', category: SearchResultCategory.tracks);
      expect(res.isSuccess, isTrue);
      final tracks = res.valueOrNull!.tracks;
      expect(tracks.first.title, equals('Star'));
    });

    test('filters search specifically by category', () async {
      TestDatabaseHelper.seedArtist(db, testArtist1);
      TestDatabaseHelper.seedArtist(db, testArtist2);
      TestDatabaseHelper.seedAlbum(db, testAlbum1);
      TestDatabaseHelper.seedAlbum(db, testAlbum2);
      TestDatabaseHelper.seedTrack(db, testTrack1);

      // Category = tracks only
      final tracksOnly = await repository.search(
        query: 'Starboy',
        category: SearchResultCategory.tracks,
      );
      expect(tracksOnly.isSuccess, isTrue);
      expect(tracksOnly.valueOrNull!.tracks.length, equals(1));
      expect(tracksOnly.valueOrNull!.albums.isEmpty, isTrue);

      // Category = albums only
      final albumsOnly = await repository.search(
        query: 'Starboy',
        category: SearchResultCategory.albums,
      );
      expect(albumsOnly.isSuccess, isTrue);
      expect(albumsOnly.valueOrNull!.tracks.isEmpty, isTrue);
      expect(albumsOnly.valueOrNull!.albums.length, equals(1));
    });

    test('returns all favorited tracks when searching Favorites token', () async {
      const fav1 = Track(
        id: 'fav-1',
        title: 'Midnight Rain',
        artist: 'Artist X',
        duration: Duration(seconds: 200),
        filePath: '/music/midnight.mp3',
        isFavorite: true,
      );
      const fav2 = Track(
        id: 'fav-2',
        title: 'Solar Echo',
        artist: 'Artist Y',
        duration: Duration(seconds: 180),
        filePath: '/music/solar.mp3',
        isFavorite: true,
      );
      const nonFav = Track(
        id: 'non-fav',
        title: 'Unliked Song',
        artist: 'Artist Z',
        duration: Duration(seconds: 150),
        filePath: '/music/unliked.mp3',
        isFavorite: false,
      );

      TestDatabaseHelper.seedTrack(db, fav1);
      TestDatabaseHelper.seedTrack(db, fav2);
      TestDatabaseHelper.seedTrack(db, nonFav);

      final res = await repository.search(query: 'Favorites');
      expect(res.isSuccess, isTrue);
      final tracks = res.valueOrNull!.tracks;
      expect(tracks.map((t) => t.id), containsAll(['fav-1', 'fav-2']));
      expect(tracks.map((t) => t.id), isNot(contains('non-fav')));
    });

    test('searches genres matching name', () async {
      TestDatabaseHelper.seedGenre(db, testGenre1);

      final res = await repository.search(query: 'Electr', category: SearchResultCategory.genres);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull!.genres.length, equals(1));
      expect(res.valueOrNull!.genres.first.name, equals('Electronic'));
    });

    test('searches playlists matching name or description', () async {
      final playlist = Playlist(
        id: 'pl-1',
        name: 'Late Night Chill',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        trackCount: 12,
      );

      db.execute(
        'INSERT INTO playlists (id, name, description, created_at, updated_at, track_count) VALUES (?, ?, ?, ?, ?, ?);',
        [
          playlist.id,
          playlist.name,
          'Atmospheric electronic vibes',
          playlist.createdAt.millisecondsSinceEpoch,
          playlist.updatedAt.millisecondsSinceEpoch,
          playlist.trackCount,
        ],
      );

      final res = await repository.search(query: 'Atmospheric', category: SearchResultCategory.playlists);
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull!.playlists.length, equals(1));
      expect(res.valueOrNull!.playlists.first.name, equals('Late Night Chill'));
    });
  });

  group('SqliteSearchRepository - Recent Searches', () {
    test('saves recent searches in reverse chronological order and deduplicates', () async {
      await repository.saveRecentSearch('Daft Punk');
      await repository.saveRecentSearch('The Weeknd');
      await repository.saveRecentSearch('Daft Punk'); // duplicate bump

      final recent = await repository.getRecentSearches();
      expect(recent, equals(['Daft Punk', 'The Weeknd']));
    });

    test('removes specific query from recent searches', () async {
      await repository.saveRecentSearch('Song A');
      await repository.saveRecentSearch('Song B');
      await repository.saveRecentSearch('Song C');

      await repository.removeRecentSearch('Song B');

      final recent = await repository.getRecentSearches();
      expect(recent, equals(['Song C', 'Song A']));
    });

    test('clears all recent searches', () async {
      await repository.saveRecentSearch('Query 1');
      await repository.saveRecentSearch('Query 2');

      await repository.clearRecentSearches();

      final recent = await repository.getRecentSearches();
      expect(recent, isEmpty);
    });
  });
}
