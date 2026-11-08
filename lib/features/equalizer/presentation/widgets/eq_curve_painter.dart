import 'package:flutter/material.dart';
import '../../domain/entities/equalizer_band.dart';

/// Studio-grade custom painter for rendering a continuous Catmull-Rom frequency
/// response curve with gradient fill, grid lines, and glowing band nodes.
class EqCurvePainter extends CustomPainter {
  EqCurvePainter({
    required this.bands,
    required this.preamp,
    required this.isEnabled,
    required this.accentColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<EqualizerBand> bands;
  final double preamp;
  final bool isEnabled;
  final Color accentColor;
  final Color gridColor;
  final Color textColor;

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

    // 1. Draw dB Grid lines and labels (-15 to +15 in 5dB steps)
    _drawGrid(
      canvas,
      size,
      leftMargin,
      rightMargin,
      topMargin,
      plotWidth,
      plotHeight,
      centerY,
    );

    // 2. Compute 2D coordinates for each band
    final List<Offset> points = [];
    for (int i = 0; i < bands.length; i++) {
      final double x = leftMargin + (i / (bands.length - 1)) * plotWidth;
      // Total effective gain includes band gain + preamp
      final double totalGain = (bands[i].gain + (preamp * 0.3)).clamp(-15.0, 15.0);
      final double y = centerY - (totalGain / 15.0) * (plotHeight / 2);
      points.add(Offset(x, y));
    }

    // 3. Build smooth Catmull-Rom / cubic Bézier curve path
    final Path curvePath = _buildSplinePath(points);

    // 4. Draw Gradient Fill under the curve down to bottom
    final Path fillPath = Path.from(curvePath);
    fillPath.lineTo(leftMargin + plotWidth, topMargin + plotHeight);
    fillPath.lineTo(leftMargin, topMargin + plotHeight);
    fillPath.close();

    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        effectiveColor.withOpacity(isEnabled ? 0.35 : 0.08),
        effectiveColor.withOpacity(isEnabled ? 0.10 : 0.02),
        Colors.transparent,
      ],
      stops: const [0.0, 0.6, 1.0],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(
        Rect.fromLTWH(leftMargin, topMargin, plotWidth, plotHeight),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Draw Glowing Line Blur (Neon effect)
    if (isEnabled) {
      final glowPaint = Paint()
        ..color = effectiveColor.withOpacity(0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
      canvas.drawPath(curvePath, glowPaint);
    }

    // 6. Draw Crisp Sharp Curve Stroke
    final strokePaint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(curvePath, strokePaint);

    // 7. Draw Band Control Nodes (tactile glowing dots)
    for (int i = 0; i < points.length; i++) {
      final point = points[i];

      // Outer halo
      if (isEnabled) {
        final haloPaint = Paint()
          ..color = effectiveColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 7.0, haloPaint);
      }

      // Middle ring
      final ringPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 4.5, ringPaint);

      // Core dot
      final corePaint = Paint()
        ..color = isEnabled ? effectiveColor : Colors.grey.shade400
        ..style = PaintingStyle.fill;
      canvas.drawCircle(point, 2.5, corePaint);
    }
  }

  void _drawGrid(
    Canvas canvas,
    Size size,
    double leftMargin,
    double rightMargin,
    double topMargin,
    double plotWidth,
    double plotHeight,
    double centerY,
  ) {
    final gridPaint = Paint()
      ..color = gridColor.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final centerGridPaint = Paint()
      ..color = (isEnabled ? accentColor : gridColor).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const dbValues = [15, 10, 5, 0, -5, -10, -15];

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    );

    for (final db in dbValues) {
      final double y = centerY - (db / 15.0) * (plotHeight / 2);

      // Line
      final isZero = db == 0;
      final paintToUse = isZero ? centerGridPaint : gridPaint;

      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + plotWidth, y),
        paintToUse,
      );

      // Text label
      final label = db > 0 ? '+$db' : '$db';
      textPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          color: isZero && isEnabled
              ? accentColor.withOpacity(0.9)
              : textColor.withOpacity(0.4),
          fontSize: 9.0,
          fontWeight: isZero ? FontWeight.bold : FontWeight.w500,
          fontFamily: 'monospace',
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(leftMargin - textPainter.width - 6.0, y - (textPainter.height / 2)),
      );
    }

    // Vertical guides for each band
    for (int i = 0; i < bands.length; i++) {
      final double x = leftMargin + (i / (bands.length - 1)) * plotWidth;
      final verticalGuidePaint = Paint()
        ..color = gridColor.withOpacity(0.05)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, topMargin + plotHeight),
        verticalGuidePaint,
      );
    }
  }

  Path _buildSplinePath(List<Offset> points) {
    final Path path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      // Catmull-Rom to Cubic Bézier control points
      // c1 = p1 + (p2 - p0) / 6
      // c2 = p2 - (p3 - p1) / 6
      final c1x = p1.dx + (p2.dx - p0.dx) / 6.0;
      final c1y = p1.dy + (p2.dy - p0.dy) / 6.0;

      final c2x = p2.dx - (p3.dx - p1.dx) / 6.0;
      final c2y = p2.dy - (p3.dy - p1.dy) / 6.0;

      path.cubicTo(c1x, c1y, c2x, c2y, p2.dx, p2.dy);
    }

    return path;
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) {
    if (oldDelegate.isEnabled != isEnabled ||
        oldDelegate.preamp != preamp ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.bands.length != bands.length) {
      return true;
    }
    for (int i = 0; i < bands.length; i++) {
      if (oldDelegate.bands[i].gain != bands[i].gain) return true;
    }
    return false;
  }
}
