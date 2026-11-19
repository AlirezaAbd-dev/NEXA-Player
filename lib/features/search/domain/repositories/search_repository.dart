import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/search/domain/models/search_result.dart';
import 'package:nexa_player/features/search/domain/models/search_result_category.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';

/// Contract for executing indexed cross-library searches and managing search history.
abstract interface class ISearchRepository {
  /// Performs an instant search matching [query] across library entities.
  ///
  /// Can be restricted to a specific [category] or return aggregated matches for [SearchResultCategory.all].
  /// Limits the number of results per category to [limitPerCategory].
  Future<Result<SearchResult, DatabaseFailure>> search({
    required String query,
    SearchResultCategory category = SearchResultCategory.all,
    int limitPerCategory = 25,
  });

  /// Retrieves chronological recent search queries (most recent first).
  Future<List<String>> getRecentSearches();

  /// Adds [query] to recent searches history, deduplicating and limiting total entries.
  Future<void> saveRecentSearch(String query);

  /// Removes a single [query] from recent searches history.
  Future<void> removeRecentSearch(String query);

  /// Clears all recent searches history.
  Future<void> clearRecentSearches();
}
