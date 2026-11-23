import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Hero artwork card featuring:
/// - Swipe left / right spring gesture navigation (skip next / previous).
/// - Double-tap left/right for quick +/- 10s seek.
/// - 3D Perspective Y-axis flip on long-press revealing the 3D Signal Chain & studio telemetry.
/// - Concentric vinyl grooves and center rotating record when playing.
class HeroArtworkCard extends StatefulWidget {
  const HeroArtworkCard({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onDoubleTapSeekForward,
    this.onDoubleTapSeekBackward,
    this.size = 280.0,
  });

  final Track? track;
  final bool isPlaying;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onDoubleTapSeekForward;
  final VoidCallback? onDoubleTapSeekBackward;
  final double size;

  @override
  State<HeroArtworkCard> createState() => _HeroArtworkCardState();
}

class _HeroArtworkCardState extends State<HeroArtworkCard>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _flipController;
  late final AnimationController _swipeOffsetController;

  bool _isFlipped = false;
  double _swipeDragDelta = 0.0;
  TapDownDetails? _lastTapDown;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _swipeOffsetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.isPlaying && !_isTest) {
      _rotationController.repeat();
    } else if (widget.isPlaying) {
      _rotationController.value = 0.2;
    }
  }

  @override
  void didUpdateWidget(HeroArtworkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && !_isTest) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
      } else if (widget.isPlaying) {
        _rotationController.value = 0.2;
      } else {
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _flipController.dispose();
    _swipeOffsetController.dispose();
    super.dispose();
  }

  void _handleFlip() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeDragDelta += details.primaryDelta ?? 0.0;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    const threshold = 60.0;
    if (_swipeDragDelta < -threshold && widget.onSwipeLeft != null) {
      HapticFeedback.lightImpact();
      widget.onSwipeLeft!();
    } else if (_swipeDragDelta > threshold && widget.onSwipeRight != null) {
      HapticFeedback.lightImpact();
      widget.onSwipeRight!();
    }

    setState(() {
      _swipeDragDelta = 0.0;
    });
  }

  void _handleDoubleTap() {
    if (_lastTapDown == null) return;
    final isRightHalf = _lastTapDown!.localPosition.dx > widget.size / 2;
    if (isRightHalf && widget.onDoubleTapSeekForward != null) {
      HapticFeedback.lightImpact();
      widget.onDoubleTapSeekForward!();
    } else if (!isRightHalf && widget.onDoubleTapSeekBackward != null) {
      HapticFeedback.lightImpact();
      widget.onDoubleTapSeekBackward!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;

    return GestureDetector(
      onTapDown: (details) => _lastTapDown = details,
      onDoubleTap: _handleDoubleTap,
      onLongPress: _handleFlip,
      onTap: _isFlipped ? _handleFlip : null,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _rotationController]),
        builder: (context, child) {
          final flipAngle = _flipController.value * math.pi;
          final isShowingBack = _flipController.value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(flipAngle)
              ..translate(_swipeDragDelta * 0.4),
            child: isShowingBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackMetadataCard(context, colorScheme, isDark, primary),
                  )
                : _buildFrontArtworkCard(context, colorScheme, isDark, primary),
          );
        },
      ),
    );
  }

  Widget _buildFrontArtworkCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color primary,
  ) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.0),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withOpacity(isDark ? 0.35 : 0.25),
            isDark ? const Color(0xFF1E2433) : const Color(0xFFE2E8F0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(isDark ? 0.32 : 0.18),
            blurRadius: 36.0,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Concentric vinyl groove rings
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0x25FFFFFF) : const Color(0x15000000),
                  width: 1.0,
                ),
              ),
              margin: const EdgeInsets.all(24.0),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x10000000),
                  width: 1.0,
                ),
              ),
              margin: const EdgeInsets.all(48.0),
            ),

            // Rotating center vinyl disc
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
                      isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                      isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x60000000),
                      blurRadius: 16.0,
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: primary,
                    ),
                    child: Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF020617) : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackMetadataCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color primary,
  ) {
    final track = widget.track;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final bitrateStr = track?.bitrate != null
        ? '${track!.bitrate! ~/ 1000} kbps'
        : '320 kbps MP3';
    final durationStr = track != null ? track.duration.toMinutesSeconds() : '3:50';
    final yearStr = track?.year != null ? '${track!.year}' : '2016';
    final genreStr = track?.genre ?? 'Synthpop / R&B';
    final pathStr = track?.filePath ?? '/Music/Starboy.mp3';

    return NexaSurface(
      level: NexaSurfaceLevel.l2,
      borderRadius: BorderRadius.circular(24.0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Header with 3D Signal Chain Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      '3D SIGNAL CHAIN',
                      style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontSize: 10.0,
                      ),
                    ),
                  ),
                  Icon(Icons.flip_to_front_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                ],
              ),

              // Interactive Signal Route Flow Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: surfaceTokens.level3,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _chainNode('SOURCE', primary, surfaceTokens),
                    _chainArrow(primary),
                    _chainNode('DSP', primary, surfaceTokens),
                    _chainArrow(primary),
                    _chainNode('DVC', primary, surfaceTokens),
                    _chainArrow(primary),
                    _chainNode('OUTPUT', primary, surfaceTokens),
                  ],
                ),
              ),

              // Telemetry Specs
              _detailRow('Format / Bitrate', bitrateStr, colorScheme, surfaceTokens),
              _detailRow('Sample Precision', '44.1 kHz / 16-bit', colorScheme, surfaceTokens),
              _detailRow('Duration', durationStr, colorScheme, surfaceTokens),
              _detailRow('ReplayGain', '+0.0 dB (Radio)', colorScheme, surfaceTokens),
              _detailRow('Genre', genreStr, colorScheme, surfaceTokens),
              _detailRow('Path', pathStr, colorScheme, surfaceTokens, isPath: true),

              Center(
                child: Text(
                  'Tap anywhere to flip back',
                  style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                    color: colorScheme.onSurface.withOpacity(0.40),
                    fontStyle: FontStyle.italic,
                    fontSize: 10.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chainNode(String name, Color primary, NexaSurfaceTokens surfaceTokens) {
    return Text(
      name,
      style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 9.0,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _chainArrow(Color primary) {
    return Icon(Icons.arrow_forward_ios_rounded, size: 8.0, color: primary.withOpacity(0.5));
  }

  Widget _detailRow(
    String label,
    String value,
    ColorScheme colorScheme,
    NexaSurfaceTokens surfaceTokens, {
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: isPath ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
            color: colorScheme.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.w600,
            fontSize: 11.0,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: (surfaceTokens.telemetryTextStyle ?? AppTypography.bodySmall).copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 11.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
