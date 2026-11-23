import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/design_system/nexa_surface_tokens.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/models/audiophile_preset.dart';
import '../providers/settings_providers.dart';

/// Semantic Keys for AudioStatusStrip testing.
abstract final class AudioStatusStripKeys {
  static const Key root = ValueKey('audio_status_strip');
  static const Key presetBitPerfect = ValueKey('preset_bit_perfect');
  static const Key presetWarmTube = ValueKey('preset_warm_tube');
  static const Key presetLateNight = ValueKey('preset_late_night');
  static const Key presetBatterySaver = ValueKey('preset_battery_saver');
}

/// Borderless L2 hardware audio status strip featuring real-time signal metrics
/// and 1-tap audiophile presets.
class AudioStatusStrip extends ConsumerWidget {
  const AudioStatusStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioSettings = ref.watch(audioSettingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = theme.extension<NexaSurfaceTokens>();

    final telemetryStyle = surfaceTokens?.telemetryTextStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontFeatures: [FontFeature.tabularFigures()],
        );

    // Compute active preset
    AudiophilePresetType? activePresetType;
    for (final p in AudiophilePreset.presets) {
      if (p.settings.sampleRate == audioSettings.sampleRate &&
          p.settings.bitDepth == audioSettings.bitDepth &&
          p.settings.dvcEnabled == audioSettings.dvcEnabled &&
          p.settings.replayGainMode == audioSettings.replayGainMode) {
        activePresetType = p.type;
        break;
      }
    }

    final sampleRateStr = audioSettings.sampleRate == 'auto'
        ? 'Auto (96kHz)'
        : '${audioSettings.sampleRate}kHz';
    final bitDepthStr = audioSettings.bitDepth == '32_float'
        ? '32-bit Float'
        : '${audioSettings.bitDepth}-bit';

    return NexaSurface(
      key: AudioStatusStripKeys.root,
      tier: NexaSurfaceTier.l2,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Pipeline telemetry & direct jump link
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: colorScheme.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AUDIO PIPELINE STATUS',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Direct Signal Flow & Master Output',
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.audioSettings),
                borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Details',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Telemetry badges row
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              _buildTelemetryBadge(
                context,
                icon: Icons.high_quality_rounded,
                label: '$sampleRateStr / $bitDepthStr',
                highlight: audioSettings.hiResMode,
                telemetryStyle: telemetryStyle,
              ),
              _buildTelemetryBadge(
                context,
                icon: Icons.bolt_rounded,
                label: audioSettings.dvcEnabled ? 'Direct DVC' : 'System Vol',
                highlight: audioSettings.dvcEnabled,
                telemetryStyle: telemetryStyle,
              ),
              _buildTelemetryBadge(
                context,
                icon: Icons.all_inclusive_rounded,
                label: audioSettings.gaplessPlayback ? 'Gapless' : 'Buffered',
                highlight: audioSettings.gaplessPlayback,
                telemetryStyle: telemetryStyle,
              ),
              _buildTelemetryBadge(
                context,
                icon: Icons.graphic_eq_rounded,
                label: audioSettings.replayGainMode == 'off'
                    ? 'Gain: Flat'
                    : 'RG: ${audioSettings.replayGainMode.toUpperCase()}',
                highlight: audioSettings.replayGainMode != 'off',
                telemetryStyle: telemetryStyle,
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // 1-Tap Audiophile Presets Label
          Text(
            '1-TAP AUDIOPHILE PRESETS',
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Preset Buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: AudiophilePreset.presets.map((preset) {
                final isSelected = activePresetType == preset.type;
                Key? presetKey;
                switch (preset.type) {
                  case AudiophilePresetType.bitPerfectPurist:
                    presetKey = AudioStatusStripKeys.presetBitPerfect;
                    break;
                  case AudiophilePresetType.warmTube:
                    presetKey = AudioStatusStripKeys.presetWarmTube;
                    break;
                  case AudiophilePresetType.lateNightClamp:
                    presetKey = AudioStatusStripKeys.presetLateNight;
                    break;
                  case AudiophilePresetType.batterySaver:
                    presetKey = AudioStatusStripKeys.presetBatterySaver;
                    break;
                }

                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: InkWell(
                    key: presetKey,
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                    onTap: () {
                      ref.read(audioSettingsProvider.notifier).update(preset.settings);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.24)
                            : colorScheme.onSurface.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              Icons.check_circle_rounded,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            preset.title,
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool highlight,
    required TextStyle telemetryStyle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight
            ? colorScheme.primary.withOpacity(0.12)
            : colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlight
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.4),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: telemetryStyle.copyWith(
              fontSize: 11,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
              color: highlight
                  ? colorScheme.primary
                  : colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}
