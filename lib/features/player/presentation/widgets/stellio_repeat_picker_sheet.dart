import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/entities/playback_state.dart';

/// Maps each of the 5 Stellio repeat modes to a distinct Material vector icon.
IconData iconForNexaRepeatMode(NexaRepeatMode mode) {
  switch (mode) {
    case NexaRepeatMode.stopOnLastTrack:
      return Icons.repeat_rounded;
    case NexaRepeatMode.repeatList:
      return Icons.repeat_on_rounded;
    case NexaRepeatMode.repeatSelectedTrack:
      return Icons.repeat_one_on_rounded;
    case NexaRepeatMode.nextListStopOnLast:
      return Icons.playlist_play_rounded;
    case NexaRepeatMode.nextListRepeatFirst:
      return Icons.all_inclusive_rounded;
  }
}

/// Shows a borderless tonal bottom sheet letting the user pick any of the
/// 5 Stellio repeat & cross-list continuation modes in a single tap.
Future<void> showStellioRepeatPickerSheet({
  required BuildContext context,
  required NexaRepeatMode activeMode,
  required ValueChanged<NexaRepeatMode> onSelected,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final tokens = NexaSurfaceTokens.of(context);
  final bottomPadding = MediaQuery.viewPaddingOf(context).bottom;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md + bottomPadding * 0.25,
          ),
          child: NexaSurface(
            key: const Key('stellio_repeat_picker_sheet'),
            level: NexaSurfaceLevel.l3,
            borderRadius: BorderRadius.circular(24.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36.0,
                      height: 4.0,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurface.withOpacity(0.24),
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Repeat & List Continuation',
                    style: Theme.of(sheetContext).textTheme.titleMedium?.copyWith(
                          color: tokens.onL3,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Choose how playback behaves at track and list boundaries.',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                          color: tokens.onL3.withOpacity(0.72),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final mode in NexaRepeatMode.values)
                    _RepeatModeOptionRow(
                      mode: mode,
                      isSelected: mode == activeMode,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onSelected(mode);
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RepeatModeOptionRow extends StatelessWidget {
  const _RepeatModeOptionRow({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final NexaRepeatMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = NexaSurfaceTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: isSelected
            ? colorScheme.primary.withOpacity(0.16)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14.0),
        child: InkWell(
          key: Key('repeat_option_${mode.name}'),
          borderRadius: BorderRadius.circular(14.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 38.0,
                  height: 38.0,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : tokens.l2,
                    borderRadius: BorderRadius.circular(11.0),
                  ),
                  child: Icon(
                    iconForNexaRepeatMode(mode),
                    size: 20.0,
                    color: isSelected
                        ? colorScheme.onPrimary
                        : tokens.onL2.withOpacity(0.84),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mode.label,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: tokens.onL3,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        mode.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: tokens.onL3.withOpacity(0.70),
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: colorScheme.primary,
                    size: 20.0,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
