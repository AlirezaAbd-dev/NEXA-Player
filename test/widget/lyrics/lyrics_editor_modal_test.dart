import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/domain/services/lrc_parser.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/features/lyrics/presentation/providers/lyrics_providers.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/lyrics_editor_modal.dart';
import 'package:nexa_player/shared/models/track.dart';

class MockLyricsService extends Mock implements ILyricsService {}

void main() {
  late MockLyricsService mockLyricsService;

  const testTrack = Track(
    id: 'trk-modal-test',
    title: 'Neon Skyline',
    artist: 'Cyber Dream',
    duration: Duration(minutes: 4),
    filePath: '/storage/music/neon_skyline.mp3',
  );

  const sampleLrc = '[00:10.00]First line\n[00:20.00]Second line';
  final sampleLyrics = const LrcParser().parse(
    sampleLrc,
    trackId: 'trk-modal-test',
    source: LyricsSource.manual,
  );

  setUp(() {
    mockLyricsService = MockLyricsService();
    registerFallbackValue(testTrack);
    registerFallbackValue(sampleLyrics);
  });

  Widget buildSubject({Lyrics? initialLyrics}) {
    return ProviderScope(
      overrides: [
        lyricsServiceProvider.overrideWithValue(mockLyricsService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => LyricsEditorModal.show(
                  context,
                  track: testTrack,
                  currentLyrics: initialLyrics,
                ),
                child: const Text('Open Editor'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, track name, and initial lyrics text', (tester) async {
    await tester.pumpWidget(buildSubject(initialLyrics: sampleLyrics));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Lyrics Editor'), findsOneWidget);
    expect(find.text('Neon Skyline'), findsOneWidget);
    expect(find.textContaining('First line'), findsOneWidget);
    expect(find.text('Fetch LRCLIB'), findsOneWidget);
    expect(find.text('Save Lyrics'), findsOneWidget);
  });

  testWidgets('shows validation message when saving empty text', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();

    // Tap Save while empty
    await tester.tap(find.text('Save Lyrics'));
    await tester.pumpAndSettle();

    expect(find.text('Lyrics cannot be completely empty.'), findsOneWidget);
    verifyNever(() => mockLyricsService.saveLyrics(any(), any(), saveToLrcFile: any(named: 'saveToLrcFile')));
  });

  testWidgets('Fetch LRCLIB queries service and updates text field', (tester) async {
    const onlineLrc = '[00:05.00]Online fetched lyrics line';
    final onlineLyrics = const LrcParser().parse(onlineLrc, trackId: 'trk-modal-test');

    when(() => mockLyricsService.fetchOnlineLyrics(testTrack))
        .thenAnswer((_) async => Result.success(onlineLyrics));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();

    // Tap Fetch LRCLIB
    await tester.tap(find.text('Fetch LRCLIB'));
    await tester.pumpAndSettle();

    verify(() => mockLyricsService.fetchOnlineLyrics(testTrack)).called(1);
    expect(find.textContaining('Online fetched lyrics line'), findsOneWidget);
    expect(find.textContaining('Fetched online lyrics from LRCLIB'), findsOneWidget);
  });

  testWidgets('Save Lyrics passes edited lyrics to service and pops modal', (tester) async {
    when(() => mockLyricsService.saveLyrics(testTrack, any(), saveToLrcFile: any(named: 'saveToLrcFile')))
        .thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();

    // Enter lyrics
    final textField = find.byType(TextField);
    await tester.enterText(textField, '[00:15.00] Brand new lyric line');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save Lyrics'));
    await tester.pumpAndSettle();

    verify(() => mockLyricsService.saveLyrics(
      testTrack,
      any(that: isA<Lyrics>().having((l) => l.lines.first.text, 'text', 'Brand new lyric line')),
      saveToLrcFile: any(named: 'saveToLrcFile'),
    )).called(1);

    expect(find.text('Lyrics saved successfully'), findsOneWidget);
  });
}
