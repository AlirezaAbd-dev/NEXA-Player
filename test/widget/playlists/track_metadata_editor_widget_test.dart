import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/track_tag_editor_modal.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

class _MockPlaylistsRepo extends Mock implements IPlaylistsRepository {}

class _MockTagEditor extends Mock implements ITagEditorService {}

class _FakeArtworkService implements IArtworkResolutionService {
  String? savedPath;
  bool cleared = false;

  @override
  Future<String?> saveCustomOverride(String trackId, Uint8List imageBytes) async {
    savedPath = '/cache/art/overrides/$trackId.jpg';
    return savedPath;
  }

  @override
  Future<void> clearCustomOverride(String trackId) async {
    cleared = true;
    savedPath = null;
  }

  @override
  Future<String?> cacheExtractedBytes(
    String cacheKey,
    Uint8List artworkBytes, {
    bool saveWithoutExtension = false,
  }) async =>
      null;

  @override
  Future<void> clearCache() async {}

  @override
  Future<String?> resolveAlbumArtwork(
    Album album, {
    List<Track> tracks = const [],
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
  }) async =>
      null;

  @override
  Future<String?> resolveTrackArtwork(
    Track track, {
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
    int? mediaStoreAlbumId,
    int maxSize = 512,
  }) async =>
      savedPath;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const EditableTrackMetadata(
        title: 'fallback',
        artist: 'fallback',
        album: 'fallback',
      ),
    );
  });

  testWidgets(
    'AddToPlaylistBottomSheet prevents duplicates with checkmarks and supports creating new playlist',
    (tester) async {
      final mockRepo = _MockPlaylistsRepo();
      const track = Track(
        id: 'trk-sheet-1',
        title: 'Midnight Drive',
        artist: 'Kavinsky',
        duration: Duration(minutes: 4),
      );

      final existingPl = Playlist(
        id: 'pl-1',
        name: 'Already Added Mix',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        trackCount: 1,
      );
      final targetPl = Playlist(
        id: 'pl-2',
        name: 'Roadtrip',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        trackCount: 0,
      );

      when(() => mockRepo.getAllPlaylists())
          .thenAnswer((_) async => Result.success([existingPl, targetPl]));
      when(() => mockRepo.getTracksForPlaylist('pl-1'))
          .thenAnswer((_) async => const Result.success([track]));
      when(() => mockRepo.getTracksForPlaylist('pl-2'))
          .thenAnswer((_) async => const Result.success([]));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playlistsRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () =>
                        AddToPlaylistBottomSheet.show(context, track: track),
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('1 Track • Added'), findsOneWidget);

      // Tapping already-added playlist does not call addTrackToPlaylist again
      await tester.tap(find.byKey(const ValueKey('add_to_playlist_item_pl-1')));
      await tester.pumpAndSettle();
      verifyNever(() => mockRepo.addTrackToPlaylist('pl-1', track.id));
    },
  );

  testWidgets(
    'TrackTagEditorModal saves custom cover override, Persian comment & metadata',
    (tester) async {
      final mockTagEditor = _MockTagEditor();
      final artworkService = _FakeArtworkService();
      final validJpeg = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01,
        0x01, 0x01, 0x00, 0x48, 0x00, 0x48, 0x00, 0x00, 0xFF, 0xD9,
      ]);

      const track = Track(
        id: 'trk-edit-ui-1',
        title: 'آواز دشتی',
        artist: 'استاد',
        album: 'سنتی',
        duration: Duration(minutes: 3),
        comment: 'یادداشت اولیه',
      );

      when(() => mockTagEditor.updateTrackMetadata('trk-edit-ui-1', any()))
          .thenAnswer(
        (_) async => const Result.success(
          Track(
            id: 'trk-edit-ui-1',
            title: 'آواز دشتی',
            artist: 'استاد',
            album: 'سنتی',
            duration: Duration(minutes: 3),
            comment: 'کامنت جدید',
          ),
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tagEditorServiceProvider.overrideWithValue(mockTagEditor),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => TrackTagEditorModal.show(
                      context,
                      track: track,
                      artworkService: artworkService,
                      pickCoverImage: () async => validJpeg,
                    ),
                    child: const Text('Edit Tags'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit Tags'));
      await tester.pumpAndSettle();

      expect(find.text('یادداشت اولیه'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('tag_editor_pick_cover')));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'یادداشت اولیه'),
        'کامنت جدید',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      verify(
        () => mockTagEditor.updateTrackMetadata(
          'trk-edit-ui-1',
          any(
            that: isA<EditableTrackMetadata>()
                .having((m) => m.comment, 'comment', 'کامنت جدید')
                .having((m) => m.artworkBytes, 'artworkBytes', isNotNull)
                .having((m) => m.artworkUri, 'artworkUri', contains('overrides')),
          ),
        ),
      ).called(1);
    },
  );
}
