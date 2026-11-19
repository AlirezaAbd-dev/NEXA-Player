import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Renders a vintage dual-needle analog VU meter (L & R stereo channels).
class VuMeterPainter extends CustomPainter {
  const VuMeterPainter({
    required this.leftLevel,
    required this.rightLevel,
    required this.accentColor,
  });

  final double leftLevel;
  final double rightLevel;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final meterWidth = (size.width - 12) / 2;
    _drawSingleMeter(canvas, Rect.fromLTWH(0, 0, meterWidth, size.height), leftLevel, 'L');
    _drawSingleMeter(canvas, Rect.fromLTWH(meterWidth + 12, 0, meterWidth, size.height), rightLevel, 'R');
  }

  void _drawSingleMeter(Canvas canvas, Rect bounds, double level, String channel) {
    // Background dial card
    final bgPaint = Paint()
      ..color = const Color(0xFF0F1218)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white12
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rrect = RRect.fromRectAndRadius(bounds, const Radius.circular(8));
    canvas.drawRRect(rrect, bgPaint);
    canvas.drawRRect(rrect, borderPaint);

    // Arc scale (-20 to +3 dB)
    final pivot = Offset(bounds.center.dx, bounds.bottom + bounds.height * 0.15);
    final radius = bounds.height * 0.95;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Green/safe zone (-20 to 0 dB)
    arcPaint.color = Colors.greenAccent.withOpacity(0.6);
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: radius),
      -math.pi * 0.75,
      math.pi * 0.35,
      false,
      arcPaint,
    );

    // Red/peak zone (0 to +3 dB)
    arcPaint.color = Colors.redAccent.withOpacity(0.8);
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: radius),
      -math.pi * 0.40,
      math.pi * 0.15,
      false,
      arcPaint,
    );

    // Needle angle: from -math.pi * 0.75 (0.0) to -math.pi * 0.25 (1.0)
    final needleAngle = -math.pi * 0.75 + (level.clamp(0.0, 1.0) * math.pi * 0.50);
    final needleEnd = Offset(
      pivot.dx + math.cos(needleAngle) * radius * 0.9,
      pivot.dy + math.sin(needleAngle) * radius * 0.9,
    );

    final needlePaint = Paint()
      ..color = level > 0.85 ? Colors.redAccent : accentColor
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(pivot, needleEnd, needlePaint);

    // Pivot cap
    final capPaint = Paint()..color = Colors.grey.shade400;
    canvas.drawCircle(Offset(pivot.dx, bounds.bottom - 4), 5.0, capPaint);

    // Channel label
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$channel  ${(level * 100).toInt()}%',
        style: TextStyle(
          color: Colors.white.withOpacity(0.7),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(bounds.center.dx - textPainter.width / 2, bounds.top + 6),
    );
  }

  @override
  bool shouldRepaint(covariant VuMeterPainter oldDelegate) {
    return oldDelegate.leftLevel != leftLevel ||
        oldDelegate.rightLevel != rightLevel ||
        oldDelegate.accentColor != accentColor;
  }
}
