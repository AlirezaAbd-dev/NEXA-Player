import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/synced_lyrics_view.dart';
import 'package:nexa_player/features/playlists/presentation/screens/ringtone_trimmer_screen.dart';
import 'package:nexa_player/features/visualizer/presentation/screens/visualizer_settings_screen.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  const sampleTrack = Track(
    id: 'trk-1',
    title: 'Instant Crush',
    artist: 'Daft Punk',
    duration: Duration(minutes: 5, seconds: 37),
    filePath: '/music/instant_crush.flac',
  );

  final sampleLyrics = Lyrics(
    trackId: 'trk-1',
    source: LyricsSource.syncedLrc,
    plainLyrics: 'I didn\'t want to be the one to forget',
    lines: const [
      LyricLine(
        timestamp: Duration(seconds: 12),
        text: 'I didn\'t want to be the one to forget',
      ),
      LyricLine(
        timestamp: Duration(seconds: 18),
        text: 'I thought of something that I never should have said',
      ),
      LyricLine(
        timestamp: Duration(seconds: 24),
        text: 'And now I\'m having to pay the cost',
      ),
    ],
  );

  group('RingtoneTrimmerScreen Widget Tests', () {
    testWidgets('renders waveform, zoom resolution badge, and zero-crossing snap toggle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RingtoneTrimmerScreen(track: sampleTrack),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ringtone Trimmer'), findsOneWidget);
      expect(find.text('Zero-Crossing Snap'), findsOneWidget);
      expect(find.textContaining('Zoom • 10ms Resolution'), findsOneWidget);
      expect(find.text('EXPORT DESTINATION'), findsOneWidget);
      expect(find.byType(RangeSlider), findsOneWidget);

      // Toggle zero-crossing snap
      await tester.tap(find.text('Zero-Crossing Snap'));
      await tester.pump();
    });
  });

  group('SyncedLyricsView Depth-of-Field Blur Tests', () {
    testWidgets('renders active line sharp and applies ImageFiltered blur on inactive lines', (tester) async {
      Duration? soughtTime;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SyncedLyricsView(
              lyrics: sampleLyrics,
              activeIndex: 1,
              onSeekToTimestamp: (t) => soughtTime = t,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Active line text
      expect(find.text('I thought of something that I never should have said'), findsOneWidget);

      // Verify ImageFiltered blur wrappers exist for inactive lines
      expect(find.byType(ImageFiltered), findsWidgets);

      // Tap on first line to seek
      await tester.tap(find.text('I didn\'t want to be the one to forget'));
      await tester.pump();

      expect(soughtTime, equals(const Duration(seconds: 12)));
    });
  });

  group('VisualizerSettingsScreen Widget Tests', () {
    testWidgets('renders live spectrum preview without border anomalies', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VisualizerSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LIVE PREVIEW'), findsOneWidget);
      expect(find.text('Visualizer & Spectrum'), findsOneWidget);
      expect(find.text('Display Style & Engine'), findsOneWidget);
      expect(find.text('Performance & Resolution'), findsOneWidget);
    });
  });
}
