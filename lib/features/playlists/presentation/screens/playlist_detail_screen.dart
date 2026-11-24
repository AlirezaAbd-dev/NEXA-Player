import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/track_tag_editor_modal.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Full-featured Playlist Detail screen with drag-to-reorder, Play All/Shuffle,
/// M3U export, tag editing, and ringtone trimming.
class PlaylistDetailScreen extends ConsumerWidget {
  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  final Playlist playlist;

  String _formatTotalDuration(List<Track> tracks) {
    final totalMs = tracks.fold<int>(0, (sum, t) => sum + t.duration.inMilliseconds);
    final totalMin = (totalMs / (1000 * 60)).round();
    if (totalMin < 60) {
      return '$totalMin mins';
    }
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;
    return '${hours}h ${mins}m';
  }

  void _handlePlayAll(BuildContext context, WidgetRef ref, List<Track> tracks) {
    if (tracks.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(playerNotifierProvider.notifier).playQueue(
          tracks,
          initialIndex: 0,
          queueContext: QueueContext.playlist(
            playlist.id,
            title: playlist.name,
          ),
        );
  }

  void _handleShuffle(BuildContext context, WidgetRef ref, List<Track> tracks) {
    if (tracks.isEmpty) return;
    HapticFeedback.selectionClick();
    ref.read(playerNotifierProvider.notifier).playQueue(
          tracks,
          initialIndex: 0,
          mode: PlaybackMode.shuffle,
          queueContext: QueueContext.playlist(
            playlist.id,
            title: playlist.name,
          ),
        );
  }

  void _handleExportM3u(BuildContext context, WidgetRef ref, List<Track> tracks) {
    final m3uService = ref.read(m3uServiceProvider);
    final content = m3uService.exportToM3u(playlist, tracks);
    Clipboard.setData(ClipboardData(text: content));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('M3U playlist exported for "${playlist.name}" (copied to clipboard)'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleDeletePlaylist(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF141924),
        title: const Text('Delete Playlist', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${playlist.name}"? Audio tracks in your library will not be deleted.',
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel', style: TextStyle(color: Colors.white.withOpacity(0.6))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(playlistsListNotifierProvider.notifier).deletePlaylist(playlist.id);
              Navigator.of(ctx).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracksAsync = ref.watch(playlistTracksProvider(playlist.id));
    final playerState = ref.watch(playerNotifierProvider);
    final currentTrackId = playerState.currentTrack?.id;
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: playlist.name,
        actions: [
          tracksAsync.when(
            data: (tracks) => IconButton(
              icon: const Icon(Icons.file_upload_outlined, size: 22),
              tooltip: 'Export M3U',
              onPressed: () => _handleExportM3u(context, ref, tracks),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 22),
            tooltip: 'Delete Playlist',
            onPressed: () => _handleDeletePlaylist(context, ref),
          ),
        ],
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
                // Header Info
                Row(
                  children: [
                    NexaSurface(
                      level: NexaSurfaceLevel.l2,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent.withOpacity(0.35), surfaceTokens.level2],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.queue_music_rounded, color: accent, size: 32),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            playlist.name,
                            style: AppTypography.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          tracksAsync.when(
                            data: (tracks) => Text(
                              '${tracks.length} tracks • ${_formatTotalDuration(tracks)}',
                              style: surfaceTokens.telemetryTextStyle.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                            loading: () => Text(
                              playlist.trackCountLabel,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                            error: (_, __) => Text(
                              playlist.trackCountLabel,
                              style: AppTypography.bodySmall,
                            ),
                          ),
                          if (playlist.isSmart) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: surfaceTokens.level2,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_awesome_rounded, size: 14, color: accent),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Smart Playlist',
                                        style: AppTypography.labelSmall.copyWith(color: accent),
                                      ),
                                    ],
                                  ),
                                ),
                                if (playlist.id == 'smart_recentlyAdded')
                                  for (final opt in const [20, 30, 50])
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        ref.read(recentlyAddedLimitProvider.notifier).state = opt;
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: ref.watch(recentlyAddedLimitProvider) == opt
                                              ? accent.withOpacity(0.22)
                                              : surfaceTokens.level2,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Latest $opt',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: ref.watch(recentlyAddedLimitProvider) == opt
                                                ? accent
                                                : Colors.white70,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Play All & Shuffle Buttons
                tracksAsync.when(
                  data: (tracks) => Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: tracks.isNotEmpty
                              ? () => _handlePlayAll(context, ref, tracks)
                              : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text(
                            'Play All',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NexaSurface(
                          level: NexaSurfaceLevel.l2,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: tracks.isNotEmpty
                                ? () => _handleShuffle(context, ref, tracks)
                                : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.shuffle_rounded, size: 18, color: accent),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Shuffle',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Reorderable Track List
                Expanded(
                  child: tracksAsync.when(
                    data: (tracks) {
                      if (tracks.isEmpty) {
                        return const Center(
                          child: Text(
                            'This playlist is empty.\nAdd tracks from the Songs or Albums tab.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                        );
                      }

                      return ReorderableListView.builder(
                        padding: nexaScrollPadding(context,
                            horizontal: 0.0, top: 0.0),
                        itemCount: tracks.length,
                        onReorder: (oldIndex, newIndex) {
                          int effectiveNew = newIndex;
                          if (oldIndex < effectiveNew) {
                            effectiveNew -= 1;
                          }
                          ref
                              .read(playlistsListNotifierProvider.notifier)
                              .reorderTrack(playlist.id, oldIndex, effectiveNew);
                        },
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          return Padding(
                            key: ValueKey('playlist_track_${track.id}_$index'),
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Row(
                              children: [
                                ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 16,
                                    ),
                                    child: const Icon(
                                      Icons.drag_handle_rounded,
                                      color: Colors.white38,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TrackTile.fromTrack(
                                    key: Phase2Keys.trackTile(track.id),
                                    track: track,
                                    isPlaying: track.id == currentTrackId,
                                    onTap: () {
                                      ref
                                          .read(playerNotifierProvider.notifier)
                                          .playQueue(
                                            tracks,
                                            initialIndex: index,
                                            queueContext: QueueContext.playlist(
                                              playlist.id,
                                              title: playlist.name,
                                            ),
                                          );
                                    },
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          key: Phase2Keys.trackFavoriteToggle(track.id),
                                          icon: Icon(
                                            track.isFavorite
                                                ? Icons.favorite_rounded
                                                : Icons.favorite_border_rounded,
                                            color: track.isFavorite
                                                ? Colors.redAccent.shade200
                                                : Colors.white54,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(playerNotifierProvider.notifier)
                                                .toggleFavorite(track);
                                            ref.invalidate(
                                              playlistTracksProvider(playlist.id),
                                            );
                                          },
                                        ),
                                        PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert_rounded,
                                        color: Colors.white54,
                                        size: 20,
                                      ),
                                      color: const Color(0xFF141924),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      onSelected: (action) {
                                        switch (action) {
                                          case 'play_next':
                                            ref
                                                .read(playbackQueueProvider)
                                                .addNext(track);
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  'Playing "${track.title}" next',
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                            break;
                                          case 'add_to_playlist':
                                            AddToPlaylistBottomSheet.show(
                                              context,
                                              track: track,
                                            );
                                            break;
                                          case 'edit_tags':
                                            TrackTagEditorModal.show(
                                              context,
                                              track: track,
                                            ).then((_) {
                                              ref.invalidate(
                                                playlistTracksProvider(
                                                    playlist.id),
                                              );
                                            });
                                            break;
                                          case 'trim_ringtone':
                                            context.push(
                                              AppRoutes.ringtoneTrimmer,
                                              extra: track,
                                            );
                                            break;
                                          case 'remove':
                                            ref
                                                .read(playlistsListNotifierProvider
                                                    .notifier)
                                                .removeTrack(
                                                    playlist.id, track.id);
                                            ref.invalidate(
                                              playlistTracksProvider(
                                                  playlist.id),
                                            );
                                            break;
                                        }
                                      },
                                      itemBuilder: (ctx) => [
                                        const PopupMenuItem(
                                          value: 'play_next',
                                          child: Row(
                                            children: [
                                              Icon(Icons.playlist_play_rounded,
                                                  size: 18),
                                              SizedBox(width: 10),
                                              Text('Play Next'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'add_to_playlist',
                                          child: Row(
                                            children: [
                                              Icon(Icons.playlist_add_rounded,
                                                  size: 18),
                                              SizedBox(width: 10),
                                              Text('Add to Playlist'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit_tags',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_note_rounded,
                                                  size: 18),
                                              SizedBox(width: 10),
                                              Text('Edit Tags & Cover'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'trim_ringtone',
                                          child: Row(
                                            children: [
                                              Icon(Icons.content_cut_rounded,
                                                  size: 18),
                                              SizedBox(width: 10),
                                              Text('Trim as Ringtone'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuDivider(),
                                        const PopupMenuItem(
                                          value: 'remove',
                                          child: Row(
                                            children: [
                                              Icon(Icons.remove_circle_outline,
                                                  color: Colors.redAccent,
                                                  size: 18),
                                              SizedBox(width: 10),
                                              Text(
                                                'Remove from Playlist',
                                                style: TextStyle(
                                                    color: Colors.redAccent),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
