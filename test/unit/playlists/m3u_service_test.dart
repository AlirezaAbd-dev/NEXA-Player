import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/playlists/data/services/m3u_service_impl.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

class MockPlaylistsRepository extends Mock implements IPlaylistsRepository {}
class MockTracksRepository extends Mock implements ITracksRepository {}

void main() {
  late MockPlaylistsRepository mockPlaylistsRepo;
  late MockTracksRepository mockTracksRepo;
  late M3uServiceImpl m3uService;

  setUp(() {
    mockPlaylistsRepo = MockPlaylistsRepository();
    mockTracksRepo = MockTracksRepository();
    m3uService = M3uServiceImpl(
      playlistsRepository: mockPlaylistsRepo,
      tracksRepository: mockTracksRepo,
    );
  });

  const testTrack1 = Track(
    id: 'track-1',
    title: 'Midnight City',
    artist: 'M83',
    album: 'Hurry Up, We\'re Dreaming',
    duration: Duration(seconds: 243),
    filePath: '/music/m83/midnight_city.mp3',
  );

  const testTrack2 = Track(
    id: 'track-2',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(seconds: 230),
    filePath: '/music/weeknd/starboy.mp3',
  );

  final testPlaylist = Playlist(
    id: 'pl-1',
    name: 'Synthwave Favorites',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    trackCount: 2,
  );

  group('M3uServiceImpl - Export', () {
    test('exports extended M3U format with header and EXTINF entries', () {
      final m3uOutput = m3uService.exportToM3u(
        testPlaylist,
        [testTrack1, testTrack2],
        extended: true,
      );

      expect(m3uOutput, contains('#EXTM3U'));
      expect(m3uOutput, contains('#PLAYLIST:Synthwave Favorites'));
      expect(m3uOutput, contains('#EXTINF:243,M83 - Midnight City'));
      expect(m3uOutput, contains('/music/m83/midnight_city.mp3'));
      expect(m3uOutput, contains('#EXTINF:230,The Weeknd - Starboy'));
      expect(m3uOutput, contains('/music/weeknd/starboy.mp3'));
    });

    test('exports simple M3U format with raw paths only when extended is false', () {
      final m3uOutput = m3uService.exportToM3u(
        testPlaylist,
        [testTrack1, testTrack2],
        extended: false,
      );

      expect(m3uOutput, isNot(contains('#EXTM3U')));
      expect(m3uOutput, isNot(contains('#EXTINF')));
      expect(m3uOutput, contains('/music/m83/midnight_city.mp3\n'));
      expect(m3uOutput, contains('/music/weeknd/starboy.mp3\n'));
    });
  });

  group('M3uServiceImpl - Parse', () {
    test('parses extended M3U content extracting artist, title, and file path', () {
      const sample = '''
#EXTM3U
#PLAYLIST:Workout Hits

#EXTINF:243,M83 - Midnight City
/music/m83/midnight_city.mp3

#EXTINF:230,The Weeknd - Starboy
/music/weeknd/starboy.mp3
''';

      final entries = m3uService.parseM3u(sample);

      expect(entries.length, equals(2));
      expect(entries[0].filePath, equals('/music/m83/midnight_city.mp3'));
      expect(entries[0].artist, equals('M83'));
      expect(entries[0].title, equals('Midnight City'));
      expect(entries[0].durationSeconds, equals(243));

      expect(entries[1].filePath, equals('/music/weeknd/starboy.mp3'));
      expect(entries[1].artist, equals('The Weeknd'));
      expect(entries[1].title, equals('Starboy'));
      expect(entries[1].durationSeconds, equals(230));
    });

    test('parses M3U with tracks lacking artist delimiter', () {
      const sample = '''
#EXTM3U
#EXTINF:180,Solo Piano Performance
/music/classical/solo_piano.mp3
''';

      final entries = m3uService.parseM3u(sample);

      expect(entries.length, equals(1));
      expect(entries[0].filePath, equals('/music/classical/solo_piano.mp3'));
      expect(entries[0].title, equals('Solo Piano Performance'));
      expect(entries[0].artist, isNull);
      expect(entries[0].durationSeconds, equals(180));
    });

    test('ignores comments and empty lines', () {
      const sample = '''
# This is a comment
# Another comment

/music/rock/song.mp3


''';

      final entries = m3uService.parseM3u(sample);

      expect(entries.length, equals(1));
      expect(entries[0].filePath, equals('/music/rock/song.mp3'));
      expect(entries[0].title, isNull);
    });
  });

  group('M3uServiceImpl - Import', () {
    test('successfully imports M3U playlist matching library tracks by path and metadata', () async {
      when(() => mockPlaylistsRepo.createPlaylist(any(), description: any(named: 'description')))
          .thenAnswer((_) async => Result.success(testPlaylist));

      when(() => mockTracksRepo.getAllTracks())
          .thenAnswer((_) async => const Result.success([testTrack1, testTrack2]));

      when(() => mockPlaylistsRepo.addTrackToPlaylist(any(), any()))
          .thenAnswer((_) async => const Result.success(null));

      when(() => mockPlaylistsRepo.getPlaylistById('pl-1'))
          .thenAnswer((_) async => Result.success(testPlaylist));

      const sample = '''
#EXTM3U
#EXTINF:243,M83 - Midnight City
/music/m83/midnight_city.mp3
#EXTINF:230,The Weeknd - Starboy
/different_path/starboy.mp3
''';

      final result = await m3uService.importM3u('My Imported List', sample);

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull?.id, equals('pl-1'));

      verify(() => mockPlaylistsRepo.createPlaylist('My Imported List', description: any(named: 'description'))).called(1);
      verify(() => mockPlaylistsRepo.addTrackToPlaylist('pl-1', 'track-1')).called(1);
      // testTrack2 matched by artist & title fallback!
      verify(() => mockPlaylistsRepo.addTrackToPlaylist('pl-1', 'track-2')).called(1);
    });

    test('returns failure when playlist creation fails', () async {
      when(() => mockPlaylistsRepo.createPlaylist(any(), description: any(named: 'description')))
          .thenAnswer((_) async => const Result.failure(DatabaseFailure('Disk full')));

      final result = await m3uService.importM3u('Fail Playlist', '/any/path.mp3');

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('Disk full'));
    });
  });
}
