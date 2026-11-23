import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/models/soundstage_position.dart';

/// Semantic Keys for SpatialSoundstagePad testing.
abstract final class SpatialSoundstagePadKeys {
  static const Key root = ValueKey('spatial_soundstage_pad');
  static const Key resetButton = ValueKey('soundstage_reset');
}

/// Interactive 2D spatial acoustic soundstage room pad.
/// Dragging the acoustic focal point dynamically adjusts stereo width and room reverberation depth.
class SpatialSoundstagePad extends StatefulWidget {
  const SpatialSoundstagePad({
    super.key,
    required this.position,
    required this.onChanged,
    this.height = 160.0,
  });

  final SoundstagePosition position;
  final ValueChanged<SoundstagePosition> onChanged;
  final double height;

  @override
  State<SpatialSoundstagePad> createState() => _SpatialSoundstagePadState();
}

class _SpatialSoundstagePadState extends State<SpatialSoundstagePad> {
  bool _wasNearCenter = true;

  void _updatePositionFromOffset(Offset localPos, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // Convert pixel coordinates to normalized x in [-1.0, 1.0], y in [0.0, 1.0]
    final normX = ((localPos.dx / size.width) * 2.0 - 1.0).clamp(-1.0, 1.0);
    // Invert Y so 0.0 is nearfield (bottom) and 1.0 is farfield hall (top)
    final normY = (1.0 - (localPos.dy / size.height)).clamp(0.0, 1.0);

    // Haptic detent on center crossing
    final isNearCenter = normX.abs() < 0.08;
    if (isNearCenter && !_wasNearCenter) {
      HapticFeedback.selectionClick();
    }
    _wasNearCenter = isNearCenter;

    widget.onChanged(SoundstagePosition(
      x: (normX * 100).round() / 100.0,
      y: (normY * 100).round() / 100.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final surfaceTokens = theme.extension<NexaSurfaceTokens>();

    final telemetryStyle = surfaceTokens?.telemetryTextStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontFeatures: [FontFeature.tabularFigures()],
        );

    final widthPct = (widget.position.stereoWideningFactor * 100).round();
    final depthPct = (widget.position.acousticDepth * 100).round();
    final balanceStr = widget.position.x.abs() < 0.05
        ? 'Center'
        : widget.position.x < 0
            ? 'L ${(widget.position.x.abs() * 100).round()}%'
            : 'R ${(widget.position.x * 100).round()}%';

    return NexaSurface(
      key: SpatialSoundstagePadKeys.root,
      tier: NexaSurfaceTier.l1,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title, Telemetry Readout, Reset Button
          Row(
            children: [
              Icon(
                Icons.surround_sound_rounded,
                size: 18,
                color: primary,
              ),
              const SizedBox(width: 8),
              Text(
                '2D SPATIAL SOUNDSTAGE',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: primary,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              Text(
                'W:$widthPct% • D:$depthPct% • $balanceStr',
                style: telemetryStyle.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: SpatialSoundstagePadKeys.resetButton,
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onChanged(SoundstagePosition.studioDefault);
                },
                borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    'Reset',
                    style: AppTypography.labelSmall.copyWith(
                      fontSize: 10,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Interactive 2D Soundstage Room Canvas
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, widget.height);

              return Semantics(
                label: '2D Spatial Soundstage Pad',
                value: 'Stereo width $widthPct%, Room depth $depthPct%, Balance $balanceStr',
                onIncrease: () {
                  final newPos = widget.position.copyWith(
                    y: (widget.position.y + 0.1).clamp(0.0, 1.0),
                  );
                  widget.onChanged(newPos);
                },
                onDecrease: () {
                  final newPos = widget.position.copyWith(
                    y: (widget.position.y - 0.1).clamp(0.0, 1.0),
                  );
                  widget.onChanged(newPos);
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanDown: (d) => _updatePositionFromOffset(d.localPosition, size),
                  onPanUpdate: (d) => _updatePositionFromOffset(d.localPosition, size),
                  onDoubleTap: () => widget.onChanged(SoundstagePosition.studioDefault),
                  child: Container(
                    height: widget.height,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                    ),
                    child: CustomPaint(
                      painter: _SoundstagePadPainter(
                        position: widget.position,
                        primaryColor: primary,
                        onSurfaceColor: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SoundstagePadPainter extends CustomPainter {
  final SoundstagePosition position;
  final Color primaryColor;
  final Color onSurfaceColor;

  _SoundstagePadPainter({
    required this.position,
    required this.primaryColor,
    required this.onSurfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerBottom = Offset(size.width / 2.0, size.height * 0.90);

    // Subtle acoustic wavefront rings emanating from center-bottom
    final wavePaint = Paint()
      ..color = onSurfaceColor.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (final r in [0.25, 0.50, 0.75, 1.0]) {
      canvas.drawCircle(centerBottom, size.height * r, wavePaint);
    }

    // Center vertical balance guideline
    final guidePaint = Paint()
      ..color = onSurfaceColor.withOpacity(0.08)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(size.width / 2.0, 10),
      Offset(size.width / 2.0, size.height - 10),
      guidePaint,
    );

    // Listener node at center-bottom
    final listenerPaint = Paint()..color = onSurfaceColor.withOpacity(0.5);
    canvas.drawCircle(centerBottom, 4.5, listenerPaint);

    // Convert position to canvas offset
    // x: [-1.0, 1.0] -> [size.width * 0.1, size.width * 0.9]
    final nodeX = size.width * 0.5 + (position.x * size.width * 0.42);
    // y: [0.0, 1.0] -> [size.height * 0.85, size.height * 0.15]
    final nodeY = size.height * 0.85 - (position.y * size.height * 0.70);
    final nodeOffset = Offset(nodeX, nodeY);

    // Audio Ray line connecting listener to focal node
    final rayPaint = Paint()
      ..color = primaryColor.withOpacity(0.35)
      ..strokeWidth = 1.5;
    canvas.drawLine(centerBottom, nodeOffset, rayPaint);

    // Focal Speaker Node Glow
    final glowPaint = Paint()
      ..color = primaryColor.withOpacity(0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    canvas.drawCircle(nodeOffset, 14.0, glowPaint);

    // Focal Node Solid
    final nodePaint = Paint()..color = primaryColor;
    canvas.drawCircle(nodeOffset, 7.0, nodePaint);

    // Center white dot on node
    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(nodeOffset, 2.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SoundstagePadPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.primaryColor != primaryColor;
  }
}
