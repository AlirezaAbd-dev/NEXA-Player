import 'package:flutter/material.dart';

/// Renders a frequency heatmap spectrogram representation.
class SpectrogramPainter extends CustomPainter {
  const SpectrogramPainter({
    required this.magnitudes,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final List<double> magnitudes;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty || size.width <= 0 || size.height <= 0) return;

    final cols = magnitudes.length;
    const rows = 12;
    final cellWidth = size.width / cols;
    final cellHeight = size.height / rows;

    final paint = Paint()..style = PaintingStyle.fill;

    for (int c = 0; c < cols; c++) {
      final mag = magnitudes[c].clamp(0.0, 1.0);
      final activeRows = (mag * rows).ceil();

      for (int r = 0; r < rows; r++) {
        final rowInverted = rows - 1 - r;
        if (r < activeRows) {
          final intensity = (r + 1) / rows;
          paint.color = Color.lerp(
            primaryColor,
            secondaryColor,
            intensity,
          )!.withOpacity((0.25 + intensity * 0.75).clamp(0.0, 1.0));
        } else {
          paint.color = Colors.white.withOpacity(0.03);
        }

        final gap = cellWidth > 2.0 ? 1.0 : cellWidth * 0.15;
        final rect = Rect.fromLTWH(
          c * cellWidth + gap * 0.5,
          rowInverted * cellHeight + 0.5,
          (cellWidth - gap).clamp(0.2, cellWidth),
          (cellHeight - 1.0).clamp(0.2, cellHeight),
        );
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(1.5)), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpectrogramPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
        oldDelegate.primaryColor != primaryColor;
  }
}
