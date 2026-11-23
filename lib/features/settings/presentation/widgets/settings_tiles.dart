import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';

/// Group card container for categorized settings with optional header title.
class SettingsGroupCard extends StatelessWidget {
  const SettingsGroupCard({
    super.key,
    this.title,
    required this.children,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 12.0,
    ),
    this.borderRadius,
  });

  final String? title;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(GlassTokens.radiusMedium);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.xs,
              top: AppSpacing.sm,
            ),
            child: Text(
              title!.toUpperCase(),
              style: AppTypography.labelSmall.copyWith(
                color: colorScheme.primary.withOpacity(0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
        NexaSurface(
          tier: NexaSurfaceTier.l1,
          padding: padding,
          borderRadius: effectiveRadius,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1)
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: colorScheme.onSurface.withOpacity(0.06),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Setting tile with toggle switch.
class SettingsSwitchTile extends StatelessWidget {
  const SettingsSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: Colors.white,
            activeTrackColor: colorScheme.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Setting tile with slider and value indicator.
class SettingsSliderTile extends StatelessWidget {
  const SettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String valueLabel;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                ),
                child: Text(
                  valueLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: colorScheme.primary,
              inactiveTrackColor: colorScheme.onSurface.withOpacity(0.12),
              thumbColor: colorScheme.primary,
              overlayColor: colorScheme.primary.withOpacity(0.2),
              trackHeight: 3.5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// Setting selector tile opening options sheet.
class SettingsSelectorTile<T> extends StatelessWidget {
  const SettingsSelectorTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final T selectedValue;
  final Map<T, String> options;
  final ValueChanged<T> onSelected;

  void _showOptionsModal(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => NexaSurface(
        tier: NexaSurfaceTier.l2,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(GlassTokens.radiusCard),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: options.entries.map((entry) {
                    final isSelected = entry.key == selectedValue;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.18)
                            : colorScheme.onSurface.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(
                          GlassTokens.radiusSmall,
                        ),
                      ),
                      child: ListTile(
                        title: Text(
                          entry.value,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        trailing: isSelected
                            ? Icon(
                                Icons.check_circle_rounded,
                                color: colorScheme.primary,
                                size: 20,
                              )
                            : null,
                        onTap: () {
                          onSelected(entry.key);
                          Navigator.of(ctx).pop();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.primary;
    final displayLabel = options[selectedValue] ?? selectedValue.toString();

    return InkWell(
      onTap: () => _showOptionsModal(context),
      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        displayLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.unfold_more_rounded,
                      size: 14,
                      color: colorScheme.primary.withOpacity(0.7),
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
}

/// Action setting tile for modals, subpage navigations, or commands.
class SettingsActionTile extends StatelessWidget {
  const SettingsActionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.trailing,
    this.isDestructive = false,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final bool isDestructive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveIconColor = isDestructive
        ? Colors.redAccent
        : (iconColor ?? colorScheme.primary);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDestructive
                          ? Colors.redAccent
                          : colorScheme.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDestructive
                            ? Colors.redAccent.withOpacity(0.7)
                            : colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colorScheme.onSurface.withOpacity(0.3),
                ),
          ],
        ),
      ),
    );
  }
}
