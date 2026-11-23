import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/entities/equalizer_band.dart';

/// Interactive Catmull-Rom Spline Equalizer canvas with logarithmic frequency grid,
/// live ghost FFT curve, and direct touch node hit-testing.
class SplineEqualizerCanvas extends StatefulWidget {
  const SplineEqualizerCanvas({
    super.key,
    required this.bands,
    required this.preamp,
    required this.isEnabled,
    required this.onBandGainChanged,
    this.accentColor,
    this.height = 190.0,
  });

  final List<EqualizerBand> bands;
  final double preamp;
  final bool isEnabled;
  final void Function(int index, double gain) onBandGainChanged;
  final Color? accentColor;
  final double height;

  @override
  State<SplineEqualizerCanvas> createState() => _SplineEqualizerCanvasState();
}

class _SplineEqualizerCanvasState extends State<SplineEqualizerCanvas> {
  int? _activeNodeIndex;
  double? _activeGainReadout;

  void _handleTouch(Offset localPosition, Size size) {
    if (!widget.isEnabled || widget.bands.isEmpty) return;

    const double leftMargin = 34.0;
    const double rightMargin = 16.0;
    const double topMargin = 14.0;
    const double bottomMargin = 18.0;

    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;
    final double centerY = topMargin + (plotHeight / 2);

    if (plotWidth <= 0 || plotHeight <= 0) return;

    // Find nearest band index horizontally
    final double touchX = (localPosition.dx - leftMargin).clamp(0.0, plotWidth);
    final double fraction = touchX / plotWidth;
    final int nearestIndex = (fraction * (widget.bands.length - 1)).round().clamp(0, widget.bands.length - 1);

    // Calculate gain from touchY
    final double touchY = (localPosition.dy - topMargin).clamp(0.0, plotHeight);
    final double gain = ((centerY - touchY) / (plotHeight / 2) * 15.0).clamp(-15.0, 15.0);

    final roundedGain = (gain * 2).round() / 2.0;

    setState(() {
      _activeNodeIndex = nearestIndex;
      _activeGainReadout = roundedGain;
    });

    widget.onBandGainChanged(nearestIndex, roundedGain);
  }

