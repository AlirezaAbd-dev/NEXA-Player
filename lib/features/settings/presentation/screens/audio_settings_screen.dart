import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Audiophile sound engine preferences screen.
class AudioSettingsScreen extends ConsumerWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audio = ref.watch(audioSettingsProvider);
    final notifier = ref.read(audioSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Audio Settings',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          // Playback Transitions
          SettingsGroupCard(
            title: 'Playback & Transitions',
            children: [
              SettingsSwitchTile(
                title: 'Gapless Playback',
                subtitle: 'Remove silence between consecutive album tracks',
                icon: Icons.all_inclusive_rounded,
                iconColor: Colors.cyanAccent,
                value: audio.gaplessPlayback,
                onChanged: (val) =>
                    notifier.update(audio.copyWith(gaplessPlayback: val)),
              ),
              SettingsSwitchTile(
                title: 'Crossfade on Track Change',
                subtitle: 'Smooth gradual overlap transition between songs',
                icon: Icons.shuffle_rounded,
                iconColor: Colors.tealAccent,
                value: audio.crossfadeEnabled,
                onChanged: (val) =>
                    notifier.update(audio.copyWith(crossfadeEnabled: val)),
              ),
              if (audio.crossfadeEnabled)
                SettingsSliderTile(
                  title: 'Crossfade Length',
                  subtitle: 'Duration of transition overlap',
                  icon: Icons.timer_outlined,
                  iconColor: Colors.tealAccent,
                  value: audio.crossfadeDurationSeconds.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  valueLabel: '${audio.crossfadeDurationSeconds}s',
                  onChanged: (val) => notifier.update(
                    audio.copyWith(crossfadeDurationSeconds: val.round()),
                  ),
                ),
              SettingsSwitchTile(
                title: 'Fading on Play / Pause',
                subtitle: 'Gradual volume ramp to avoid abrupt audio pops',
                icon: Icons.waves_rounded,
                iconColor: Colors.blueAccent,
                value: audio.fadingOnPlayPause,
                onChanged: (val) =>
                    notifier.update(audio.copyWith(fadingOnPlayPause: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Output & Clock
          SettingsGroupCard(
            title: 'Hardware Output & Clock',
            children: [
              SettingsSelectorTile<String>(
                title: 'Audio Buffer Size',
                subtitle: 'Tune playback latency vs dropout protection',
                icon: Icons.storage_rounded,
                iconColor: Colors.purpleAccent,
                selectedValue: audio.audioBufferSize,
                options: const {
                  'low': 'Low Latency (50ms)',
                  'medium': 'Balanced (100ms)',
                  'high': 'Safe Buffer (200ms)',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(audioBufferSize: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Audio Output Routing',
                subtitle: 'Target output device routing',
                icon: Icons.speaker_group_rounded,
                iconColor: Colors.amberAccent,
                selectedValue: audio.audioOutput,
                options: const {
                  'auto': 'Auto-Detect',
                  'speaker': 'Internal Speaker',
                  'headset': 'Wired Headset / AUX',
                  'bluetooth': 'Bluetooth A2DP / LDAC',
                  'usb_dac': 'USB DAC Bit-Perfect',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(audioOutput: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Sample Rate',
                subtitle: 'Output sampling frequency',
                icon: Icons.speed_rounded,
                iconColor: Colors.lightGreenAccent,
                selectedValue: audio.sampleRate,
                options: const {
                  'auto': 'Track Native (Auto)',
                  '44.1': '44.1 kHz (CD Quality)',
                  '48': '48.0 kHz (Studio)',
                  '88.2': '88.2 kHz (Hi-Res)',
                  '96': '96.0 kHz (Master)',
                  '192': '192.0 kHz (Ultra Hi-Res)',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(sampleRate: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Bit Depth Output',
                subtitle: 'Quantization resolution',
                icon: Icons.graphic_eq_rounded,
                iconColor: Colors.greenAccent,
                selectedValue: audio.bitDepth,
                options: const {
                  '16': '16-bit Integer',
                  '24': '24-bit Hi-Res',
                  '32_float': '32-bit Floating Point',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(bitDepth: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Dithering',
                subtitle: 'Quantization noise shaping algorithm',
                icon: Icons.blur_linear_rounded,
                iconColor: Colors.indigoAccent,
                selectedValue: audio.dithering,
                options: const {
                  'off': 'Off (Truncate)',
                  'triangular': 'Triangular (Standard TPDF)',
                  'shaped': 'Psychoacoustic Noise Shaped',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(dithering: val)),
              ),
              SettingsSwitchTile(
                title: 'Hi-Res Audio Mode',
                subtitle: 'Bypass Android AudioFlinger mixer for bit-perfect output',
                icon: Icons.high_quality_rounded,
                iconColor: Colors.amberAccent,
                value: audio.hiResMode,
                onChanged: (val) =>
                    notifier.update(audio.copyWith(hiResMode: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Dynamics & Volume
          SettingsGroupCard(
            title: 'Dynamics & Loudness',
            children: [
              SettingsSelectorTile<String>(
                title: 'ReplayGain Mode',
                subtitle: 'Loudness normalization across tracks',
                icon: Icons.tune_rounded,
                iconColor: Colors.orangeAccent,
                selectedValue: audio.replayGainMode,
                options: const {
                  'off': 'Disabled',
                  'track': 'Track Gain (Equalize Songs)',
                  'album': 'Album Gain (Preserve Dynamics)',
                  'smart': 'Smart Dynamic ReplayGain',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(replayGainMode: val)),
              ),
              if (audio.replayGainMode != 'off')
                SettingsSliderTile(
                  title: 'ReplayGain Preamp',
                  subtitle: 'Global gain boost or attenuation',
                  icon: Icons.linear_scale_rounded,
                  iconColor: Colors.orangeAccent,
                  value: audio.replayGainPreampDb,
                  min: -12,
                  max: 12,
                  divisions: 24,
                  valueLabel:
                      '${audio.replayGainPreampDb >= 0 ? '+' : ''}${audio.replayGainPreampDb.toStringAsFixed(1)} dB',
                  onChanged: (val) => notifier.update(
                    audio.copyWith(replayGainPreampDb: val),
                  ),
                ),
              SettingsSwitchTile(
                title: 'Direct Volume Control (DVC)',
                subtitle: 'Hardware DAC volume bypass for expanded dynamic range',
                icon: Icons.volume_up_rounded,
                iconColor: Colors.redAccent,
                value: audio.dvcEnabled,
                onChanged: (val) =>
                    notifier.update(audio.copyWith(dvcEnabled: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Stereo Widening',
                subtitle: 'Soundstage psychoacoustic expansion',
                icon: Icons.surround_sound_rounded,
                iconColor: Colors.deepPurpleAccent,
                selectedValue: audio.stereoWidening,
                options: const {
                  'off': 'Off (Native Stereo)',
                  'software': 'Software Crosstalk Cancellation',
                  'hardware': 'DSP Hardware Soundstage',
                },
                onSelected: (val) =>
                    notifier.update(audio.copyWith(stereoWidening: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Equalizer Quick Link
          SettingsGroupCard(
            title: 'Digital Signal Processing',
            children: [
              SettingsActionTile(
                title: 'Equalizer & DSP Engine',
                subtitle: '10-Band Parametric EQ, Z-Bass, Reverb, Presets',
                icon: Icons.equalizer_rounded,
                iconColor: Colors.tealAccent,
                onTap: () => context.push(AppRoutes.equalizer),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
