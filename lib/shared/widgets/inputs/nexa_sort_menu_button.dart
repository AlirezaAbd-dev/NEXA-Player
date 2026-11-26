import 'package:flutter/material.dart';

/// Descriptor for a single sort criterion in [NexaSortMenuButton].
class NexaSortOption<T> {
  const NexaSortOption({
    required this.value,
    required this.label,
    this.key,
  });

  final T value;
  final String label;
  final Key? key;
}

/// Reusable sort popup menu button displaying all sort criteria alongside an
/// ascending/descending directional indicator on the active option.
class NexaSortMenuButton<T> extends StatelessWidget {
  const NexaSortMenuButton({
    super.key,
    required this.selected,
    required this.ascending,
    required this.options,
    required this.onSelected,
    this.tooltip,
  });

  final T selected;
  final bool ascending;
  final List<NexaSortOption<T>> options;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      icon: const Icon(Icons.sort_rounded),
      tooltip: tooltip,
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            key: option.key,
            value: option.value,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option.label),
                if (selected == option.value)
                  Icon(
                    ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
