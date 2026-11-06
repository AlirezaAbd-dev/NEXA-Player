import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/extensions/string_x.dart';

void main() {
  group('StringX Extension', () {
    test('capitalize capitalizes the first character only', () {
      expect(''.capitalize, '');
      expect('a'.capitalize, 'A');
      expect('rock'.capitalize, 'Rock');
      expect('ELECTRONIC'.capitalize, 'ELECTRONIC');
    });

    test('toTitleCase capitalizes every word in string', () {
      expect(''.toTitleCase, '');
      expect('dark side of the moon'.toTitleCase, 'Dark Side Of The Moon');
      expect('nexa player'.toTitleCase, 'Nexa Player');
    });

    test('fileExtension extracts lowercase extension without dot', () {
      expect('song.mp3'.fileExtension, 'mp3');
      expect('track.FLAC'.fileExtension, 'flac');
      expect('/storage/music/audio.wav'.fileExtension, 'wav');
      expect('no_extension'.fileExtension, '');
      expect('trailing_dot.'.fileExtension, '');
    });

    test('fileNameWithoutExtension parses paths across platforms', () {
      expect('/storage/music/song.mp3'.fileNameWithoutExtension, 'song');
      expect(r'C:\Music\Album\track.flac'.fileNameWithoutExtension, 'track');
      expect('simple.wav'.fileNameWithoutExtension, 'simple');
      expect('no_extension'.fileNameWithoutExtension, 'no_extension');
    });

    test('isValidAudioExtension verifies supported audio formats', () {
      expect('song.mp3'.isValidAudioExtension, isTrue);
      expect('song.flac'.isValidAudioExtension, isTrue);
      expect('song.wav'.isValidAudioExtension, isTrue);
      expect('song.m4a'.isValidAudioExtension, isTrue);
      expect('song.ogg'.isValidAudioExtension, isTrue);
      expect('song.opus'.isValidAudioExtension, isTrue);
      expect('document.pdf'.isValidAudioExtension, isFalse);
      expect('script.sh'.isValidAudioExtension, isFalse);
    });

    test('ifBlank returns fallback when string is empty or whitespace', () {
      expect(''.ifBlank('Unknown'), 'Unknown');
      expect('   '.ifBlank('Unknown'), 'Unknown');
      expect('NEXA'.ifBlank('Unknown'), 'NEXA');
    });

    test('truncateWithEllipsis limits length and appends ellipsis', () {
      expect('Short'.truncateWithEllipsis(10), 'Short');
      expect('Very Long Title Exceeding Limit'.truncateWithEllipsis(15), 'Very Long Ti...');
      expect('NEXA'.truncateWithEllipsis(4), 'NEXA');
    });

    test('truncate shorthand alias limits length and appends ellipsis', () {
      expect('Short'.truncate(10), 'Short');
      expect('Very Long Title Exceeding Limit'.truncate(15), 'Very Long Ti...');
    });

    test('toColorOrNull parses 6 and 8 character hex strings', () {
      expect('#FF5722'.toColorOrNull(), const Color(0xFFFF5722));
      expect('FF5722'.toColorOrNull(), const Color(0xFFFF5722));
      expect('#80FF5722'.toColorOrNull(), const Color(0x80FF5722));
      expect('80FF5722'.toColorOrNull(), const Color(0x80FF5722));
      expect('invalid'.toColorOrNull(), isNull);
      expect('#123'.toColorOrNull(), isNull);
    });

    test('NullableStringX checks isNullOrEmpty and isNotNullOrEmpty', () {
      const String? nullStr = null;
      const String emptyStr = '';
      const String filledStr = 'hello';

      expect(nullStr.isNullOrEmpty, isTrue);
      expect(emptyStr.isNullOrEmpty, isTrue);
      expect(filledStr.isNullOrEmpty, isFalse);

      expect(nullStr.isNotNullOrEmpty, isFalse);
      expect(emptyStr.isNotNullOrEmpty, isFalse);
      expect(filledStr.isNotNullOrEmpty, isTrue);
    });
  });
}
