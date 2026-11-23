import 'package:flutter/material.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/entities/reverb_preset.dart';

/// Studio acoustic space / reverb simulation selector widget with borderless L1 surface.
class ReverbSelector extends StatelessWidget {
  const ReverbSelector({
    super.key,
    required this.selectedPreset,
    required this.isEnabled,
    required this.onSelected,
    this.accentColor,
  });

  final ReverbPreset selectedPreset;
  final bool isEnabled;
  final ValueChanged<ReverbPreset> onSelected;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = accentColor ?? theme.colorScheme.primary;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    return NexaSurface(
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnabled && selectedPreset != ReverbPreset.none
                        ? effectiveAccent.withOpacity(0.15)
                        : surfaceTokens.level2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.spatial_audio_rounded,
                    size: 18,
                    color: isEnabled && selectedPreset != ReverbPreset.none
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
                        'ACOUSTIC REVERB',
                        style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: isEnabled
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      Text(
                        selectedPreset.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.45),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Scrollable pill row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: ReverbPreset.values.map((preset) {
                  final isSelected = preset == selectedPreset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: isEnabled ? () => onSelected(preset) : null,
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected && isEnabled
                              ? effectiveAccent
                              : surfaceTokens.level2,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          preset.displayName,
                          style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected && isEnabled
                                ? Colors.black
                                : Colors.white.withOpacity(isEnabled ? 0.75 : 0.35),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
