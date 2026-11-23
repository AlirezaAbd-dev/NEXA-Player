import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Scrubbing precision gears.
enum GearShift {
  /// Normal 1x real-time scrubbing across the full track.
  normal(1.0, '1× Normal'),

  /// 0.5x precision for navigating phrases.
  fine(0.5, '0.5× Fine'),

  /// 0.1x precision for frame-accurate 100ms scrubbing.
  ultraFine(0.1, '0.1× Ultra-Fine');

  const GearShift(this.multiplier, this.label);
  final double multiplier;
  final String label;
}

/// Variable-speed tactile waveform gearshift scrubber.
/// Dragging horizontally scrubs the track; dragging downward shifts precision
/// down from 1x -> 0.5x -> 0.1x with real-time HUD pill and tick haptics.
class GearshiftWaveformScrubber extends StatefulWidget {
  const GearshiftWaveformScrubber({
    super.key,
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.onSeek,
    this.cachedAmplitudes,
    this.activeColor,
    this.onScrubbingStart,
    this.onScrubbingEnd,
    this.height = 70.0,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration> onSeek;
  final List<double>? cachedAmplitudes;
  final Color? activeColor;
  final VoidCallback? onScrubbingStart;
  final VoidCallback? onScrubbingEnd;
  final double height;

  @override
  State<GearshiftWaveformScrubber> createState() =>
      _GearshiftWaveformScrubberState();
}

class _GearshiftWaveformScrubberState extends State<GearshiftWaveformScrubber> {
  bool _isDragging = false;
  Duration _dragPosition = Duration.zero;
  Duration _initialPosition = Duration.zero;
  double _dragStartX = 0.0;
  double _dragStartY = 0.0;
  GearShift _currentGear = GearShift.normal;

  GearShift _calculateGear(double dy) {
    if (dy > 70.0) return GearShift.ultraFine;
    if (dy > 30.0) return GearShift.fine;
    return GearShift.normal;
  }

  void _onPanStart(DragStartDetails details) {
    widget.onScrubbingStart?.call();
    _isDragging = true;
    _initialPosition = widget.position;
    _dragPosition = widget.position;
    _dragStartX = details.localPosition.dx;
    _dragStartY = details.localPosition.dy;
    _currentGear = GearShift.normal;
    HapticFeedback.selectionClick();
    widget.onSeek(_dragPosition);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    if (!_isDragging || width <= 0) return;

    final dx = details.localPosition.dx - _dragStartX;
    final dy = (details.localPosition.dy - _dragStartY).clamp(0.0, 200.0);

    final newGear = _calculateGear(dy);
    if (newGear != _currentGear) {
      _currentGear = newGear;
      HapticFeedback.selectionClick();
    }

    final totalMs = widget.duration.inMilliseconds;
    if (totalMs > 0) {
      final deltaFraction = (dx / width) * _currentGear.multiplier;
      final targetMs = (_initialPosition.inMilliseconds + (totalMs * deltaFraction))
          .clamp(0.0, totalMs.toDouble())
          .round();

      setState(() {
        _dragPosition = Duration(milliseconds: targetMs);
      });
      widget.onSeek(_dragPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_isDragging) {
      widget.onSeek(_dragPosition);
      widget.onScrubbingEnd?.call();
      setState(() {
        _isDragging = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.activeColor ?? theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    final activeDuration = _isDragging ? _dragPosition : widget.position;
    final totalDuration = widget.duration;
    final progress = totalDuration.inMilliseconds > 0
        ? (activeDuration.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Gear HUD Indicator (visible when scrubbing)
            AnimatedOpacity(
              opacity: _isDragging ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 150),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: NexaSurface(
                  level: NexaSurfaceLevel.l3,
                  borderRadius: BorderRadius.circular(16.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _currentGear == GearShift.ultraFine
                              ? Icons.slow_motion_video_rounded
                              : _currentGear == GearShift.fine
                                  ? Icons.speed_rounded
                                  : Icons.play_arrow_rounded,
                          size: 14.0,
                          color: primary,
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          '${_currentGear.label} • ${activeDuration.toMinutesSeconds()}',
                          style: surfaceTokens.telemetryTextStyle.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Waveform Scrubber Touch Canvas with Screen Reader Semantics
            Semantics(
              slider: true,
              label: 'Waveform scrubber',
              value: '${activeDuration.toMinutesSeconds()} of ${totalDuration.toMinutesSeconds()}',
              increasedValue: (activeDuration + const Duration(seconds: 10)).clamp(Duration.zero, totalDuration).toMinutesSeconds(),
              decreasedValue: (activeDuration - const Duration(seconds: 10)).clamp(Duration.zero, totalDuration).toMinutesSeconds(),
              onIncrease: () {
                final next = (widget.position + const Duration(seconds: 10)).clamp(Duration.zero, widget.duration);
                widget.onSeek(next);
              },
              onDecrease: () {
                final prev = (widget.position - const Duration(seconds: 10)).clamp(Duration.zero, widget.duration);
                widget.onSeek(prev);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onPanStart,
                onHorizontalDragUpdate: (details) => _onPanUpdate(details, width),
                onHorizontalDragEnd: _onPanEnd,
                onVerticalDragStart: _onPanStart,
                onVerticalDragUpdate: (details) => _onPanUpdate(details, width),
                onVerticalDragEnd: _onPanEnd,
                child: SizedBox(
                  height: widget.height,
                  width: width,
                  child: CustomPaint(
                    painter: _WaveformPainter(
                      progress: progress,
                      amplitudes: widget.cachedAmplitudes,
                      activeColor: primary,
                      inactiveColor: onSurface.withOpacity(0.18),
                      thumbColor: primary,
                      isDragging: _isDragging,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4.0),

            // Timestamps Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  activeDuration.toMinutesSeconds(),
                  style: surfaceTokens.telemetryTextStyle.copyWith(
                    color: _isDragging ? primary : onSurfaceVariant,
                    fontWeight: _isDragging ? FontWeight.bold : FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
                Text(
                  '-${(totalDuration - activeDuration).toMinutesSeconds()}',
                  style: surfaceTokens.telemetryTextStyle.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.progress,
    required this.amplitudes,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.isDragging,
  });

  final double progress;
  final List<double>? amplitudes;
  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;
  final bool isDragging;

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 48;
    final totalWidth = size.width;
    final barWidth = (totalWidth / barCount) * 0.60;
    final barSpacing = (totalWidth / barCount) * 0.40;
    final centerY = size.height / 2;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    final amplitudesList = amplitudes;
    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing) + barWidth / 2;
      final barFraction = i / barCount;
      final isActive = barFraction <= progress;

      double amp = 0.4;
      if (amplitudesList != null && amplitudesList.isNotEmpty) {
        final sampleIndex = (i * amplitudesList.length ~/ barCount).clamp(0, amplitudesList.length - 1);
        amp = amplitudesList[sampleIndex].clamp(0.15, 1.0);
      } else {
        // Natural audio aesthetic fallback
        amp = (0.25 + 0.65 * math.sin(i * 0.35).abs()).clamp(0.18, 0.95);
      }

      final halfH = (size.height * 0.42 * amp).clamp(3.0, size.height * 0.45);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, centerY), width: barWidth, height: halfH * 2),
        const Radius.circular(3.0),
      );

      canvas.drawRRect(rrect, isActive ? activePaint : inactivePaint);
    }

    // Thumb Playhead
    final thumbX = totalWidth * progress;
    final thumbRadius = isDragging ? 7.0 : 5.0;
    final thumbPaint = Paint()..color = thumbColor;
    final glowPaint = Paint()
      ..color = thumbColor.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0);

    canvas.drawCircle(Offset(thumbX, centerY), thumbRadius + 3.0, glowPaint);
    canvas.drawCircle(Offset(thumbX, centerY), thumbRadius, thumbPaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDragging != isDragging ||
        oldDelegate.activeColor != activeColor;
  }
}
