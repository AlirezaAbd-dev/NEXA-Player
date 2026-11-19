import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/features/lyrics/presentation/providers/lyrics_providers.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/lyrics_time_offset_control.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';

class MockLyricsService extends Mock implements ILyricsService {}

void main() {
  late MockLyricsService mockLyricsService;

  const testTrack = Track(
    id: 'trk-offset-test',
    title: 'Offset Song',
    artist: 'NEXA',
    duration: Duration(minutes: 3),
  );

  setUp(() {
    mockLyricsService = MockLyricsService();
  });

  Widget buildSubject({VoidCallback? onClose}) {
    return ProviderScope(
      overrides: [
        lyricsServiceProvider.overrideWithValue(mockLyricsService),
        currentTrackProvider.overrideWithValue(testTrack),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LyricsTimeOffsetControl(
            onClose: onClose ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('displays current offset and nudges forward/backward', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Sync Offset: 0 ms'), findsOneWidget);

    // Tap +0.1s
    await tester.tap(find.text('+0.1s'));
    await tester.pumpAndSettle();

    expect(find.text('Sync Offset: +100 ms (0.10s)'), findsOneWidget);

    // Tap +0.5s
    await tester.tap(find.text('+0.5s'));
    await tester.pumpAndSettle();

    expect(find.text('Sync Offset: +600 ms (0.60s)'), findsOneWidget);

    // Tap Reset
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(find.text('Sync Offset: 0 ms'), findsOneWidget);
  });

  testWidgets('Save Offset button persists offset to lyrics service', (tester) async {
    when(() => mockLyricsService.updateOffset('trk-offset-test', 500))
        .thenAnswer((_) async => const Result.success(null));

    bool closed = false;

    await tester.pumpWidget(buildSubject(onClose: () => closed = true));
    await tester.pumpAndSettle();

    await tester.tap(find.text('+0.5s'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save Offset'));
    await tester.pumpAndSettle();

    verify(() => mockLyricsService.updateOffset('trk-offset-test', 500)).called(1);
    expect(closed, isTrue);
  });
}
