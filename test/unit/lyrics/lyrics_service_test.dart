import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/lyrics/data/services/lrclib_api_client.dart';
import 'package:nexa_player/features/lyrics/data/services/lyrics_service_impl.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/domain/services/lrc_parser.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../../helpers/mock_services.dart';

class MockLrclibApiClient extends Mock implements ILrclibApiClient {}

void main() {
  late FakeStorageService fakeStorage;
  late MockLrclibApiClient mockLrclib;
  late LyricsServiceImpl lyricsService;
  late Directory tempDir;

  setUp(() {
    fakeStorage = FakeStorageService();
    mockLrclib = MockLrclibApiClient();
    lyricsService = LyricsServiceImpl(
      storageService: fakeStorage,
      lrclibClient: mockLrclib,
    );
    tempDir = Directory.systemTemp.createTempSync('nexa_lyrics_test_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const testTrack = Track(
    id: 'trk-lyrics-1',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(seconds: 230),
    filePath: '/storage/music/starboy.mp3',
  );

  group('LyricsServiceImpl', () {
    test('fetches from online LRCLIB client when no cache or file exists, and saves to cache', () async {
      when(() => mockLrclib.fetchLyrics(
        trackName: 'Starboy',
        artistName: 'The Weeknd',
        albumName: 'Starboy',
        durationSeconds: 230,
      )).thenAnswer((_) async => const Result.success(
            LrclibResponse(
              id: 999,
              trackName: 'Starboy',
              artistName: 'The Weeknd',
              syncedLyrics: '[00:15.00]I\'m tryna put you in the worst mood, ah\n[00:19.00]P1 cleaner than your church shoes, ah',
            ),
          ));

      final result = await lyricsService.getLyricsForTrack(testTrack);

      expect(result.isSuccess, isTrue);
      final lyrics = result.valueOrNull!;
      expect(lyrics.isSynced, isTrue);
      expect(lyrics.source, equals(LyricsSource.lrclib));
      expect(lyrics.lines.length, equals(2));
      expect(lyrics.lines[0].text, equals('I\'m tryna put you in the worst mood, ah'));

      // Verify cached in storage
      final cached = fakeStorage.getString('nexa_lyrics_${testTrack.id}');
      expect(cached.isSuccess, isTrue);
      expect(cached.valueOrNull, contains('church shoes'));
    });

    test('returns cached lyrics without hitting online client', () async {
      // Pre-seed storage
      await fakeStorage.setString(
        'nexa_lyrics_${testTrack.id}',
        '{"track_id":"trk-lyrics-1","lines":[{"timestamp_ms":1000,"text":"Cached Line","translation":null}],"is_synced":true,"source":"manual","offset_ms":50}',
      );

      final result = await lyricsService.getLyricsForTrack(testTrack);

      expect(result.isSuccess, isTrue);
      final lyrics = result.valueOrNull!;
      expect(lyrics.lines.first.text, equals('Cached Line'));
      expect(lyrics.offsetMs, equals(50));
      verifyNever(() => mockLrclib.fetchLyrics(
        trackName: any(named: 'trackName'),
        artistName: any(named: 'artistName'),
        albumName: any(named: 'albumName'),
        durationSeconds: any(named: 'durationSeconds'),
      ));
    });

    test('reads companion .lrc file from disk when cache is empty', () async {
      final audioFile = File('${tempDir.path}/track.mp3');
      final lrcFile = File('${tempDir.path}/track.lrc');

      await audioFile.writeAsString('dummy mp3');
      await lrcFile.writeAsString('[00:05.50]Local LRC Line');

      final trackWithLocalLrc = Track(
        id: 'trk-local-lrc',
        title: 'Local Song',
        artist: 'Local Artist',
        duration: const Duration(seconds: 100),
        filePath: audioFile.path,
      );

      final result = await lyricsService.getLyricsForTrack(trackWithLocalLrc);

      expect(result.isSuccess, isTrue);
      final lyrics = result.valueOrNull!;
      expect(lyrics.isSynced, isTrue);
      expect(lyrics.source, equals(LyricsSource.lrcFile));
      expect(lyrics.lines.first.text, equals('Local LRC Line'));
    });

    test('saveLyrics writes to cache and optionally writes companion .lrc file', () async {
      final audioFile = File('${tempDir.path}/save_test.mp3');
      await audioFile.writeAsString('audio');

      final trackToSave = Track(
        id: 'trk-save-1',
        title: 'Save Me',
        artist: 'Artist',
        duration: const Duration(seconds: 120),
        filePath: audioFile.path,
      );

      final lyricsToSave = (await lyricsService.fetchOnlineLyrics(testTrack)).valueOrNull ??
          const LrcParser().parse('[00:10.00]Save me line', trackId: 'trk-save-1');

      final saveResult = await lyricsService.saveLyrics(
        trackToSave,
        lyricsToSave,
        saveToLrcFile: true,
      );

      expect(saveResult.isSuccess, isTrue);

      // Verify companion .lrc file was created on disk
      final expectedLrc = File('${tempDir.path}/save_test.lrc');
      expect(expectedLrc.existsSync(), isTrue);
      final content = await expectedLrc.readAsString();
      expect(content, contains('Save me line'));
    });

    test('updateOffset modifies offsetMs in storage cache', () async {
      await fakeStorage.setString(
        'nexa_lyrics_${testTrack.id}',
        '{"track_id":"trk-lyrics-1","lines":[],"is_synced":false,"source":"none","offset_ms":0}',
      );

      final res = await lyricsService.updateOffset(testTrack.id, 750);
      expect(res.isSuccess, isTrue);

      final cached = fakeStorage.getString('nexa_lyrics_${testTrack.id}').valueOrNull!;
      expect(cached, contains('"offset_ms":750'));
    });

    test('deleteLyrics removes item from storage', () async {
      await fakeStorage.setString('nexa_lyrics_${testTrack.id}', '{"track_id":"trk-lyrics-1"}');
      final res = await lyricsService.deleteLyrics(testTrack.id);
      expect(res.isSuccess, isTrue);

      final cached = fakeStorage.getString('nexa_lyrics_${testTrack.id}').valueOrNull;
      expect(cached, isNull);
    });
  });
}
