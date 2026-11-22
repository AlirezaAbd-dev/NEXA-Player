import 'package:flutter/material.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/models/track.dart';
import '../../../lyrics/domain/models/lyric_line.dart';
import '../../domain/models/widget_config.dart';

/// 4x3 Karaoke / Synced Lyrics card widget for homescreen.
class KaraokeWidgetCard extends StatelessWidget {
  const KaraokeWidgetCard({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.position,
    required this.duration,
    this.lyricLines,
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
  final List<LyricLine>? lyricLines;
  final Color? accentColor;
  final WidgetConfig config;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onTap;

  int _findActiveLyricIndex() {
    final lines = lyricLines;
    if (lines == null || lines.isEmpty) return -1;
    var active = -1;
    for (var i = 0; i < lines.length; i++) {
      if (position >= lines[i].timestamp) {
        active = i;
      } else {
        break;
      }
    }
    return active;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = accentColor ?? theme.colorScheme.primary;

    final title = track?.title ?? 'No Track Playing';
    final artist = track?.artist ?? 'Select music to play';

    final totalMs = duration.inMilliseconds > 0 ? duration.inMilliseconds : 1;
    final progress = (position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    final lines = lyricLines;
    final hasLyrics = lines != null && lines.isNotEmpty;
    final activeIndex = _findActiveLyricIndex();

    final prevText = (hasLyrics && activeIndex > 0)
        ? lines[activeIndex - 1].text
        : null;
    final currentText = (hasLyrics && activeIndex >= 0)
        ? lines[activeIndex].text
        : (hasLyrics ? lines.first.text : '♪ Instrumental or seeking lyrics... ♪');
    final nextText = (hasLyrics && activeIndex >= 0 && activeIndex + 1 < lines.length)
        ? lines[activeIndex + 1].text
        : null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(config.cornerRadius),
      child: Container(
        height: 196,
        padding: const EdgeInsets.all(14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF0C101A).withOpacity(config.backgroundOpacity),
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
                    blurRadius: 20.0,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            // Header Row: Artwork + Track details + Controls
            Row(
              children: [
                // Mini Artwork
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.0),
                    color: const Color(0xFF1B2336),
                    border: Border.all(
                      color: accent.withOpacity(0.35),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.lyrics_rounded,
                      color: accent,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Track Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.60),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Controls
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 20,
                      color: Colors.white70,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onPrevious,
                      tooltip: 'Previous',
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 32,
                      height: 32,
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
                          color: const Color(0xFF0A0D14),
                          size: 18,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onPlayPause,
                        tooltip: isPlaying ? 'Pause' : 'Play',
                      ),
                    ),
                    const SizedBox(width: 2),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 20,
                      color: Colors.white70,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 28, minHeight: 28),
                      onPressed: onNext,
                      tooltip: 'Next',
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 2.5,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),

            const SizedBox(height: 10),

            // Real-Time Karaoke Lines Stream
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF080C14).withOpacity(0.65),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Previous Line
                    Text(
                      prevText ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),

                    // Active Line (Neon Glowing)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 3.0,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        currentText,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: accent,
                          shadows: [
                            Shadow(
                              color: accent.withOpacity(0.60),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),

                    // Next Line
                    Text(
                      nextText ?? '',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.40),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
