import 'package:flutter/material.dart';
import '../../domain/entities/equalizer_preset.dart';
import '../../domain/entities/reverb_preset.dart';

/// Modal bottom sheet allowing users to switch sound profile presets,
/// save custom presets, or delete user-created profiles.
class PresetSelectorModal extends StatelessWidget {
  const PresetSelectorModal({
    super.key,
    required this.presets,
    required this.activePresetId,
    required this.onSelectPreset,
    required this.onSaveCustomPreset,
    required this.onDeleteCustomPreset,
  });

  final List<EqualizerPreset> presets;
  final String? activePresetId;
  final ValueChanged<String> onSelectPreset;
  final ValueChanged<String> onSaveCustomPreset;
  final ValueChanged<String> onDeleteCustomPreset;

  static Future<void> show(
    BuildContext context, {
    required List<EqualizerPreset> presets,
    required String? activePresetId,
    required ValueChanged<String> onSelectPreset,
    required ValueChanged<String> onSaveCustomPreset,
    required ValueChanged<String> onDeleteCustomPreset,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PresetSelectorModal(
        presets: presets,
        activePresetId: activePresetId,
        onSelectPreset: onSelectPreset,
        onSaveCustomPreset: onSaveCustomPreset,
        onDeleteCustomPreset: onDeleteCustomPreset,
      ),
    );
  }

  void _showSaveDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: const Color(0xFF161B26),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        title: const Text(
          'Save Custom Preset',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current 10-band gains, preamp, and DSP effects will be stored.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Bass Boost Extreme, Warm Vinyl',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: const Color(0xFF0F131D),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                onSaveCustomPreset(name);
                Navigator.of(dialogCtx).pop();
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save Preset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F131D),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sound Presets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${presets.length} profiles available',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showSaveDialog(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Save Current'),
                  style: TextButton.styleFrom(
                    foregroundColor: accent,
                    backgroundColor: accent.withOpacity(0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withOpacity(0.06), height: 1),

          // Preset List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: presets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (ctx, index) {
                final preset = presets[index];
                final isSelected = preset.id == activePresetId;

                return InkWell(
                  onTap: () {
                    onSelectPreset(preset.id);
                    Navigator.of(context).pop();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? accent.withOpacity(0.12)
                          : const Color(0xFF161B26),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? accent.withOpacity(0.4)
                            : Colors.white.withOpacity(0.04),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_off_rounded,
                          color: isSelected ? accent : Colors.white38,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                preset.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected ? accent : Colors.white,
                                ),
                              ),
                              if (preset.reverb != ReverbPreset.none)
                                Text(
                                  'Reverb: ${preset.reverb.label}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white.withOpacity(0.4),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (preset.isBuiltIn)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'FACTORY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: Colors.white.withOpacity(0.5),
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 18,
                              color: Colors.redAccent,
                            ),
                            onPressed: () {
                              onDeleteCustomPreset(preset.id);
                            },
                            tooltip: 'Delete custom preset',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
