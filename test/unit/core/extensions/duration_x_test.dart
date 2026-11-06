import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';

void main() {
  group('DurationX Extension', () {
    test('toMinutesSeconds formats standard track durations correctly', () {
      expect(Duration.zero.toMinutesSeconds(), '00:00');
      expect(const Duration(seconds: 5).toMinutesSeconds(), '00:05');
      expect(const Duration(minutes: 3, seconds: 42).toMinutesSeconds(), '03:42');
      expect(const Duration(minutes: 62, seconds: 5).toMinutesSeconds(), '62:05');
    });

    test('toMinutesSeconds handles unpadded minutes option', () {
      expect(const Duration(minutes: 3, seconds: 42).toMinutesSeconds(padMinutes: false), '3:42');
      expect(const Duration(seconds: 42).toMinutesSeconds(padMinutes: false), '0:42');
    });

    test('toMinutesSeconds preserves negative sign for remaining playback time', () {
      expect(const Duration(seconds: -15).toMinutesSeconds(), '-00:15');
      expect(const Duration(minutes: -3, seconds: -42).toMinutesSeconds(), '-03:42');
    });

    test('toHoursMinutesSeconds formats long audio durations', () {
      expect(Duration.zero.toHoursMinutesSeconds(), '00:00:00');
      expect(const Duration(hours: 1, minutes: 23, seconds: 45).toHoursMinutesSeconds(), '01:23:45');
      expect(const Duration(hours: -2, minutes: -10).toHoursMinutesSeconds(), '-02:10:00');
    });

    test('formatAdaptive dynamically adapts to presence of hours', () {
      expect(const Duration(minutes: 3, seconds: 42).formatAdaptive(), '03:42');
      expect(const Duration(hours: 1, minutes: 2, seconds: 3).formatAdaptive(), '1:02:03');
      expect(const Duration(hours: 1, minutes: 2, seconds: 3).formatAdaptive(padHours: true), '01:02:03');
      expect(const Duration(hours: -1, minutes: -5).formatAdaptive(), '-1:05:00');
    });

    test('convenience getters return expected string representations', () {
      const dur = Duration(minutes: 4, seconds: 12);
      expect(dur.formatted, '04:12');
      expect(dur.mmSs, '04:12');
      expect(dur.hhMmSs, '00:04:12');
    });
  });
}
