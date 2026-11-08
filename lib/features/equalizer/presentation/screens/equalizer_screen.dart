import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../providers/equalizer_providers.dart';
import '../widgets/dsp_knob_slider.dart';
import '../widgets/eq_band_slider.dart';
import '../widgets/eq_curve_painter.dart';
import '../widgets/preset_selector_modal.dart';
import '../widgets/reverb_selector.dart';

/// Full-featured, studio-grade parametric Equalizer and DSP audio engine screen.
class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerNotifierProvider);
    final eqNotifier = ref.read(equalizerNotifierProvider.notifier);
    final theme = Theme.of(context);
    final accentColor = theme.colorScheme.primary;

    final activePreset = eqState.activePreset;
    final presetName = activePreset?.name ?? 'Custom';

    return Scaffold(
      backgroundColor: const Color(0xFF090C13),
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
              style: AppTypography.labelSmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 0.5,
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
                  style: TextStyle(
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
                  activeColor: accentColor,
                  activeTrackColor: accentColor.withOpacity(0.3),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              ),
              const SizedBox(height: 16),

              // 2. Frequency Response Curve Card
              _buildCurveCard(
                context,
                eqState: eqState,
                accentColor: accentColor,
              ),
              const SizedBox(height: 20),

              // 3. Preamp Gain Control
              _buildPreampSection(
                context,
                preamp: eqState.preamp,
                isEnabled: eqState.isEnabled,
                onChanged: (val) => eqNotifier.setPreamp(val),
                accentColor: accentColor,
              ),
              const SizedBox(height: 16),

              // 4. 10-Band Graphic Fader Bank
              _buildFadersBank(
                context,
                eqState: eqState,
                onGainChanged: (index, gain) =>
                    eqNotifier.setBandGain(index, gain),
                accentColor: accentColor,
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
                    style: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 6. Bass Boost Control
              DspKnobSlider(
                title: 'BASS BOOST',
                subtitle: 'Low-frequency harmonic resonance',
                icon: Icons.speaker_group_rounded,
                value: eqState.bassBoost,
                isEnabled: eqState.isEnabled,
                onChanged: (val) => eqNotifier.setBassBoost(val),
                accentColor: accentColor,
              ),
              const SizedBox(height: 12),

              // 7. Virtualizer (3D Surround)
              DspKnobSlider(
                title: '3D VIRTUALIZER',
                subtitle: 'Stereo soundstage expansion',
                icon: Icons.surround_sound_rounded,
                value: eqState.virtualizer,
                isEnabled: eqState.isEnabled,
                onChanged: (val) => eqNotifier.setVirtualizer(val),
                accentColor: accentColor,
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
  }) {
    return Row(
      children: [
        // Active preset pill button that opens modal
        Expanded(
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF131722),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1,
                ),
              ),
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
                          style: TextStyle(
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
        const SizedBox(width: 8),

        // Quick Browse Button
        IconButton.filledTonal(
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
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF131722),
            foregroundColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurveCard(
    BuildContext context, {
    required dynamic eqState,
    required Color accentColor,
  }) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF10141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: eqState.isEnabled
              ? accentColor.withOpacity(0.25)
              : Colors.white.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: eqState.isEnabled
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.06),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Spline response curve custom painter
            CustomPaint(
              size: const Size(double.infinity, 180),
              painter: EqCurvePainter(
                bands: eqState.bands,
                preamp: eqState.preamp,
                isEnabled: eqState.isEnabled,
                accentColor: accentColor,
                gridColor: Colors.white,
                textColor: Colors.white,
              ),
            ),

            // Top overlay badge
            Positioned(
              top: 10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: eqState.isEnabled
                            ? accentColor
                            : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '31Hz - 16kHz',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontFamily: 'monospace',
                        color: Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreampSection(
    BuildContext context, {
    required double preamp,
    required bool isEnabled,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
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
            style: TextStyle(
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
                inactiveTrackColor: Colors.white.withOpacity(0.08),
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
            width: 48,
            child: Text(
              preamp.abs() < 0.05
                  ? '0.0 dB'
                  : '${preamp > 0 ? '+' : ''}${preamp.toStringAsFixed(1)} dB',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: isEnabled && preamp.abs() > 0.05
                    ? accentColor
                    : Colors.white54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFadersBank(
    BuildContext context, {
    required dynamic eqState,
    required void Function(int index, double gain) onGainChanged,
    required Color accentColor,
  }) {
    return Container(
      height: 250,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF10141E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
                Text(
                  '-15 dB  /  +15 dB',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
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
          ),
        ],
      ),
    );
  }
}
