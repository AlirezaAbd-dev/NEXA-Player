/// Searchable setting descriptor with keywords, category, route, and icon.
class SettingSearchItem {
  const SettingSearchItem({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.route,
    required this.keywords,
  });

  final String title;
  final String subtitle;
  final String category;
  final String route;
  final List<String> keywords;

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return false;
    if (title.toLowerCase().contains(q)) return true;
    if (subtitle.toLowerCase().contains(q)) return true;
    if (category.toLowerCase().contains(q)) return true;
    return keywords.any((k) => k.toLowerCase().contains(q));
  }
}
