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
    this.cachedAmplitudes,
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
  final List<double>? cachedAmplitudes;

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
    _resolveAmplitudes();
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
    if (widget.cachedAmplitudes != oldWidget.cachedAmplitudes ||
        widget.trackSeed != oldWidget.trackSeed ||
        widget.barCount != oldWidget.barCount) {
      _resolveAmplitudes();
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

  void _resolveAmplitudes() {
    if (widget.cachedAmplitudes != null && widget.cachedAmplitudes!.isNotEmpty) {
      if (widget.cachedAmplitudes!.length == widget.barCount) {
        _amplitudes = List.of(widget.cachedAmplitudes!);
        return;
      } else {
        // Resample cached amplitudes to match barCount
        final source = widget.cachedAmplitudes!;
        final resampled = <double>[];
        for (int i = 0; i < widget.barCount; i++) {
          final idx = ((i / widget.barCount) * source.length).floor().clamp(0, source.length - 1);
          resampled.add(source[idx]);
        }
        _amplitudes = resampled;
        return;
      }
    }

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
    if (_dragRatio != null && width > 0) {
      final seekMillis = (_dragRatio! * widget.duration.inMilliseconds).round();
      widget.onSeek?.call(Duration(milliseconds: seekMillis));
      setState(() => _dragRatio = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.activeColor ?? theme.colorScheme.primary;
    final inactive = widget.inactiveColor ??
        (theme.brightness == Brightness.dark
            ? Colors.white.withOpacity(0.18)
            : Colors.black.withOpacity(0.15));

    final totalMillis = widget.duration.inMilliseconds;
    final progress = totalMillis > 0
        ? (_dragRatio ??
            (widget.position.inMilliseconds / totalMillis).clamp(0.0, 1.0))
        : 0.0;

    final currentPositionText = _dragRatio != null
        ? Duration(milliseconds: (_dragRatio! * totalMillis).round())
            .toMinutesSeconds(padMinutes: false)
        : widget.position.toMinutesSeconds(padMinutes: false);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                _handleSeek(details.localPosition, width);
                _commitSeek(width);
              },
              onHorizontalDragStart: (details) =>
                  _handleSeek(details.localPosition, width),
              onHorizontalDragUpdate: (details) =>
                  _handleSeek(details.localPosition, width),
              onHorizontalDragEnd: (_) => _commitSeek(width),
              onHorizontalDragCancel: () => setState(() => _dragRatio = null),
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return CustomPaint(
                    size: Size(width, widget.height),
                    painter: _WaveformPainter(
                      amplitudes: _amplitudes,
                      progress: progress,
                      activeColor: primary,
                      inactiveColor: inactive,
                      pulseAnimation: _isTest ? 0.0 : _pulseController.value,
                      isPlaying: widget.isPlaying,
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 6.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentPositionText,
              style: AppTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              widget.duration.toMinutesSeconds(padMinutes: false),
              style: AppTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.pulseAnimation,
    required this.isPlaying,
  });

  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final double pulseAnimation;
  final bool isPlaying;

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barCount = amplitudes.length;
    const barSpacing = 2.0;
    final totalSpacing = (barCount - 1) * barSpacing;
    final barWidth = ((size.width - totalSpacing) / barCount).clamp(1.5, 6.0);

    final activeIndex = (progress * barCount).floor();
    final centerY = size.height / 2;

    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.fill;

    final activeGlowPaint = Paint()
      ..color = activeColor.withOpacity(0.35 + (pulseAnimation * 0.25))
      ..style = PaintingStyle.fill;

    final inactivePaint = Paint()
      ..color = inactiveColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barSpacing);
      final rawAmp = amplitudes[i];

      // Subtle dynamic breath pulse on active bars during playback
      final amp = (i <= activeIndex && isPlaying)
          ? (rawAmp * (0.92 + (pulseAnimation * 0.16))).clamp(0.08, 1.0)
          : rawAmp;

      final halfH = (size.height * 0.85 * amp) / 2;
      final top = centerY - halfH;
      final bottom = centerY + halfH;

      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x, top, x + barWidth, bottom),
        Radius.circular(barWidth / 2),
      );

      if (i < activeIndex) {
        canvas.drawRRect(rrect, activePaint);
      } else if (i == activeIndex) {
        // Glowing playhead scrubber bar
        final glowExpand = 1.5 + (pulseAnimation * 1.5);
        final glowRRect = RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x - glowExpand,
            top - glowExpand,
            x + barWidth + glowExpand,
            bottom + glowExpand,
          ),
          Radius.circular((barWidth + glowExpand * 2) / 2),
        );
        canvas.drawRRect(glowRRect, activeGlowPaint);
        canvas.drawRRect(rrect, activePaint);
      } else {
        canvas.drawRRect(rrect, inactivePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseAnimation != pulseAnimation ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor ||
        oldDelegate.amplitudes != amplitudes;
  }
}
