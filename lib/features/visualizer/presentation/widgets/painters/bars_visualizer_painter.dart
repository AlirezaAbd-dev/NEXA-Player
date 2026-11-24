import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Computes dynamic bar width and inter-bar gap so [count] bars always fit
/// cleanly within [width] without right-edge overflow at any viewport size.
({double barWidth, double gap}) computeVisualizerBarGeometry(
  double width,
  int count, {
  double preferredGap = 2.5,
}) {
  if (width <= 0 || count <= 0) {
    return (barWidth: 0.0, gap: 0.0);
  }
  if (count == 1) {
    return (barWidth: width.clamp(1.0, width), gap: 0.0);
  }
  final maxGapBudget = width * 0.35;
  final gap = math.min(preferredGap, maxGapBudget / (count - 1));
  final rawBarWidth = (width - (count - 1) * gap) / count;
  return (barWidth: rawBarWidth.clamp(0.5, width), gap: gap);
}

/// Renders a modern multi-band bar spectrum with glowing tips and gradients.
class BarsVisualizerPainter extends CustomPainter {
  const BarsVisualizerPainter({
    required this.magnitudes,
    required this.primaryColor,
    required this.secondaryColor,
    this.sensitivity = 1.0,
  });

  final List<double> magnitudes;
  final Color primaryColor;
  final Color secondaryColor;
  final double sensitivity;

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty || size.width <= 0 || size.height <= 0) return;

    final barCount = magnitudes.length;
    final geom = computeVisualizerBarGeometry(size.width, barCount);
    final barWidth = geom.barWidth;
    final gap = geom.gap;
    if (barWidth <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final rawMag = magnitudes[i];
      final safeMag = (rawMag.isNaN || rawMag.isInfinite) ? 0.0 : rawMag;
      final mag = (safeMag * sensitivity).clamp(0.03, 1.0);
      final barHeight = size.height * mag;
      final x = i * (barWidth + gap);
      final y = size.height - barHeight;
      final radius = math.min(3.0, barWidth * 0.45);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        Radius.circular(radius),
      );

      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          primaryColor.withOpacity(0.3),
          primaryColor,
          secondaryColor,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect.outerRect);

      canvas.drawRRect(rect, paint);

      // Neon tip glow
      if (mag > 0.4) {
        glowPaint.color = secondaryColor.withOpacity((mag - 0.4) * 0.8);
        canvas.drawCircle(
          Offset(x + barWidth / 2, y + 1.5),
          barWidth / 2.2,
          glowPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BarsVisualizerPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.sensitivity != sensitivity;
  }
}
