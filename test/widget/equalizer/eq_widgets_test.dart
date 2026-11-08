import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_band.dart';
import 'package:nexa_player/features/equalizer/domain/entities/equalizer_preset.dart';
import 'package:nexa_player/features/equalizer/domain/entities/reverb_preset.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/dsp_knob_slider.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/eq_band_slider.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/eq_curve_painter.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/preset_selector_modal.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/reverb_selector.dart';

void main() {
  group('EqCurvePainter Widget Tests', () {
    testWidgets('paints without error on canvas in both active and disabled modes', (tester) async {
      final bands = List.generate(
        10,
        (i) => EqualizerBand(index: i, centerFrequency: 100 * (i + 1), gain: (i - 5).toDouble()),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 200),
              painter: EqCurvePainter(
                bands: bands,
                preamp: 2.0,
                isEnabled: true,
                accentColor: Colors.deepPurpleAccent,
                gridColor: Colors.white,
                textColor: Colors.white,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is EqCurvePainter),
        findsOneWidget,
      );

      // Now disabled mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomPaint(
              size: const Size(400, 200),
              painter: EqCurvePainter(
                bands: bands,
                preamp: 0.0,
                isEnabled: false,
                accentColor: Colors.deepPurpleAccent,
                gridColor: Colors.white,
                textColor: Colors.white,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is EqCurvePainter),
        findsOneWidget,
      );
    });
  });

  group('EqBandSlider Widget Tests', () {
    testWidgets('renders labels and responds to gain adjustments when enabled', (tester) async {
      double changedGain = 0.0;
      const band = EqualizerBand(index: 0, centerFrequency: 62, gain: 3.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 60,
              child: EqBandSlider(
                band: band,
                isEnabled: true,
                onGainChanged: (val) => changedGain = val,
              ),
            ),
          ),
        ),
      );

      expect(find.text('+3.5'), findsOneWidget);
      expect(find.text('62'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Drag the slider
      await tester.drag(find.byType(Slider), const Offset(0, -30));
      await tester.pumpAndSettle();
      expect(changedGain, isNot(0.0));
    });

    testWidgets('disables slider interactions when isEnabled is false', (tester) async {
      const band = EqualizerBand(index: 1, centerFrequency: 125, gain: 0.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 60,
              child: EqBandSlider(
                band: band,
                isEnabled: false,
                onGainChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('0.0'), findsOneWidget);
      expect(find.text('125'), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.onChanged, isNull);
    });
  });

  group('DspKnobSlider Widget Tests', () {
    testWidgets('renders title, percentage badge, and triggers onChanged', (tester) async {
      double updatedValue = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DspKnobSlider(
              title: 'BASS BOOST',
              subtitle: 'Sub-bass warmth',
              icon: Icons.speaker_group_rounded,
              value: 0.45,
              isEnabled: true,
              onChanged: (val) => updatedValue = val,
            ),
          ),
        ),
      );

      expect(find.text('BASS BOOST'), findsOneWidget);
      expect(find.text('Sub-bass warmth'), findsOneWidget);
      expect(find.text('45%'), findsOneWidget);

      await tester.drag(find.byType(Slider), const Offset(50, 0));
      await tester.pumpAndSettle();
      expect(updatedValue, isNot(0.0));
    });
  });

  group('ReverbSelector Widget Tests', () {
    testWidgets('renders 6 presets and selects on tap', (tester) async {
      ReverbPreset selected = ReverbPreset.none;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReverbSelector(
              selectedPreset: ReverbPreset.room,
              isEnabled: true,
              onSelected: (p) => selected = p,
            ),
          ),
        ),
      );

      expect(find.text('ACOUSTIC REVERB'), findsOneWidget);
      expect(find.text('Small Room'), findsOneWidget);
      expect(find.text('Concert Hall'), findsOneWidget);
      expect(find.text('Plate Reverb'), findsOneWidget);

      await tester.tap(find.text('Concert Hall'));
      await tester.pumpAndSettle();
      expect(selected, ReverbPreset.hall);
    });
  });

  group('PresetSelectorModal Widget Tests', () {
    testWidgets('lists factory presets and handles selection', (tester) async {
      String selectedId = '';
      const presets = [
        EqualizerPreset(id: 'flat', name: 'Flat', isBuiltIn: true, bandGains: []),
        EqualizerPreset(id: 'rock', name: 'Rock', isBuiltIn: true, bandGains: []),
        EqualizerPreset(id: 'custom_1', name: 'My Sound', isBuiltIn: false, bandGains: []),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PresetSelectorModal(
              presets: presets,
              activePresetId: 'rock',
              onSelectPreset: (id) => selectedId = id,
              onSaveCustomPreset: (_) {},
              onDeleteCustomPreset: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Sound Presets'), findsOneWidget);
      expect(find.text('Flat'), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('My Sound'), findsOneWidget);
      expect(find.text('FACTORY'), findsNWidgets(2));
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);

      await tester.tap(find.text('Flat'));
      await tester.pumpAndSettle();
      expect(selectedId, 'flat');
    });
  });
}
