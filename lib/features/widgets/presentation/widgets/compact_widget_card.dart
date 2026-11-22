import 'package:flutter/material.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/models/track.dart';
import '../../domain/models/widget_config.dart';

/// 4x1 Compact horizontal pill widget for homescreen and desktop docks.
class CompactWidgetCard extends StatelessWidget {
  const CompactWidgetCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.accentColor,
    this.config = const WidgetConfig(),
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onTap,
  });

  final Track? track;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Color? accentColor;
  final WidgetConfig config;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    final title = track?.title ?? 'No Track Playing';
    final artist = track?.artist ?? 'Select music to play';

    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(config.cornerRadius),
      child: Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0F141F).withOpacity(config.backgroundOpacity),
          borderRadius: BorderRadius.circular(config.cornerRadius),
          border: Border.all(
            color: config.showGlow
                ? accent.withOpacity(0.35)
                : const Color(0x20FFFFFF),
            width: 1.0,
          ),
          boxShadow: config.showGlow
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.20),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // 1. Mini Vinyl / Artwork Thumb
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: const Color(0xFF1E2538),
                    border: Border.all(
                      color: accent.withOpacity(0.3),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.album_rounded,
                      color: accent,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // 3. Compact Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 22,
                      color: Colors.white.withOpacity(0.85),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: onPrevious,
                      tooltip: 'Previous',
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.40),
                            blurRadius: 8.0,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: const Color(0xFF0A0D14),
                          size: 20,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onPlayPause,
                        tooltip: isPlaying ? 'Pause' : 'Play',
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 22,
                      color: Colors.white.withOpacity(0.85),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      onPressed: onNext,
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ],
            ),

            // 4. Subtle Bottom Progress Line
            ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
