import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/presentation/widgets/waveform_visualizer.dart';

void main() {
  group('WaveformVisualizer Widget Tests', () {
    testWidgets('renders waveform custom painter and formatted timestamps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: WaveformVisualizer(
              position: Duration(minutes: 1, seconds: 15),
              duration: Duration(minutes: 3, seconds: 45),
              isPlaying: false,
              barCount: 40,
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('1:15'), findsOneWidget);
      expect(find.text('3:45'), findsOneWidget);
    });

    testWidgets('tapping on waveform calculates ratio and calls onSeek', (tester) async {
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: WaveformVisualizer(
                  position: Duration.zero,
                  duration: const Duration(seconds: 100),
                  onSeek: (pos) => seekedDuration = pos,
                ),
              ),
            ),
          ),
        ),
      );

      // Tap in the middle of the waveform (should be ~50 seconds)
      final center = tester.getCenter(find.byType(WaveformVisualizer));
      await tester.tapAt(center);
      await tester.pump();

      expect(seekedDuration, isNotNull);
      expect(seekedDuration!.inSeconds, closeTo(50, 5));
    });

    testWidgets('horizontal dragging on waveform triggers onSeek on drag end', (tester) async {
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                child: WaveformVisualizer(
                  position: Duration.zero,
                  duration: const Duration(seconds: 200),
                  onSeek: (pos) => seekedDuration = pos,
                ),
              ),
            ),
          ),
        ),
      );

      final waveformFinder = find.byType(WaveformVisualizer);
      await tester.drag(waveformFinder, const Offset(60, 0));
      await tester.pump();

      expect(seekedDuration, isNotNull);
    });
  });
}
