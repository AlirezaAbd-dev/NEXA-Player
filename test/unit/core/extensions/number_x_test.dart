import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/extensions/number_x.dart';

void main() {
  group('NumberX Extension', () {
    test('toFileSize formats byte quantities with correct SI unit', () {
      expect(0.toFileSize(), '0 B');
      expect((-10).toFileSize(), '0 B');
      expect(512.toFileSize(), '512 B');
      expect(1024.toFileSize(), '1.0 KB');
      expect((1024 * 1024).toFileSize(), '1.0 MB');
      expect((15.5 * 1024 * 1024).toFileSize(), '15.5 MB');
      expect((2.2 * 1024 * 1024 * 1024).toFileSize(), '2.2 GB');
    });

    test('toBitrateString formats audio bitrates correctly', () {
      expect(0.toBitrateString(), '0 kbps');
      expect(320.toBitrateString(), '320 kbps');
      expect(320000.toBitrateString(), '320 kbps');
      expect(1411200.toBitrateString(), '1411 kbps');
    });

    test('toSampleRateString formats sample rate in kHz', () {
      expect(0.toSampleRateString(), '0 kHz');
      expect(44100.toSampleRateString(), '44.1 kHz');
      expect(96000.toSampleRateString(), '96.0 kHz');
      expect(192000.toSampleRateString(decimals: 0), '192 kHz');
    });

    test('formatCount formats singular and plural items', () {
      expect(1.formatCount('track'), '1 track');
      expect(5.formatCount('track'), '5 tracks');
      expect(0.formatCount('track'), '0 tracks');
      expect(2.formatCount('category', 'categories'), '2 categories');
    });

    test('toCompact formats compact numbers', () {
      expect(950.toCompact(), '950');
      expect(1500.toCompact(), '1.5K');
      expect(25000.toCompact(), '25.0K');
      expect(1200000.toCompact(), '1.2M');
    });

    test('toPercentageString formats percentage strings', () {
      expect(0.0.toPercentageString(), '0%');
      expect(0.75.toPercentageString(), '75%');
      expect(1.0.toPercentageString(), '100%');
      expect(0.333.toPercentageString(decimals: 1), '33.3%');
    });

    test('verticalSpace and horizontalSpace return sized boxes', () {
      final vSpace = 16.verticalSpace;
      expect(vSpace, isA<SizedBox>());
      expect((vSpace as SizedBox).height, 16.0);

      final hSpace = 24.horizontalSpace;
      expect(hSpace, isA<SizedBox>());
      expect((hSpace as SizedBox).width, 24.0);
    });
  });
}
