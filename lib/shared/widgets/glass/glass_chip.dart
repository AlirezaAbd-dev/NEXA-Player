import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Selectable frosted glass chip for filters, tags, and category chips
/// with accent selection state, checkmark transition, and haptic feedback.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.selected,
    this.isSelected,
    this.onSelected,
    this.icon,
    this.avatar,
    this.trailing,
    this.onDeleted,
    this.showCheckmark = true,
    this.accentColor,
    this.blur = GlassTokens.blurSubtle,
    this.enableBlur = true,
    this.enableHaptics = true,
    this.borderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
  });

  /// Accepts either a [Widget] or a [String].
  final dynamic label;

  final bool? selected;
  final bool? isSelected;
  final ValueChanged<bool>? onSelected;

  /// Accepts either a [Widget] or an [IconData].
  final dynamic icon;

  final Widget? avatar;
  final Widget? trailing;
  final VoidCallback? onDeleted;
  final bool showCheckmark;
  final Color? accentColor;
  final double blur;
  final bool enableBlur;
  final bool enableHaptics;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry padding;

  bool get effectiveSelected => isSelected ?? selected ?? false;

  void _handleTap() {
    if (enableHaptics) {
      HapticFeedback.selectionClick();
    }
    onSelected?.call(!effectiveSelected);
  }

  Widget? _resolveAvatar(Color primary) {
    if (avatar != null) return avatar;
    if (icon != null) {
      if (icon is IconData) {
        return Icon(icon as IconData, size: 16.0, color: primary);
      }
      if (icon is Widget) {
        return IconTheme(
          data: IconThemeData(size: 16.0, color: primary),
          child: icon as Widget,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = accentColor ?? theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final resolvedRadius = borderRadius ?? BorderRadius.circular(GlassTokens.radiusPill);

    final backgroundColor = effectiveSelected
        ? primary.withOpacity(isDark ? 0.28 : 0.20)
        : surface.withOpacity(isDark ? 0.10 : 0.06);

    final borderColor = effectiveSelected
        ? primary.withOpacity(0.75)
        : (isDark ? GlassTokens.borderColorLight : GlassTokens.borderColorDark);

    final labelColor = effectiveSelected
        ? primary
        : theme.colorScheme.onSurface;

    final shadows = effectiveSelected
        ? [
            BoxShadow(
              color: primary.withOpacity(0.25),
              blurRadius: 10.0,
              offset: const Offset(0, 2),
            ),
          ]
        : const <BoxShadow>[];

    final resolvedAvatar = _resolveAvatar(primary);

    Widget labelWidget;
    if (label is Widget) {
      labelWidget = label as Widget;
    } else {
      labelWidget = Text(label.toString());
    }

    Widget chipSurface = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: borderColor,
          width: GlassTokens.borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (resolvedAvatar != null) ...[
            resolvedAvatar,
            const SizedBox(width: AppSpacing.xs),
          ] else if (effectiveSelected && showCheckmark) ...[
            Icon(
              Icons.check_rounded,
              size: 16.0,
              color: primary,
            ),
            const SizedBox(width: AppSpacing.xxs),
          ],
          DefaultTextStyle(
            style: AppTypography.labelMedium.copyWith(
              color: labelColor,
              fontWeight: effectiveSelected ? FontWeight.bold : FontWeight.w600,
            ),
            child: labelWidget,
          ),
          if (onDeleted != null) ...[
            const SizedBox(width: AppSpacing.xxs),
            GestureDetector(
              onTap: onDeleted,
              child: Icon(
                Icons.cancel_rounded,
                size: 16.0,
                color: labelColor.withOpacity(0.7),
              ),
            ),
          ] else if (trailing != null) ...[
            const SizedBox(width: AppSpacing.xxs),
            trailing!,
          ],
        ],
      ),
    );

    if (enableBlur) {
      chipSurface = ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: chipSurface,
        ),
      );
    } else {
      chipSurface = ClipRRect(
        borderRadius: resolvedRadius,
        child: chipSurface,
      );
    }

    return Semantics(
      button: true,
      selected: effectiveSelected,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 48.0,
          minWidth: 48.0,
        ),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onSelected != null ? _handleTap : null,
              borderRadius: resolvedRadius,
              child: chipSurface,
            ),
          ),
        ),
      ),
    );
  }
}
