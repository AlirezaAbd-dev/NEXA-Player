import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/scanner/data/media_scanner_service_impl.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

import '../../helpers/synthetic_audio_generator.dart';

void main() {
  group('MediaScannerServiceImpl Unit Tests', () {
    late IAppDatabase database;
    late MediaScannerServiceImpl scanner;
    late Directory tempRootDir;

    setUp(() {
      database = AppDatabase.inMemory();
      scanner = MediaScannerServiceImpl(
        database: database,
        metadataReader: const PureDartAudioMetadataReader(),
      );
      tempRootDir = Directory.systemTemp.createTempSync('scanner_unit_test_');
    });

    tearDown(() {
      scanner.dispose();
      database.close();
      if (tempRootDir.existsSync()) {
        tempRootDir.deleteSync(recursive: true);
      }
    });

    test('recursively scans directory and inserts tracks, albums, artists, genres', () async {
      final musicDir = Directory('${tempRootDir.path}/Music')..createSync();
      final rockSubDir = Directory('${musicDir.path}/Rock')..createSync();

      final t1 = File('${rockSubDir.path}/song1.mp3');
      t1.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
        title: 'Song One',
        artist: 'Artist A',
        album: 'Album X',
        genre: 'Rock',
        duration: const Duration(seconds: 120),
      ));

      final t2 = File('${musicDir.path}/song2.mp3');
      t2.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
        title: 'Song Two',
        artist: 'Artist B',
        album: 'Album Y',
        genre: 'Pop',
        duration: const Duration(seconds: 200),
      ));

      // Non-audio file that should be skipped
      File('${musicDir.path}/readme.txt').writeAsStringSync('not an audio file');

      final states = <ScannerState>[];
      final sub = scanner.stateStream.listen(states.add);

      const config = ScannerConfig(skipSmallFiles: false, minDurationSeconds: 5);
      final result = await scanner.scanDirectories([tempRootDir.path], config: config);
      await sub.cancel();

      expect(result.isSuccess, isTrue);
      final scanResult = result.valueOrNull!;
      expect(scanResult.insertedTracksCount, equals(2));
      expect(scanResult.scannedFilesCount, equals(2));

      // Verify SQLite state
      final trackRows = database.select('SELECT * FROM tracks ORDER BY title ASC');
      expect(trackRows.length, equals(2));
      expect(trackRows[0]['title'], equals('Song One'));
      expect(trackRows[0]['artist'], equals('Artist A'));
      expect(trackRows[0]['album'], equals('Album X'));
      expect(trackRows[1]['title'], equals('Song Two'));

      final albumRows = database.select('SELECT * FROM albums ORDER BY title ASC');
      expect(albumRows.length, equals(2));
      expect(albumRows[0]['title'], equals('Album X'));
      expect(albumRows[1]['title'], equals('Album Y'));

      final artistRows = database.select('SELECT * FROM artists ORDER BY name ASC');
      expect(artistRows.length, equals(2));
      expect(artistRows[0]['name'], equals('Artist A'));
      expect(artistRows[1]['name'], equals('Artist B'));

      final genreRows = database.select('SELECT * FROM genres ORDER BY name ASC');
      expect(genreRows.length, equals(2));
      expect(genreRows[0]['name'], equals('Pop'));
      expect(genreRows[1]['name'], equals('Rock'));

      expect(states.any((s) => s.status == ScannerStatus.scanning), isTrue);
      expect(scanner.currentState.status, equals(ScannerStatus.completed));
    });

    test('prunes directory tree containing .nomedia file', () async {
      final ignoredDir = Directory('${tempRootDir.path}/Ringtones')..createSync();
      File('${ignoredDir.path}/.nomedia').writeAsStringSync('');

      final ringtone = File('${ignoredDir.path}/beep.mp3');
      ringtone.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
        title: 'Beep',
        artist: 'Phone',
      ));

      final publicDir = Directory('${tempRootDir.path}/PublicMusic')..createSync();
      final song = File('${publicDir.path}/public_song.mp3');
      song.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
        title: 'Public Anthem',
        artist: 'Anthem Band',
      ));

      const config = ScannerConfig(skipSmallFiles: false, minDurationSeconds: 5);
      final result = await scanner.scanDirectories([tempRootDir.path], config: config);
      expect(result.isSuccess, isTrue);

      final tracks = database.select('SELECT * FROM tracks');
      expect(tracks.length, equals(1));
      expect(tracks.first['title'], equals('Public Anthem'));
    });

    test('skips audio files shorter than minDurationSeconds', () async {
      final musicDir = Directory('${tempRootDir.path}/Music')..createSync();

      final shortAudio = File('${musicDir.path}/short.mp3');
      shortAudio.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
        title: 'Short Clip',
        duration: const Duration(seconds: 3),
      ));

      final longAudio = File('${musicDir.path}/long.mp3');
      longAudio.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
        title: 'Full Track',
        duration: const Duration(seconds: 60),
      ));

      const config = ScannerConfig(
        skipShortAudio: true,
        minDurationSeconds: 10,
        skipSmallFiles: false,
      );

      final result = await scanner.scanDirectories([tempRootDir.path], config: config);
      expect(result.isSuccess, isTrue);

      final tracks = database.select('SELECT * FROM tracks');
      expect(tracks.length, equals(1));
      expect(tracks.first['title'], equals('Full Track'));
    });

    test('stopScan cancels active scan gracefully', () async {
      final musicDir = Directory('${tempRootDir.path}/Music')..createSync();

      for (var i = 1; i <= 5; i++) {
        final f = File('${musicDir.path}/track_$i.mp3');
        f.writeAsBytesSync(SyntheticAudioGenerator.createMp3Bytes(
          title: 'Track $i',
        ));
      }

      scanner.stopScan();

      final result = await scanner.scanDirectories([tempRootDir.path]);
      expect(result.isSuccess, isTrue);
    });
  });
}
