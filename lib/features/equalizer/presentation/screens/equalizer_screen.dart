import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../providers/equalizer_providers.dart';
import '../widgets/eq_band_slider.dart';
import '../widgets/preset_selector_modal.dart';
import '../widgets/reverb_selector.dart';
import '../widgets/spline_equalizer_canvas.dart';
import '../widgets/tactile_rotary_knob.dart';

/// Full-featured, studio-grade parametric Equalizer and DSP audio engine screen
/// with interactive Catmull-Rom spline sculpting, tactile rotary dials, and borderless L1-L4 surfaces.
class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerNotifierProvider);
    final eqNotifier = ref.read(equalizerNotifierProvider.notifier);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    final activePreset = eqState.activePreset;
    final presetName = activePreset?.name ?? 'Custom';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Equalizer & DSP',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '10-Band Parametric • Studio DSP',
              style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 0.5,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
        actions: [
          // Reset to Flat button
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded, size: 22),
            onPressed: () {
              HapticFeedback.mediumImpact();
              eqNotifier.resetToFlat();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Equalizer reset to Flat'),
                  duration: Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Reset to Flat',
          ),

          // Master Power Switch
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  eqState.isEnabled ? 'ACTIVE' : 'BYPASS',
                  style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: eqState.isEnabled
                        ? accentColor
                        : Colors.white.withOpacity(0.35),
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: eqState.isEnabled,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    eqNotifier.setEnabled(val);
                  },
                  activeColor: Colors.white,
                  activeTrackColor: accentColor,
                  inactiveThumbColor: Colors.grey.shade600,
                  inactiveTrackColor: Colors.white.withOpacity(0.08),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: nexaScrollPadding(context, horizontal: 16.0, top: 8.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Preset Selector Bar
              _buildPresetSelectorBar(
                context,
                eqState: eqState,
                presetName: presetName,
                onSelectPreset: (id) => eqNotifier.applyPreset(id),
                onSaveCustom: (name) => eqNotifier.saveCustomPreset(name),
                onDeleteCustom: (id) => eqNotifier.deleteCustomPreset(id),
                accentColor: accentColor,
                surfaceTokens: surfaceTokens,
              ),
              const SizedBox(height: 16),

              // 2. Interactive Catmull-Rom Spline Curve Canvas with Touch Sculpting
              SplineEqualizerCanvas(
                bands: eqState.bands,
                preamp: eqState.preamp,
                isEnabled: eqState.isEnabled,
                accentColor: accentColor,
                onBandGainChanged: (index, gain) => eqNotifier.setBandGain(index, gain),
              ),
              const SizedBox(height: 16),

              // 3. Preamp Gain Control
              _buildPreampSection(
                context,
                preamp: eqState.preamp,
                isEnabled: eqState.isEnabled,
                onChanged: (val) => eqNotifier.setPreamp(val),
                accentColor: accentColor,
                surfaceTokens: surfaceTokens,
              ),
              const SizedBox(height: 16),

              // 4. 10-Band Graphic Fader Bank
              _buildFadersBank(
                context,
                eqState: eqState,
                onGainChanged: (index, gain) => eqNotifier.setBandGain(index, gain),
                accentColor: accentColor,
                surfaceTokens: surfaceTokens,
              ),
              const SizedBox(height: 24),

              // 5. Psychoacoustic DSP Effects Header
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PSYCHOACOUSTIC DSP EFFECTS',
                    style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelMedium).copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 11.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6 & 7. Tactile Rotary Knobs (Bass Boost & 3D Virtualizer)
              NexaSurface(
                level: NexaSurfaceLevel.l1,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TactileRotaryKnob(
                        label: 'BASS BOOST',
                        value: eqState.bassBoost,
                        isEnabled: eqState.isEnabled,
                        icon: Icons.speaker_group_rounded,
                        accentColor: accentColor,
                        onChanged: (val) => eqNotifier.setBassBoost(val),
                      ),
                      Container(
                        width: 1,
                        height: 60,
                        color: surfaceTokens.level2,
                      ),
                      TactileRotaryKnob(
                        label: '3D VIRTUALIZER',
                        value: eqState.virtualizer,
                        isEnabled: eqState.isEnabled,
                        icon: Icons.surround_sound_rounded,
                        accentColor: accentColor,
                        onChanged: (val) => eqNotifier.setVirtualizer(val),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 8. Acoustic Reverb Environment
              ReverbSelector(
                selectedPreset: eqState.reverb,
                isEnabled: eqState.isEnabled,
                onSelected: (preset) => eqNotifier.setReverb(preset),
                accentColor: accentColor,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetSelectorBar(
    BuildContext context, {
    required dynamic eqState,
    required String presetName,
    required ValueChanged<String> onSelectPreset,
    required ValueChanged<String> onSaveCustom,
    required ValueChanged<String> onDeleteCustom,
    required Color accentColor,
    required NexaSurfaceTokens surfaceTokens,
  }) {
    return Row(
      children: [
        // Active preset pill button that opens modal
        Expanded(
          child: NexaSurface(
            level: NexaSurfaceLevel.l1,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () {
                PresetSelectorModal.show(
                  context,
                  presets: eqState.presets,
                  activePresetId: eqState.activePresetId,
                  onSelectPreset: onSelectPreset,
                  onSaveCustomPreset: onSaveCustom,
                  onDeleteCustomPreset: onDeleteCustom,
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: accentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOUND PRESET',
                            style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ),
                          Text(
                            presetName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Quick Browse Button
        NexaSurface(
          level: NexaSurfaceLevel.l2,
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            onPressed: () {
              PresetSelectorModal.show(
                context,
                presets: eqState.presets,
                activePresetId: eqState.activePresetId,
                onSelectPreset: onSelectPreset,
                onSaveCustomPreset: onSaveCustom,
                onDeleteCustomPreset: onDeleteCustom,
              );
            },
            icon: const Icon(Icons.library_music_rounded, size: 20),
            tooltip: 'All Presets',
            color: accentColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPreampSection(
    BuildContext context, {
    required double preamp,
    required bool isEnabled,
    required ValueChanged<double> onChanged,
    required Color accentColor,
    required NexaSurfaceTokens surfaceTokens,
  }) {
    return NexaSurface(
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.speed_rounded,
              size: 20,
              color: isEnabled ? accentColor : Colors.white30,
            ),
            const SizedBox(width: 12),
            Text(
              'PREAMP',
              style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isEnabled ? Colors.white : Colors.white38,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3.0,
                  activeTrackColor: isEnabled ? accentColor : Colors.white24,
                  inactiveTrackColor: surfaceTokens.level2,
                  thumbColor: isEnabled ? accentColor : Colors.grey,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                ),
                child: Slider(
                  value: preamp.clamp(-15.0, 15.0),
                  min: -15.0,
                  max: 15.0,
                  onChanged: isEnabled ? onChanged : null,
                ),
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                preamp.abs() < 0.05
                    ? '0.0 dB'
                    : '${preamp > 0 ? '+' : ''}${preamp.toStringAsFixed(1)} dB',
                textAlign: TextAlign.end,
                style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isEnabled && preamp.abs() > 0.05
                      ? accentColor
                      : Colors.white54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFadersBank(
    BuildContext context, {
    required dynamic eqState,
    required void Function(int index, double gain) onGainChanged,
    required Color accentColor,
    required NexaSurfaceTokens surfaceTokens,
  }) {
    return NexaSurface(
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '10-BAND PARAMETRIC FILTER',
                    style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                  Text(
                    '-15 dB  /  +15 dB',
                    style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                      fontSize: 9.5,
                      color: Colors.white.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(
                  eqState.bands.length,
                  (index) => SizedBox(
                    width: 52,
                    child: EqBandSlider(
                      band: eqState.bands[index],
                      isEnabled: eqState.isEnabled,
                      accentColor: accentColor,
                      onGainChanged: (gain) => onGainChanged(index, gain),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
