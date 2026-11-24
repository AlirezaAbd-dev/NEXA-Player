import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Artist detail screen displaying artist profile banner dissolving into L0 canvas,
/// action buttons, and track list.
class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({
    super.key,
    required this.artist,
  });

  final Artist artist;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final tracksAsync = ref.watch(artistDetailTracksProvider(artist.id));
    final playerState = ref.watch(playerNotifierProvider);
    final currentTrackId = playerState.currentTrack?.id;

    return Scaffold(
      key: Phase2Keys.artistDetailScreen,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: artist.name,
        leading: IconButton(
          key: Phase2Keys.artistDetailBackButton,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAmbientBackground(),

          // Dissolving Artist Profile Banner via multi-stop cubic gradient ShaderMask
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 320.0,
            child: ShaderMask(
              shaderCallback: (rect) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white,
                    Colors.white,
                    Color(0x99FFFFFF),
                    Color(0x22FFFFFF),
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.40, 0.65, 0.85, 1.0],
                ).createShader(rect);
              },
              blendMode: BlendMode.dstIn,
              child: Hero(
                tag: 'artist_art_${artist.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        primary.withOpacity(0.30),
                        surfaceTokens.level1,
                        surfaceTokens.level0,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 140.0,
                      color: primary.withOpacity(0.35),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content Layer: Info + Action Bar + Track List
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 108.0, 16.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artist.name,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  artist.tracksAndAlbumsLabel,
                  style: AppTypography.titleSmall.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Action Bar: Play All & Shuffle
                Row(
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
                      label: const Text('Play Top'),
                      onPressed: () {
                        final tracks = tracksAsync.valueOrNull;
                        if (tracks != null && tracks.isNotEmpty) {
                          ref
                              .read(playerNotifierProvider.notifier)
                              .playQueue(tracks, initialIndex: 0);
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    NexaSurface(
                      level: NexaSurfaceLevel.l2,
                      borderRadius: BorderRadius.circular(20.0),
                      child: IconButton(
                        icon: const Icon(Icons.shuffle_rounded, size: 20.0),
                        tooltip: 'Shuffle artist tracks',
                        onPressed: () {
                          final tracks = tracksAsync.valueOrNull;
                          if (tracks != null && tracks.isNotEmpty) {
                            ref.read(playerNotifierProvider.notifier).playQueue(
                                  tracks,
                                  initialIndex: 0,
                                  mode: PlaybackMode.shuffle,
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                Expanded(
                  child: tracksAsync.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const Center(
                          child: Text(
                            'No tracks found for this artist.',
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }

                      return ListView.builder(
                        key: Phase2Keys.artistDetailTrackList,
                        padding: nexaScrollPadding(context,
                            horizontal: 0.0, top: 0.0),
                        itemCount: tracks.length,
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                            child: TrackTile.fromTrack(
                              key: Phase2Keys.trackTile(track.id),
                              track: track,
                              isPlaying: track.id == currentTrackId,
                              onTap: () {
                                ref
                                    .read(playerNotifierProvider.notifier)
                                    .playQueue(tracks, initialIndex: index);
                              },
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
