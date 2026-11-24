import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/features/settings/presentation/widgets/settings_tiles.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/models/visualizer_settings.dart';
import '../providers/visualizer_providers.dart';
import '../widgets/spectrum_visualizer_widget.dart';

/// Full visualizer customizer screen with live interactive preview and borderless surfaces.
class VisualizerSettingsScreen extends ConsumerWidget {
  const VisualizerSettingsScreen({super.key});

  static const Map<VisualizerStyle, String> _modeLabels = {
    VisualizerStyle.bars: 'Bars',
    VisualizerStyle.circle: 'Mandala',
    VisualizerStyle.wave: 'Wave',
    VisualizerStyle.spectrogram: 'Heatmap',
    VisualizerStyle.vuMeter: 'VU',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(visualizerSettingsProvider);
    final notifier = ref.read(visualizerSettingsProvider.notifier);
    final liveMags = ref.watch(liveMagnitudesProvider).valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    // Match preview bar count 1:1 with header resolution when no live audio stream is active.
    final List<double> previewMagnitudes =
        (liveMags != null && liveMags.any((v) => v > 0.01))
            ? liveMags
            : List<double>.generate(settings.fftSize, (i) {
                final t = i / math.max(1, settings.fftSize - 1);
                return (0.22 +
                        0.55 * math.sin(t * math.pi * 2.4).abs() +
                        0.20 * math.cos(t * math.pi * 5.2).abs())
                    .clamp(0.08, 0.96);
              });

    final parsedColor = Color(int.tryParse(settings.colorHex) ?? 0xFF00E5FF);
    final renderedCount =
        settings.style == VisualizerStyle.off ? 0 : previewMagnitudes.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Visualizer & Spectrum',
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Live Preview Card
          Text(
            'LIVE PREVIEW',
            style: surfaceTokens.telemetryTextStyle.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 10.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          NexaSurface(
            level: NexaSurfaceLevel.l1,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  NexaSurface(
                    level: NexaSurfaceLevel.l2,
                    borderRadius: BorderRadius.circular(14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: SpectrumVisualizerWidget(
                              magnitudes: previewMagnitudes,
                              style: settings.style,
                              accentColor: parsedColor,
                              secondaryColor: colorScheme.secondary,
                              sensitivity: settings.sensitivity,
                              height: 124,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _modeLabels.entries.map((entry) {
                        final selected = settings.style == entry.key;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: selected,
                            onSelected: (_) async {
                              await notifier.update(
                                settings.copyWith(style: entry.key),
                              );
                              await notifier
                                  .requestLiveFftPermissionIfActivated();
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mode: ${settings.style.name.toUpperCase()}',
                        style: surfaceTokens.telemetryTextStyle.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        '${settings.fpsCap} FPS • $renderedCount BANDS',
                        style: surfaceTokens.telemetryTextStyle.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Display Mode & Style
          SettingsGroupCard(
            title: 'Display Style & Engine',
            children: [
              SettingsSelectorTile<VisualizerStyle>(
                title: 'Visualization Mode',
                subtitle: 'Active real-time rendering algorithm',
                icon: Icons.graphic_eq_rounded,
                iconColor: parsedColor,
                selectedValue: settings.style,
                options: const {
                  VisualizerStyle.bars: 'Equalizer Bars (Neon Tips)',
                  VisualizerStyle.circle: 'Radial Circle (Mandala Glow)',
                  VisualizerStyle.wave: 'Flowing Wave (Backdrop Spline)',
                  VisualizerStyle.spectrogram: 'Spectrogram Heatmap (12 Bands)',
                  VisualizerStyle.vuMeter: 'Analog Dual VU Meter (L / R)',
                  VisualizerStyle.off: 'Disabled',
                },
                onSelected: (style) async {
                  await notifier.update(settings.copyWith(style: style));
                  await notifier.requestLiveFftPermissionIfActivated();
                },
              ),
              SettingsSelectorTile<String>(
                title: 'Color Accent Glow',
                subtitle: 'Primary neon tint for visualizer animations',
                icon: Icons.color_lens_rounded,
                iconColor: parsedColor,
                selectedValue: settings.colorHex,
                options: const {
                  '0xFF00E5FF': 'Neon Cyan',
                  '0xFFD946EF': 'Electric Orchid',
                  '0xFFFFD600': 'Cyberpunk Gold',
                  '0xFFFF4081': 'Hot Rose Pink',
                  '0xFF00E676': 'Emerald Neon',
                  '0xFFFF9100': 'Amber Flame',
                },
                onSelected: (hex) =>
                    notifier.update(settings.copyWith(colorHex: hex)),
              ),
              SettingsSliderTile(
                title: 'Motion Sensitivity',
                subtitle: 'Amplitude multiplier for visualizer needle and bars',
                icon: Icons.speed_rounded,
                iconColor: parsedColor,
                value: settings.sensitivity,
                min: 0.5,
                max: 2.5,
                divisions: 8,
                valueLabel: '${settings.sensitivity.toStringAsFixed(1)}×',
                onChanged: (val) =>
                    notifier.update(settings.copyWith(sensitivity: val)),
              ),
              SettingsSelectorTile<int>(
                title: 'Ballistic Smoothing',
                subtitle: 'Peak decay damping between consecutive FFT frames',
                icon: Icons.tune_rounded,
                iconColor: parsedColor,
                selectedValue: (settings.smoothing * 100).round(),
                options: const {
                  25: '25% (Fast Attack)',
                  50: '50% (Balanced)',
                  65: '65% (Smooth Studio)',
                  85: '85% (Heavy Damping)',
                },
                onSelected: (pct) =>
                    notifier.update(settings.copyWith(smoothing: pct / 100.0)),
              ),
              SettingsSelectorTile<bool>(
                title: 'Cover Breathing',
                subtitle: 'Pulse Now Playing artwork softly with 20–80 Hz sub-bass',
                icon: Icons.album_rounded,
                iconColor: parsedColor,
                selectedValue: settings.coverBreathing,
                options: const {
                  true: 'Enabled (Sub-Bass Pulse)',
                  false: 'Disabled',
                },
                onSelected: (enabled) =>
                    notifier.update(settings.copyWith(coverBreathing: enabled)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Performance & Frame Cap
          SettingsGroupCard(
            title: 'Performance & Resolution',
            children: [
              SettingsSelectorTile<int>(
                title: 'Frame Rate Cap (FPS)',
                subtitle:
                    'Throttle refresh rate to balance smoothness vs battery life',
                icon: Icons.bolt_rounded,
                iconColor: Colors.amberAccent,
                selectedValue: settings.fpsCap,
                options: const {
                  30: '30 FPS (Energy Saver)',
                  60: '60 FPS (Silky Smooth)',
                  120: '120 FPS (Ultra ProMotion / High Refresh)',
                },
                onSelected: (fps) =>
                    notifier.update(settings.copyWith(fpsCap: fps)),
              ),
              SettingsSelectorTile<int>(
                title: 'FFT Frequency Resolution',
                subtitle: 'Number of discrete logarithmic frequency bands',
                icon: Icons.memory_rounded,
                iconColor: Colors.purpleAccent,
                selectedValue: settings.fftSize,
                options: const {
                  32: '32 Bands (Fast)',
                  64: '64 Bands (Standard Studio)',
                  128: '128 Bands (High Definition)',
                },
                onSelected: (size) =>
                    notifier.update(settings.copyWith(fftSize: size)),
              ),
              SettingsSwitchTile(
                title: 'Show on Lock Screen',
                subtitle: 'Render live visualizer on active lock screen controls',
                icon: Icons.screen_lock_portrait_rounded,
                iconColor: Colors.lightGreenAccent,
                value: settings.showOnLockScreen,
                onChanged: (val) =>
                    notifier.update(settings.copyWith(showOnLockScreen: val)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
