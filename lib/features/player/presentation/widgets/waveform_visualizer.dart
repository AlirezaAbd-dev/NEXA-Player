import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/extensions/duration_x.dart';

/// Interactive, seekable audio waveform visualizer.
///
/// Renders pre-computed or generated amplitude bars with active glow,
/// live playhead progress, and smooth touch-scrubbing.
class WaveformVisualizer extends StatefulWidget {
  const WaveformVisualizer({
    super.key,
    required this.position,
    required this.duration,
    this.isPlaying = false,
    this.onSeek,
    this.activeColor,
    this.inactiveColor,
    this.barCount = 56,
    this.height = 48.0,
    this.trackSeed = 'default_seed',
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration>? onSeek;
  final Color? activeColor;
  final Color? inactiveColor;
  final int barCount;
  final double height;
  final String trackSeed;

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late List<double> _amplitudes;
  double? _dragRatio;
  late final AnimationController _pulseController;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _generateAmplitudes();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.isPlaying && !_isTest) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackSeed != oldWidget.trackSeed ||
        widget.barCount != oldWidget.barCount) {
      _generateAmplitudes();
    }
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && !_isTest) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _generateAmplitudes() {
    final seed = widget.trackSeed.codeUnits.fold(0, (acc, c) => acc + c) +
        widget.duration.inSeconds;
    final random = math.Random(seed);

    _amplitudes = List.generate(widget.barCount, (i) {
      // Natural music waveform curve: lower at intro and outro, fuller in middle
      final normalizedPos = i / widget.barCount;
      final envelope = math.sin(normalizedPos * math.pi);
      final raw = 0.20 + (random.nextDouble() * 0.75 * envelope);
      return raw.clamp(0.12, 1.0);
    });
  }

  void _handleSeek(Offset localPosition, double width) {
    if (width <= 0) return;
    final ratio = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _dragRatio = ratio);
  }

  void _commitSeek(double width) {
    if (_dragRatio != null && widget.onSeek != null) {
      final totalMs = widget.duration.inMilliseconds > 0
          ? widget.duration.inMilliseconds
          : 230000;
      final targetMs = (totalMs * _dragRatio!).toInt();
      widget.onSeek!(Duration(milliseconds: targetMs));
    }
    setState(() => _dragRatio = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final active = widget.activeColor ?? colorScheme.primary;
    final inactive = widget.inactiveColor ??
        (isDark ? const Color(0x30FFFFFF) : const Color(0x20000000));

    final totalMs = widget.duration.inMilliseconds > 0
        ? widget.duration.inMilliseconds
        : 230000;
    final currentMs = widget.position.inMilliseconds.clamp(0, totalMs);
    final progress = _dragRatio ?? (currentMs / totalMs).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) => _handleSeek(details.localPosition, width),
          onHorizontalDragUpdate: (details) => _handleSeek(details.localPosition, width),
          onHorizontalDragEnd: (_) => _commitSeek(width),
          onTapDown: (details) {
            _handleSeek(details.localPosition, width);
            _commitSeek(width);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return SizedBox(
                    height: widget.height,
                    width: width,
                    child: CustomPaint(
                      painter: _WaveformPainter(
                        amplitudes: _amplitudes,
                        progress: progress,
                        activeColor: active,
                        inactiveColor: inactive,
                        pulse: widget.isPlaying && !_isTest
                            ? _pulseController.value
                            : 0.0,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 6.0),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.position.toMinutesSeconds(padMinutes: false),
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      widget.duration.toMinutesSeconds(padMinutes: false),
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.pulse,
  });

  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barCount = amplitudes.length;
    const totalSpacingRatio = 0.40; // Spacing takes 40% of bar slot
    final slotWidth = size.width / barCount;
    final barWidth = math.max(1.5, slotWidth * (1.0 - totalSpacingRatio));
    final barRadius = Radius.circular(barWidth / 2.0);

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final barRatio = (i + 0.5) / barCount;
      final isActive = barRatio <= progress;

      double amp = amplitudes[i];
      // Subtle pulse on active bars near playhead
      if (isActive && (progress - barRatio).abs() < 0.15) {
        amp = (amp * (1.0 + (pulse * 0.18))).clamp(0.12, 1.0);
      }

      final barHeight = math.max(4.0, size.height * amp);
      final left = (i * slotWidth) + ((slotWidth - barWidth) / 2.0);
      final top = (size.height - barHeight) / 2.0;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        barRadius,
      );

      canvas.drawRRect(rect, isActive ? activePaint : inactivePaint);
    }

    // Playhead glowing indicator circle
    final playheadX = (size.width * progress).clamp(0.0, size.width);
    final playheadGlow = Paint()
      ..color = activeColor.withOpacity(0.40)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawCircle(Offset(playheadX, size.height / 2.0), 5.0, playheadGlow);
    canvas.drawCircle(Offset(playheadX, size.height / 2.0), 3.0, activePaint);
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulse != pulse ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.amplitudes != amplitudes;
  }
}
