import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a radial circle/mandala spectrum radiating outward.
class CircleVisualizerPainter extends CustomPainter {
  const CircleVisualizerPainter({
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

    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = math.min(size.width, size.height) * 0.22;
    final maxSpike = math.min(size.width, size.height) * 0.26;
    final count = magnitudes.length;
    final angleStep = (2 * math.pi) / count;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (baseRadius * 0.12).clamp(2.0, 5.0);

    for (int i = 0; i < count; i++) {
      final angle = i * angleStep;
      final mag = (magnitudes[i] * sensitivity).clamp(0.05, 1.0);
      final spikeLength = mag * maxSpike;

      final start = Offset(
        center.dx + math.cos(angle) * baseRadius,
        center.dy + math.sin(angle) * baseRadius,
      );
      final end = Offset(
        center.dx + math.cos(angle) * (baseRadius + spikeLength),
        center.dy + math.sin(angle) * (baseRadius + spikeLength),
      );

      final colorRatio = i / count;
      paint.color = Color.lerp(primaryColor, secondaryColor, colorRatio)!
          .withOpacity((0.4 + mag * 0.6).clamp(0.0, 1.0));

      canvas.drawLine(start, end, paint);
    }

    // Inner glowing ring
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = primaryColor.withOpacity(0.5);
    canvas.drawCircle(center, baseRadius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant CircleVisualizerPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.sensitivity != sensitivity;
  }
}
