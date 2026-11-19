import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/playlists/data/services/ringtone_service_impl.dart';
import 'package:nexa_player/features/playlists/domain/models/ringtone_trim_range.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  late Directory tempDir;
  late RingtoneServiceImpl ringtoneService;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nexa_ringtone_test_');
    ringtoneService = RingtoneServiceImpl(outputDirectoryPath: tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  const testTrack = Track(
    id: 'track-ringtone-1',
    title: 'Neon Lights',
    artist: 'Craft',
    duration: Duration(seconds: 180),
    filePath: '/dev/null',
  );

  group('RingtoneServiceImpl', () {
    test('successfully trims audio and exports output file with target name', () async {
      const range = RingtoneTrimRange(
        startMs: 10000,
        endMs: 40000,
      );

      final result = await ringtoneService.trimAudio(
        track: testTrack,
        range: range,
        target: RingtoneTarget.alarm,
      );

      expect(result.isSuccess, isTrue);
      final outputPath = result.valueOrNull!;
      expect(outputPath, contains('Neon_Lights_alarm_10000_40000.mp3'));
      expect(File(outputPath).existsSync(), isTrue);
    });

    test('asserts when creating range with negative start time', () {
      expect(
        () => RingtoneTrimRange(startMs: -500, endMs: 30000),
        throwsAssertionError,
      );
    });

    test('asserts when creating range with end time before start time', () {
      expect(
        () => RingtoneTrimRange(startMs: 30000, endMs: 10000),
        throwsAssertionError,
      );
    });

    test('rejects duration shorter than 1000ms', () async {
      const range = RingtoneTrimRange(
        startMs: 5000,
        endMs: 5500, // 500ms duration
      );

      final result = await ringtoneService.trimAudio(
        track: testTrack,
        range: range,
        target: RingtoneTarget.ringtone,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull?.message, contains('at least 1 second'));
    });

    test('slices actual file bytes when source file exists', () async {
      // Create a dummy audio file in tempDir
      final dummySource = File('${tempDir.path}/source.mp3');
      final dummyBytes = List<int>.generate(1000, (i) => i % 256);
      await dummySource.writeAsBytes(dummyBytes);

      final realTrack = Track(
        id: 'real-track',
        title: 'Real Song',
        artist: 'Artist',
        duration: const Duration(seconds: 100),
        filePath: dummySource.path,
      );

      // Slice 20s to 40s (ratio 0.2 to 0.4 -> roughly bytes 200 to 400)
      const range = RingtoneTrimRange(
        startMs: 20000,
        endMs: 40000,
      );

      final result = await ringtoneService.trimAudio(
        track: realTrack,
        range: range,
        target: RingtoneTarget.audioFile,
      );

      expect(result.isSuccess, isTrue);
      final outFile = File(result.valueOrNull!);
      expect(outFile.existsSync(), isTrue);
      final outputBytes = await outFile.readAsBytes();
      expect(outputBytes.length, inInclusiveRange(195, 205));
    });
  });
}
