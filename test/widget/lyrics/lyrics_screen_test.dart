import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyric_line.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/features/lyrics/presentation/providers/lyrics_providers.dart';
import 'package:nexa_player/features/lyrics/presentation/screens/lyrics_screen.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';

class MockLyricsService extends Mock implements ILyricsService {}

void main() {
  late MockLyricsService mockLyricsService;

  const testTrack = Track(
    id: 'trk-screen-1',
    title: 'Instant Crush',
    artist: 'Daft Punk',
    duration: Duration(seconds: 337),
  );

  const sampleLines = [
    LyricLine(timestamp: Duration(seconds: 10), text: 'I didn\'t want to be the one to forget'),
    LyricLine(timestamp: Duration(seconds: 15), text: 'I thought about the little things you said'),
  ];

  const sampleLyrics = Lyrics(
    trackId: 'trk-screen-1',
    lines: sampleLines,
    isSynced: true,
    source: LyricsSource.lrclib,
  );

  setUp(() {
    mockLyricsService = MockLyricsService();
  });

  Widget buildSubject({Track? track, Lyrics? lyrics, int activeIndex = 0}) {
    return ProviderScope(
      overrides: [
        lyricsServiceProvider.overrideWithValue(mockLyricsService),
        currentTrackProvider.overrideWithValue(track),
        activeLyricIndexProvider.overrideWithValue(activeIndex),
        if (track != null)
          trackLyricsProvider(track).overrideWith((ref) => Future.value(lyrics)),
      ],
      child: const MaterialApp(
        home: LyricsScreen(),
      ),
    );
  }

  testWidgets('displays placeholder message when no track is playing', (tester) async {
    await tester.pumpWidget(buildSubject(track: null));
    await tester.pumpAndSettle();

    expect(find.text('No track is currently playing.'), findsOneWidget);
  });

  testWidgets('renders track title, artist, and synced lines when track is playing', (tester) async {
    await tester.pumpWidget(buildSubject(track: testTrack, lyrics: sampleLyrics));
    await tester.pumpAndSettle();

    expect(find.text('Lyrics'), findsOneWidget);
    expect(find.text('Instant Crush'), findsOneWidget);
    expect(find.text('Daft Punk'), findsOneWidget);
    expect(find.text('LRCLIB Online'), findsOneWidget);
    expect(find.text('I didn\'t want to be the one to forget'), findsOneWidget);
    expect(find.text('I thought about the little things you said'), findsOneWidget);
  });

  testWidgets('toggles sync offset toolbar when tune button is pressed', (tester) async {
    await tester.pumpWidget(buildSubject(track: testTrack, lyrics: sampleLyrics));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Sync Offset'), findsOneWidget);
    expect(find.text('Sync Offset: 0 ms'), findsNothing);

    // Tap tune icon in AppBar
    await tester.tap(find.byTooltip('Sync Offset'));
    await tester.pumpAndSettle();

    expect(find.text('Sync Offset: 0 ms'), findsOneWidget);

    // Tap again to toggle off
    await tester.tap(find.byTooltip('Sync Offset'));
    await tester.pumpAndSettle();

    expect(find.text('Sync Offset: 0 ms'), findsNothing);
  });

  testWidgets('displays empty lyrics state with action button when lyrics are missing', (tester) async {
    await tester.pumpWidget(buildSubject(track: testTrack, lyrics: null));
    await tester.pumpAndSettle();

    expect(find.text('No lyrics found for "Instant Crush"'), findsOneWidget);
    expect(find.text('Add or Search Lyrics'), findsOneWidget);
  });
}
