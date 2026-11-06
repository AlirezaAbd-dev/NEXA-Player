import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/app_constants.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/extensions/build_context_x.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';
import 'package:nexa_player/core/extensions/number_x.dart';
import 'package:nexa_player/core/extensions/string_x.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // ATTACK SURFACE 1: DurationX Extreme Values & Boundary Conditions
  // ===========================================================================
  group('Adversarial Challenge: DurationX Extreme Values & Signs', () {
    test('extreme negative durations preserve minus sign and format accurately', () {
      // 1. -100 hours
      const minus100Hours = Duration(hours: -100);
      expect(minus100Hours.toMinutesSeconds(), equals('-6000:00'));
      expect(minus100Hours.toHoursMinutesSeconds(), equals('-100:00:00'));
      expect(minus100Hours.formatAdaptive(), equals('-100:00:00'));
      expect(minus100Hours.formatAdaptive(padHours: true), equals('-100:00:00'));

      // 2. -1 millisecond: sub-second remaining time
      const minus1Ms = Duration(milliseconds: -1);
      expect(minus1Ms.toMinutesSeconds(), equals('-00:00'));
      expect(minus1Ms.toHoursMinutesSeconds(), equals('-00:00:00'));
      expect(minus1Ms.formatAdaptive(), equals('-00:00'));

      // 3. -1 microsecond: smallest negative step
      const minus1Us = Duration(microseconds: -1);
      expect(minus1Us.toMinutesSeconds(), equals('-00:00'));
      expect(minus1Us.formatAdaptive(), equals('-00:00'));

      // 4. -59 seconds vs -60 seconds vs -61 seconds
      expect(const Duration(seconds: -59).toMinutesSeconds(), equals('-00:59'));
      expect(const Duration(seconds: -60).toMinutesSeconds(), equals('-01:00'));
      expect(const Duration(seconds: -61).toMinutesSeconds(), equals('-01:01'));

      // 5. -3599 seconds vs -3600 seconds vs -3601 seconds
      expect(const Duration(seconds: -3599).toHoursMinutesSeconds(), equals('-00:59:59'));
      expect(const Duration(seconds: -3600).toHoursMinutesSeconds(), equals('-01:00:00'));
      expect(const Duration(seconds: -3601).toHoursMinutesSeconds(), equals('-01:00:01'));
      expect(const Duration(seconds: -3599).formatAdaptive(), equals('-59:59'));
      expect(const Duration(seconds: -3600).formatAdaptive(), equals('-1:00:00'));
      expect(const Duration(seconds: -3601).formatAdaptive(), equals('-1:00:01'));

      // 6. -999 days: massive negative duration
      const minus999Days = Duration(days: -999);
      expect(minus999Days.toHoursMinutesSeconds(), equals('-23976:00:00'));
    });

    test('extreme positive durations format accurately without truncation or overflow', () {
      // 1. 100 hours
      const plus100Hours = Duration(hours: 100);
      expect(plus100Hours.toMinutesSeconds(), equals('6000:00'));
      expect(plus100Hours.toHoursMinutesSeconds(), equals('100:00:00'));
      expect(plus100Hours.formatAdaptive(), equals('100:00:00'));

      // 2. 10,000 hours
      const plus10000Hours = Duration(hours: 10000);
      expect(plus10000Hours.toHoursMinutesSeconds(), equals('10000:00:00'));

      // 3. 3650 days (~10 years continuous audio stream)
      const plus10Years = Duration(days: 3650);
      expect(plus10Years.toHoursMinutesSeconds(), equals('87600:00:00'));
    });

    test('exact boundaries around zero and transitions', () {
      expect(Duration.zero.toMinutesSeconds(), equals('00:00'));
      expect(Duration.zero.toHoursMinutesSeconds(), equals('00:00:00'));
      expect(Duration.zero.formatAdaptive(), equals('00:00'));

      // 1 microsecond positive
      expect(const Duration(microseconds: 1).toMinutesSeconds(), equals('00:00'));
      expect(const Duration(microseconds: 1).formatAdaptive(), equals('00:00'));

      // Exactly 59 minutes and 59 seconds
      const maxMinute = Duration(minutes: 59, seconds: 59);
      expect(maxMinute.toMinutesSeconds(), equals('59:59'));
      expect(maxMinute.formatAdaptive(), equals('59:59'));

      // Exactly 60 minutes
      const oneHour = Duration(minutes: 60);
      expect(oneHour.toMinutesSeconds(), equals('60:00'));
      expect(oneHour.toHoursMinutesSeconds(), equals('01:00:00'));
      expect(oneHour.formatAdaptive(), equals('1:00:00'));
      expect(oneHour.formatAdaptive(padHours: true), equals('01:00:00'));
    });

    test('padMinutes option handles arbitrary magnitude inputs', () {
      expect(const Duration(minutes: 5, seconds: 3).toMinutesSeconds(padMinutes: false), equals('5:03'));
      expect(const Duration(minutes: 0, seconds: 3).toMinutesSeconds(padMinutes: false), equals('0:03'));
      expect(const Duration(minutes: -5, seconds: -3).toMinutesSeconds(padMinutes: false), equals('-5:03'));
      expect(const Duration(hours: -2).toMinutesSeconds(padMinutes: false), equals('-120:00'));
    });

    test('convenience getters remain consistent with method calls', () {
      final sampleDurations = [
        Duration.zero,
        const Duration(seconds: 45),
        const Duration(minutes: 12, seconds: 34),
        const Duration(hours: 2, minutes: 15, seconds: 9),
        const Duration(seconds: -15),
        const Duration(hours: -5, minutes: -20),
      ];

      for (final dur in sampleDurations) {
        expect(dur.formatted, equals(dur.formatAdaptive()));
        expect(dur.mmSs, equals(dur.toMinutesSeconds()));
        expect(dur.hhMmSs, equals(dur.toHoursMinutesSeconds()));
      }
    });
  });

  // ===========================================================================
  // ATTACK SURFACE 2: NumberX Boundary Conditions, Exabytes & Numerical Extremes
  // ===========================================================================
  group('Adversarial Challenge: NumberX Extremes & SI Formats', () {
    test('toFileSize handles massive sizes (Petabytes, Exabytes, maxFinite) and clamping', () {
      // 0 bytes and negative bytes
      expect(0.toFileSize(), equals('0 B'));
      expect((-1).toFileSize(), equals('0 B'));
      expect((-1024).toFileSize(), equals('0 B'));
      expect((-999999999).toFileSize(), equals('0 B'));

      // Exact boundaries
      expect(1.toFileSize(), equals('1 B'));
      expect(1023.toFileSize(), equals('1023 B'));
      expect(1024.toFileSize(), equals('1.0 KB'));
      expect((1024 * 1024 - 1).toFileSize(), equals('1024.0 KB'));
      expect((1024 * 1024).toFileSize(), equals('1.0 MB'));
      expect((1024 * 1024 * 1024).toFileSize(), equals('1.0 GB'));
      expect((1024 * 1024 * 1024 * 1024).toFileSize(), equals('1.0 TB'));

      // Petabytes (1024^5 bytes): clamps to TB index (suffixes maxes at TB)
      const petabyte = 1024.0 * 1024 * 1024 * 1024 * 1024;
      expect(petabyte.toFileSize(), equals('1024.0 TB'));

      // Exabytes (1024^6 bytes): clamps cleanly to TB
      const exabyte = petabyte * 1024.0;
      expect(exabyte.toFileSize(), equals('1048576.0 TB'));

      // double.maxFinite: does not crash or throw
      expect(double.maxFinite.toFileSize(), endsWith('TB'));

      // Custom decimals parameter
      expect(1536.toFileSize(decimals: 0), equals('2 KB'));
      expect(1536.toFileSize(decimals: 2), equals('1.50 KB'));
      expect(1536.toFileSize(decimals: 4), equals('1.5000 KB'));
    });

    test('toBitrateString handles edge cases, negative rates, and bps/kbps conversions', () {
      expect(0.toBitrateString(), equals('0 kbps'));
      expect((-320).toBitrateString(), equals('0 kbps'));
      expect((-100000).toBitrateString(), equals('0 kbps'));

      // Small standard kbps rates (<= 10000)
      expect(32.toBitrateString(), equals('32 kbps'));
      expect(64.toBitrateString(), equals('64 kbps'));
      expect(128.toBitrateString(), equals('128 kbps'));
      expect(320.toBitrateString(), equals('320 kbps'));
      expect(10000.toBitrateString(), equals('10000 kbps'));

      // High raw bps rates (> 10000)
      expect(10001.toBitrateString(), equals('10 kbps'));
      expect(128000.toBitrateString(), equals('128 kbps'));
      expect(320000.toBitrateString(), equals('320 kbps'));
      expect(1411200.toBitrateString(), equals('1411 kbps'));
      expect(9216000.toBitrateString(), equals('9216 kbps'));
    });

    test('toSampleRateString handles zero, negative, fractional, and boundary rates', () {
      expect(0.toSampleRateString(), equals('0 kHz'));
      expect((-44100).toSampleRateString(), equals('0 kHz'));

      // Already in kHz (<= 1000)
      expect(44.1.toSampleRateString(), equals('44.1 kHz'));
      expect(48.0.toSampleRateString(), equals('48.0 kHz'));
      expect(96.0.toSampleRateString(), equals('96.0 kHz'));
      expect(192.0.toSampleRateString(), equals('192.0 kHz'));
      expect(1000.toSampleRateString(), equals('1000.0 kHz'));

      // In raw Hz (> 1000)
      expect(44100.toSampleRateString(), equals('44.1 kHz'));
      expect(48000.toSampleRateString(), equals('48.0 kHz'));
      expect(88200.toSampleRateString(), equals('88.2 kHz'));
      expect(96000.toSampleRateString(), equals('96.0 kHz'));
      expect(192000.toSampleRateString(), equals('192.0 kHz'));
      expect(384000.toSampleRateString(), equals('384.0 kHz'));
    });

    test('formatCount formats pluralization across boundary and custom words', () {
      expect(1.formatCount('track'), equals('1 track'));
      expect(0.formatCount('track'), equals('0 tracks'));
      expect((-1).formatCount('track'), equals('-1 tracks'));
      expect(2.formatCount('track'), equals('2 tracks'));
      expect(1000000.formatCount('track'), equals('1000000 tracks'));

      // Custom plurals
      expect(1.formatCount('category', 'categories'), equals('1 category'));
      expect(3.formatCount('category', 'categories'), equals('3 categories'));
      expect(1.formatCount('index', 'indices'), equals('1 index'));
      expect(4.formatCount('index', 'indices'), equals('4 indices'));

      // Empty string word
      expect(1.formatCount(''), equals('1 '));
      expect(2.formatCount(''), equals('2 s'));

      // Unicode words
      expect(1.formatCount('🎵', '🎶'), equals('1 🎵'));
      expect(5.formatCount('🎵', '🎶'), equals('5 🎶'));
    });

    test('toCompact formats large positive and negative numbers and trillion scale', () {
      // Sub-thousand (both positive and negative)
      expect(0.toCompact(), equals('0'));
      expect(999.toCompact(), equals('999'));
      expect((-999).toCompact(), equals('-999'));

      // Thousands (K)
      expect(1000.toCompact(), equals('1.0K'));
      expect(1500.toCompact(), equals('1.5K'));
      expect((-1500).toCompact(), equals('-1.5K'));
      expect(999999.toCompact(), equals('1000.0K'));

      // Millions (M)
      expect(1000000.toCompact(), equals('1.0M'));
      expect(2500000.toCompact(), equals('2.5M'));
      expect((-1200000).toCompact(), equals('-1.2M'));

      // Billions (B)
      expect(1000000000.toCompact(), equals('1.0B'));
      expect((-5000000000).toCompact(), equals('-5.0B'));

      // Trillions (exceeds billion branch, stays formatted with B)
      expect(1000000000000.toCompact(), equals('1000.0B'));
    });

    test('toPercentageString clamps within [0%, 100%] regardless of input magnitude', () {
      expect(0.0.toPercentageString(), equals('0%'));
      expect(0.5.toPercentageString(), equals('50%'));
      expect(1.0.toPercentageString(), equals('100%'));

      // Clamping below 0
      expect((-0.5).toPercentageString(), equals('0%'));
      expect((-100.0).toPercentageString(), equals('0%'));

      // Clamping above 1
      expect(1.5.toPercentageString(), equals('100%'));
      expect(999.0.toPercentageString(), equals('100%'));

      // Decimal formatting
      expect(0.33333.toPercentageString(decimals: 2), equals('33.33%'));
      expect(0.33333.toPercentageString(decimals: 4), equals('33.3330%'));
    });

    test('toProgressFraction clamps within [0.0, 1.0]', () {
      expect(0.toProgressFraction, equals(0.0));
      expect(50.toProgressFraction, equals(0.5));
      expect(100.toProgressFraction, equals(1.0));

      // Out of bounds
      expect((-25).toProgressFraction, equals(0.0));
      expect(175.toProgressFraction, equals(1.0));
    });

    test('verticalSpace and horizontalSpace produce valid SizedBox instances', () {
      final v = 32.verticalSpace;
      final h = 16.horizontalSpace;

      expect(v, isA<SizedBox>());
      expect((v as SizedBox).height, equals(32.0));
      expect((v).width, isNull);

      expect(h, isA<SizedBox>());
      expect((h as SizedBox).width, equals(16.0));
      expect((h).height, isNull);
    });
  });

  // ===========================================================================
  // ATTACK SURFACE 3: StringX Extreme Strings, Unicode, Paths & Colors
  // ===========================================================================
  group('Adversarial Challenge: StringX Unicode, Lengths & Robustness', () {
    test('capitalize and toTitleCase handle extreme lengths and complex scripts', () {
      // 1. Empty string
      expect(''.capitalize, equals(''));
      expect(''.toTitleCase, equals(''));

      // 2. 10,000 character string
      final hugeLower = 'a' * 10000;
      final capitalizedHuge = hugeLower.capitalize;
      expect(capitalizedHuge.length, equals(10000));
      expect(capitalizedHuge[0], equals('A'));
      expect(capitalizedHuge.substring(1), equals('a' * 9999));

      // 3. Multi-word 10,000 character string
      final longTitle = List.generate(500, (i) => 'word$i').join(' ');
      final titleCased = longTitle.toTitleCase;
      expect(titleCased, startsWith('Word0 Word1'));
      expect(titleCased, endsWith('Word499'));

      // 4. Consecutive spaces preserved in toTitleCase
      expect('alpha   beta     gamma'.toTitleCase, equals('Alpha   Beta     Gamma'));
      expect('   leading and trailing   '.toTitleCase, equals('   Leading And Trailing   '));

      // 5. Multi-byte Unicode Emojis & Surrogate Pairs
      expect('🎵song'.capitalize, equals('🎵song'));
      expect('🎧 cool music'.toTitleCase, equals('🎧 Cool Music'));
      expect('👨‍👩‍👧‍👦 family'.toTitleCase, equals('👨‍👩‍👧‍👦 Family'));

      // 6. RTL scripts (Persian & Arabic)
      expect('موسیقی آرامش بخش'.toTitleCase, equals('موسیقی آرامش بخش'));
      expect('فارسی'.capitalize, equals('فارسی'));

      // 7. Accented & non-English Latin
      expect('élégant'.capitalize, equals('Élégant'));
      expect('über alles'.toTitleCase, equals('Über Alles'));

      // 8. Numbers and symbols at start of words
      expect('123abc'.capitalize, equals('123abc'));
      expect('#rock !jazz &ambient'.toTitleCase, equals('#rock !jazz &ambient'));
    });

    test('path operations across Windows, POSIX, and adversarial filenames', () {
      // 1. Windows path
      const winPath = r'C:\Users\Nexa\Music\Beethoven - Symphony 9.flac';
      expect(winPath.fileExtension, equals('flac'));
      expect(winPath.fileNameWithoutExtension, equals('Beethoven - Symphony 9'));
      expect(winPath.isValidAudioExtension, isTrue);

      // 2. POSIX path
      const posixPath = '/sdcard/Music/Electronic/Daft Punk/One More Time.MP3';
      expect(posixPath.fileExtension, equals('mp3'));
      expect(posixPath.fileNameWithoutExtension, equals('One More Time'));
      expect(posixPath.isValidAudioExtension, isTrue);

      // 3. File without directory
      expect('standalone.wav'.fileExtension, equals('wav'));
      expect('standalone.wav'.fileNameWithoutExtension, equals('standalone'));

      // 4. Multiple dots in filename
      const multiDot = '/music/artist.name - album.title (2024.remaster).m4a';
      expect(multiDot.fileExtension, equals('m4a'));
      expect(multiDot.fileNameWithoutExtension, equals('artist.name - album.title (2024.remaster)'));

      // 5. File without extension
      expect('/storage/music/README'.fileExtension, equals(''));
      expect('/storage/music/README'.fileNameWithoutExtension, equals('README'));
      expect('/storage/music/README'.isValidAudioExtension, isFalse);

      // 6. Hidden files (leading dot)
      expect('/music/.nomedia'.fileExtension, equals('nomedia'));
      expect('/music/.hidden_track'.fileNameWithoutExtension, equals('.hidden_track'));

      // 7. Trailing dot
      expect('track.'.fileExtension, equals(''));
      expect('track.'.fileNameWithoutExtension, equals('track'));

      // 8. Empty string
      expect(''.fileExtension, equals(''));
      expect(''.fileNameWithoutExtension, equals(''));

      // 9. Root separators only
      expect('/'.fileExtension, equals(''));
      expect('/'.fileNameWithoutExtension, equals(''));
      expect(r'\'.fileNameWithoutExtension, equals(''));
    });

    test('audio format validation strictly recognizes all 10 supported formats and rejects impostors', () {
      for (final ext in AppConstants.supportedAudioExtensions) {
        expect('test_audio.$ext'.isValidAudioExtension, isTrue, reason: 'Failed for supported ext: $ext');
        expect('test_audio.${ext.toUpperCase()}'.isValidAudioExtension, isTrue, reason: 'Failed uppercase: $ext');
      }

      // Rejects non-audio formats
      final rejected = ['mp4', 'mkv', 'avi', 'mov', 'pdf', 'txt', 'exe', 'apk', 'zip', 'tar', 'iso', 'dart'];
      for (final bad in rejected) {
        expect('file.$bad'.isValidAudioExtension, isFalse, reason: 'Incorrectly allowed: $bad');
      }
    });

    test('ifBlank handles empty, all-whitespace, Unicode whitespace, and populated strings', () {
      expect(''.ifBlank('Fallback'), equals('Fallback'));
      expect('   '.ifBlank('Fallback'), equals('Fallback'));
      expect('\t\n\r  '.ifBlank('Fallback'), equals('Fallback'));
      expect('\u00A0\u2003'.ifBlank('Fallback'), equals('Fallback')); // NBSP and EM space
      expect('NEXA'.ifBlank('Fallback'), equals('NEXA'));
      expect('  Valid Track  '.ifBlank('Fallback'), equals('  Valid Track  '));
    });

    test('truncate and truncateWithEllipsis edge cases, small limits, and long strings', () {
      const text = 'NEXA Player High Resolution Audio';

      // Shorter or equal to limit
      expect(text.truncate(100), equals(text));
      expect(text.truncate(text.length), equals(text));

      // Standard truncation with ellipsis
      expect(text.truncate(15), equals('NEXA Player ...'));
      expect(text.truncate(15).length, equals(15));

      // Limit equal to ellipsis length (3)
      expect(text.truncate(3), equals('NEX'));

      // Limit smaller than ellipsis length (2 and 1)
      expect(text.truncate(2), equals('NE'));
      expect(text.truncate(1), equals('N'));
      expect(text.truncate(0), equals(''));

      // Custom ellipsis with exact maxLength verification
      expect(text.truncate(10, ellipsis: ' [..]'), equals('NEXA  [..]'));
      expect(text.truncate(10, ellipsis: ' [..]').length, equals(10));

      // Negative maxLength produces RangeError due to substring(0, negative)
      expect(() => text.truncate(-1), throwsA(isA<RangeError>()));
      expect(() => text.truncate(-10), throwsA(isA<RangeError>()));

      // 10,000 character string
      final huge = 'Z' * 10000;
      final truncatedHuge = huge.truncate(20);
      expect(truncatedHuge.length, equals(20));
      expect(truncatedHuge, equals('${'Z' * 17}...'));
    });

    test('toColorOrNull parses valid formats and safely rejects malformed inputs without throwing', () {
      // 6-digit hex with and without hash
      expect('#FF0000'.toColorOrNull(), equals(const Color(0xFFFF0000)));
      expect('FF0000'.toColorOrNull(), equals(const Color(0xFFFF0000)));
      expect('#00FF00'.toColorOrNull(), equals(const Color(0xFF00FF00)));
      expect('#0000FF'.toColorOrNull(), equals(const Color(0xFF0000FF)));

      // 8-digit hex with alpha
      expect('#80FF0000'.toColorOrNull(), equals(const Color(0x80FF0000)));
      expect('80FF0000'.toColorOrNull(), equals(const Color(0x80FF0000)));
      expect('#00000000'.toColorOrNull(), equals(const Color(0x00000000))); // Transparent
      expect('#FFFFFFFF'.toColorOrNull(), equals(const Color(0xFFFFFFFF))); // Full white

      // Case insensitivity
      expect('#abcdef'.toColorOrNull(), equals(const Color(0xFFABCDEF)));
      expect('12ab34cd'.toColorOrNull(), equals(const Color(0x12AB34CD)));

      // Leading/trailing whitespace
      expect('  #FF5722  '.toColorOrNull(), equals(const Color(0xFFFF5722)));

      // Malformed inputs returning null safely
      expect(''.toColorOrNull(), isNull);
      expect('#'.toColorOrNull(), isNull);
      expect('123'.toColorOrNull(), isNull);
      expect('#12345'.toColorOrNull(), isNull);
      expect('#1234567'.toColorOrNull(), isNull);
      expect('#123456789'.toColorOrNull(), isNull);
      expect('GGGGGG'.toColorOrNull(), isNull);
      expect('blue'.toColorOrNull(), isNull);
      expect(('F' * 10000).toColorOrNull(), isNull);
    });

    test('NullableStringX handles null, empty, and non-empty variants', () {
      const String? nullString = null;
      const emptyString = '';
      const filledString = 'valid';

      expect(nullString.isNullOrEmpty, isTrue);
      expect(emptyString.isNullOrEmpty, isTrue);
      expect(filledString.isNullOrEmpty, isFalse);

      expect(nullString.isNotNullOrEmpty, isFalse);
      expect(emptyString.isNotNullOrEmpty, isFalse);
      expect(filledString.isNotNullOrEmpty, isTrue);
    });
  });

  // ===========================================================================
  // ATTACK SURFACE 4: BuildContextX Unbounded Dimensions & Breakpoint Boundaries
  // ===========================================================================
  group('Adversarial Challenge: BuildContextX Unbounded Layouts & Edge Boundaries', () {
    testWidgets('breakpoint boundary precision at 599.9, 600.0, 840.0, and 840.1 dp', (tester) async {
      // Helper to pump size and query breakpoints
      Future<Map<String, bool>> checkBreakpointsForWidth(double width) async {
        tester.setDisplaySize(Size(width, 1000));
        late bool isPhone;
        late bool isTablet;
        late bool isDesktop;
        late bool isWideScreen;

        await tester.pumpApp(
          Builder(builder: (context) {
            isPhone = context.isPhone;
            isTablet = context.isTablet;
            isDesktop = context.isDesktop;
            isWideScreen = context.isWideScreen;
            return const SizedBox();
          }),
        );

        return {
          'isPhone': isPhone,
          'isTablet': isTablet,
          'isDesktop': isDesktop,
          'isWideScreen': isWideScreen,
        };
      }

      // 1. Just below phone breakpoint: 599.9 dp
      final r599 = await checkBreakpointsForWidth(599.9);
      expect(r599['isPhone'], isTrue);
      expect(r599['isTablet'], isFalse);
      expect(r599['isDesktop'], isFalse);
      expect(r599['isWideScreen'], isFalse);

      // 2. Exact phone breakpoint boundary: 600.0 dp (becomes Tablet & WideScreen)
      final r600 = await checkBreakpointsForWidth(600.0);
      expect(r600['isPhone'], isFalse);
      expect(r600['isTablet'], isTrue);
      expect(r600['isDesktop'], isFalse);
      expect(r600['isWideScreen'], isTrue);

      // 3. Exact tablet upper boundary: 840.0 dp (still Tablet & WideScreen)
      final r840 = await checkBreakpointsForWidth(840.0);
      expect(r840['isPhone'], isFalse);
      expect(r840['isTablet'], isTrue);
      expect(r840['isDesktop'], isFalse);
      expect(r840['isWideScreen'], isTrue);

      // 4. Just above tablet boundary: 840.1 dp (becomes Desktop)
      final r8401 = await checkBreakpointsForWidth(840.1);
      expect(r8401['isPhone'], isFalse);
      expect(r8401['isTablet'], isFalse);
      expect(r8401['isDesktop'], isTrue);
      expect(r8401['isWideScreen'], isTrue);
    });

    testWidgets('unbounded and zero viewport queries execute safely', (tester) async {
      // 1. Extreme large display (e.g. 8K monitor: 7680x4320)
      tester.setDisplaySize(const Size(7680, 4320));
      await tester.pumpApp(
        Builder(builder: (context) {
          expect(context.screenWidth, equals(7680.0));
          expect(context.screenHeight, equals(4320.0));
          expect(context.isDesktop, isTrue);
          expect(context.isWideScreen, isTrue);
          expect(context.isLandscape, isTrue);
          expect(context.isPortrait, isFalse);
          return const SizedBox();
        }),
      );

      // 2. Very narrow smart watch viewport (200x200)
      tester.setDisplaySize(const Size(200, 200));
      await tester.pumpApp(
        Builder(builder: (context) {
          expect(context.screenWidth, equals(200.0));
          expect(context.screenHeight, equals(200.0));
          expect(context.isPhone, isTrue);
          expect(context.isWideScreen, isFalse);
          return const SizedBox();
        }),
      );
    });

    testWidgets('feedback and focus helpers execute cleanly without unhandled crashes', (tester) async {
      final textController = TextEditingController();
      final focusNode = FocusNode();

      await tester.pumpApp(
        Scaffold(
          body: Builder(builder: (context) {
            return Column(
              children: [
                TextField(
                  controller: textController,
                  focusNode: focusNode,
                ),
                ElevatedButton(
                  onPressed: () {
                    context.showSnackBar(const SnackBar(content: Text('Test SnackBar')));
                  },
                  child: const Text('Show'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.hideCurrentSnackBar();
                  },
                  child: const Text('Hide'),
                ),
                ElevatedButton(
                  onPressed: () {
                    context.unfocus();
                  },
                  child: const Text('Unfocus'),
                ),
              ],
            );
          }),
        ),
      );

      // Verify focus management
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      // Tap Unfocus
      await tester.tap(find.text('Unfocus'));
      await tester.pump();
      expect(focusNode.hasFocus, isFalse);

      // Verify SnackBar show and hide
      await tester.tap(find.text('Show'));
      await tester.pump(); // Start animation
      expect(find.text('Test SnackBar'), findsOneWidget);

      await tester.tap(find.text('Hide'));
      await tester.pump(); // Trigger hide
      await tester.pump(const Duration(milliseconds: 500)); // Finish hide
      expect(find.text('Test SnackBar'), findsNothing);
    });
  });

  // ===========================================================================
  // ATTACK SURFACE 5: AppConstants & StorageKeys Immutability & Namespace Integrity
  // ===========================================================================
  group('Adversarial Challenge: Constants & StorageKeys Integrity', () {
    test('all StorageKeys are unique, non-empty, and prefixed with nexa_', () {
      final keys = [
        StorageKeys.themePreset,
        StorageKeys.themeMode,
        StorageKeys.customPrimaryColor,
        StorageKeys.customSurfaceColor,
        StorageKeys.customBackgroundColor,
        StorageKeys.glassBlurIntensity,
        StorageKeys.glassOpacityIntensity,
        StorageKeys.volume,
        StorageKeys.isMuted,
        StorageKeys.repeatMode,
        StorageKeys.shuffleEnabled,
        StorageKeys.lastTrackId,
        StorageKeys.lastPositionMs,
        StorageKeys.equalizerEnabled,
        StorageKeys.equalizerPreset,
        StorageKeys.bassBoost,
        StorageKeys.virtualizer,
        StorageKeys.crossfadeDurationMs,
        StorageKeys.onboardingCompleted,
        StorageKeys.libraryScanFolders,
        StorageKeys.lastScanTimestamp,
        StorageKeys.sortOrder,
        StorageKeys.sortAscending,
      ];

      // 1. All keys must be unique (no duplicates or collisions)
      final uniqueSet = keys.toSet();
      expect(uniqueSet.length, equals(keys.length), reason: 'Duplicate storage key detected!');

      // 2. All keys must start with nexa_ prefix
      for (final key in keys) {
        expect(key.startsWith('nexa_'), isTrue, reason: 'Key does not have nexa_ prefix: $key');
        expect(key, matches(r'^[a-z0-9_]+$'), reason: 'Key contains illegal characters: $key');
      }
    });

    test('AppConstants values adhere to design tokens and mathematical invariants', () {
      // Breakpoints
      expect(AppConstants.phoneBreakpoint, lessThan(AppConstants.tabletBreakpoint));

      // Glassmorphism tokens
      expect(AppConstants.minGlassBlur, lessThanOrEqualTo(AppConstants.defaultGlassBlur));
      expect(AppConstants.defaultGlassBlur, lessThanOrEqualTo(AppConstants.maxGlassBlur));
      expect(AppConstants.minGlassOpacity, lessThanOrEqualTo(AppConstants.defaultGlassOpacity));
      expect(AppConstants.defaultGlassOpacity, lessThanOrEqualTo(AppConstants.maxGlassOpacity));
      expect(AppConstants.glassBorderWidth, greaterThan(0));

      // Spacing scale is strictly monotonically increasing
      final spacings = [
        AppConstants.spaceXxs,
        AppConstants.spaceXs,
        AppConstants.spaceSm,
        AppConstants.spaceMd,
        AppConstants.spaceLg,
        AppConstants.spaceXl,
        AppConstants.spaceXxl,
        AppConstants.space3xl,
      ];
      for (int i = 0; i < spacings.length - 1; i++) {
        expect(spacings[i], lessThan(spacings[i + 1]), reason: 'Spacing scale inversion at step $i');
      }

      // Corner radii scale is strictly monotonically increasing
      final radii = [
        AppConstants.radiusXs,
        AppConstants.radiusSm,
        AppConstants.radiusMd,
        AppConstants.radiusLg,
        AppConstants.radiusXl,
        AppConstants.radiusFull,
      ];
      for (int i = 0; i < radii.length - 1; i++) {
        expect(radii[i], lessThan(radii[i + 1]), reason: 'Radius scale inversion at step $i');
      }

      // Animation durations are ordered
      expect(AppConstants.animFast, lessThan(AppConstants.animNormal));
      expect(AppConstants.animNormal, lessThan(AppConstants.animSlow));

      // Seek step constraints
      expect(AppConstants.minSeekStep, lessThanOrEqualTo(AppConstants.defaultSeekStep));
      expect(AppConstants.defaultSeekStep, lessThanOrEqualTo(AppConstants.maxSeekStep));

      // Audio extensions are non-empty and all lowercase without dots
      expect(AppConstants.supportedAudioExtensions, isNotEmpty);
      for (final ext in AppConstants.supportedAudioExtensions) {
        expect(ext.contains('.'), isFalse, reason: 'Extension contains dot: $ext');
        expect(ext, equals(ext.toLowerCase()), reason: 'Extension not lowercase: $ext');
      }
    });
  });

  // ===========================================================================
  // ATTACK SURFACE 6: IEEE-754 Special Values, Layout Constraints & Microsecond Extremes
  // ===========================================================================
  group('Adversarial Challenge: IEEE-754 & Layout Stress', () {
    test('IEEE-754 special values (NaN, Infinity, -Infinity) behavior documented empirically', () {
      // -Infinity is <= 0 so returns '0 B'
      expect(double.negativeInfinity.toFileSize(), equals('0 B'));
      expect(double.negativeInfinity.toBitrateString(), equals('0 kbps'));
      expect(double.negativeInfinity.toSampleRateString(), equals('0 kHz'));

      // NaN and +Infinity throw UnsupportedError when trying to floor/round
      expect(() => double.nan.toFileSize(), throwsA(isA<UnsupportedError>()));
      expect(() => double.infinity.toFileSize(), throwsA(isA<UnsupportedError>()));
      expect(() => double.nan.toBitrateString(), throwsA(isA<UnsupportedError>()));
      expect(() => double.infinity.toBitrateString(), throwsA(isA<UnsupportedError>()));
    });

    test('int64 extreme duration limits do not cause arithmetic crashes', () {
      // Max 64-bit microsecond duration: ~292,277 years
      const maxDuration = Duration(microseconds: 9223372036854775000);
      expect(maxDuration.toHoursMinutesSeconds(), isNotEmpty);
      expect(maxDuration.formatAdaptive(), isNotEmpty);

      // Negative max 64-bit microsecond duration
      const minDuration = Duration(microseconds: -9223372036854775000);
      expect(minDuration.toHoursMinutesSeconds(), startsWith('-'));
      expect(minDuration.formatAdaptive(), startsWith('-'));
    });

    test('directory containing dot edge case in fileExtension behavior', () {
      // Path where folder has a dot but file has no extension
      const folderWithDot = '/storage/emulated/0/My.Music/track';
      expect(folderWithDot.fileExtension, equals('music/track'));
      // Audio validation safely rejects it
      expect(folderWithDot.isValidAudioExtension, isFalse);
      // fileNameWithoutExtension correctly ignores directory dots
      expect(folderWithDot.fileNameWithoutExtension, equals('track'));
    });

    testWidgets('zero and positive spacing widgets layout cleanly in Flutter tree', (tester) async {
      await tester.pumpApp(
        Column(
          children: [
            const Text('Header'),
            0.verticalSpace,
            16.verticalSpace,
            Row(
              children: [
                const Text('Left'),
                0.horizontalSpace,
                24.horizontalSpace,
                const Text('Right'),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Header'), findsOneWidget);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });
  });
}

