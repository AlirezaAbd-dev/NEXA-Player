import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../surfaces/nexa_surface.dart';

export '../surfaces/nexa_surface.dart' show SurfaceBorderReason;

/// Frosted container delegating to [NexaSurface] under the Tactile Studio Instrument standard.
///
/// In compliance with the borderless design language, default borders are strictly eliminated
/// (`border: null`). Visible borders may only appear when explicitly justified by an approved
/// [SurfaceBorderReason] (e.g. keyboard focus rings, active control contrast, or secondary destructive actions).
class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(GlassTokens.radiusMedium)),
    this.blur = GlassTokens.blurStandard,
    this.opacity = GlassTokens.opacityStandard,
    this.borderWidth = GlassTokens.borderWidth,
    this.borderColor,
    this.borderReason,
    this.tier = NexaSurfaceTier.l2,
    this.backgroundColor,
    this.gradient,
    this.boxShadow = GlassTokens.elevationStandard,
    this.padding = const EdgeInsets.all(AppSpacing.md),
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

  /// Named constructor for unpadded full-bleed cards (waveforms, EQ canvases, custom containers).
  const GlassCard.raw({
    required this.child,
    super.key,
    this.borderRadius =
        const BorderRadius.all(Radius.circular(GlassTokens.radiusMedium)),
    this.blur = GlassTokens.blurStandard,
    this.opacity = GlassTokens.opacityStandard,
    this.borderWidth = GlassTokens.borderWidth,
    this.borderColor,
    this.borderReason,
    this.tier = NexaSurfaceTier.l2,
    this.backgroundColor,
    this.gradient,
    this.boxShadow = GlassTokens.elevationStandard,
    this.padding = EdgeInsets.zero,
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

  /// The child content.
  final Widget child;

  /// Corner radius.
  final BorderRadius borderRadius;

  /// Backdrop blur radius.
  final double blur;

  /// Legacy opacity parameter (retained for backward compatibility).
  final double opacity;

  /// Outline width, used only when [borderReason] is non-null.
  final double borderWidth;

  /// Custom outline color override, used only when [borderReason] is non-null.
  final Color? borderColor;

  /// Explicit architectural reason for applying a border. When null, border is strictly omitted.
  final SurfaceBorderReason? borderReason;

  /// Tonal elevation tier ($L_0$ to $L_4$). Defaults to [NexaSurfaceTier.l2].
  final NexaSurfaceTier tier;

  /// Background color override.
  final Color? backgroundColor;

  /// Optional surface gradient.
  final Gradient? gradient;

  /// Box shadows.
  final List<BoxShadow>? boxShadow;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Explicit width.
  final double? width;

  /// Explicit height.
  final double? height;

  /// Box constraints.
  final BoxConstraints? constraints;

  /// Inner alignment.
  final AlignmentGeometry? alignment;

  /// Tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// Whether backdrop blur is enabled.
  final bool enableBlur;

  /// Content clip behavior.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    return NexaSurface(
      tier: tier,
      borderRadius: borderRadius,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      constraints: constraints,
      alignment: alignment,
      onTap: onTap,
      onLongPress: onLongPress,
      blurSigma: enableBlur && blur > 0 ? blur : 0.0,
      borderReason: borderReason,
      customBorderColor: borderColor,
      borderWidth: borderWidth,
      backgroundColor: backgroundColor,
      gradient: gradient,
      boxShadow: boxShadow,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
