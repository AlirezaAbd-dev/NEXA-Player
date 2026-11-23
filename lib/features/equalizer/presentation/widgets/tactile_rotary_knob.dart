import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';

/// Tactile studio rotary knob with 270-degree arc sweep,
/// smooth drag-to-turn gestures, haptic detents, and real-time telemetry readout.
class TactileRotaryKnob extends StatefulWidget {
  const TactileRotaryKnob({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.isEnabled = true,
    this.accentColor,
    this.size = 80.0,
    this.icon,
    this.unit = '%',
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool isEnabled;
  final Color? accentColor;
  final double size;
  final IconData? icon;
  final String unit;

  @override
  State<TactileRotaryKnob> createState() => _TactileRotaryKnobState();
}

class _TactileRotaryKnobState extends State<TactileRotaryKnob> {
  int _lastHapticStep = 0;

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!widget.isEnabled) return;
    final delta = -(details.primaryDelta ?? 0.0) / 140.0;
    final newValue = (widget.value + delta).clamp(0.0, 1.0);

    final step = (newValue * 10).round();
    if (step != _lastHapticStep) {
      _lastHapticStep = step;
      HapticFeedback.selectionClick();
    }

    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.accentColor ?? theme.colorScheme.primary;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final percentage = (widget.value * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rotary Dial Canvas with Screen Reader Semantics
        Semantics(
          slider: true,
          enabled: widget.isEnabled,
          label: widget.label,
          value: widget.unit == '%'
              ? '$percentage%'
              : '${widget.value.toStringAsFixed(1)} ${widget.unit}',
          onIncrease: widget.isEnabled
              ? () {
                  final next = (widget.value + 0.05).clamp(0.0, 1.0);
                  widget.onChanged(next);
                }
              : null,
          onDecrease: widget.isEnabled
              ? () {
                  final prev = (widget.value - 0.05).clamp(0.0, 1.0);
                  widget.onChanged(prev);
                }
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: _onVerticalDragUpdate,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(
                painter: _KnobPainter(
                  value: widget.value,
                  isEnabled: widget.isEnabled,
                  primaryColor: primary,
                  surfaceLevel2: surfaceTokens.level2,
                  surfaceLevel3: surfaceTokens.level3,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 6.0),

        // Readout Value
        Text(
          widget.unit == '%' ? '$percentage%' : '${widget.value.toStringAsFixed(1)} ${widget.unit}',
          style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
            fontWeight: FontWeight.bold,
            color: widget.isEnabled && widget.value > 0.01
                ? primary
                : onSurface.withOpacity(0.5),
            fontSize: 11.5,
          ),
        ),

        const SizedBox(height: 2.0),

        // Label
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(
                widget.icon,
                size: 11.0,
                color: onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 4.0),
            ],
            Text(
              widget.label,
              style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                color: onSurface.withOpacity(0.6),
                fontSize: 10.0,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  _KnobPainter({
    required this.value,
    required this.isEnabled,
    required this.primaryColor,
    required this.surfaceLevel2,
    required this.surfaceLevel3,
  });

  final double value;
  final bool isEnabled;
  final Color primaryColor;
  final Color surfaceLevel2;
  final Color surfaceLevel3;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const startAngle = 135.0 * (math.pi / 180.0);
    const totalSweep = 270.0 * (math.pi / 180.0);
    final activeSweep = totalSweep * value.clamp(0.0, 1.0);

    // 1. Inactive Track Arc
    final trackRadius = radius - 6.0;
    final trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: trackRadius),
      startAngle,
      totalSweep,
      false,
      trackPaint,
    );

    // 2. Active Arc
    if (isEnabled && value > 0.005) {
      final activePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: trackRadius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }

    // 3. Dial Body
    final dialRadius = radius - 14.0;
    final dialPaint = Paint()
      ..shader = RadialGradient(
        colors: [surfaceLevel3, surfaceLevel2],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: dialRadius));

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawCircle(center, dialRadius, shadowPaint);
    canvas.drawCircle(center, dialRadius, dialPaint);

    // 4. Indicator Pointer Notch
    final currentAngle = startAngle + activeSweep;
    final notchStart = Offset(
      center.dx + (dialRadius - 10.0) * math.cos(currentAngle),
      center.dy + (dialRadius - 10.0) * math.sin(currentAngle),
    );
    final notchEnd = Offset(
      center.dx + (dialRadius - 2.0) * math.cos(currentAngle),
      center.dy + (dialRadius - 2.0) * math.sin(currentAngle),
    );

    final notchPaint = Paint()
      ..color = isEnabled ? primaryColor : Colors.white38
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(notchStart, notchEnd, notchPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.primaryColor != primaryColor;
  }
}
