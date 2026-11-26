import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';
import 'package:nexa_player/core/utils/contrast_validator.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/domain/services/queue_list_navigator.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/lists/active_track_auto_scroller.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

final _nextListPreviewProvider =
    FutureProvider.family<QueueListTransitionResult?, (QueueContext, bool)>(
        (ref, args) async {
  final nav = ref.watch(queueListNavigatorProvider);
  if (nav == null) return null;
  return nav.nextList(args.$1, wrapToFirst: args.$2);
});

/// Stellio-style interactive Playing Queue bottom sheet showing:
/// - Played history (`index < currentIndex`) at softened opacity
/// - Highlighted currently playing track (`index == currentIndex`) auto-centered
///   on open & on track transitions
/// - Upcoming tracks (`index > currentIndex`) with `"Up Next"` badges
/// - Next-list footer preview when Stellio `nextList*` repeat modes are active
/// - Drag-to-reorder, swipe-to-remove with 3s Undo, Save as Playlist, & Clear Up Next
class PlayingQueueSheet extends ConsumerStatefulWidget {
  const PlayingQueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PlayingQueueSheet(),
    );
  }

  @override
  ConsumerState<PlayingQueueSheet> createState() => _PlayingQueueSheetState();
}

class _PlayingQueueSheetState extends ConsumerState<PlayingQueueSheet> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  final GlobalKey _currentItemKey = GlobalKey();
  String? _lastAutoCenteredKey;
  Track? _pendingUndoTrack;
  int? _pendingUndoIndex;
  Timer? _undoTimer;

  @override
  void dispose() {
    _undoTimer?.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  void _showUndoBanner(int removedIndex, Track removedTrack) {
    _undoTimer?.cancel();
    setState(() {
      _pendingUndoIndex = removedIndex;
      _pendingUndoTrack = removedTrack;
    });
    _undoTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _pendingUndoTrack = null;
          _pendingUndoIndex = null;
        });
      }
    });
  }

  void _scrollToCurrentIfNeeded(
    ScrollController? controller,
    int currentIndex,
    int queueLength,
    String? currentTrackId, {
    int attempt = 0,
  }) {
    if (!mounted || controller == null || !controller.hasClients) return;
    if (currentIndex < 0 || currentIndex >= queueLength) return;
    final key = '${currentTrackId ?? ''}_$currentIndex';
    if (_lastAutoCenteredKey == key) return;

    final pos = controller.position;
    // Wait until DraggableScrollableSheet & ReorderableListView finish initial layout.
    if (!pos.hasContentDimensions ||
        !pos.hasViewportDimension ||
        pos.viewportDimension <= 0 ||
        (queueLength > 8 && pos.maxScrollExtent <= 0)) {
      if (attempt < 5) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentIfNeeded(
            controller,
            currentIndex,
            queueLength,
            currentTrackId,
            attempt: attempt + 1,
          );
        });
      }
      return;
    }

    _lastAutoCenteredKey = key;

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final scroller = ActiveTrackAutoScroller(itemExtent: 72.0);
    final target = scroller.computeTargetOffset(
      itemIndex: currentIndex,
      currentPixels: pos.pixels,
      viewportDimension: pos.viewportDimension,
      maxScrollExtent: pos.maxScrollExtent,
      bottomOcclusionClearance: 32.0,
      forceScroll: false,
    );
    if (target == null) return;

    if (reduceMotion) {
      controller.jumpTo(target);
    } else {
      controller.animateTo(
        target,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }

    // Refine with Scrollable.ensureVisible once the target item is built in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final itemCtx = _currentItemKey.currentContext;
      if (itemCtx != null) {
        Scrollable.ensureVisible(
          itemCtx,
          alignment: 0.35,
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _handleSaveAsPlaylist(List<Track> tracks) async {
    if (tracks.isEmpty) return;
    final controller = TextEditingController(
      text: ref.read(playbackQueueProvider).state.queueContext?.collectionTitle ??
          'Playing Queue',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Save Queue as Playlist'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Playlist name',
              hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;

    final repo = ref.read(playlistsRepositoryProvider);
    final createRes = await repo.createPlaylist(name);
    if (!createRes.isSuccess || createRes.valueOrNull == null) return;
    final created = createRes.valueOrNull!;
    for (final track in tracks) {
      await repo.addTrackToPlaylist(created.id, track.id);
    }
    ref.invalidate(playlistsListNotifierProvider);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved ${tracks.length} tracks to "$name"'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final primary = colorScheme.primary;

    final queue = ref.watch(playbackQueueProvider);
    final queueState =
        ref.watch(playbackQueueStateStreamProvider).valueOrNull ?? queue.state;
    final playerState = ref.watch(playerNotifierProvider);
    final tracks = queueState.tracks;
    final currentIndex = queueState.currentIndex;
    final isPlaying = playerState.isPlaying;
    final repeatMode = playerState.repeatMode;

    final totalDuration = tracks.fold<Duration>(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );

    final sourceTitle =
        queueState.queueContext?.collectionTitle ?? 'Playing Queue';
    final hasUpNext =
        tracks.isNotEmpty && currentIndex >= 0 && currentIndex < tracks.length - 1;

    QueueListTransitionResult? nextListPreview;
    if (repeatMode.jumpsToNextList && queueState.queueContext != null) {
      nextListPreview = ref
          .watch(
            _nextListPreviewProvider((
              queueState.queueContext!,
              repeatMode == NexaRepeatMode.nextListRepeatFirst,
            )),
          )
          .valueOrNull;
    }

    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: 0.72,
      minChildSize: 0.40,
      maxChildSize: 0.94,
      expand: false,
      builder: (context, scrollController) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _scrollToCurrentIfNeeded(
              scrollController,
              currentIndex,
              tracks.length,
              queueState.currentTrack?.id,
            );
          }
        });

        return NexaSurface(
          tier: NexaSurfaceTier.l3,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10.0),
                Container(
                  key: const ValueKey('playing_queue_grabber'),
                  width: 36.0,
                  height: 4.0,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(2.0),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Header Region
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                BidiText(
                                  'Playing From: $sourceTitle',
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '${tracks.length} tracks • ${totalDuration.toMinutesSeconds(padMinutes: false)}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('playing_queue_close_button'),
                            icon: const Icon(Icons.close_rounded),
                            tooltip: 'Close Queue',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 6.0,
                        children: [
                          FilledButton.tonalIcon(
                            key: const ValueKey('playing_queue_save_playlist'),
                            onPressed: tracks.isEmpty
                                ? null
                                : () => _handleSaveAsPlaylist(tracks),
                            icon: const Icon(Icons.playlist_add_rounded, size: 16),
                            label: const Text('Save as Playlist'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            key: const ValueKey('playing_queue_clear_up_next'),
                            onPressed: hasUpNext
                                ? () {
                                    HapticFeedback.lightImpact();
                                    queue.clearUpNext();
                                  }
                                : null,
                            icon: const Icon(Icons.clear_all_rounded, size: 16),
                            label: const Text('Clear Up Next'),
                            style: OutlinedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10.0),

                // Contextual Queue List (Previous + Active + Up Next + Next List Footer)
                Expanded(
                  child: tracks.isEmpty
                      ? Center(
                          child: Text(
                            'Queue is empty',
                            style: AppTypography.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ReorderableListView.builder(
                          key: const ValueKey('playing_queue_reorderable_list'),
                          scrollController: scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                          buildDefaultDragHandles: false,
                          itemCount: tracks.length,
                          onReorder: (oldIdx, newIdx) {
                            HapticFeedback.selectionClick();
                            queue.reorder(oldIdx, newIdx);
                          },
                          footer: nextListPreview != null
                              ? Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    8,
                                    12,
                                    8,
                                    8,
                                  ),
                                  child: NexaSurface(
                                    level: NexaSurfaceLevel.l2,
                                    borderRadius: BorderRadius.circular(14.0),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14.0,
                                        vertical: 10.0,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.playlist_play_rounded,
                                            size: 18,
                                            color: primary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: BidiText(
                                              'Up next list: ${nextListPreview.context.collectionTitle ?? 'Next Collection'}',
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                          itemBuilder: (context, index) {
                            final track = tracks[index];
                            final isCurrent = index == currentIndex;
                            final isPrevious =
                                currentIndex >= 0 && index < currentIndex;
                            final isUpNextBadge = index > currentIndex &&
                                queueState.playNextIds.contains(track.id);

                            final activeBg = Color.alphaBlend(
                              primary.withOpacity(0.10),
                              surfaceTokens.level2,
                            );
                            final titleColor = isCurrent
                                ? ContrastValidator.ensureContrast(
                                    primary,
                                    activeBg,
                                  )
                                : colorScheme.onSurface;

                            final rowTile = Opacity(
                              opacity: isPrevious ? 0.55 : 1.0,
                              child: Container(
                                key: isCurrent ? _currentItemKey : null,
                                margin: const EdgeInsets.only(bottom: 4.0),
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? activeBg
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: ListTile(
                                  key: ValueKey('queue_tile_${track.id}_$index'),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 2.0,
                                  ),
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(10.0),
                                    child: SizedBox(
                                      width: 42.0,
                                      height: 42.0,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          NexaArtworkImage(
                                            track: track,
                                            artworkUri: track.artworkUri,
                                            width: 42.0,
                                            height: 42.0,
                                            cacheWidth: 160,
                                            fallbackBuilder: (_) => Container(
                                              color: isCurrent
                                                  ? primary.withOpacity(0.20)
                                                  : surfaceTokens.level1,
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${index + 1}',
                                                style: AppTypography.labelSmall
                                                    .copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (isCurrent)
                                            Container(
                                              color: Colors.black
                                                  .withOpacity(0.45),
                                              alignment: Alignment.center,
                                              child: AnimatedEqualizerGlyph(
                                                color: primary,
                                                isActive: isPlaying,
                                                width: 18.0,
                                                height: 18.0,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: BidiText(
                                          track.title,
                                          style: AppTypography.bodyMedium
                                              .copyWith(
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                            color: titleColor,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isUpNextBadge) ...[
                                        const SizedBox(width: 6.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6.0,
                                            vertical: 2.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color: primary.withOpacity(0.16),
                                            borderRadius:
                                                BorderRadius.circular(6.0),
                                          ),
                                          child: Text(
                                            'Up Next',
                                            style: AppTypography.labelSmall
                                                .copyWith(
                                              color: primary,
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: BidiText(
                                    track.artist,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        track.duration.toMinutesSeconds(
                                          padMinutes: false,
                                        ),
                                        style: AppTypography.labelSmall.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6.0),
                                      ReorderableDragStartListener(
                                        key: ValueKey('queue_drag_$index'),
                                        index: index,
                                        child: Padding(
                                          padding: const EdgeInsets.all(6.0),
                                          child: Icon(
                                            Icons.drag_handle_rounded,
                                            size: 20.0,
                                            color: colorScheme.onSurfaceVariant
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    ref
                                        .read(playerNotifierProvider.notifier)
                                        .skipToIndex(index);
                                  },
                                ),
                              ),
                            );

                            if (isCurrent) {
                              return KeyedSubtree(
                                key: ValueKey('queue_item_${track.id}_$index'),
                                child: rowTile,
                              );
                            }

                            return Dismissible(
                              key: ValueKey('queue_item_${track.id}_$index'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: AlignmentDirectional.centerEnd,
                                padding: const EdgeInsetsDirectional.only(end: 20.0),
                                margin: const EdgeInsets.only(bottom: 4.0),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withOpacity(0.22),
                                  borderRadius: BorderRadius.circular(14.0),
                                ),
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                              ),
                              onDismissed: (_) {
                                queue.removeAt(index);
                                _showUndoBanner(index, track);
                              },
                              child: rowTile,
                            );
                          },
                        ),
                ),
                if (_pendingUndoTrack != null && _pendingUndoIndex != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: NexaSurface(
                      level: NexaSurfaceLevel.l2,
                      borderRadius: BorderRadius.circular(14.0),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: BidiText(
                                'Removed "${_pendingUndoTrack!.title}"',
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () {
                                final t = _pendingUndoTrack!;
                                final idx = _pendingUndoIndex!;
                                _undoTimer?.cancel();
                                setState(() {
                                  _pendingUndoTrack = null;
                                  _pendingUndoIndex = null;
                                });
                                queue.insertTrackAt(idx, t);
                              },
                              child: const Text('Undo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
