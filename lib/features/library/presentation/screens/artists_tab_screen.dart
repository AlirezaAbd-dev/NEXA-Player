import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/features/library/domain/repositories/artists_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/widgets/library_segmented_pill_bar.dart';
import 'package:nexa_player/shared/widgets/cards/artist_card.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';

/// Artists tab screen displaying artist list.
class ArtistsTabScreen extends ConsumerStatefulWidget {
  const ArtistsTabScreen({super.key});

  @override
  ConsumerState<ArtistsTabScreen> createState() => _ArtistsTabScreenState();
}

class _ArtistsTabScreenState extends ConsumerState<ArtistsTabScreen> {
  ArtistSortBy _sortBy = ArtistSortBy.name;
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final queryParams = (_sortBy == ArtistSortBy.name && _ascending)
        ? null
        : ArtistQueryParams(sortBy: _sortBy, ascending: _ascending);
    final artistsAsync = ref.watch(artistsListProvider(queryParams));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.tabArtists, style: AppTypography.titleLarge),
            artistsAsync.maybeWhen(
              data: (artists) => Text(
                context.l10n.artistsCountMeta(artists.length),
                style: AppTypography.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  fontSize: 10.5,
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<ArtistSortBy>(
            key: const ValueKey('artists_sort_btn'),
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort artists',
            onSelected: (sortBy) {
              setState(() {
                if (_sortBy == sortBy) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = sortBy;
                  _ascending = true;
                }
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: ArtistSortBy.name,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Name'),
                    if (_sortBy == ArtistSortBy.name)
                      Icon(
                        _ascending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                      ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: ArtistSortBy.trackCount,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Track Count'),
                    if (_sortBy == ArtistSortBy.trackCount)
                      Icon(
                        _ascending
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 16,
                      ),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search library',
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
        bottom: const LibrarySegmentedPillBar(
          selectedTab: LibrarySubTab.artists,
        ),
      ),
      body: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 148.0, 4.0, 0.0),
        child: artistsAsync.when(
          data: (artists) {
            if (artists.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.noArtistsFound,
                  style: AppTypography.bodyMedium,
                ),
              );
            }

            final basePadding =
                nexaScrollPadding(context, horizontal: 0.0, top: 8.0);
            return Stack(
              children: [
                // Direct-on-L0 Artist List (No repetitive boxed cards)
                ListView.builder(
                  key: Phase2Keys.artistsList,
                  padding: EdgeInsetsDirectional.only(
                    start: basePadding.left,
                    end: 24.0,
                    top: basePadding.top,
                    bottom: basePadding.bottom,
                  ),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ArtistCard.fromArtist(
                        key: Phase2Keys.artistCard(artist.id),
                        artist: artist,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ArtistDetailScreen(artist: artist),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Slim A-Z Fast-Scroll Scrubber Rail on end margin
                PositionedDirectional(
                  end: 2,
                  top: 16,
                  bottom: 140,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 3.0),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['A', 'C', 'D', 'J', 'K', 'M', 'T', 'W', '#']
                            .map((letter) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      color: letter == 'D'
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.6),
                                      fontWeight: letter == 'D' ? FontWeight.bold : FontWeight.w500,
                                      fontSize: 10.0,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              'Error loading artists: $error',
              style: AppTypography.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
