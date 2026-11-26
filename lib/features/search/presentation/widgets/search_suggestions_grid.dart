import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/features/library/domain/repositories/genres_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_smart_playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';

/// Quick discovery suggestions displayed on the empty search state,
/// backed by live Favorites count and indexed library genres when available.
class SearchSuggestionsGrid extends ConsumerWidget {
  const SearchSuggestionsGrid({
    super.key,
    required this.onSelectSuggestion,
  });

  final ValueChanged<String> onSelectSuggestion;

  static const _genrePalette = <Color>[
    Color(0xFF00E5FF),
    Color(0xFFFF3D00),
    Color(0xFFE040FB),
    Color(0xFF00E676),
    Color(0xFFFFAB00),
  ];

  static const _fallbackSuggestions = [
    _Suggestion(label: 'Electronic', query: 'Electronic', icon: Icons.electric_bolt_rounded, color: Color(0xFF00E5FF)),
    _Suggestion(label: 'Rock', query: 'Rock', icon: Icons.album_rounded, color: Color(0xFFFF3D00)),
    _Suggestion(label: 'Synthwave', query: 'Synthwave', icon: Icons.waves_rounded, color: Color(0xFFE040FB)),
    _Suggestion(label: 'Ambient', query: 'Ambient', icon: Icons.cloud_queue_rounded, color: Color(0xFF00E676)),
    _Suggestion(label: 'Pop', query: 'Pop', icon: Icons.music_note_rounded, color: Color(0xFFFFAB00)),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = NexaSurfaceTokens.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final l10n = context.l10n;

    int? favCount;
    if (getIt.isRegistered<SqliteSmartPlaylistsRepository>() ||
        getIt.isRegistered<ITracksRepository>()) {
      favCount = ref
          .watch(smartPlaylistTracksProvider(SmartPlaylistType.favorites))
          .valueOrNull
          ?.length;
    }

    final favLabel =
        favCount != null ? '${l10n.favorites} ($favCount)' : l10n.favorites;

    final items = <_Suggestion>[
      _Suggestion(
        label: favLabel,
        query: 'favorites',
        icon: Icons.favorite_rounded,
        color: const Color(0xFFFF1744),
      ),
    ];

    if (getIt.isRegistered<IGenresRepository>()) {
      final genres = ref.watch(genresListProvider(null)).valueOrNull ?? const [];
      for (int i = 0; i < genres.length && items.length < 6; i++) {
        final genre = genres[i];
        items.add(
          _Suggestion(
            label: genre.name,
            query: genre.name,
            icon: Icons.music_note_rounded,
            color: _genrePalette[i % _genrePalette.length],
          ),
        );
      }
    }

    for (final fallback in _fallbackSuggestions) {
      if (items.length >= 6) break;
      final alreadyIncluded = items.any(
        (item) => item.query.toLowerCase() == fallback.query.toLowerCase(),
      );
      if (!alreadyIncluded) {
        items.add(fallback);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              Icon(Icons.explore_outlined, size: 18, color: onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                l10n.exploreLibrary,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: tokens.onL0,
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
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final blendedBg = Color.alphaBlend(
                    item.color.withOpacity(0.14),
                    tokens.l2,
                  );
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelectSuggestion(item.query);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              blendedBg,
                              tokens.l2,
                            ],
                            begin: AlignmentDirectional.topStart,
                            end: AlignmentDirectional.bottomEnd,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: item.color.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item.icon, size: 16, color: item.color),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  color: tokens.onL2,
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
    required this.label,
    required this.query,
    required this.icon,
    required this.color,
  });

  final String label;
  final String query;
  final IconData icon;
  final Color color;
}
