import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_folders_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/folders_tab_screen.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import '../../helpers/test_database_helper.dart';

void main() {
  test('SqliteFoldersRepository populates FileNode.track with full metadata and artworkUri', () async {
    final db = TestDatabaseHelper.createInMemoryDatabase();
    addTearDown(() {
      if (!db.isClosed) db.close();
    });

    final repo = SqliteFoldersRepository(db);
    const track = Track(
      id: 'trk-1',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, Were Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      filePath: '/storage/emulated/0/Music/Electro/01_track_raw.mp3',
      artworkUri: 'content://media/external/audio/albumart/99',
      fileSize: 9800000,
    );
    TestDatabaseHelper.seedTrack(db, track);

    final res = await repo.getFoldersTree(const []);
    expect(res.isSuccess, isTrue);
    final roots = res.valueOrNull!;
    expect(roots, isNotEmpty);

    final file = roots.first.files.single;
    expect(file.name, '01_track_raw.mp3');
    expect(file.displayTitle, 'Midnight City');
    expect(file.displayArtist, 'M83');
    expect(file.track?.artworkUri, 'content://media/external/audio/albumart/99');
    expect(file.track?.album, 'Hurry Up, Were Dreaming');
    expect(file.track?.duration, const Duration(minutes: 4, seconds: 3));
  });

  testWidgets('FoldersTabScreen displays track title, small artist, real artwork, and rich sort menu', (tester) async {
    const trackA = Track(
      id: 't-a',
      title: 'Zebra Song',
      artist: 'Alpha Artist',
      album: 'Beta Album',
      duration: Duration(minutes: 5),
      filePath: '/music/Mix/raw_file_a.mp3',
      artworkUri: 'content://art/1',
    );
    const trackB = Track(
      id: 't-b',
      title: 'Apple Song',
      artist: 'Zeta Artist',
      album: 'Alpha Album',
      duration: Duration(minutes: 2),
      filePath: '/music/Mix/raw_file_b.mp3',
      artworkUri: 'content://art/2',
    );

    final folder = FolderNode(
      path: '/music/Mix',
      name: 'Mix',
      files: [
        FileNode(
          path: trackA.filePath!,
          name: 'raw_file_a.mp3',
          trackId: trackA.id,
          track: trackA,
        ),
        FileNode(
          path: trackB.filePath!,
          name: 'raw_file_b.mp3',
          trackId: trackB.id,
          track: trackB,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          foldersTreeProvider(const []).overrideWith((ref) => Future.value([folder])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FoldersTabScreen(initialPath: '/music/Mix'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Track titles & small artists shown instead of raw filenames
    expect(find.text('Zebra Song'), findsOneWidget);
    expect(find.text('Alpha Artist'), findsOneWidget);
    expect(find.text('Apple Song'), findsOneWidget);
    expect(find.text('Zeta Artist'), findsOneWidget);
    expect(find.text('raw_file_a.mp3'), findsNothing);

    // Real artworkUri passed to NexaArtworkImage
    final artworkWidgets = tester.widgetList<NexaArtworkImage>(find.byType(NexaArtworkImage)).toList();
    expect(artworkWidgets.map((w) => w.track?.artworkUri).toSet(), {'content://art/1', 'content://art/2'});

    // Default sort is Title ascending: Apple Song above Zebra Song
    expect(
      tester.getTopLeft(find.byKey(Phase2Keys.fileNode(trackB.filePath!))).dy,
      lessThan(tester.getTopLeft(find.byKey(Phase2Keys.fileNode(trackA.filePath!))).dy),
    );

    // Open sort menu and verify rich sort options exist, then sort by Artist
    await tester.tap(find.byKey(const ValueKey('folders_sort_btn')));
    await tester.pumpAndSettle();
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Artist'), findsOneWidget);
    expect(find.text('Album'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Date Added'), findsOneWidget);

    await tester.tap(find.text('Artist'));
    await tester.pumpAndSettle();

    // Artist ascending: Alpha Artist (trackA) above Zeta Artist (trackB)
    expect(
      tester.getTopLeft(find.byKey(Phase2Keys.fileNode(trackA.filePath!))).dy,
      lessThan(tester.getTopLeft(find.byKey(Phase2Keys.fileNode(trackB.filePath!))).dy),
    );
  });
}
