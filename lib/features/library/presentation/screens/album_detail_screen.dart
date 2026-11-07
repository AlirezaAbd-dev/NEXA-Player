import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';

/// Album detail screen displaying album metadata and track list.
class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(albumDetailTracksProvider(album.id));

    return Scaffold(
      key: Phase2Keys.albumDetailScreen,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: album.title,
        leading: IconButton(
          key: Phase2Keys.albumDetailBackButton,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAmbientBackground(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 24.0),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              album.title,
              style: AppTypography.headlineMedium
                  .copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              album.artistAndYear,
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: tracksAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return const Center(
                      child: Text(
                        'No tracks in this album.',
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    key: Phase2Keys.albumDetailTrackList,
                    padding: EdgeInsets.zero,
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TrackTile.fromTrack(
                          key: Phase2Keys.trackTile(track.id),
                          track: track,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error: $error',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  ),
);
  }
}
