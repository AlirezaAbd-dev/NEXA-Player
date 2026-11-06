import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Transparent, blurred frosted top app bar implementing [PreferredSizeWidget].
///
/// Features:
/// - Full [BackdropFilter] blurring with configurable sigma.
/// - Integrated brightness-aware bottom border (1dp).
/// - Title with automatic [AppTypography.headlineMedium] / [AppTypography.titleLarge] styling.
/// - Automatic navigation leading icon detection (`Navigator.canPop`).
/// - Action items slot with horizontal spacing.
/// - Optional [bottom] widget (tabs, search bar) with automatic height computation.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.titleText,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.bottom,
    this.toolbarHeight = kToolbarHeight,
    this.blur = GlassTokens.blurStandard,
    this.opacity = GlassTokens.opacitySurface,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = GlassTokens.borderWidth,
    this.centerTitle,
    this.titleSpacing,
    this.elevation = 0.0,
    this.enableBlur = true,
    this.onLeadingPressed,
    this.systemOverlayStyle,
  });

  final Widget? title;
  final String? titleText;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final double toolbarHeight;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool? centerTitle;
  final double? titleSpacing;
  final double elevation;
  final bool enableBlur;
  final VoidCallback? onLeadingPressed;
  final SystemUiOverlayStyle? systemOverlayStyle;

  @override
  Size get preferredSize => Size.fromHeight(
        toolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBorderColor = GlassTokens.resolveBorderColor(
      context,
      customColor: borderColor,
    );

    final effectiveBackgroundColor = backgroundColor ??
        theme.colorScheme.surface.withOpacity(opacity);

    Widget? leadingWidget = leading;
    if (leadingWidget == null && automaticallyImplyLeading) {
      final canPop = ModalRoute.of(context)?.canPop ?? false;
      if (canPop) {
        leadingWidget = IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onLeadingPressed ?? () => Navigator.maybePop(context),
        );
      } else {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold?.hasDrawer ?? false) {
          leadingWidget = IconButton(
            icon: const Icon(Icons.menu),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
            onPressed: () => scaffold!.openDrawer(),
          );
        }
      }
    }

    Widget? titleWidget = title;
    if (titleWidget == null && titleText != null) {
      titleWidget = Text(
        titleText!,
        style: AppTypography.titleLarge.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    final effectiveSystemOverlay = systemOverlayStyle ??
        (theme.brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark);

    Widget content = AppBar(
      title: titleWidget,
      leading: leadingWidget,
      automaticallyImplyLeading: false,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing,
      backgroundColor: Colors.transparent,
      elevation: elevation,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle: effectiveSystemOverlay,
    );

    Widget backgroundBox = Container(
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        border: borderWidth > 0
            ? Border(
                bottom: BorderSide(
                  color: resolvedBorderColor,
                  width: borderWidth,
                ),
              )
            : null,
      ),
      child: content,
    );

    if (enableBlur && blur > 0) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: backgroundBox,
        ),
      );
    }

    return ClipRect(child: backgroundBox);
  }
}
