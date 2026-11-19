import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/search/domain/models/search_result.dart';
import 'package:nexa_player/features/search/domain/models/search_result_category.dart';
import 'package:nexa_player/features/search/domain/repositories/search_repository.dart';

/// Provider exposing the registered [ISearchRepository].
final searchRepositoryProvider = Provider<ISearchRepository>((ref) {
  return getIt<ISearchRepository>();
});

/// Current raw search query string entered in the search bar.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Active category filter for search queries (defaults to [SearchResultCategory.all]).
final searchCategoryProvider = StateProvider<SearchResultCategory>((ref) => SearchResultCategory.all);

/// Manages recent search history state with immediate UI updates.
class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier(this._repository) : super(const []) {
    load();
  }

  final ISearchRepository _repository;

  /// Loads persisted recent searches into state.
  Future<void> load() async {
    final list = await _repository.getRecentSearches();
    state = list;
  }

  /// Saves a search query and refreshes state.
  Future<void> save(String query) async {
    await _repository.saveRecentSearch(query);
    await load();
  }

  /// Removes an individual search query from history.
  Future<void> remove(String query) async {
    await _repository.removeRecentSearch(query);
    await load();
  }

  /// Clears all search history.
  Future<void> clear() async {
    await _repository.clearRecentSearches();
    state = const [];
  }
}

/// Provider for managing and observing recent search history.
final recentSearchesProvider = StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return RecentSearchesNotifier(repo);
});

/// Reactive search results provider responding to [searchQueryProvider] and [searchCategoryProvider].
final searchResultsProvider = FutureProvider<SearchResult>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(searchCategoryProvider);
  final repository = ref.watch(searchRepositoryProvider);

  final trimmed = query.trim();
  if (trimmed.isEmpty) {
    return SearchResult.empty();
  }

  final result = await repository.search(
    query: trimmed,
    category: category,
  );

  return result.when(
    success: (data) => data,
    failure: (failure) => throw failure,
  );
});
