import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/design_system/nexa_surface_tokens.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/models/frequency_spotlight_filter.dart';

/// Semantic Keys for FrequencySpotlightLoupe testing.
abstract final class FrequencySpotlightLoupeKeys {
  static const Key root = ValueKey('frequency_spotlight_loupe');
  static const Key loupeHandle = ValueKey('spotlight_loupe_handle');
}

/// Interactive "Acoustic Magnifying Glass" Loupe widget.
/// Pressing and dragging sweeps a high-Q frequency spotlight across 40 Hz – 16 kHz.
/// Releasing triggers a 200ms smooth crossfade restoring original baseline EQ.
class FrequencySpotlightLoupe extends StatefulWidget {
  const FrequencySpotlightLoupe({
    super.key,
    required this.filter,
    required this.onChanged,
  });

  final FrequencySpotlightFilter filter;
  final ValueChanged<FrequencySpotlightFilter> onChanged;

  @override
  State<FrequencySpotlightLoupe> createState() =>
      _FrequencySpotlightLoupeState();
}

class _FrequencySpotlightLoupeState extends State<FrequencySpotlightLoupe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _releaseController;
  int _lastOctaveIndex = -1;

  static const List<double> _octaves = [
    60.0,
    125.0,
    250.0,
    500.0,
    1000.0,
    2000.0,
    4000.0,
    8000.0,
    16000.0,
  ];

  @override
  void initState() {
    super.initState();
    _releaseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _releaseController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details, double width) {
    _releaseController.stop();
    HapticFeedback.mediumImpact();
    _updateSweep(details.localPosition.dx, width, active: true);
  }

  void _onPanUpdate(DragUpdateDetails details, double width) {
    _updateSweep(details.localPosition.dx, width, active: true);
  }

  void _onPanEnd(DragEndDetails details) {
    // Smooth 200ms release crossfade
    _releaseController.forward(from: 0.0).then((_) {
      if (mounted) {
        widget.onChanged(widget.filter.copyWith(isActive: false));
      }
    });
  }

  void _updateSweep(double dx, double width, {required bool active}) {
    if (width <= 0) return;
    final fraction = (dx / width).clamp(0.0, 1.0);
    final updated = widget.filter.copyWith(
      sweepFraction: fraction,
      isActive: active,
    );

    // Haptic detent on octave boundaries
    final currentHz = updated.centerFrequencyHz;
    for (int i = 0; i < _octaves.length; i++) {
      if ((currentHz - _octaves[i]).abs() / _octaves[i] < 0.08) {
        if (_lastOctaveIndex != i) {
          _lastOctaveIndex = i;
          HapticFeedback.selectionClick();
        }
        break;
      }
    }

    widget.onChanged(updated);
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

    return NexaSurface(
      key: FrequencySpotlightLoupeKeys.root,
      tier: NexaSurfaceTier.l2,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Spotlight Loupe Status & Telemetry
          Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: widget.filter.isActive
                    ? primary
                    : colorScheme.onSurface.withOpacity(0.5),
              ),
              const SizedBox(width: 8),
              Text(
                'FREQUENCY SPOTLIGHT LOUPE',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: widget.filter.isActive
                      ? primary
                      : colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: widget.filter.isActive
                      ? primary.withOpacity(0.20)
                      : colorScheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                ),
                child: Text(
                  widget.filter.isActive
                      ? '${widget.filter.formattedFrequency} (${widget.filter.bandCategory})'
                      : 'Hold & Drag to Solo',
                  style: telemetryStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.filter.isActive
                        ? primary
                        : colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Sweepable Spectrum Bar
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final handleX = (width * widget.filter.sweepFraction)
                  .clamp(14.0, width - 14.0);

              return Semantics(
                slider: true,
                label: 'Frequency spotlight loupe',
                value: '${widget.filter.formattedFrequency}, ${widget.filter.bandCategory}',
                onIncrease: () {
                  final next = (widget.filter.sweepFraction + 0.1).clamp(0.0, 1.0);
                  widget.onChanged(widget.filter.copyWith(
                    sweepFraction: next,
                    isActive: true,
                  ));
                },
                onDecrease: () {
                  final prev = (widget.filter.sweepFraction - 0.1).clamp(0.0, 1.0);
                  widget.onChanged(widget.filter.copyWith(
                    sweepFraction: prev,
                    isActive: true,
                  ));
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (d) => _onPanStart(d, width),
                  onHorizontalDragUpdate: (d) => _onPanUpdate(d, width),
                  onHorizontalDragEnd: _onPanEnd,
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurface.withOpacity(0.05),
                      borderRadius:
                          BorderRadius.circular(GlassTokens.radiusSmall),
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Octave tick markers
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(8, (i) {
                            return Container(
                              width: 1.5,
                              height: 12,
                              color: colorScheme.onSurface.withOpacity(0.12),
                            );
                          }),
                        ),

                        // Loupe Magnifier Bubble Handle
                        Positioned(
                          left: handleX - 16,
                          child: AnimatedScale(
                            scale: widget.filter.isActive ? 1.15 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              key: FrequencySpotlightLoupeKeys.loupeHandle,
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.filter.isActive
                                    ? primary
                                    : colorScheme.onSurface.withOpacity(0.3),
                                boxShadow: [
                                  BoxShadow(
                                    color: (widget.filter.isActive
                                            ? primary
                                            : Colors.black)
                                        .withOpacity(0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 16,
                                  color: widget.filter.isActive
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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
