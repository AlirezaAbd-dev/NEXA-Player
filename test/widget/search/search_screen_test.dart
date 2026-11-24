import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/player/player.dart';
import 'package:nexa_player/features/search/search.dart';
import 'package:nexa_player/shared/models/models.dart';

class MockSearchRepository extends Mock implements ISearchRepository {}

class FakePlayerNotifier extends StateNotifier<PlaybackState> implements PlayerNotifier {
  FakePlayerNotifier([Track? initialTrack])
      : super(PlaybackState(currentTrack: initialTrack));

  Track? playedTrack;

  @override
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? initialIndex,
    QueueContext? queueContext,
  }) async {
    playedTrack = track;
    state = state.copyWith(currentTrack: track, status: PlaybackStatus.playing);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    registerFallbackValue(SearchResultCategory.all);
  });

  late MockSearchRepository mockSearchRepository;
  late FakePlayerNotifier fakePlayerNotifier;

  const testTrack = Track(
    id: 'trk-1',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(seconds: 230),
    filePath: '/music/starboy.mp3',
  );

  const testAlbum = Album(
    id: 'alb-1',
    title: 'Starboy',
    artist: 'The Weeknd',
    year: 2016,
    trackCount: 18,
  );

  const testArtist = Artist(
    id: 'art-1',
    name: 'The Weeknd',
    trackCount: 18,
    albumCount: 1,
  );

  const sampleResult = SearchResult(
    query: 'Starboy',
    tracks: [testTrack],
    albums: [testAlbum],
    artists: [testArtist],
  );

  setUp(() {
    mockSearchRepository = MockSearchRepository();
    fakePlayerNotifier = FakePlayerNotifier();

    when(() => mockSearchRepository.getRecentSearches())
        .thenAnswer((_) async => ['Daft Punk', 'Starboy']);
    when(() => mockSearchRepository.saveRecentSearch(any()))
        .thenAnswer((_) async {});
    when(() => mockSearchRepository.removeRecentSearch(any()))
        .thenAnswer((_) async {});
    when(() => mockSearchRepository.clearRecentSearches())
        .thenAnswer((_) async {});
  });

  Widget buildSubject({
    String initialQuery = '',
    SearchResultCategory initialCategory = SearchResultCategory.all,
    SearchResult? overrideResult,
  }) {
    when(() => mockSearchRepository.search(
          query: any(named: 'query'),
          category: any(named: 'category'),
          limitPerCategory: any(named: 'limitPerCategory'),
        )).thenAnswer((_) async => Result.success(overrideResult ?? SearchResult.empty()));

    return ProviderScope(
      overrides: [
        searchRepositoryProvider.overrideWithValue(mockSearchRepository),
        searchQueryProvider.overrideWith((ref) => initialQuery),
        searchCategoryProvider.overrideWith((ref) => initialCategory),
        playerNotifierProvider.overrideWith((ref) => fakePlayerNotifier),
      ],
      child: const MaterialApp(
        home: SearchScreen(),
      ),
    );
  }

  group('SearchScreen Widget Tests', () {
    testWidgets('renders search input field, category chips, and recent searches when query is empty', (tester) async {
      await tester.pumpWidget(buildSubject(initialQuery: ''));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search songs, albums, artists...'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Songs'), findsOneWidget);
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Genres'), findsOneWidget);

      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('Daft Punk'), findsOneWidget);
      expect(find.text('Explore Library'), findsOneWidget);
    });

    testWidgets('displays empty state when query returns no results', (tester) async {
      await tester.pumpWidget(buildSubject(
        initialQuery: 'NonExistentSong12345',
        overrideResult: SearchResult.empty('NonExistentSong12345'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('No Results for "NonExistentSong12345"'), findsOneWidget);
      expect(find.text('Clear Search Query'), findsOneWidget);
    });

    testWidgets('renders search results grouped by category when All is selected', (tester) async {
      await tester.pumpWidget(buildSubject(
        initialQuery: 'Starboy',
        overrideResult: sampleResult,
      ));
      await tester.pumpAndSettle();

      // Section headers with badge counts
      expect(find.text('Starboy'), findsWidgets);
      expect(find.text('The Weeknd'), findsWidgets);
    });

    testWidgets('switches category chip and updates filter', (tester) async {
      await tester.pumpWidget(buildSubject(
        initialQuery: 'Starboy',
        overrideResult: sampleResult,
      ));
      await tester.pumpAndSettle();

      // Tap Albums category chip inside SearchCategoryChips
      final albumsChip = find.descendant(
        of: find.byType(SearchCategoryChips),
        matching: find.text('Albums'),
      );
      await tester.tap(albumsChip);
      await tester.pumpAndSettle();

      verify(() => mockSearchRepository.search(
            query: any(named: 'query'),
            category: SearchResultCategory.albums,
            limitPerCategory: any(named: 'limitPerCategory'),
          )).called(greaterThanOrEqualTo(1));
    });

    testWidgets('opens voice search bottom sheet when mic button is pressed', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Voice Search'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Listening...'), findsOneWidget);
      expect(find.text('Say a song title, artist, or album name'), findsOneWidget);
      expect(find.text('Or tap a voice phrase:'), findsOneWidget);

      // Tap a voice sample chip
      final voiceChip = find.descendant(
        of: find.byType(ActionChip),
        matching: find.text('Starboy'),
      );
      await tester.tap(voiceChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Modal dismissed
      expect(find.text('Listening...'), findsNothing);
    });
  });
}
