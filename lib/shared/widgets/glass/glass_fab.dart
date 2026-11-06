import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Frosted Floating Action Button with 100 dp border radius, accent glow shadow,
/// and interactive press scale animation.
class GlassFAB extends StatefulWidget {
  const GlassFAB({
    required this.onPressed,
    super.key,
    this.icon,
    this.label,
    this.tooltip,
    this.accentColor,
    this.blur = GlassTokens.blurStandard,
    this.opacity = 0.25,
    this.borderRadius = GlassTokens.radiusFab,
    this.size = 56.0,
    this.elevation,
    this.enableBlur = true,
    this.heroTag,
  });

  final VoidCallback? onPressed;
  final Widget? icon;
  final Widget? label;
  final String? tooltip;
  final Color? accentColor;
  final double blur;
  final double opacity;
  final double borderRadius;
  final double size;
  final List<BoxShadow>? elevation;
  final bool enableBlur;
  final Object? heroTag;

  @override
  State<GlassFAB> createState() => _GlassFABState();
}

class _GlassFABState extends State<GlassFAB> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveAccent = widget.accentColor ?? theme.colorScheme.primary;
    final isEnabled = widget.onPressed != null;

    final resolvedBorderColor = isEnabled
        ? effectiveAccent.withOpacity(0.40)
        : Colors.white.withOpacity(0.12);

    final resolvedBackgroundColor = isEnabled
        ? effectiveAccent.withOpacity(widget.opacity)
        : theme.colorScheme.surface.withOpacity(0.10);

    final shadows = widget.elevation ??
        (isEnabled ? GlassTokens.accentGlow(effectiveAccent) : const []);

    final isExtended = widget.label != null;
    final rRadius = BorderRadius.circular(widget.borderRadius);

    Widget innerContent;
    if (isExtended) {
      innerContent = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              IconTheme(
                data: IconThemeData(color: effectiveAccent, size: 22.0),
                child: widget.icon!,
              ),
              const SizedBox(width: 8.0),
            ],
            DefaultTextStyle(
              style: AppTypography.labelLarge.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              child: widget.label!,
            ),
          ],
        ),
      );
    } else {
      innerContent = Center(
        child: IconTheme(
          data: IconThemeData(color: effectiveAccent, size: 26.0),
          child: widget.icon ?? const Icon(Icons.add),
        ),
      );
    }

    Widget buttonBody = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.onPressed,
        child: Container(
          width: isExtended ? null : widget.size,
          height: widget.size,
          constraints: isExtended
              ? BoxConstraints(minWidth: widget.size, minHeight: widget.size)
              : null,
          decoration: BoxDecoration(
            color: resolvedBackgroundColor,
            borderRadius: rRadius,
            border: Border.all(
              color: resolvedBorderColor,
              width: GlassTokens.borderWidth,
            ),
            boxShadow: shadows,
          ),
          child: innerContent,
        ),
      ),
    );

    if (widget.enableBlur && widget.blur > 0) {
      buttonBody = ClipRRect(
        borderRadius: rRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: buttonBody,
        ),
      );
    } else {
      buttonBody = ClipRRect(
        borderRadius: rRadius,
        child: buttonBody,
      );
    }

    if (widget.tooltip != null) {
      buttonBody = Tooltip(
        message: widget.tooltip!,
        child: buttonBody,
      );
    }

    if (widget.heroTag != null) {
      buttonBody = Hero(
        tag: widget.heroTag!,
        child: buttonBody,
      );
    }

    return buttonBody;
  }
}
