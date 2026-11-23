import 'package:flutter/material.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/utils/contrast_validator.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';

/// Reusable preset card displaying theme name, color swatches, active selection indicator,
/// and live player artwork preview.
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
    final rawTitleColor = cardIsDark ? Colors.white : const Color(0xFF0F172A);
    final rawSubtitleColor =
        cardIsDark ? const Color(0x99FFFFFF) : const Color(0x99000000);

    // Enforce WCAG AA contrast against card surface
    final titleColor = ensureContrast(rawTitleColor, surfaceColor, minRatio: 4.5);
    final subtitleColor =
        ensureContrast(rawSubtitleColor, surfaceColor, minRatio: 3.0);

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$title theme preset',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor.withOpacity(isDark ? 0.22 : 0.15)
                  : surfaceColor.withOpacity(isDark ? 0.75 : 0.90),
              borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
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
                            : const Color(0x0D000000),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top row: Color swatches & Selection indicator
                Row(
                  children: [
                    // Background swatch
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    // Primary accent swatch
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded, color: primaryColor, size: 20)
                    else if (trailingIcon != null)
                      trailingIcon!,
                  ],
                ),
                const SizedBox(height: 8),

                // Miniature Live Player / Artwork Preview Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.40),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                  ),
                  child: Row(
                    children: [
                      // Mini artwork vinyl tile
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 13,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Mini live track title & equalizer wave bars
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: 3,
                              width: 38,
                              decoration: BoxDecoration(
                                color: titleColor.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              height: 2.5,
                              width: 22,
                              decoration: BoxDecoration(
                                color: subtitleColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Mini animated-style EQ bars
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 2,
                            height: 6,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 1.5),
                          Container(
                            width: 2,
                            height: 10,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 1.5),
                          Container(
                            width: 2,
                            height: 4,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Title and subtitle
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: titleColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 10,
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
