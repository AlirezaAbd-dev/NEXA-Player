import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyric_line.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/synced_lyrics_view.dart';

void main() {
  const sampleLines = [
    LyricLine(timestamp: Duration(seconds: 10), text: 'I feel it coming'),
    LyricLine(timestamp: Duration(seconds: 20), text: 'I feel it coming, babe'),
    LyricLine(timestamp: Duration(seconds: 30), text: 'You\'ve been scared of love'),
  ];

  const syncedLyrics = Lyrics(
    trackId: 'trk-1',
    lines: sampleLines,
    isSynced: true,
    source: LyricsSource.lrclib,
  );

  const unsyncedLyrics = Lyrics(
    trackId: 'trk-2',
    plainLyrics: 'Just a plain lyric line\nSecond plain lyric line',
    isSynced: false,
    source: LyricsSource.lrclib,
  );

  testWidgets('renders all synced lyric lines and highlights active index', (tester) async {
    Duration? seekedTimestamp;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncedLyricsView(
            lyrics: syncedLyrics,
            activeIndex: 1, // 'I feel it coming, babe' is active
            onSeekToTimestamp: (t) => seekedTimestamp = t,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('I feel it coming'), findsOneWidget);
    expect(find.text('I feel it coming, babe'), findsOneWidget);
    expect(find.text('You\'ve been scared of love'), findsOneWidget);

    // Tap third line -> should seek to 30s
    await tester.tap(find.text('You\'ve been scared of love'));
    await tester.pumpAndSettle();

    expect(seekedTimestamp, equals(const Duration(seconds: 30)));
  });

  testWidgets('renders plain unsynced text when isSynced is false', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SyncedLyricsView(
            lyrics: unsyncedLyrics,
            activeIndex: -1,
            onSeekToTimestamp: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Just a plain lyric line'), findsOneWidget);
    expect(find.textContaining('Second plain lyric line'), findsOneWidget);
  });
}
