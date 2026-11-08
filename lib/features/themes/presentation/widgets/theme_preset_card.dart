import 'package:flutter/material.dart';

/// Reusable preset card displaying theme name, color swatches, and active selection indicator.
class ThemePresetCard extends StatelessWidget {
  const ThemePresetCard({
    required this.title,
    required this.primaryColor,
    required this.surfaceColor,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.subtitle,
    this.trailingIcon,
  });

  final String title;
  final String? subtitle;
  final Color primaryColor;
  final Color surfaceColor;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Calculate contrast against card's surfaceColor
    final cardIsDark =
        ThemeData.estimateBrightnessForColor(surfaceColor) == Brightness.dark;
    final titleColor = cardIsDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = cardIsDark ? const Color(0x99FFFFFF) : const Color(0x99000000);

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title theme preset',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: surfaceColor.withOpacity(isDark ? 0.70 : 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark
                        ? const Color(0x33FFFFFF)
                        : const Color(0x1F000000)),
                width: isSelected ? 2.0 : 1.0,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: isDark
                            ? const Color(0x30000000)
                            : const Color(0x10000000),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color swatches row
                Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cardIsDark ? Colors.white30 : Colors.black12,
                          width: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle, color: primaryColor, size: 20)
                    else if (trailingIcon != null)
                      trailingIcon!,
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
