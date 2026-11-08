import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';

void main() {
  group('SleepTimerServiceImpl Tests', () {
    testWidgets('starts countdown, emits decrements, and triggers onCompleted', (tester) async {
      bool completed = false;
      double lastVolumeMultiplier = 1.0;

      final timer = SleepTimerServiceImpl(
        onVolumeFade: (vol) => lastVolumeMultiplier = vol,
      );

      expect(timer.isActive, isFalse);
      expect(timer.remainingTime, isNull);

      timer.start(
        const Duration(seconds: 5),
        fadeOut: true,
        onCompleted: () => completed = true,
      );

      expect(timer.isActive, isTrue);
      expect(timer.remainingTime, const Duration(seconds: 5));

      // Advance 2 seconds
      await tester.pump(const Duration(seconds: 2));
      expect(timer.remainingTime, const Duration(seconds: 3));
      expect(completed, isFalse);

      // Advance 3 more seconds to finish
      await tester.pump(const Duration(seconds: 3));
      expect(completed, isTrue);
      expect(timer.isActive, isFalse);
      expect(timer.remainingTime, isNull);
      expect(lastVolumeMultiplier, 1.0); // Restored upon completion

      timer.dispose();
    });

    testWidgets('cancel aborts active timer and restores volume', (tester) async {
      bool completed = false;
      double volume = 1.0;

      final timer = SleepTimerServiceImpl(
        onVolumeFade: (vol) => volume = vol,
      );

      timer.start(
        const Duration(minutes: 15),
        onCompleted: () => completed = true,
      );

      await tester.pump(const Duration(minutes: 5));
      expect(timer.isActive, isTrue);

      timer.cancel();
      expect(timer.isActive, isFalse);
      expect(timer.remainingTime, isNull);
      expect(volume, 1.0);

      await tester.pump(const Duration(minutes: 15));
      expect(completed, isFalse);

      timer.dispose();
    });

    testWidgets('volume fade ducks gradually during final 30 seconds', (tester) async {
      final volumeLevels = <double>[];

      final timer = SleepTimerServiceImpl(
        onVolumeFade: (vol) => volumeLevels.add(vol),
      );

      timer.start(
        const Duration(seconds: 35),
        fadeOut: true,
      );

      // Advance 5 seconds to enter the 30-second window
      await tester.pump(const Duration(seconds: 5));
      expect(timer.remainingTime, const Duration(seconds: 30));

      // Advance 10 seconds into the fade window
      await tester.pump(const Duration(seconds: 10));
      expect(timer.remainingTime, const Duration(seconds: 20));

      // At 20s remaining, volume multiplier should be ~20/30 = 0.666
      expect(volumeLevels.isNotEmpty, isTrue);
      expect(volumeLevels.last, closeTo(0.66, 0.05));

      timer.dispose();
    });
  });
}