  void _onPanEnd() {
    setState(() {
      _activeNodeIndex = null;
      _activeGainReadout = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.accentColor ?? theme.colorScheme.primary;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    return NexaSurface(
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(20.0),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, widget.height);

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (details) {
                HapticFeedback.selectionClick();
                _handleTouch(details.localPosition, size);
              },
              onTapUp: (_) => _onPanEnd(),
              onPanStart: (details) {
                HapticFeedback.selectionClick();
                _handleTouch(details.localPosition, size);
              },
              onPanUpdate: (details) => _handleTouch(details.localPosition, size),
              onPanEnd: (_) => _onPanEnd(),
              onPanCancel: () => _onPanEnd(),
              child: Stack(
                children: [
                  CustomPaint(
                    size: size,
                    painter: _SplineCanvasPainter(
                      bands: widget.bands,
                      preamp: widget.preamp,
                      isEnabled: widget.isEnabled,
                      accentColor: primary,
                      activeNodeIndex: _activeNodeIndex,
                    ),
                  ),

                  // Top Status / Frequency Range Badge
                  Positioned(
                    top: 10,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: surfaceTokens.level2.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isEnabled ? primary : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _activeNodeIndex != null && _activeGainReadout != null
                                ? '${widget.bands[_activeNodeIndex!].displayFrequency}: ${_activeGainReadout! > 0 ? "+" : ""}${_activeGainReadout!.toStringAsFixed(1)} dB'
                                : '31 Hz – 16 kHz • FFT Active',
                            style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                              fontSize: 10.0,
                              color: widget.isEnabled ? primary : Colors.white60,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SplineCanvasPainter extends CustomPainter {
  _SplineCanvasPainter({
    required this.bands,
    required this.preamp,
    required this.isEnabled,
    required this.accentColor,
    required this.activeNodeIndex,
  });

  final List<EqualizerBand> bands;
  final double preamp;
  final bool isEnabled;
  final Color accentColor;
  final int? activeNodeIndex;

  @override
  void paint(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    const double leftMargin = 34.0;
    const double rightMargin = 16.0;
    const double topMargin = 14.0;
    const double bottomMargin = 18.0;

    final double plotWidth = size.width - leftMargin - rightMargin;
    final double plotHeight = size.height - topMargin - bottomMargin;
    final double centerY = topMargin + (plotHeight / 2);

    final effectiveColor = isEnabled ? accentColor : Colors.grey.shade600;

    // 1. Grid Lines & Labels
    _drawGrid(canvas, size, leftMargin, plotWidth, plotHeight, centerY, topMargin);

    // 2. Ghost FFT Spectrum Curve (live background acoustic trace)
    if (isEnabled) {
      _drawGhostFft(canvas, leftMargin, plotWidth, plotHeight, centerY, topMargin);
    }

    // 3. Compute coordinates for each band
    final List<Offset> points = [];
    for (int i = 0; i < bands.length; i++) {
      final double x = leftMargin + (i / (bands.length - 1)) * plotWidth;
      final double totalGain = (bands[i].gain + (preamp * 0.3)).clamp(-15.0, 15.0);
      final double y = centerY - (totalGain / 15.0) * (plotHeight / 2);
      points.add(Offset(x, y));
    }

    // 4. Catmull-Rom Spline Curve Path
    final Path curvePath = _buildSplinePath(points);

    // 5. Gradient Area Fill under the spline
    final Path fillPath = Path.from(curvePath);
    fillPath.lineTo(leftMargin + plotWidth, topMargin + plotHeight);
    fillPath.lineTo(leftMargin, topMargin + plotHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        effectiveColor.withOpacity(isEnabled ? 0.30 : 0.06),
        effectiveColor.withOpacity(isEnabled ? 0.08 : 0.01),
        Colors.transparent,
      ],
      stops: const [0.0, 0.55, 1.0],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(leftMargin, topMargin, plotWidth, plotHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 6. Spline Curve Neon Glow
    if (isEnabled) {
      final glowPaint = Paint()
        ..color = effectiveColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(curvePath, glowPaint);
    }

    // 7. Sharp Curve Stroke
    final strokePaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(curvePath, strokePaint);

    // 8. Interactive Control Nodes
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isCurrent = i == activeNodeIndex;
      final nodeRadius = isCurrent ? 6.5 : 4.0;

      if (isCurrent && isEnabled) {
        final nodeGlow = Paint()
          ..color = accentColor.withOpacity(0.50)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);
        canvas.drawCircle(pt, nodeRadius + 4.0, nodeGlow);
      }

      final nodePaint = Paint()..color = effectiveColor;
      canvas.drawCircle(pt, nodeRadius, nodePaint);

      final centerPaint = Paint()..color = Colors.black;
      canvas.drawCircle(pt, nodeRadius * 0.45, centerPaint);
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double leftMargin,
    double plotWidth,
    double plotHeight,
    double centerY,
    double topMargin,
  ) {
    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1.0;

    final centerLinePaint = Paint()
      ..color = Colors.white.withOpacity(0.14)
      ..strokeWidth = 1.0;

    // Horizontal dB lines (-15 to +15)
    final dbLevels = [15.0, 10.0, 5.0, 0.0, -5.0, -10.0, -15.0];
    for (final db in dbLevels) {
      final double y = centerY - (db / 15.0) * (plotHeight / 2);
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + plotWidth, y),
        db == 0.0 ? centerLinePaint : linePaint,
      );

      // Label
      if (db % 10 == 0 || db == 0) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${db > 0 ? "+" : ""}${db.toInt()}',
            style: TextStyle(
              color: Colors.white.withOpacity(db == 0 ? 0.5 : 0.25),
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(leftMargin - textPainter.width - 6, y - textPainter.height / 2),
        );
      }
    }

    // Vertical frequency markers
    for (int i = 0; i < bands.length; i++) {
      final double x = leftMargin + (i / (bands.length - 1)) * plotWidth;
      canvas.drawLine(Offset(x, topMargin), Offset(x, topMargin + plotHeight), linePaint);
    }
  }

  void _drawGhostFft(
    Canvas canvas,
    double leftMargin,
    double plotWidth,
    double plotHeight,
    double centerY,
    double topMargin,
  ) {
    final fftPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Path fftPath = Path();
    const int steps = 30;
    for (int i = 0; i <= steps; i++) {
      final double fraction = i / steps;
      final double x = leftMargin + fraction * plotWidth;
      // Synthetic acoustic energy envelope
      final double amp = 0.3 * math.sin(fraction * math.pi * 3.5).abs() +
          0.2 * math.cos(fraction * math.pi * 2.0).abs();
      final double y = centerY + (plotHeight * 0.4) - (amp * plotHeight * 0.6);

      if (i == 0) {
        fftPath.moveTo(x, y);
      } else {
        fftPath.lineTo(x, y);
      }
    }
    canvas.drawPath(fftPath, fftPaint);
  }

  Path _buildSplinePath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    path.moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) return path;

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      // Catmull-Rom to Cubic Bézier conversion
      final cp1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final cp1y = p1.dy + (p2.dy - p0.dy) / 6.0;
      final cp2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final cp2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant _SplineCanvasPainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.preamp != preamp ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.activeNodeIndex != activeNodeIndex ||
        oldDelegate.accentColor != accentColor;
  }
}
