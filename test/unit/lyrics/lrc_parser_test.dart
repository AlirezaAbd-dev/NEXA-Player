import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/lyrics/domain/services/lrc_parser.dart';

void main() {
  const parser = LrcParser();

  group('LrcParser - Parsing', () {
    test('parses standard centisecond LRC timestamps', () {
      const sample = '''
[ti:Midnight City]
[ar:M83]
[al:Hurry Up, We're Dreaming]
[offset:+250]
[00:15.20]Waiting in a car
[00:18.50]Waiting for a ride in the dark
[00:23.00]The night city grows
''';

      final lyrics = parser.parse(sample, trackId: 'trk-1');

      expect(lyrics.isSynced, isTrue);
      expect(lyrics.trackId, equals('trk-1'));
      expect(lyrics.offsetMs, equals(250));
      expect(lyrics.lines.length, equals(3));

      expect(lyrics.lines[0].text, equals('Waiting in a car'));
      expect(lyrics.lines[0].timestamp, equals(const Duration(seconds: 15, milliseconds: 200)));

      expect(lyrics.lines[1].text, equals('Waiting for a ride in the dark'));
      expect(lyrics.lines[1].timestamp, equals(const Duration(seconds: 18, milliseconds: 500)));

      expect(lyrics.lines[2].text, equals('The night city grows'));
      expect(lyrics.lines[2].timestamp, equals(const Duration(seconds: 23)));
    });

    test('parses millisecond timestamps [mm:ss.xxx]', () {
      const sample = '''
[01:05.123]High precision timestamp
[01:10.500]Half second line
''';

      final lyrics = parser.parse(sample, trackId: 'trk-2');

      expect(lyrics.lines.length, equals(2));
      expect(lyrics.lines[0].timestamp, equals(const Duration(minutes: 1, seconds: 5, milliseconds: 123)));
      expect(lyrics.lines[1].timestamp, equals(const Duration(minutes: 1, seconds: 10, milliseconds: 500)));
    });

    test('parses multi-timestamp lines and sorts chronologically', () {
      const sample = '''
[00:30.00]Second verse
[00:10.00][00:50.00]Repeating chorus
''';

      final lyrics = parser.parse(sample, trackId: 'trk-3');

      expect(lyrics.lines.length, equals(3));
      // Chronological order: 10s -> 30s -> 50s
      expect(lyrics.lines[0].timestamp, equals(const Duration(seconds: 10)));
      expect(lyrics.lines[0].text, equals('Repeating chorus'));

      expect(lyrics.lines[1].timestamp, equals(const Duration(seconds: 30)));
      expect(lyrics.lines[1].text, equals('Second verse'));

      expect(lyrics.lines[2].timestamp, equals(const Duration(seconds: 50)));
      expect(lyrics.lines[2].text, equals('Repeating chorus'));
    });

    test('parses plain unsynchronized text', () {
      const sample = '''
Just a small town girl
Living in a lonely world
She took the midnight train going anywhere
''';

      final lyrics = parser.parsePlainText(sample, trackId: 'trk-4');

      expect(lyrics.isSynced, isFalse);
      expect(lyrics.lines, isEmpty);
      expect(lyrics.plainLyrics, contains('Just a small town girl'));
      expect(lyrics.plainLyrics, contains('Living in a lonely world'));
    });
  });

  group('LrcParser - Serialization', () {
    test('serializes LyricLines to standard LRC format', () {
      final sample = parser.parse('''
[00:12.34]First Line
[00:25.00]Second Line
''', trackId: 'trk-5');

      final lrcOutput = parser.toLrc(
        sample.lines,
        title: 'Song Title',
        artist: 'Artist Name',
        album: 'Album Name',
        offsetMs: 150,
      );

      expect(lrcOutput, contains('[ti:Song Title]'));
      expect(lrcOutput, contains('[ar:Artist Name]'));
      expect(lrcOutput, contains('[al:Album Name]'));
      expect(lrcOutput, contains('[offset:150]'));
      expect(lrcOutput, contains('[00:12.34] First Line'));
      expect(lrcOutput, contains('[00:25.00] Second Line'));
    });
  });

  group('Lyrics Model - findActiveLineIndex', () {
    test('accurately resolves active line index across playback progression', () {
      final lyrics = parser.parse('''
[00:10.00]Intro
[00:20.00]Verse 1
[00:30.00]Chorus
[00:40.00]Outro
''', trackId: 'trk-6');

      // Before first line
      expect(lyrics.findActiveLineIndex(const Duration(seconds: 5)), equals(-1));

      // Exactly at first line
      expect(lyrics.findActiveLineIndex(const Duration(seconds: 10)), equals(0));

      // Between verse 1 and chorus
      expect(lyrics.findActiveLineIndex(const Duration(seconds: 25)), equals(1));

      // Exactly at chorus
      expect(lyrics.findActiveLineIndex(const Duration(seconds: 30)), equals(2));

      // Far past outro
      expect(lyrics.findActiveLineIndex(const Duration(seconds: 90)), equals(3));
    });

    test('respects user offsetMs when finding active line', () {
      final baseLyrics = parser.parse('''
[00:10.00]Line 1
[00:20.00]Line 2
''', trackId: 'trk-7');

      // Offset +2000ms (+2s): audio at 11s acts like 9s (before line 1 at 10s)
      final delayedLyrics = baseLyrics.copyWith(offsetMs: 2000);
      expect(delayedLyrics.findActiveLineIndex(const Duration(seconds: 11)), equals(-1));
      expect(delayedLyrics.findActiveLineIndex(const Duration(seconds: 12)), equals(0));

      // Offset -2000ms (-2s): audio at 8s acts like 10s (reaches line 1 early)
      final earlyLyrics = baseLyrics.copyWith(offsetMs: -2000);
      expect(earlyLyrics.findActiveLineIndex(const Duration(seconds: 8)), equals(0));
    });
  });
}
