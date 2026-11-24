import 'package:flutter/material.dart';

/// Renders a flowing spline audio wave with gradient backdrop glow.
class WaveVisualizerPainter extends CustomPainter {
  const WaveVisualizerPainter({
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

    final count = magnitudes.length;
    final stepX = count > 1 ? size.width / (count - 1) : size.width;
    final midY = size.height * 0.7;

    if (count == 1) {
      final y = (midY - (magnitudes.first * sensitivity * size.height * 0.6))
          .clamp(4.0, size.height - 4.0);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = primaryColor,
      );
      return;
    }

    final path = Path();
    final fillPath = Path();

    final firstY = (midY - (magnitudes.first * sensitivity * size.height * 0.6))
        .clamp(4.0, size.height - 4.0);
    path.moveTo(0, firstY);
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, firstY);

    for (int i = 0; i < count - 1; i++) {
      final x0 = i * stepX;
      final y0 = (midY - (magnitudes[i] * sensitivity * size.height * 0.6))
          .clamp(4.0, size.height - 4.0);
      final x1 = (i + 1) * stepX;
      final y1 = (midY - (magnitudes[i + 1] * sensitivity * size.height * 0.6))
          .clamp(4.0, size.height - 4.0);

      final cx = (x0 + x1) / 2;
      path.cubicTo(cx, y0, cx, y1, x1, y1);
      fillPath.cubicTo(cx, y0, cx, y1, x1, y1);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Gradient fill under the wave
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor.withOpacity(0.35),
          secondaryColor.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Glowing wave line
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        colors: [primaryColor, secondaryColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant WaveVisualizerPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.sensitivity != sensitivity;
  }
}
