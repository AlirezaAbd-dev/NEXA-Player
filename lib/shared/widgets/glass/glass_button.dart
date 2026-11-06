import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Style variants for [GlassButton].
enum GlassButtonVariant {
  /// Filled with accent/surface tint and glass glow.
  filled,

  /// Frosted glass fill with crisp 1dp outline border.
  outlined,

  /// Ultra-light frosted fill, borderless at rest.
  ghost,
}

/// Sizing scale for [GlassButton].
enum GlassButtonSize {
  small(
    height: 36.0,
    iconSize: 16.0,
    textStyle: AppTypography.labelMedium,
    horizontalPadding: 14.0,
  ),
  medium(
    height: 48.0,
    iconSize: 20.0,
    textStyle: AppTypography.titleMedium,
    horizontalPadding: 20.0,
  ),
  large(
    height: 56.0,
    iconSize: 24.0,
    textStyle: AppTypography.titleLarge,
    horizontalPadding: 28.0,
  );

  const GlassButtonSize({
    required this.height,
    required this.iconSize,
    required this.textStyle,
    required this.horizontalPadding,
  });

  final double height;
  final double iconSize;
  final TextStyle textStyle;
  final double horizontalPadding;
}

/// Frosted glass button with press scale animation, loading state, icon support,
/// and guaranteed WCAG touch target compliance (>= 48 dp).
class GlassButton extends StatefulWidget {
  const GlassButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.variant = GlassButtonVariant.filled,
    this.size = GlassButtonSize.medium,
    this.isLoading = false,
    this.borderRadius,
    this.blur = GlassTokens.blurSubtle,
    this.accentColor,
    this.textColor,
    this.borderColor,
    this.enablePressScale = true,
    this.pressScale = 0.96,
    this.enableHaptics = true,
    this.enableBlur = true,
    this.semanticLabel,
    this.expanded = false,
  });

  const GlassButton.filled({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = GlassButtonSize.medium,
    this.isLoading = false,
    this.borderRadius,
    this.blur = GlassTokens.blurSubtle,
    this.accentColor,
    this.textColor,
    this.borderColor,
    this.enablePressScale = true,
    this.pressScale = 0.96,
    this.enableHaptics = true,
    this.enableBlur = true,
    this.semanticLabel,
    this.expanded = false,
  }) : variant = GlassButtonVariant.filled;

  const GlassButton.outlined({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = GlassButtonSize.medium,
    this.isLoading = false,
    this.borderRadius,
    this.blur = GlassTokens.blurSubtle,
    this.accentColor,
    this.textColor,
    this.borderColor,
    this.enablePressScale = true,
    this.pressScale = 0.96,
    this.enableHaptics = true,
    this.enableBlur = true,
    this.semanticLabel,
    this.expanded = false,
  }) : variant = GlassButtonVariant.outlined;

  const GlassButton.ghost({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.trailingIcon,
    this.size = GlassButtonSize.medium,
    this.isLoading = false,
    this.borderRadius,
    this.blur = GlassTokens.blurSubtle,
    this.accentColor,
    this.textColor,
    this.borderColor,
    this.enablePressScale = true,
    this.pressScale = 0.96,
    this.enableHaptics = true,
    this.enableBlur = true,
    this.semanticLabel,
    this.expanded = false,
  }) : variant = GlassButtonVariant.ghost;

  final VoidCallback? onPressed;
  final String? label;

  /// Accepts either a [Widget] or an [IconData].
  final dynamic icon;

  /// Accepts either a [Widget] or an [IconData].
  final dynamic trailingIcon;

  final GlassButtonVariant variant;
  final GlassButtonSize size;
  final bool isLoading;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? accentColor;
  final Color? textColor;
  final Color? borderColor;
  final bool enablePressScale;
  final double pressScale;
  final bool enableHaptics;
  final bool enableBlur;
  final String? semanticLabel;
  final bool expanded;

  bool get isEnabled => onPressed != null && !isLoading;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (!widget.isEnabled) return;
    if (widget.enablePressScale) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (!widget.isEnabled) return;
    if (widget.enablePressScale) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (!widget.isEnabled) return;
    if (widget.enablePressScale) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (!widget.isEnabled) return;
    if (widget.enableHaptics) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  Widget? _resolveIcon(dynamic iconDataOrWidget, Color foregroundColor) {
    if (iconDataOrWidget == null) return null;
    if (iconDataOrWidget is IconData) {
      return Icon(
        iconDataOrWidget,
        size: widget.size.iconSize,
        color: foregroundColor,
      );
    }
    if (iconDataOrWidget is Widget) {
      return IconTheme(
        data: IconThemeData(
          size: widget.size.iconSize,
          color: foregroundColor,
        ),
        child: iconDataOrWidget,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = widget.accentColor ?? theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final resolvedRadius = widget.borderRadius ??
        BorderRadius.circular(widget.size.height / 2);

    Color backgroundColor;
    Color effectiveBorderColor;
    Color foregroundColor;
    List<BoxShadow> shadows = const [];

    switch (widget.variant) {
      case GlassButtonVariant.filled:
        backgroundColor = primary.withOpacity(
          widget.isEnabled ? (isDark ? 0.28 : 0.22) : 0.10,
        );
        effectiveBorderColor = widget.borderColor ??
            (widget.isEnabled
                ? primary.withOpacity(0.55)
                : (isDark ? GlassTokens.borderColorLight : GlassTokens.borderColorDark));
        foregroundColor = widget.textColor ??
            (widget.isEnabled ? primary : primary.withOpacity(0.4));
        if (widget.isEnabled && !_isPressed) {
          shadows = [
            BoxShadow(
              color: primary.withOpacity(0.25),
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
          ];
        }
        break;

      case GlassButtonVariant.outlined:
        backgroundColor = surface.withOpacity(
          widget.isEnabled ? (isDark ? 0.12 : 0.08) : 0.04,
        );
        effectiveBorderColor = widget.borderColor ??
            (widget.isEnabled
                ? (isDark ? GlassTokens.borderColorHighlight : const Color(0x33000000))
                : (isDark ? const Color(0x1AFFFFFF) : const Color(0x1A000000)));
        foregroundColor = widget.textColor ??
            (widget.isEnabled ? theme.colorScheme.onSurface : theme.colorScheme.onSurface.withOpacity(0.4));
        break;

      case GlassButtonVariant.ghost:
        backgroundColor = _isPressed
            ? surface.withOpacity(0.16)
            : Colors.transparent;
        effectiveBorderColor = Colors.transparent;
        foregroundColor = widget.textColor ??
            (widget.isEnabled ? primary : primary.withOpacity(0.4));
        break;
    }

    Widget content;
    if (widget.isLoading) {
      content = SizedBox(
        width: widget.size.iconSize,
        height: widget.size.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    } else {
      final children = <Widget>[];

      final leadingIcon = _resolveIcon(widget.icon, foregroundColor);
      if (leadingIcon != null) {
        children.add(leadingIcon);
      }

      if (widget.label != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(width: AppSpacing.xs));
        }
        children.add(
          Flexible(
            child: Text(
              widget.label!,
              style: widget.size.textStyle.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      final trailing = _resolveIcon(widget.trailingIcon, foregroundColor);
      if (trailing != null) {
        if (children.isNotEmpty) {
          children.add(const SizedBox(width: AppSpacing.xs));
        }
        children.add(trailing);
      }

      content = Row(
        mainAxisSize: widget.expanded ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      );
    }

    Widget buttonSurface = Container(
      height: widget.size.height,
      padding: EdgeInsets.symmetric(
        horizontal: widget.size.horizontalPadding,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: GlassTokens.borderWidth,
        ),
        boxShadow: shadows,
      ),
      child: Center(child: content),
    );

    if (widget.enableBlur) {
      buttonSurface = ClipRRect(
        borderRadius: resolvedRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blur,
            sigmaY: widget.blur,
          ),
          child: buttonSurface,
        ),
      );
    } else {
      buttonSurface = ClipRRect(
        borderRadius: resolvedRadius,
        child: buttonSurface,
      );
    }

    Widget buttonBody = Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isEnabled ? _handleTap : null,
        borderRadius: resolvedRadius,
        child: buttonSurface,
      ),
    );

    if (widget.enablePressScale) {
      buttonBody = AnimatedScale(
        scale: _isPressed ? widget.pressScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: buttonBody,
      );
    }

    return Semantics(
      button: true,
      enabled: widget.isEnabled,
      label: widget.semanticLabel ?? widget.label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 48.0,
          minHeight: 48.0,
        ),
        child: Center(
          widthFactor: widget.expanded ? 1.0 : null,
          child: buttonBody,
        ),
      ),
    );
  }
}
