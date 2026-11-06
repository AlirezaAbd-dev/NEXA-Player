import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/design_system/glass_tokens.dart';
import '../../shared/widgets/glass/glass_card.dart';
import '../routes.dart';

/// Semantic Keys matching E2EKeys.
abstract final class _MiniPlayerKeys {
  static const Key miniPlayerSlot = ValueKey('mini_player_slot');
  static const Key miniPlayerPlayPause = ValueKey('mini_player_play_pause');
}

/// Persistent glassmorphism mini-player slot anchored directly above the navigation bar.
class MiniPlayerSlot extends StatefulWidget {
  const MiniPlayerSlot({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd • Daft Punk',
    this.progress = 0.42,
    this.isPlaying = true,
    this.onPlayPause,
    this.onTap,
  });

  final String title;
  final String artist;
  final double progress;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;

  @override
  State<MiniPlayerSlot> createState() => _MiniPlayerSlotState();
}

class _MiniPlayerSlotState extends State<MiniPlayerSlot> {
  late bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
  }

  @override
  void didUpdateWidget(MiniPlayerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      _isPlaying = widget.isPlaying;
    }
  }

  void _handlePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    widget.onPlayPause?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: GlassCard(
        key: _MiniPlayerKeys.miniPlayerSlot,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
        blur: GlassTokens.blurDefault,
        opacity: GlassTokens.opacityMedium,
        onTap: widget.onTap ?? () => context.push(AppRoutes.player),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  // 1. Mini Album Art with Glass Border
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.8),
                          colorScheme.secondary.withOpacity(0.5),
                        ],
                      ),
                      boxShadow: GlassTokens.elevationLow,
                    ),
                    child: const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 24.0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // 2. Track Title & Artist
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: AppTypography.titleMedium.copyWith(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          widget.artist,
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // 3. Like / Heart Button
                  IconButton(
                    icon: Icon(
                      Icons.favorite_rounded,
                      color: colorScheme.primary,
                      size: 22.0,
                    ),
                    onPressed: () {},
                    tooltip: 'Like',
                  ),

                  // 4. Play / Pause Button
                  IconButton(
                    key: _MiniPlayerKeys.miniPlayerPlayPause,
                    icon: Icon(
                      _isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: colorScheme.primary,
                      size: 34.0,
                    ),
                    onPressed: _handlePlayPause,
                    tooltip: _isPlaying ? 'Pause' : 'Play',
                  ),
                ],
              ),
            ),

            // 5. Linear Progress Micro-Seek Indicator
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(GlassTokens.radiusMedium),
                bottomRight: Radius.circular(GlassTokens.radiusMedium),
              ),
              child: LinearProgressIndicator(
                value: widget.progress.clamp(0.0, 1.0),
                minHeight: 2.5,
                backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
