import 'package:flutter/material.dart';
import 'gearshift_waveform_scrubber.dart';

/// Interactive, seekable audio waveform visualizer powered by the
/// [GearshiftWaveformScrubber] precision variable-speed engine.
class WaveformVisualizer extends StatelessWidget {
  const WaveformVisualizer({
    super.key,
    required this.position,
    required this.duration,
    this.isPlaying = false,
    this.onSeek,
    this.activeColor,
    this.inactiveColor,
    this.barCount = 56,
    this.height = 48.0,
    this.trackSeed = 'default_seed',
    this.cachedAmplitudes,
  });

  final Duration position;
  final Duration duration;
  final bool isPlaying;
  final ValueChanged<Duration>? onSeek;
  final Color? activeColor;
  final Color? inactiveColor;
  final int barCount;
  final double height;
  final String trackSeed;
  final List<double>? cachedAmplitudes;

  @override
  Widget build(BuildContext context) {
    return GearshiftWaveformScrubber(
      position: position,
      duration: duration,
      isPlaying: isPlaying,
      onSeek: (pos) => onSeek?.call(pos),
      cachedAmplitudes: cachedAmplitudes,
      activeColor: activeColor,
      height: height,
    );
  }
}
