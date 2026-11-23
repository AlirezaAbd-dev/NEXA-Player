import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/features/equalizer/presentation/widgets/tactile_rotary_knob.dart';
import 'package:nexa_player/features/lyrics/domain/models/synced_lyrics.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/synced_lyrics_view.dart';
import 'package:nexa_player/features/player/presentation/widgets/gearshift_waveform_scrubber.dart';

void main() {
  group('WCAG AA Global Accessibility & Ergonomics Tests', () {
    testWidgets('GearshiftWaveformScrubber exposes slider semantics with 10s step actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [NexaSurfaceTokens.midnightBlack],
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: GearshiftWaveformScrubber(
                  position: const Duration(seconds: 75),
                  duration: const Duration(seconds: 225),
                  isPlaying: true,
                  onSeek: (d) => seekedDuration = d,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find semantic node for waveform scrubber
      final scrubberFinder = find.bySemanticsLabel('Waveform scrubber');
      expect(scrubberFinder, findsOneWidget);

      final SemanticsNode node = tester.getSemantics(scrubberFinder);
      expect(node.hasFlag(SemanticsFlag.isSlider), isTrue);
      expect(node.value, equals('01:15 of 03:45'));

      // Perform semantic increase action (+10s)
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(seekedDuration?.inSeconds, equals(85));

      // Perform semantic decrease action (-10s)
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      expect(seekedDuration?.inSeconds, equals(65));

      handle.dispose();
    });

    testWidgets('TactileRotaryKnob exposes slider semantics with 5% step actions',
        (tester) async {
      final handle = tester.ensureSemantics();
      double? updatedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [NexaSurfaceTokens.midnightBlack],
          ),
          home: Scaffold(
            body: Center(
              child: TactileRotaryKnob(
                label: 'Bass Boost',
                value: 0.40,
                onChanged: (v) => updatedValue = v,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final knobFinder = find.bySemanticsLabel('Bass Boost');
      expect(knobFinder, findsOneWidget);

      final SemanticsNode node = tester.getSemantics(knobFinder);
      expect(node.hasFlag(SemanticsFlag.isSlider), isTrue);
      expect(node.value, equals('40%'));

      // Perform semantic increase action (+5%)
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      expect(updatedValue, closeTo(0.45, 0.001));

      // Perform semantic decrease action (-5%)
      tester.binding.pipelineOwner.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      expect(updatedValue, closeTo(0.35, 0.001));

      handle.dispose();
    });

    testWidgets('SyncedLyricsView disables optical blur under reduced-motion preference',
        (tester) async {
      const lyrics = SyncedLyrics(
        isSynced: true,
        lines: [
          LyricLine(timestampMs: 0, text: 'First verse line'),
          LyricLine(timestampMs: 5000, text: 'Active verse line'),
          LyricLine(timestampMs: 10000, text: 'Third verse line'),
        ],
      );

      // Normal motion: Inactive lines have ImageFiltered blur
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: false),
            child: Scaffold(
              body: SyncedLyricsView(
                lyrics: lyrics,
                activeIndex: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // ImageFiltered should exist on inactive lines
      expect(find.byType(ImageFiltered), findsWidgets);

      // Reduced motion: optical blur is completely disabled
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: SyncedLyricsView(
                lyrics: lyrics,
                activeIndex: 1,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Zero ImageFiltered blur widgets under reduced motion
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('Rotary knobs and touch controls provide >= 48x48dp interaction size',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: [NexaSurfaceTokens.midnightBlack],
          ),
          home: Scaffold(
            body: Center(
              child: TactileRotaryKnob(
                label: 'Virtualizer',
                value: 0.5,
                size: 80.0,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final knobBox = tester.getRect(find.byType(CustomPaint));
      expect(knobBox.width, greaterThanOrEqualTo(48.0));
      expect(knobBox.height, greaterThanOrEqualTo(48.0));
    });
  });
}
