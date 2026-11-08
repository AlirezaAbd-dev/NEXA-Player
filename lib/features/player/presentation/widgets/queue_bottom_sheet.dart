import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/extensions/duration_x.dart';
import '../providers/player_providers.dart';

/// Modal bottom sheet presenting the active playback queue with drag-and-drop reordering
/// and fast track navigation.
class QueueBottomSheet extends ConsumerWidget {
  const QueueBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const QueueBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;

    final queue = ref.watch(playbackQueueProvider);
    final queueState = queue.state;
    final tracks = queueState.tracks;
    final currentIndex = queueState.currentIndex;

    final totalDuration = tracks.fold<Duration>(
      Duration.zero,
      (sum, track) => sum + track.duration,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141923) : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border.all(
          color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x60000000),
            blurRadius: 32.0,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12.0),
            Container(
              width: 36.0,
              height: 4.0,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.20),
                borderRadius: BorderRadius.circular(2.0),
              ),
            ),
            const SizedBox(height: 16.0),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Up Next Queue',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${tracks.length} tracks • ${totalDuration.toMinutesSeconds(padMinutes: false)}',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.60),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 20.0),

            // Reorderable Queue List
            Expanded(
              child: tracks.isEmpty
                  ? Center(
                      child: Text(
                        'Queue is empty',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.only(bottom: 24.0),
                      itemCount: tracks.length,
                      onReorder: (oldIdx, newIdx) {
                        queue.reorder(oldIdx, newIdx);
                      },
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isCurrent = index == currentIndex;

                        return Dismissible(
                          key: ValueKey('queue_track_${track.id}_$index'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20.0),
                            color: Colors.redAccent.withOpacity(0.2),
                            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                          ),
                          onDismissed: (_) {
                            queue.removeAt(index);
                          },
                          child: Container(
                            color: isCurrent
                                ? primary.withOpacity(isDark ? 0.12 : 0.08)
                                : Colors.transparent,
                            child: ListTile(
                              key: ValueKey('tile_${track.id}_$index'),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 2.0),
                              leading: Container(
                                width: 40.0,
                                height: 40.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  gradient: LinearGradient(
                                    colors: isCurrent
                                        ? [primary, colorScheme.secondary]
                                        : [
                                            isDark ? const Color(0xFF1E2433) : const Color(0xFFE2E8F0),
                                            isDark ? const Color(0xFF141923) : const Color(0xFFCBD5E1),
                                          ],
                                  ),
                                ),
                                child: Center(
                                  child: isCurrent
                                      ? Icon(
                                          Icons.volume_up_rounded,
                                          color: isDark ? const Color(0xFF0A0D14) : Colors.white,
                                          size: 20.0,
                                        )
                                      : Text(
                                          '${index + 1}',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: colorScheme.onSurface.withOpacity(0.60),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              title: Text(
                                track.title,
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                                  color: isCurrent ? primary : colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artist,
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.60),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    track.duration.toMinutesSeconds(padMinutes: false),
                                    style: AppTypography.labelSmall.copyWith(
                                      color: colorScheme.onSurface.withOpacity(0.50),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: Icon(
                                      Icons.drag_handle_rounded,
                                      color: colorScheme.onSurface.withOpacity(0.35),
                                    ),
                                  ),
                                ],
                              ),
                              onTap: () {
                                ref.read(playerNotifierProvider.notifier).playTrack(
                                      track,
                                      initialIndex: index,
                                    );
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
