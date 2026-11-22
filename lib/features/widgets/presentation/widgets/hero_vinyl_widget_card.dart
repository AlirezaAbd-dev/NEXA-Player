import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/models/track.dart';
import '../../domain/models/widget_config.dart';

/// 4x2 Hero Card with album sleeve, spinning vinyl disc, seekbar, and controls.
class HeroVinylWidgetCard extends StatefulWidget {
  const HeroVinylWidgetCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.accentColor,
    this.config = const WidgetConfig(),
    this.isFavorite = false,
    this.onPlayPause,
    this.onNext,
    this.onPrevious,
    this.onFavoriteToggle,
    this.onSeek,
    this.onTap,
  });

  final Track? track;
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final Color? accentColor;
  final WidgetConfig config;
  final bool isFavorite;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onFavoriteToggle;
  final ValueChanged<Duration>? onSeek;
  final VoidCallback? onTap;

  @override
  State<HeroVinylWidgetCard> createState() => _HeroVinylWidgetCardState();
}

class _HeroVinylWidgetCardState extends State<HeroVinylWidgetCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (widget.isPlaying) {
      _spinController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant HeroVinylWidgetCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    final title = widget.track?.title ?? 'No Track Playing';
    final artist = widget.track?.artist ?? 'Select music to play';
    final album = widget.track?.album ?? 'NEXA High-Res Engine';

    final totalMs = widget.duration.inMilliseconds > 0
        ? widget.duration.inMilliseconds
        : 1;
    final progress =
        (widget.position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.config.cornerRadius),
      child: Container(
        height: 196,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0D121D)
              .withOpacity(widget.config.backgroundOpacity),
          borderRadius: BorderRadius.circular(widget.config.cornerRadius),
          border: Border.all(
            color: widget.config.showGlow
                ? accent.withOpacity(0.35)
                : const Color(0x22FFFFFF),
            width: 1.0,
          ),
          boxShadow: widget.config.showGlow
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.22),
                    blurRadius: 20.0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Top Section: Album Cover + Peeking Vinyl & Track Details
            Expanded(
              child: Row(
                children: [
                  // Sleeve & Vinyl Stack
                  SizedBox(
                    width: widget.config.showVinyl ? 116 : 84,
                    height: 84,
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Peeking Vinyl Disc
                        if (widget.config.showVinyl)
                          Positioned(
                            left: 32,
                            child: AnimatedBuilder(
                              animation: _spinController,
                              builder: (context, child) {
                                return Transform.rotate(
                                  angle: _spinController.value * 2 * math.pi,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF14171F),
                                  border: Border.all(
                                    color: const Color(0xFF2A3142),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black54,
                                      blurRadius: 8.0,
                                      offset: Offset(2, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Vinyl Grooves
                                    Container(
                                      width: 62,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF222838),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFF2E364A),
                                          width: 1.0,
                                        ),
                                      ),
                                    ),
                                    // Vinyl Center Label
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: accent,
                                        border: Border.all(
                                          color: Colors.white24,
                                          width: 1.0,
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircleAvatar(
                                          radius: 4,
                                          backgroundColor: Color(0xFF0D121D),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                        // Front Album Sleeve
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.0),
                            color: const Color(0xFF1B2233),
                            border: Border.all(
                              color: accent.withOpacity(0.35),
                              width: 1.0,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 10.0,
                                offset: Offset(2, 3),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.album_rounded,
                              color: accent,
                              size: 44,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Track Metadata & Favorite Heart
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: AppTypography.titleMedium.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                widget.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: widget.isFavorite
                                    ? const Color(0xFFFF4081)
                                    : Colors.white.withOpacity(0.4),
                                size: 20,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              onPressed: widget.onFavoriteToggle,
                              tooltip: 'Favorite',
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          artist,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.85),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          album,
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10.5,
                            color: Colors.white.withOpacity(0.50),
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

            const SizedBox(height: 6),

            // Middle Section: Scrubber Progress & Timestamps
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 3.5,
                    backgroundColor: Colors.white.withOpacity(0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(widget.position),
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                    Text(
                      _formatDuration(widget.duration),
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            // Bottom Section: Playback Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: 26,
                  color: Colors.white.withOpacity(0.9),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: widget.onPrevious,
                  tooltip: 'Previous',
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withOpacity(0.45),
                        blurRadius: 10.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF090D14),
                      size: 26,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: widget.onPlayPause,
                    tooltip: widget.isPlaying ? 'Pause' : 'Play',
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 26,
                  color: Colors.white.withOpacity(0.9),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  onPressed: widget.onNext,
                  tooltip: 'Next',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
