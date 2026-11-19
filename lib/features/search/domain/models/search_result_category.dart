/// Supported category filters for cross-library search.
enum SearchResultCategory {
  all('All'),
  tracks('Songs'),
  albums('Albums'),
  artists('Artists'),
  playlists('Playlists'),
  genres('Genres');

  const SearchResultCategory(this.displayName);

  /// Human-readable tab label.
  final String displayName;
}
