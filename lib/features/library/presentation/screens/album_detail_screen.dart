import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Album detail screen displaying album hero artwork dissolving into L0 canvas,
/// comprehensive metadata, playback action bar, and track list.
class AlbumDetailScreen extends ConsumerWidget {
  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  final Album album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final tracksAsync = ref.watch(albumDetailTracksProvider(album.id));
    final playerState = ref.watch(playerNotifierProvider);
    final currentTrackId = playerState.currentTrack?.id;

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

          // Hero Album Artwork dissolving into L0 canvas via multi-stop cubic gradient ShaderMask
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 340.0,
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
                tag: 'album_art_${album.id}',
                child: NexaArtworkImage(
                  artworkUri: album.artworkUri,
                  album: album,
                  albumTracks: tracksAsync.valueOrNull ?? const [],
                  cacheWidth: 720,
                  fit: BoxFit.cover,
                  fallbackBuilder: (_) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primary.withOpacity(0.32),
                          surfaceTokens.level1,
                          surfaceTokens.level0,
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.album_rounded,
                        size: 140.0,
                        color: primary.withOpacity(0.40),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content Layer: Album Meta + Track List
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 108.0, 16.0, 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Album Title & Metadata
                Text(
                  album.title,
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  album.artistAndYear,
                  style: AppTypography.titleSmall.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Metadata Pill & Action Buttons Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceTokens.level2,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        '${album.year != null ? '${album.year} • ' : ''}${album.trackCountLabel} • FLAC 96/24',
                        style: surfaceTokens.telemetryTextStyle.copyWith(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.0,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Play All button
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 10.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                      ),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20.0),
                      label: const Text('Play All'),
                      onPressed: () {
                        final tracks = tracksAsync.valueOrNull;
                        if (tracks != null && tracks.isNotEmpty) {
                          ref.read(playerNotifierProvider.notifier).playQueue(
                                tracks,
                                initialIndex: 0,
                                queueContext: QueueContext.album(
                                  album.id,
                                  title: album.title,
                                ),
                              );
                        }
                      },
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    // Shuffle button
                    NexaSurface(
                      level: NexaSurfaceLevel.l2,
                      borderRadius: BorderRadius.circular(20.0),
                      child: IconButton(
                        icon: const Icon(Icons.shuffle_rounded, size: 20.0),
                        tooltip: 'Shuffle album',
                        onPressed: () {
                          final tracks = tracksAsync.valueOrNull;
                          if (tracks != null && tracks.isNotEmpty) {
                            ref.read(playerNotifierProvider.notifier).playQueue(
                                  tracks,
                                  initialIndex: 0,
                                  mode: PlaybackMode.shuffle,
                                  queueContext: QueueContext.album(
                                    album.id,
                                    title: album.title,
                                  ),
                                );
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Track List
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
                              showTrackNumber: true,
                              isPlaying: track.id == currentTrackId,
                              onTap: () {
                                ref
                                    .read(playerNotifierProvider.notifier)
                                    .playQueue(
                                      tracks,
                                      initialIndex: index,
                                      queueContext: QueueContext.album(
                                        album.id,
                                        title: album.title,
                                      ),
                                    );
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
