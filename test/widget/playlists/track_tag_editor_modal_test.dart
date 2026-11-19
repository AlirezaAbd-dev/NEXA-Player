import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/track_tag_editor_modal.dart';
import 'package:nexa_player/shared/models/track.dart';

class MockTagEditorService extends Mock implements ITagEditorService {}

void main() {
  late MockTagEditorService mockTagEditor;

  const initialTrack = Track(
    id: 'track-123',
    title: 'Midnight Echoes',
    artist: 'Luna Eclipse',
    album: 'Nocturne',
    genre: 'Ambient',
    year: 2023,
    trackNumber: 3,
    duration: Duration(minutes: 5),
    filePath: '/storage/music/nocturne/midnight.mp3',
  );

  setUp(() {
    mockTagEditor = MockTagEditorService();
    registerFallbackValue(
      const EditableTrackMetadata(
        title: 'fallback',
        artist: 'fallback',
        album: 'fallback',
      ),
    );
  });

  Widget buildHostApp() {
    return ProviderScope(
      overrides: [
        tagEditorServiceProvider.overrideWithValue(mockTagEditor),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => TrackTagEditorModal.show(context, track: initialTrack),
                child: const Text('Open Tag Editor'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('populates form fields with initial track metadata', (tester) async {
    await tester.pumpWidget(buildHostApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Tag Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Track Tags'), findsOneWidget);
    expect(find.text('Midnight Echoes'), findsOneWidget);
    expect(find.text('Luna Eclipse'), findsOneWidget);
    expect(find.text('Nocturne'), findsOneWidget);
    expect(find.text('Ambient'), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
  });

  testWidgets('shows validation error when title is erased and does not invoke service', (tester) async {
    await tester.pumpWidget(buildHostApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Tag Editor'));
    await tester.pumpAndSettle();

    // Erase title field
    final titleFinder = find.widgetWithText(TextField, 'Midnight Echoes');
    await tester.enterText(titleFinder, '');
    await tester.pumpAndSettle();

    // Tap Save
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Title cannot be empty'), findsOneWidget);
    verifyNever(() => mockTagEditor.updateTrackMetadata(any(), any()));
  });

  testWidgets('submits updated metadata to tag editor service successfully', (tester) async {
    const updatedTrack = Track(
      id: 'track-123',
      title: 'Midnight Echoes (Remix)',
      artist: 'Luna Eclipse',
      album: 'Nocturne Deluxe',
      genre: 'Chillstep',
      year: 2024,
      trackNumber: 3,
      duration: Duration(minutes: 5),
    );

    when(() => mockTagEditor.updateTrackMetadata('track-123', any()))
        .thenAnswer((_) async => const Result.success(updatedTrack));

    await tester.pumpWidget(buildHostApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Tag Editor'));
    await tester.pumpAndSettle();

    final titleFinder = find.widgetWithText(TextField, 'Midnight Echoes');
    await tester.enterText(titleFinder, 'Midnight Echoes (Remix)');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    verify(() => mockTagEditor.updateTrackMetadata(
      'track-123',
      any(that: isA<EditableTrackMetadata>().having((m) => m.title, 'title', 'Midnight Echoes (Remix)')),
    )).called(1);

    expect(find.text('Track tags updated successfully'), findsOneWidget);
  });
}
