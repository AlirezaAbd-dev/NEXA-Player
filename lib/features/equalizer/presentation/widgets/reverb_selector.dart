import 'package:flutter/material.dart';
import '../../domain/entities/reverb_preset.dart';

/// Studio acoustic space / reverb simulation selector widget.
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131722),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEnabled && selectedPreset != ReverbPreset.none
              ? effectiveAccent.withOpacity(0.3)
              : Colors.white.withOpacity(0.06),
          width: 1,
        ),
      ),
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
                      : Colors.white.withOpacity(0.05),
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
                      style: TextStyle(
                        fontSize: 12,
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
            child: Row(
              children: ReverbPreset.values.map((preset) {
                final isSelected = preset == selectedPreset;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: isEnabled ? () => onSelected(preset) : null,
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isEnabled
                                ? effectiveAccent.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1))
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? (isEnabled
                                  ? effectiveAccent
                                  : Colors.white.withOpacity(0.2))
                              : Colors.white.withOpacity(0.08),
                          width: isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Text(
                        preset.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? (isEnabled
                                  ? effectiveAccent
                                  : Colors.white.withOpacity(0.8))
                              : theme.colorScheme.onSurface
                                  .withOpacity(isEnabled ? 0.6 : 0.3),
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
    );
  }
}
