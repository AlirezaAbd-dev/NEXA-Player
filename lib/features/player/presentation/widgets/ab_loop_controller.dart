import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/design_system/nexa_surface_tokens.dart';
import '../../../../core/extensions/duration_x.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../data/datasources/track_bookmark_dao.dart';
import '../providers/player_providers.dart';

/// Semantic Keys for ABLoopController testing.
abstract final class ABLoopControllerKeys {
  static const Key root = ValueKey('ab_loop_controller');
  static const Key setPinA = ValueKey('set_pin_a');
  static const Key setPinB = ValueKey('set_pin_b');
  static const Key toggleLoop = ValueKey('toggle_loop');
  static const Key clearLoop = ValueKey('clear_loop');
  static const Key openInTrimmer = ValueKey('open_in_trimmer');
}

/// Borderless studio widget for waveform micro-bookmarks and precision A-B looping.
class ABLoopController extends ConsumerWidget {
  const ABLoopController({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerNotifierProvider);
    final loopRange = ref.watch(abLoopNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = theme.extension<NexaSurfaceTokens>();

    final telemetryStyle = surfaceTokens?.telemetryTextStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontFeatures: [FontFeature.tabularFigures()],
        );

    final currentPos = playerState.position;
    final pinAStr = loopRange.start != null ? loopRange.start!.toMinutesSeconds() : '--:--';
    final pinBStr = loopRange.end != null ? loopRange.end!.toMinutesSeconds() : '--:--';

    return NexaSurface(
      key: ABLoopControllerKeys.root,
      tier: NexaSurfaceTier.l2,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with active status
          Row(
            children: [
              Icon(
                Icons.repeat_one_rounded,
                size: 16,
                color: loopRange.isEnabled && loopRange.isValid
                    ? colorScheme.primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                'A-B LOOP PINNING',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: loopRange.isEnabled && loopRange.isValid
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (loopRange.isValid) ...[
                Text(
                  '$pinAStr ⇄ $pinBStr (${loopRange.loopDuration.toMinutesSeconds()})',
                  style: telemetryStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Clear Button
              if (loopRange.start != null || loopRange.end != null)
                InkWell(
                  key: ABLoopControllerKeys.clearLoop,
                  onTap: () {
                    ref.read(abLoopNotifierProvider.notifier).clear();
                  },
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Actions row: Set Pin A, Set Pin B, Toggle, Open Trimmer
          Row(
            children: [
              // Pin A button
              Expanded(
                child: _buildPinButton(
                  context,
                  key: ABLoopControllerKeys.setPinA,
                  label: 'Pin A [ $pinAStr ]',
                  isSet: loopRange.start != null,
                  onTap: () {
                    ref.read(abLoopNotifierProvider.notifier).setPinA(currentPos);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Pin B button
              Expanded(
                child: _buildPinButton(
                  context,
                  key: ABLoopControllerKeys.setPinB,
                  label: 'Pin B [ $pinBStr ]',
                  isSet: loopRange.end != null,
                  onTap: () {
                    ref.read(abLoopNotifierProvider.notifier).setPinB(currentPos);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Loop toggle
              IconButton(
                key: ABLoopControllerKeys.toggleLoop,
                icon: Icon(
                  loopRange.isEnabled
                      ? Icons.all_inclusive_rounded
                      : Icons.loop_rounded,
                  color: loopRange.isEnabled && loopRange.isValid
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.4),
                  size: 20,
                ),
                tooltip: loopRange.isEnabled ? 'Disable Loop' : 'Enable Loop',
                onPressed: loopRange.isValid
                    ? () {
                        ref.read(abLoopNotifierProvider.notifier).toggleEnabled();
                      }
                    : null,
              ),

              // Open in Trimmer
              if (loopRange.isValid)
                IconButton(
                  key: ABLoopControllerKeys.openInTrimmer,
                  icon: Icon(
                    Icons.content_cut_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  tooltip: 'Open in Ringtone Trimmer',
                  onPressed: () {
                    context.push(AppRoutes.ringtoneTrimmer);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPinButton(
    BuildContext context, {
    required Key key,
    required String label,
    required bool isSet,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: isSet
              ? colorScheme.primary.withOpacity(0.18)
              : colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontSize: 11,
              fontWeight: isSet ? FontWeight.bold : FontWeight.w500,
              color: isSet
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
