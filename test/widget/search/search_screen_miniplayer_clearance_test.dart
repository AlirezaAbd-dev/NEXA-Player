import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/search/domain/models/search_result.dart';
import 'package:nexa_player/features/search/presentation/providers/search_providers.dart';
import 'package:nexa_player/features/search/presentation/screens/search_screen.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';
import 'package:nexa_player/shared/widgets/inputs/nexa_search_bar.dart';

class _FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _FakePlayerNotifier() : super(const PlaybackState());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeRecentSearchesNotifier extends StateNotifier<List<String>>
    implements RecentSearchesNotifier {
  _FakeRecentSearchesNotifier() : super(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'SearchScreen bottom search deck clears MiniPlayer/nav bottom padding when keyboard is closed',
    (tester) async {
      const screenSize = Size(390, 844);
      const bottomShellInset = 146.0;

      await tester.binding.setSurfaceSize(screenSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerNotifierProvider.overrideWith((ref) => _FakePlayerNotifier()),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(const SearchResult(query: '')),
            ),
            recentSearchesProvider.overrideWith(
              (ref) => _FakeRecentSearchesNotifier(),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: screenSize,
                padding: EdgeInsets.only(bottom: bottomShellInset),
              ),
              child: SearchScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final searchBarBottom = tester.getBottomLeft(find.byType(NexaSearchBar)).dy;
      // Search bar must sit cleanly above the 146dp MiniPlayer + nav dock inset
      expect(searchBarBottom, lessThanOrEqualTo(screenSize.height - bottomShellInset));
    },
  );
}
