import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_band.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/eq_band_slider.dart';

void main() {
  testWidgets(
    'EqBandSlider increases gain when dragged up and decreases when dragged down in RTL mode',
    (tester) async {
      double latestGain = 0.0;
      const band = EqualizerBand(
        index: 0,
        centerFrequency: 1000,
        gain: 0.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  height: 220,
                  width: 60,
                  child: EqBandSlider(
                    band: band,
                    isEnabled: true,
                    onGainChanged: (val) => latestGain = val,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sliderFinder = find.byType(Slider);
      expect(sliderFinder, findsOneWidget);

      // Dragging UPWARD should increase gain (> 0 dB) even in RTL
      await tester.drag(sliderFinder, const Offset(0, -50));
      await tester.pump();
      expect(latestGain, greaterThan(0.0));

      // Dragging DOWNWARD should decrease gain (< 0 dB) even in RTL
      await tester.drag(sliderFinder, const Offset(0, 50));
      await tester.pump();
      expect(latestGain, lessThan(0.0));
    },
  );
}
