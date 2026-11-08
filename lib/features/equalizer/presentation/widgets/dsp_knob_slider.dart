import 'package:flutter/material.dart';

/// Studio FX control card for psychoacoustic DSP effects (Bass Boost, Virtualizer).
class DspKnobSlider extends StatelessWidget {
  const DspKnobSlider({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.isEnabled,
    required this.onChanged,
    this.accentColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final double value;
  final bool isEnabled;
  final ValueChanged<double> onChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;
    final percentage = (value * 100).round();
    final isActive = isEnabled && value > 0.01;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? effectiveAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: effectiveAccent.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? effectiveAccent.withOpacity(0.15)
                      : Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isActive
                      ? effectiveAccent
                      : theme.colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isEnabled
                            ? theme.colorScheme.onSurface
                            : theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? effectiveAccent.withOpacity(0.12)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isActive
                        ? effectiveAccent
                        : theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3.5,
              activeTrackColor: isEnabled
                  ? effectiveAccent
                  : Colors.white.withOpacity(0.2),
              inactiveTrackColor: Colors.white.withOpacity(0.08),
              thumbColor: isEnabled ? effectiveAccent : Colors.grey,
              overlayColor: effectiveAccent.withOpacity(0.12),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6.0,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 12.0,
              ),
            ),
            child: Slider(
              value: value.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: isEnabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
