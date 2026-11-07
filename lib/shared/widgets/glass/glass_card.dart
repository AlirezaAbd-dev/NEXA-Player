import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Reusable frosted glass container with configurable blur, opacity,
/// border, gradient, elevation shadow, and tactile interaction support.
///
/// Features:
/// - Optical backdrop diffusion via [BackdropFilter].
/// - Specular dual-stop surface gradient by default.
/// - Inner specular top-edge gloss reflection.
/// - Tactile micro-scale feedback on tap.
/// - Strict bounds clipping via [ClipRRect].
class GlassCard extends StatefulWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(GlassTokens.radiusCard)),
    this.blur = GlassTokens.blurStandard,
    this.opacity = GlassTokens.opacityStandard,
    this.borderWidth = GlassTokens.borderWidth,
    this.borderColor,
    this.backgroundColor,
    this.gradient,
    this.boxShadow = GlassTokens.elevationStandard,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.onTap,
    this.onLongPress,
    this.enableBlur = true,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final double opacity;
  final double borderWidth;
  final Color? borderColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxConstraints? constraints;
  final AlignmentGeometry? alignment;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableBlur;
  final Clip clipBehavior;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedBorderColor = GlassTokens.resolveBorderColor(
      context,
      customColor: widget.borderColor,
    );

    final border = widget.borderWidth > 0
        ? Border.all(color: resolvedBorderColor, width: widget.borderWidth)
        : null;

    final effectiveGradient = widget.gradient ??
        GlassTokens.glassSurfaceGradient(
          context,
          surfaceColor: widget.backgroundColor,
          opacity: widget.opacity,
        );

    final decoration = BoxDecoration(
      gradient: effectiveGradient,
      borderRadius: widget.borderRadius,
      border: border,
      boxShadow: widget.boxShadow,
    );

    Widget innerContent = Container(
      padding: widget.padding,
      alignment: widget.alignment,
      child: widget.child,
    );

    if (widget.onTap != null || widget.onLongPress != null) {
      innerContent = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: widget.borderRadius,
          onTap: widget.onTap,
          onLongPress: widget.onLongPress,
          child: innerContent,
        ),
      );
    }

    // Stack with inner specular top highlight
    final bodyStack = Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? Colors.white : Colors.white).withOpacity(isDark ? 0.14 : 0.40),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.22],
                ),
              ),
            ),
          ),
        ),
        innerContent,
      ],
    );

    Widget glassBody = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      decoration: decoration,
      child: bodyStack,
    );

    if (widget.enableBlur && widget.blur > 0) {
      glassBody = ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: widget.clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blur, sigmaY: widget.blur),
          child: glassBody,
        ),
      );
    } else {
      glassBody = ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: widget.clipBehavior,
        child: glassBody,
      );
    }

    if (widget.onTap != null || widget.onLongPress != null) {
      glassBody = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.translucent,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: glassBody,
        ),
      );
    }

    if (widget.margin != null) {
      glassBody = Padding(
        padding: widget.margin!,
        child: glassBody,
      );
    }

    return glassBody;
  }
}
