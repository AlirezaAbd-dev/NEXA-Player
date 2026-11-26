import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../../core/design_system/nexa_surface_tokens.dart';

export '../../../core/design_system/nexa_surface_tokens.dart';
export '../layout/nexa_scroll_padding.dart';

/// Architectural exceptions permitting a visible outline on a [NexaSurface].
///
/// In the borderless tonal design system, surfaces are distinguished strictly by
/// luminance elevation (L0 to L4). Decorative borders are strictly prohibited.
/// An outline may ONLY be applied when justified by one of these functional reasons:
enum SurfaceBorderReason {
  /// Keyboard, accessibility focus, or Wear OS rotary navigation focus ring.
  focusRing,

  /// Tactile control contrast state (e.g. selected EQ node, active theme swatch, waveform loop/trim handle).
  activeControlContrast,

  /// Secondary destructive action confirmation outline (e.g. clear cache, reset backup).
  destructiveSecondary,
}

/// Borderless tonal elevation container representing the Tactile Studio Instrument standard.
///
/// Distinguishes surfaces via luminance tiers ([NexaSurfaceTier.l0] through [NexaSurfaceTier.l4])
/// rather than raw borders. Zero raw [Border.all] instances are rendered unless explicitly
/// justified by an approved [SurfaceBorderReason].
class NexaSurface extends StatefulWidget {
  const NexaSurface({
    required this.child,
    super.key,
    NexaSurfaceTier? tier,
    NexaSurfaceTier? level,
    this.borderRadius = const BorderRadius.all(Radius.circular(GlassTokens.radiusCard)),
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.constraints,
    this.alignment,
    this.onTap,
    this.onLongPress,
    this.blurSigma = 0.0,
    this.borderReason,
    this.customBorderColor,
    this.borderWidth = 1.0,
    this.backgroundColor,
    this.gradient,
    this.boxShadow,
    this.clipBehavior = Clip.antiAlias,
    this.enablePressFeedback = true,
  }) : tier = tier ?? level ?? NexaSurfaceTier.l2;

  /// The widget content rendered inside the surface.
  final Widget child;

  /// Luminance elevation tier governing surface background and contrast foreground.
  final NexaSurfaceTier tier;

  /// Backwards-compatibility alias for [tier].
  NexaSurfaceTier get level => tier;

  /// Corner radius for bounds clipping and ripple shape.
  final BorderRadius borderRadius;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Outer margin surrounding the surface.
  final EdgeInsetsGeometry? margin;

  /// Explicit surface width.
  final double? width;

  /// Explicit surface height.
  final double? height;

  /// Constraints applied to the container.
  final BoxConstraints? constraints;

  /// Content alignment within the container.
  final AlignmentGeometry? alignment;

  /// Optional tap callback enabling tactile feedback and InkWell ripple.
  final VoidCallback? onTap;

  /// Optional long press callback.
  final VoidCallback? onLongPress;

  /// Optional backdrop diffusion blur sigma (typically used for floating L3 sheets/pills).
  final double blurSigma;

  /// Explicit architectural reason for applying a border. When null, border is strictly omitted.
  final SurfaceBorderReason? borderReason;

  /// Optional border color override, evaluated only when [borderReason] is non-null.
  final Color? customBorderColor;

  /// Outline width, evaluated only when [borderReason] is non-null.
  final double borderWidth;

  /// Optional background color override. If null, resolves from [NexaSurfaceTokens.colorForTier].
  final Color? backgroundColor;

  /// Optional surface gradient.
  final Gradient? gradient;

  /// Explicit box shadows. If null and [tier] is [NexaSurfaceTier.l3], resolves from [NexaSurfaceTokens.l3Shadow].
  final List<BoxShadow>? boxShadow;

  /// Clipping behavior for content and blur filters.
  final Clip clipBehavior;

  /// Whether to play subtle scale-down spring feedback on touch down.
  final bool enablePressFeedback;

  @override
  State<NexaSurface> createState() => _NexaSurfaceState();
}

class _NexaSurfaceState extends State<NexaSurface> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.enablePressFeedback && (widget.onTap != null || widget.onLongPress != null)) {
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
    final tokens = NexaSurfaceTokens.of(context);
    final effectiveBg = widget.backgroundColor ?? tokens.colorForTier(widget.tier);

    // Strict Border Exceptions: Only render a border if an approved reason is supplied
    Border? border;
    if (widget.borderReason != null && widget.borderWidth > 0) {
      final borderColor = widget.customBorderColor ?? switch (widget.borderReason!) {
        SurfaceBorderReason.focusRing => tokens.l4,
        SurfaceBorderReason.activeControlContrast => tokens.l4,
        SurfaceBorderReason.destructiveSecondary => const Color(0xFFFF3B30),
      };
      border = Border.all(color: borderColor, width: widget.borderWidth);
    }

    final effectiveShadow = widget.boxShadow ??
        (widget.tier == NexaSurfaceTier.l3 ? tokens.l3Shadow : null);

    final decoration = BoxDecoration(
      color: widget.gradient == null ? effectiveBg : null,
      gradient: widget.gradient,
      borderRadius: widget.borderRadius,
      border: border,
      boxShadow: effectiveShadow,
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

    Widget surfaceBody = Container(
      width: widget.width,
      height: widget.height,
      constraints: widget.constraints,
      decoration: decoration,
      child: innerContent,
    );

    if (widget.blurSigma > 0) {
      surfaceBody = ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: widget.clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: widget.blurSigma, sigmaY: widget.blurSigma),
          child: surfaceBody,
        ),
      );
    } else {
      surfaceBody = ClipRRect(
        borderRadius: widget.borderRadius,
        clipBehavior: widget.clipBehavior,
        child: surfaceBody,
      );
    }

    if (widget.enablePressFeedback && (widget.onTap != null || widget.onLongPress != null)) {
      surfaceBody = GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.translucent,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: surfaceBody,
        ),
      );
    }

    if (widget.margin != null) {
      surfaceBody = Padding(
        padding: widget.margin!,
        child: surfaceBody,
      );
    }

    return surfaceBody;
  }
}
