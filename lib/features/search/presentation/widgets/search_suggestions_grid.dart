import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';

/// Quick discovery suggestions displayed on the empty search state.
class SearchSuggestionsGrid extends StatelessWidget {
  const SearchSuggestionsGrid({
    super.key,
    required this.onSelectSuggestion,
  });

  final ValueChanged<String> onSelectSuggestion;

  static const _suggestions = [
    _Suggestion(title: 'Electronic', icon: Icons.electric_bolt_rounded, color: Color(0xFF00E5FF)),
    _Suggestion(title: 'Rock', icon: Icons.album_rounded, color: Color(0xFFFF3D00)),
    _Suggestion(title: 'Favorites', icon: Icons.favorite_rounded, color: Color(0xFFFF1744)),
    _Suggestion(title: 'Synthwave', icon: Icons.waves_rounded, color: Color(0xFFE040FB)),
    _Suggestion(title: 'Ambient', icon: Icons.cloud_queue_rounded, color: Color(0xFF00E676)),
    _Suggestion(title: 'Pop', icon: Icons.music_note_rounded, color: Color(0xFFFFAB00)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              const Icon(Icons.explore_outlined, size: 18, color: Colors.white70),
              const SizedBox(width: 8),
              Text(
                'Explore Library',
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 600 ? 3 : 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.5,
                ),
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final item = _suggestions[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelectSuggestion(item.title);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              item.color.withOpacity(0.18),
                              const Color(0xFF141923),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.color.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.icon, size: 16, color: item.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Suggestion {
  const _Suggestion({
    required this.title,
    required this.icon,
    required this.color,
  });

  final String title;
  final IconData icon;
  final Color color;
}
