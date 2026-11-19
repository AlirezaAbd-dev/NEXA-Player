import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/visualizer_settings.dart';
import '../providers/visualizer_providers.dart';
import 'painters/bars_visualizer_painter.dart';
import 'painters/circle_visualizer_painter.dart';
import 'painters/spectrogram_painter.dart';
import 'painters/vu_meter_painter.dart';
import 'painters/wave_visualizer_painter.dart';

/// Interactive visualizer canvas that renders bars, radial circle, wave, spectrogram, or VU meter.
///
/// Can either be supplied custom magnitudes, style, and accent colors (e.g., for static previews)
/// or read live reactive streams from [liveMagnitudesProvider] and [visualizerSettingsProvider].
class SpectrumVisualizerWidget extends ConsumerWidget {
  const SpectrumVisualizerWidget({
    super.key,
    this.magnitudes,
    this.style,
    this.accentColor,
    this.secondaryColor,
    this.sensitivity,
    this.height = 120.0,
    this.width = double.infinity,
  });

  final List<double>? magnitudes;
  final VisualizerStyle? style;
  final Color? accentColor;
  final Color? secondaryColor;
  final double? sensitivity;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeStyle = style ?? ref.watch(visualizerSettingsProvider).style;

    if (activeStyle == VisualizerStyle.off) {
      return const SizedBox.shrink();
    }

    final activeMagnitudes = magnitudes ??
        ref.watch(liveMagnitudesProvider).valueOrNull ??
        const [];
    final activeAccent = accentColor ??
        Color(int.tryParse(ref.watch(visualizerSettingsProvider).colorHex) ??
            0xFF00E5FF);
    final activeSens =
        sensitivity ?? ref.watch(visualizerSettingsProvider).sensitivity;
    final secColor = secondaryColor ?? Colors.purpleAccent;

    final CustomPainter painter;
    switch (activeStyle) {
      case VisualizerStyle.bars:
        painter = BarsVisualizerPainter(
          magnitudes: activeMagnitudes,
          primaryColor: activeAccent,
          secondaryColor: secColor,
          sensitivity: activeSens,
        );
        break;
      case VisualizerStyle.circle:
        painter = CircleVisualizerPainter(
          magnitudes: activeMagnitudes,
          primaryColor: activeAccent,
          secondaryColor: secColor,
          sensitivity: activeSens,
        );
        break;
      case VisualizerStyle.wave:
        painter = WaveVisualizerPainter(
          magnitudes: activeMagnitudes,
          primaryColor: activeAccent,
          secondaryColor: secColor,
          sensitivity: activeSens,
        );
        break;
      case VisualizerStyle.spectrogram:
        painter = SpectrogramPainter(
          magnitudes: activeMagnitudes,
          primaryColor: activeAccent,
          secondaryColor: secColor,
        );
        break;
      case VisualizerStyle.vuMeter:
        final leftPeak = activeMagnitudes.isNotEmpty
            ? (activeMagnitudes.take(activeMagnitudes.length ~/ 2).reduce((a, b) => a > b ? a : b))
            : 0.0;
        final rightPeak = activeMagnitudes.length > 1
            ? (activeMagnitudes.skip(activeMagnitudes.length ~/ 2).reduce((a, b) => a > b ? a : b))
            : 0.0;
        painter = VuMeterPainter(
          leftLevel: (leftPeak * activeSens).clamp(0.0, 1.0),
          rightLevel: (rightPeak * activeSens).clamp(0.0, 1.0),
          accentColor: activeAccent,
        );
        break;
      case VisualizerStyle.off:
        return const SizedBox.shrink();
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: Size(width, height),
        painter: painter,
      ),
    );
  }
}
