import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Semantic variants for [AppSnackbar].
enum AppSnackbarVariant {
  info,
  success,
  warning,
  error,
}

/// Frosted floating snackbar with icon, message, action button, dismiss gesture,
/// and smooth spring entrance animation conforming to NEXA glassmorphism standards.
abstract final class AppSnackbar {
  /// Displays a frosted floating snackbar using [ScaffoldMessenger].
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason> show(
    BuildContext context, {
    required String message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    AppSnackbarVariant variant = AppSnackbarVariant.info,
    Duration duration = const Duration(seconds: 4),
    Key? key,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    final snackBar = SnackBar(
      key: key ?? const ValueKey('app_snackbar'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      padding: EdgeInsets.zero,
      duration: duration,
      dismissDirection: DismissDirection.horizontal,
      content: AppSnackbarContent(
        message: message,
        icon: icon,
        actionLabel: actionLabel,
        onAction: onAction,
        variant: variant,
      ),
    );

    return messenger.showSnackBar(snackBar);
  }
}

/// Standalone visual content widget for [AppSnackbar].
///
/// Can be embedded directly or used inside a [SnackBar].
class AppSnackbarContent extends StatelessWidget {
  const AppSnackbarContent({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.variant = AppSnackbarVariant.info,
    this.borderRadius,
    this.blur,
  });

  final String message;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final AppSnackbarVariant variant;
  final BorderRadius? borderRadius;
  final double? blur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedRadius =
        borderRadius ?? BorderRadius.circular(GlassTokens.radiusCard);
    final resolvedBlur = blur ?? GlassTokens.blurHeavy;

    final (Color accentColor, IconData defaultIcon) = switch (variant) {
      AppSnackbarVariant.info => (
          theme.colorScheme.primary,
          Icons.info_outline_rounded,
        ),
      AppSnackbarVariant.success => (
          const Color(0xFF00E676),
          Icons.check_circle_outline_rounded,
        ),
      AppSnackbarVariant.warning => (
          const Color(0xFFFFAB00),
          Icons.warning_amber_rounded,
        ),
      AppSnackbarVariant.error => (
          theme.colorScheme.error,
          Icons.error_outline_rounded,
        ),
    };

    final resolvedIcon = icon ?? defaultIcon;
    final surfaceColor = theme.colorScheme.surface;
    final borderColor = isDark
        ? GlassTokens.borderColorLight
        : GlassTokens.borderColorDark;

    return ClipRRect(
      borderRadius: resolvedRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: resolvedBlur, sigmaY: resolvedBlur),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(
              isDark ? GlassTokens.opacityElevated : 0.88,
            ),
            borderRadius: resolvedRadius,
            border: Border.all(
              color: borderColor,
              width: GlassTokens.borderWidth,
            ),
            boxShadow: GlassTokens.elevationStandard,
          ),
          child: Row(
            children: [
              // Leading Accent Icon with subtle tinted pill background
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    resolvedIcon,
                    color: accentColor,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Message text
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.bodyMedium.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Optional action button
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: AppSpacing.xs),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    onAction!();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: accentColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: AppTypography.labelMedium.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
