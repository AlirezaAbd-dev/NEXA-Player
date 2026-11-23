import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/widgets/branding/nexa_animated_logo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NexaAnimatedLogo Sizing & Rendering Tests', () {
    for (final size in [24.0, 48.0, 96.0, 200.0]) {
      testWidgets('Renders cleanly at ${size}dp with zero layout overflow',
          (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: NexaAnimatedLogo(
                  size: size,
                  mode: NexaLogoAnimationMode.static,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(NexaAnimatedLogo), findsOneWidget);

        final renderBox =
            tester.renderObject<RenderBox>(find.byType(NexaAnimatedLogo));
        expect(renderBox.size.width, equals(size));
        expect(renderBox.size.height, equals(size));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Renders monochrome mode with colorOverride cleanly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NexaAnimatedLogo(
                size: 64.0,
                mode: NexaLogoAnimationMode.static,
                colorOverride: Colors.white,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NexaAnimatedLogo), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Has correct Semantics image and label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NexaAnimatedLogo(
                size: 48.0,
                semanticLabel: 'Test NEXA Logo',
              ),
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('Test NEXA Logo'),
        findsOneWidget,
      );
    });
  });

  group('NexaAnimatedLogo Animation Mode Lifecycles', () {
    testWidgets('splash mode runs to completion (850ms) and stops ticking',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NexaAnimatedLogo(
                size: 88.0,
                mode: NexaLogoAnimationMode.splash,
              ),
            ),
          ),
        ),
      );

      // Verify widget initial state
      expect(find.byType(NexaAnimatedLogo), findsOneWidget);

      // Advance by 400ms (midpoint)
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);

      // Advance past 850ms completion
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify ticker is stopped: pumping without elapsed time returns 0 frames scheduled
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('playing mode pauses ticker when isPlaying is false',
        (tester) async {
      var isPlaying = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    NexaAnimatedLogo(
                      size: 72.0,
                      mode: NexaLogoAnimationMode.playing,
                      isPlaying: isPlaying,
                    ),
                    GestureDetector(
                      onTap: () => setState(() => isPlaying = !isPlaying),
                      child: const Text('Toggle Play'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      // Playing mode ticks while isPlaying == true
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);

      // Toggle to false
      await tester.tap(find.text('Toggle Play'));
      await tester.pump();

      // Pump to ensure controller has stopped
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('MediaQuery(disableAnimations: true) forces static mode',
        (tester) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: NexaAnimatedLogo(
                  size: 72.0,
                  mode: NexaLogoAnimationMode.splash,
                ),
              ),
            ),
          ),
        ),
      );

      // Immediate static render, no ticker ticking
      await tester.pump();
      expect(tester.binding.hasScheduledFrame, isFalse);
      expect(tester.takeException(), isNull);
    });
  });

  group('Approved SVG Assets Verification', () {
    final assetPaths = [
      'assets/branding/nexa_logo_full.svg',
      'assets/branding/nexa_logo_foreground.svg',
      'assets/branding/nexa_logo_mono.svg',
    ];

    for (final path in assetPaths) {
      test('SVG file $path exists and is valid XML', () {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path should exist on disk');

        final content = file.readAsStringSync();
        expect(content, contains('<svg'));
        expect(content, contains('viewBox="0 0 512 512"'));
        expect(content, contains('</svg>'));
      });

      testWidgets('SVG file $path parses cleanly in SvgPicture.string',
          (tester) async {
        final file = File(path);
        final content = file.readAsStringSync();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SvgPicture.string(
                  content,
                  width: 128,
                  height: 128,
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
