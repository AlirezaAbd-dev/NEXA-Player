import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/features/library/presentation/widgets/swipeable_track_tile.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';

void main() {
  group('SwipeableTrackTile & Borderless TrackTile Widget Tests', () {
    const testTrack = Track(
      id: 'test-track-1',
      title: 'Get Lucky',
      artist: 'Daft Punk',
      album: 'Random Access Memories',
      duration: Duration(seconds: 248),
      filePath: '/music/get_lucky.flac',
    );

    testWidgets('short swipe right triggers onPlayNext', (tester) async {
      var playNextCalled = false;
      var queueEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: SwipeableTrackTile(
                onPlayNext: () => playNextCalled = true,
                onAddToQueueEnd: () => queueEndCalled = true,
                child: TrackTile.fromTrack(track: testTrack),
              ),
            ),
          ),
        ),
      );

      // Drag right by 80px (above short threshold 68, below deep threshold 148)
      await tester.drag(find.byType(TrackTile), const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(playNextCalled, isTrue);
      expect(queueEndCalled, isFalse);
    });

    testWidgets('deep swipe right triggers onAddToQueueEnd', (tester) async {
      var playNextCalled = false;
      var queueEndCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: SwipeableTrackTile(
                onPlayNext: () => playNextCalled = true,
                onAddToQueueEnd: () => queueEndCalled = true,
                child: TrackTile.fromTrack(track: testTrack),
              ),
            ),
          ),
        ),
      );

      // Drag right by 160px (above deep threshold 148)
      await tester.drag(find.byType(TrackTile), const Offset(160, 0));
      await tester.pumpAndSettle();

      expect(queueEndCalled, isTrue);
      expect(playNextCalled, isFalse);
    });

    testWidgets('swipe left triggers onSwipeLeft', (tester) async {
      var swipeLeftCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 100,
              child: SwipeableTrackTile(
                onPlayNext: () {},
                onAddToQueueEnd: () {},
                onSwipeLeft: () => swipeLeftCalled = true,
                child: TrackTile.fromTrack(track: testTrack),
              ),
            ),
          ),
        ),
      );

      // Drag left by -80px (past left threshold -68)
      await tester.drag(find.byType(TrackTile), const Offset(-80, 0));
      await tester.pumpAndSettle();

      expect(swipeLeftCalled, isTrue);
    });

    testWidgets('active playing track renders AnimatedEqualizerGlyph with zero border', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
          home: Scaffold(
            body: TrackTile.fromTrack(
              track: testTrack,
              isPlaying: true,
            ),
          ),
        ),
      );

      // Must find the animated 3-bar equalizer glyph
      expect(find.byType(AnimatedEqualizerGlyph), findsOneWidget);

      // Assert zero Border.all decoration
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TrackTile),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull, reason: 'Playing track row must be borderless');
      expect(decoration.color, isNotNull);
    });

    testWidgets('inactive track renders cleanly with zero border and transparent background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(preset: ThemePreset.midnightBlack),
          home: Scaffold(
            body: TrackTile.fromTrack(
              track: testTrack,
              isPlaying: false,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedEqualizerGlyph), findsNothing);
      expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(TrackTile),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.border, isNull, reason: 'Inactive track row must be borderless');
      expect(decoration.color, equals(Colors.transparent));
    });
  });
}
