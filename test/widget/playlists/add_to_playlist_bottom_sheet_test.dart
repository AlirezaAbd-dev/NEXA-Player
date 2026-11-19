import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

class MockPlaylistsRepository extends Mock implements IPlaylistsRepository {}

void main() {
  late MockPlaylistsRepository mockRepo;

  const testTrack = Track(
    id: 'track-101',
    title: 'Solar Echoes',
    artist: 'Nigel',
    duration: Duration(minutes: 4),
  );

  final testPlaylists = [
    Playlist(
      id: 'pl-chill',
      name: 'Chill Beats',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      trackCount: 5,
    ),
    Playlist(
      id: 'pl-running',
      name: 'Running Energy',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      trackCount: 12,
    ),
  ];

  setUp(() {
    mockRepo = MockPlaylistsRepository();
  });

  Widget buildHostApp() {
    return ProviderScope(
      overrides: [
        playlistsRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => AddToPlaylistBottomSheet.show(context, track: testTrack),
                child: const Text('Open Bottom Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('displays track title and existing user playlists', (tester) async {
    when(() => mockRepo.getAllPlaylists())
        .thenAnswer((_) async => Result.success(testPlaylists));

    await tester.pumpWidget(buildHostApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Bottom Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Add to Playlist'), findsOneWidget);
    expect(find.text('Solar Echoes'), findsOneWidget);
    expect(find.text('Chill Beats'), findsOneWidget);
    expect(find.text('Running Energy'), findsOneWidget);
    expect(find.text('New Playlist'), findsOneWidget);
  });

  testWidgets('adds track to existing playlist when tapped', (tester) async {
    when(() => mockRepo.getAllPlaylists())
        .thenAnswer((_) async => Result.success(testPlaylists));
    when(() => mockRepo.addTrackToPlaylist('pl-chill', 'track-101'))
        .thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(buildHostApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Bottom Sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chill Beats'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.addTrackToPlaylist('pl-chill', 'track-101')).called(1);
    expect(find.text('Added "Solar Echoes" to "Chill Beats"'), findsOneWidget);
  });

  testWidgets('creates a new playlist and adds track when submitting new playlist field', (tester) async {
    when(() => mockRepo.getAllPlaylists())
        .thenAnswer((_) async => Result.success(testPlaylists));
    final newPlaylist = Playlist(
      id: 'pl-new',
      name: 'Late Night Study',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      trackCount: 0,
    );
    when(() => mockRepo.createPlaylist('Late Night Study'))
        .thenAnswer((_) async => Result.success(newPlaylist));
    when(() => mockRepo.addTrackToPlaylist('pl-new', 'track-101'))
        .thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(buildHostApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Bottom Sheet'));
    await tester.pumpAndSettle();

    // Tap "New Playlist" button to show input
    await tester.tap(find.text('New Playlist'));
    await tester.pumpAndSettle();

    // Enter name
    await tester.enterText(find.byType(TextField), 'Late Night Study');
    await tester.pumpAndSettle();

    // Tap Add button
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    verify(() => mockRepo.createPlaylist('Late Night Study')).called(1);
    verify(() => mockRepo.addTrackToPlaylist('pl-new', 'track-101')).called(1);
    expect(find.text('Added "Solar Echoes" to "Late Night Study"'), findsOneWidget);
  });
}
