import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/theme/dynamic_palette_providers.dart';
import '../../../../shared/models/track.dart';
import '../../../player/presentation/providers/player_providers.dart';

/// Interactive preview and testing canvas for the NEXA Wear OS / Smartwatch Companion.
class WearCompanionScreen extends ConsumerStatefulWidget {
  const WearCompanionScreen({super.key});

  @override
  ConsumerState<WearCompanionScreen> createState() =>
      _WearCompanionScreenState();
}

class _WearCompanionScreenState extends ConsumerState<WearCompanionScreen> {
  bool _isRound = true;

  static const Track _sampleTrack = Track(
    id: 'wear_sample',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 50),
  );

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final isPlaying = playerState.isPlaying;
    final track = playerState.currentTrack ?? _sampleTrack;
    final isFavorite = track.isFavorite;

    final isDynamicEnabled = ref.watch(dynamicThemeEnabledProvider);
    final dynamicPalette = ref.watch(activeDynamicPaletteProvider);
    final accent = isDynamicEnabled
        ? dynamicPalette.primary
        : Theme.of(context).colorScheme.primary;

    final totalMs = playerState.duration.inMilliseconds > 0
        ? playerState.duration.inMilliseconds
        : 1;
    final progress =
        (playerState.position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFF070A0F),
      appBar: AppBar(
        title: const Text('Wear OS Smartwatch Hub'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isRound
                ? Icons.radio_button_checked_rounded
                : Icons.crop_square_rounded),
            tooltip: _isRound ? 'Switch to Square Bezel' : 'Switch to Round Bezel',
            onPressed: () {
              setState(() => _isRound = !_isRound);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          children: [
            // 1. Wear OS Smartwatch Physical Enclosure Preview
            Center(
              child: Container(
                width: 340,
                height: 340,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  shape: _isRound ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: _isRound ? null : BorderRadius.circular(44.0),
                  color: const Color(0xFF141A29),
                  border: Border.all(
                    color: const Color(0xFF2B354C),
                    width: 4.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withOpacity(0.20),
                      blurRadius: 36.0,
                      spreadRadius: 4.0,
                    ),
                    const BoxShadow(
                      color: Colors.black87,
                      blurRadius: 20.0,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_isRound ? 170.0 : 36.0),
                  child: Container(
                    color: Colors.black, // Pure AMOLED watch display
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Bezel Circular Progress Scrubber
                        if (_isRound)
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _WearBezelProgressPainter(
                                progress: progress,
                                accentColor: accent,
                              ),
                            ),
                          ),

                        // Wrist UI Layout
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Bar: Mini Time & Favorite Status
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '10:42',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    isFavorite
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 13,
                                    color: isFavorite ? Colors.redAccent : accent,
                                  ),
                                ],
                              ),

                              // Center: Artwork Thumb & Title
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFF192236),
                                      border: Border.all(
                                        color: accent.withOpacity(0.40),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.album_rounded,
                                        color: accent,
                                        size: 28,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    track.title,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    track.artist,
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                      color: Colors.white.withOpacity(0.60),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),

                              // Bottom Controls Row
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.skip_previous_rounded),
                                    iconSize: 22,
                                    color: Colors.white70,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(playerNotifierProvider.notifier)
                                          .skipPrevious();
                                    },
                                    tooltip: 'Previous',
                                  ),
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accent,
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.withOpacity(0.40),
                                          blurRadius: 10.0,
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.black,
                                        size: 24,
                                      ),
                                      padding: EdgeInsets.zero,
                                      onPressed: () {
                                        HapticFeedback.mediumImpact();
                                        final notifier = ref.read(
                                            playerNotifierProvider.notifier);
                                        if (isPlaying) {
                                          notifier.pause();
                                        } else {
                                          notifier.play();
                                        }
                                      },
                                      tooltip: isPlaying ? 'Pause' : 'Play',
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.skip_next_rounded),
                                    iconSize: 22,
                                    color: Colors.white70,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                        minWidth: 32, minHeight: 32),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      ref
                                          .read(playerNotifierProvider.notifier)
                                          .skipNext();
                                    },
                                    tooltip: 'Next',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Bezel Mode Switcher & Quick Information Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1420),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.watch_rounded, color: accent, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Wear OS Remote MediaSession',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _isRound ? 'CIRCULAR (450px)' : 'SQUARE (390px)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compatible with Galaxy Watch 4/5/6/7, Pixel Watch 1/2/3, and all Wear OS 3+ devices. Playback controls, metadata sync, and volume scrubbing route directly through Android MediaBrowserService and Bluetooth LE.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.65),
                      height: 1.4,
                    ),
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

/// Custom painter rendering the circular bezel progress rim around the watch edge.
class _WearBezelProgressPainter extends CustomPainter {
  const _WearBezelProgressPainter({
    required this.progress,
    required this.accentColor,
  });

  final double progress;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 4.0;

    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final progressPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Background track ring
    canvas.drawCircle(center, radius, trackPaint);

    // Active progress arc starting at top (-pi/2)
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WearBezelProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accentColor != accentColor;
  }
}
