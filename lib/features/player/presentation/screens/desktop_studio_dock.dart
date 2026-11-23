import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../../equalizer/presentation/providers/equalizer_providers.dart';
import '../../../player/presentation/providers/player_providers.dart';

/// Semantic Keys for DesktopStudioDock testing.
abstract final class DesktopStudioDockKeys {
  static const Key root = ValueKey('desktop_studio_dock');
  static const Key quickEqButton = ValueKey('studio_dock_quick_eq');
  static const Key queueList = ValueKey('studio_dock_queue_list');
}

/// Dockable Right-Hand Studio Inspector for wide desktop viewports (width >= 1200dp).
/// Features live track artwork, micro-spline EQ preview, and Up Next queue peek.
class DesktopStudioDock extends ConsumerWidget {
  const DesktopStudioDock({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;
    final eqState = ref.watch(equalizerNotifierProvider);
    final queue = ref.watch(playbackQueueProvider).state.tracks;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = theme.extension<NexaSurfaceTokens>();

    final telemetryStyle = surfaceTokens?.telemetryTextStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontFeatures: [FontFeature.tabularFigures()],
        );

    return NexaSurface(
      key: DesktopStudioDockKeys.root,
      tier: NexaSurfaceTier.l1,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
      child: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Studio Inspector & Status Dot
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'STUDIO INSPECTOR',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                  ),
                  child: Text(
                    '96k / 24b',
                    style: telemetryStyle.copyWith(
                      fontSize: 10,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Live Track Artwork & Metadata
            if (currentTrack != null) ...[
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                    ),
                    child: Icon(
                      Icons.album_rounded,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTrack.title,
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentTrack.artist,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Acoustic Engine & Quick EQ Preview
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACOUSTIC ENGINE',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                InkWell(
                  key: DesktopStudioDockKeys.quickEqButton,
                  onTap: () => context.push(AppRoutes.equalizer),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          'Open EQ',
                          style: AppTypography.labelSmall.copyWith(
                            color: colorScheme.primary,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 9,
                          color: colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Mini Spline Curve Representation
            NexaSurface(
              tier: NexaSurfaceTier.l2,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '10-Band Parametric EQ',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        eqState.isEnabled ? 'ACTIVE' : 'FLAT',
                        style: telemetryStyle.copyWith(
                          fontSize: 9,
                          color: eqState.isEnabled
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.4),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Visual Frequency Bars
                  SizedBox(
                    height: 28,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(10, (i) {
                        final gain = i < eqState.bandGains.length
                            ? eqState.bandGains[i]
                            : 0.0;
                        final normalizedHeight =
                            (((gain + 12.0) / 24.0) * 24.0).clamp(4.0, 24.0);
                        return Container(
                          width: 4,
                          height: normalizedHeight,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Up Next Queue Peek
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'UP NEXT QUEUE',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontSize: 10,
                  ),
                ),
                Text(
                  '${queue.length} Tracks',
                  style: telemetryStyle.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Up Next list
            Expanded(
              child: queue.isEmpty
                  ? Center(
                      child: Text(
                        'Queue is empty',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    )
                  : ListView.builder(
                      key: DesktopStudioDockKeys.queueList,
                      itemCount: queue.length.clamp(0, 6),
                      itemBuilder: (context, index) {
                        final t = queue[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(playerNotifierProvider.notifier)
                                  .playTrack(t);
                            },
                            borderRadius:
                                BorderRadius.circular(GlassTokens.radiusSmall),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    '${index + 1}',
                                    style: telemetryStyle.copyWith(
                                      fontSize: 11,
                                      color: colorScheme.onSurface
                                          .withOpacity(0.4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.title,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          t.artist,
                                          style: AppTypography.labelSmall
                                              .copyWith(
                                            color: colorScheme.onSurface
                                                .withOpacity(0.5),
                                            fontSize: 10,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Keyboard Shortcuts Legend
            NexaSurface(
              tier: NexaSurfaceTier.l2,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildShortcutBadge(context, 'Space', 'Play/Pause'),
                  _buildShortcutBadge(context, 'J/L', '±10s'),
                  _buildShortcutBadge(context, 'M', 'Mute'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutBadge(
      BuildContext context, String keyText, String desc) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            keyText,
            style: const TextStyle(
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          desc,
          style: TextStyle(
            fontSize: 9,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}
