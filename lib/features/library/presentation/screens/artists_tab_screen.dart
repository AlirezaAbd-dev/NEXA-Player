import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/artist_detail_screen.dart';
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
      appBar: const GlassAppBar(
        titleText: 'Artists',
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
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

            return ListView.builder(
              key: Phase2Keys.artistsList,
              padding: EdgeInsets.zero,
              itemCount: artists.length,
              itemBuilder: (context, index) {
                final artist = artists[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
