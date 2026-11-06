import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Frosted glass modal dialog conforming to NEXA glassmorphism standards.
///
/// Features:
/// - Full-screen backdrop blur barrier
/// - Responsive width clamping (min 280dp, max 460dp, zero overflow on phone/tablet/desktop)
/// - Title with optional leading icon
/// - Flexible/scrollable content slot
/// - Primary and secondary action buttons
/// - Spring entrance transition animation
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    this.message,
    this.content,
    this.icon,
    this.iconColor,
    this.primaryActionText,
    this.onPrimaryAction,
    this.secondaryActionText,
    this.onSecondaryAction,
    this.maxWidth = 460.0,
    this.minWidth = 280.0,
  });

  final String title;
  final String? message;
  final Widget? content;
  final IconData? icon;
  final Color? iconColor;
  final String? primaryActionText;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionText;
  final VoidCallback? onSecondaryAction;
  final double maxWidth;
  final double minWidth;

  /// Displays the [AppDialog] with a full-screen frosted backdrop blur barrier.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    String? message,
    Widget? content,
    IconData? icon,
    Color? iconColor,
    String? primaryActionText,
    VoidCallback? onPrimaryAction,
    String? secondaryActionText,
    VoidCallback? onSecondaryAction,
    bool barrierDismissible = true,
    Key? key,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.45),
      transitionDuration: const Duration(milliseconds: 250),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 12.0 * animation.value,
            sigmaY: 12.0 * animation.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: AppDialog(
            key: key ?? const ValueKey('app_dialog'),
            title: title,
            message: message,
            content: content,
            icon: icon,
            iconColor: iconColor,
            primaryActionText: primaryActionText,
            onPrimaryAction: onPrimaryAction,
            secondaryActionText: secondaryActionText,
            onSecondaryAction: onSecondaryAction,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final borderColor = isDark
        ? GlassTokens.borderColorLight
        : GlassTokens.borderColorDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final clampedWidth =
            (availableWidth - 32.0).clamp(minWidth, maxWidth);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: clampedWidth,
              minWidth: minWidth,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: GlassTokens.blurHeavy,
                  sigmaY: GlassTokens.blurHeavy,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor.withOpacity(
                      isDark ? GlassTokens.opacityElevated : 0.90,
                    ),
                    borderRadius:
                        BorderRadius.circular(GlassTokens.radiusCard),
                    border: Border.all(
                      color: borderColor,
                      width: GlassTokens.borderWidth,
                    ),
                    boxShadow: GlassTokens.elevationStandard,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header: Optional Icon + Title
                          if (icon != null) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                width: 44,
                                height: 44,
                                margin: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                decoration: BoxDecoration(
                                  color: (iconColor ?? primaryColor)
                                      .withOpacity(0.18),
                                  borderRadius: BorderRadius.circular(
                                    GlassTokens.radiusSmall,
                                  ),
                                ),
                                child: Icon(
                                  icon,
                                  color: iconColor ?? primaryColor,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                          Text(
                            title,
                            style: AppTypography.titleLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          // Message
                          if (message != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              message!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withOpacity(0.75),
                              ),
                            ),
                          ],
                          // Custom Content Slot
                          if (content != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            content!,
                          ],
                          // Actions
                          if (primaryActionText != null ||
                              secondaryActionText != null) ...[
                            const SizedBox(height: AppSpacing.xl),
                            _buildActionButtons(context, theme, primaryColor),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
  ) {
    final actions = <Widget>[
      if (secondaryActionText != null)
        TextButton(
          key: const ValueKey('app_dialog_secondary_action'),
          onPressed: () {
            if (onSecondaryAction != null) {
              onSecondaryAction!();
            } else {
              Navigator.of(context).pop();
            }
          },
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
            ),
          ),
          child: Text(secondaryActionText!),
        ),
      if (primaryActionText != null)
        ElevatedButton(
          key: const ValueKey('app_dialog_primary_action'),
          onPressed: () {
            if (onPrimaryAction != null) {
              onPrimaryAction!();
            } else {
              Navigator.of(context).pop();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
            ),
          ),
          child: Text(
            primaryActionText!,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          actions[i],
        ],
      ],
    );
  }
}
