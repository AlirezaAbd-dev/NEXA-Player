import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/equalizer_band.dart';

/// Tactile studio fader widget for adjusting an individual frequency band.
class EqBandSlider extends StatelessWidget {
  const EqBandSlider({
    super.key,
    required this.band,
    required this.isEnabled,
    required this.onGainChanged,
    this.accentColor,
  });

  final EqualizerBand band;
  final bool isEnabled;
  final ValueChanged<double> onGainChanged;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;

    final gainColor = !isEnabled
        ? theme.colorScheme.onSurface.withOpacity(0.3)
        : band.gain > 0.05
            ? effectiveAccent
            : band.gain < -0.05
                ? Colors.cyanAccent.shade200
                : theme.colorScheme.onSurface.withOpacity(0.6);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 1. dB Value Readout at the top
        SizedBox(
          height: 18,
          child: Text(
            band.gain.abs() < 0.05
                ? '0.0'
                : '${band.gain > 0 ? '+' : ''}${band.gain.toStringAsFixed(1)}',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              color: gainColor,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // 2. Vertical Fader Track
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Zero dB horizontal reference line
              Positioned(
                child: Container(
                  width: 22,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: isEnabled
                        ? effectiveAccent.withOpacity(0.3)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),

              // Rotated Slider (Quarter turns = 3 makes up = increase gain)
              RotatedBox(
                quarterTurns: 3,
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.0,
                    activeTrackColor: isEnabled
                        ? effectiveAccent
                        : Colors.white.withOpacity(0.2),
                    inactiveTrackColor: isEnabled
                        ? Colors.white.withOpacity(0.12)
                        : Colors.white.withOpacity(0.06),
                    thumbColor: isEnabled ? effectiveAccent : Colors.grey,
                    overlayColor: effectiveAccent.withOpacity(0.15),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6.5,
                      elevation: 3.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                  ),
                  child: Slider(
                    value: band.gain.clamp(band.minGain, band.maxGain),
                    min: band.minGain,
                    max: band.maxGain,
                    onChanged: isEnabled
                        ? (newVal) {
                            // Haptic tick if crossing 0 dB
                            if ((band.gain > 0 && newVal <= 0) ||
                                (band.gain < 0 && newVal >= 0)) {
                              HapticFeedback.selectionClick();
                            }
                            onGainChanged(newVal);
                          }
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // 3. Frequency Label at the bottom
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 0.5,
            ),
          ),
          child: Text(
            band.shortFrequency,
            style: TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? theme.colorScheme.onSurface.withOpacity(0.85)
                  : theme.colorScheme.onSurface.withOpacity(0.35),
            ),
          ),
        ),
      ],
    );
  }
}
