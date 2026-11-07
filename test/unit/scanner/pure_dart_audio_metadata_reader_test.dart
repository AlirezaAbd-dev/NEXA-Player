import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';

import '../../helpers/synthetic_audio_generator.dart';

void main() {
  group('PureDartAudioMetadataReader Unit Tests', () {
    const reader = PureDartAudioMetadataReader();

    test('extracts ID3v2 metadata correctly from synthetic MP3', () {
      final bytes = SyntheticAudioGenerator.createMp3Bytes(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        genre: 'Rock',
        year: 1975,
        trackNumber: 4,
        duration: const Duration(seconds: 354),
      );

      final meta = reader.extractBytes(bytes, 'bohemian_fallback');

      expect(meta.title, equals('Bohemian Rhapsody'));
      expect(meta.artist, equals('Queen'));
      expect(meta.album, equals('A Night at the Opera'));
      expect(meta.genre, equals('Rock'));
      expect(meta.year, equals(1975));
      expect(meta.trackNumber, equals(4));
      expect(meta.duration.inSeconds, equals(354));
    });

    test('extracts metadata from synthetic WAV buffer', () {
      final bytes = SyntheticAudioGenerator.createWavBytes(
        duration: const Duration(seconds: 12),
      );

      final meta = reader.extractBytes(bytes, 'test_sample');

      expect(meta.title, equals('test_sample'));
      expect(meta.artist, equals('WAV Artist'));
      expect(meta.duration.inSeconds, equals(12));
    });

    test('extracts metadata from synthetic FLAC buffer', () {
      final bytes = SyntheticAudioGenerator.createFlacBytes(
        duration: const Duration(seconds: 25),
      );

      final meta = reader.extractBytes(bytes, 'flac_sample');

      expect(meta.title, equals('flac_sample'));
      expect(meta.artist, equals('FLAC Artist'));
      expect(meta.duration.inSeconds, equals(25));
    });

    test('handles truncated or unknown audio bytes with fallback title', () {
      final dummyBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
      final meta = reader.extractBytes(dummyBytes, 'unknown_file');

      expect(meta.title, equals('unknown_file'));
      expect(meta.artist, equals('Unknown Artist'));
      expect(meta.album, equals('Unknown Album'));
      expect(meta.duration, equals(const Duration(seconds: 180)));
    });

    test('extracts metadata from real File on disk', () async {
      final tempDir = Directory.systemTemp.createTempSync('metadata_test_');
      final tempFile = File('${tempDir.path}/track_01.mp3');

      final bytes = SyntheticAudioGenerator.createMp3Bytes(
        title: 'Drive My Car',
        artist: 'The Beatles',
        album: 'Rubber Soul',
        year: 1965,
        trackNumber: 1,
      );

      tempFile.writeAsBytesSync(bytes);

      final meta = await reader.extract(tempFile);

      expect(meta.title, equals('Drive My Car'));
      expect(meta.artist, equals('The Beatles'));
      expect(meta.album, equals('Rubber Soul'));
      expect(meta.year, equals(1965));
      expect(meta.trackNumber, equals(1));

      tempDir.deleteSync(recursive: true);
    });

    test('throws FormatException when file is under 10 bytes', () async {
      final tempDir = Directory.systemTemp.createTempSync('metadata_test_');
      final tempFile = File('${tempDir.path}/corrupt.mp3');
      tempFile.writeAsBytesSync([1, 2, 3]);

      expect(
        () => reader.extract(tempFile),
        throwsA(isA<FormatException>()),
      );

      tempDir.deleteSync(recursive: true);
    });
  });
}
