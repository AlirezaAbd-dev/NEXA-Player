import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Reusable frosted glass container with configurable blur, opacity,
/// border, gradient, elevation shadow, and interaction support.
///
/// Ensures strict bounds clipping via [ClipRRect] so that backdrop filter
/// does not bleed across the widget tree.
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(GlassTokens.radiusCard)),
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBorderColor = GlassTokens.resolveBorderColor(
      context,
      customColor: borderColor,
    );

    final resolvedSurfaceColor = backgroundColor ??
        theme.colorScheme.surface.withOpacity(opacity);

    final border = borderWidth > 0
        ? Border.all(color: resolvedBorderColor, width: borderWidth)
        : null;

    final decoration = BoxDecoration(
      color: gradient == null ? resolvedSurfaceColor : null,
      gradient: gradient,
      borderRadius: borderRadius,
      border: border,
      boxShadow: boxShadow,
    );

    Widget innerContent = Container(
      padding: padding,
      alignment: alignment,
      child: child,
    );

    if (onTap != null || onLongPress != null) {
      innerContent = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          onLongPress: onLongPress,
          child: innerContent,
        ),
      );
    }

    Widget glassBody = Container(
      width: width,
      height: height,
      constraints: constraints,
      decoration: decoration,
      child: innerContent,
    );

    if (enableBlur && blur > 0) {
      glassBody = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: glassBody,
        ),
      );
    } else {
      glassBody = ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: clipBehavior,
        child: glassBody,
      );
    }

    if (margin != null) {
      glassBody = Padding(
        padding: margin!,
        child: glassBody,
      );
    }

    return glassBody;
  }
}
