import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/widgets/library_segmented_pill_bar.dart';
import 'package:nexa_player/shared/widgets/cards/artist_card.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';

/// Artists tab screen displaying artist list.
class ArtistsTabScreen extends ConsumerWidget {
  const ArtistsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistsAsync = ref.watch(artistsListProvider(null));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Artists', style: AppTypography.titleLarge),
            artistsAsync.maybeWhen(
              data: (artists) => Text(
                '${artists.length} ARTISTS IN LIBRARY',
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
          IconButton(
            icon: const Icon(Icons.sort_by_alpha_rounded),
            tooltip: 'Sort A to Z',
            onPressed: () {},
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
        padding: const EdgeInsets.fromLTRB(16.0, 148.0, 4.0, 130.0),
        child: artistsAsync.when(
          data: (artists) {
            if (artists.isEmpty) {
              return const Center(
                child: Text(
                  'No artists found. Scan your media in Settings!',
                  style: AppTypography.bodyMedium,
                ),
              );
            }

            return Stack(
              children: [
                // Direct-on-L0 Artist List (No repetitive boxed cards)
                ListView.builder(
                  key: Phase2Keys.artistsList,
                  padding: const EdgeInsets.fromLTRB(0.0, 8.0, 24.0, 140.0),
                  itemCount: artists.length,
                  itemBuilder: (context, index) {
                    final artist = artists[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: ArtistCard.fromArtist(
                        key: Phase2Keys.artistCard(artist.id),
                        artist: artist,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ArtistDetailScreen(artist: artist),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Slim A-Z Fast-Scroll Scrubber Rail on right margin
                Positioned(
                  right: 2,
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
