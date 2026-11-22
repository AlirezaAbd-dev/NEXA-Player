import 'package:flutter/material.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/models/track.dart';
import '../../domain/models/widget_config.dart';

/// 2x2 Square tile widget with circular progress rim and touch overlay.
class SquareWidgetCard extends StatelessWidget {
  const SquareWidgetCard({
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
    final artist = track?.artist ?? 'Select music';

    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(config.cornerRadius),
      child: Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF0F1420).withOpacity(config.backgroundOpacity),
          borderRadius: BorderRadius.circular(config.cornerRadius),
          border: Border.all(
            color: config.showGlow
                ? accent.withOpacity(0.35)
                : const Color(0x22FFFFFF),
            width: 1.0,
          ),
          boxShadow: config.showGlow
              ? [
                  BoxShadow(
                    color: accent.withOpacity(0.20),
                    blurRadius: 18.0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Artwork Placeholder / Gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: [
                      accent.withOpacity(0.25),
                      const Color(0xFF0A0E17),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.music_note_rounded,
                    size: 54,
                    color: accent.withOpacity(0.22),
                  ),
                ),
              ),
            ),

            // Subtle Glass Dark Vignette
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Color(0xCC080B12),
                    ],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),

            // Content Overlay
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: NEXA tag & Next Skip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: accent.withOpacity(0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'NEXA',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: accent,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        iconSize: 20,
                        color: Colors.white70,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 26, minHeight: 26),
                        onPressed: onNext,
                        tooltip: 'Next',
                      ),
                    ],
                  ),

                  // Center circular progress + Play/Pause button
                  Center(
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3.0,
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(accent),
                          ),
                          Container(
                            width: 40,
                            height: 40,
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
                                isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: const Color(0xFF090D14),
                                size: 24,
                              ),
                              padding: EdgeInsets.zero,
                              onPressed: onPlayPause,
                              tooltip: isPlaying ? 'Pause' : 'Play',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom: Title & Artist
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        artist,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.70),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
