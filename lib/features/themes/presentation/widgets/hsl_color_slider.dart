import 'package:flutter/material.dart';

/// Reusable HSL slider with header title, current value display, and optional gradient track.
class HslColorSlider extends StatelessWidget {
  const HslColorSlider({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.displayValue,
    super.key,
    this.min = 0.0,
    this.max = 1.0,
    this.sliderKey,
    this.activeColor,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final Key? sliderKey;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6.0,
            activeTrackColor: activeColor ?? theme.colorScheme.primary,
            thumbColor: activeColor ?? theme.colorScheme.primary,
          ),
          child: Slider(
            key: sliderKey,
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
