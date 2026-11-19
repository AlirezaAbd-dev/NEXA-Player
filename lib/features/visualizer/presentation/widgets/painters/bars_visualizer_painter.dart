import 'package:flutter/material.dart';

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
    final totalSpacing = (barCount - 1) * 2.5;
    final barWidth = ((size.width - totalSpacing) / barCount).clamp(2.0, 16.0);

    final paint = Paint()..style = PaintingStyle.fill;
    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final mag = (magnitudes[i] * sensitivity).clamp(0.04, 1.0);
      final barHeight = size.height * mag;
      final x = i * (barWidth + 2.5);
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(3.0),
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
