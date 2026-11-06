import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Frosted modal bottom sheet with drag handle, smooth spring physics,
/// scrollable content area, and backdrop blur conforming to NEXA glassmorphism standards.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    required this.child,
    this.title,
    this.trailingAction,
    this.showDragHandle = true,
    this.maxHeightFraction = 0.85,
    this.maxWidth = 640.0,
  });

  final Widget child;
  final String? title;
  final Widget? trailingAction;
  final bool showDragHandle;
  final double maxHeightFraction;
  final double maxWidth;

  /// Displays the [AppBottomSheet] as a modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    Widget? trailingAction,
    bool isDismissible = true,
    bool enableDrag = true,
    double maxHeightFraction = 0.85,
    double maxWidth = 640.0,
    Key? key,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      elevation: 0,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return AppBottomSheet(
          key: key ?? const ValueKey('app_bottom_sheet'),
          title: title,
          trailingAction: trailingAction,
          maxHeightFraction: maxHeightFraction,
          maxWidth: maxWidth,
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.colorScheme.surface;
    final borderColor = isDark
        ? GlassTokens.borderColorLight
        : GlassTokens.borderColorDark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final clampedWidth = screenWidth > maxWidth ? maxWidth : screenWidth;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: clampedWidth,
          maxHeight: screenHeight * maxHeightFraction,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(GlassTokens.radiusCard),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: GlassTokens.blurHeavy,
              sigmaY: GlassTokens.blurHeavy,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor.withOpacity(
                  isDark ? GlassTokens.opacityElevated : 0.92,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(GlassTokens.radiusCard),
                ),
                border: Border(
                  top: BorderSide(
                    color: borderColor,
                    width: GlassTokens.borderWidth,
                  ),
                  left: BorderSide(
                    color: borderColor,
                    width: GlassTokens.borderWidth,
                  ),
                  right: BorderSide(
                    color: borderColor,
                    width: GlassTokens.borderWidth,
                  ),
                ),
                boxShadow: GlassTokens.elevationStandard,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    if (showDragHandle) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                    // Header: Title and Trailing Action
                    if (title != null || trailingAction != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        child: Row(
                          children: [
                            if (title != null)
                              Expanded(
                                child: Text(
                                  title!,
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            if (trailingAction != null) trailingAction!,
                          ],
                        ),
                      ),
                      Divider(
                        color: borderColor,
                        height: 1,
                        thickness: GlassTokens.borderWidth,
                      ),
                    ],
                    // Scrollable Content Area with bouncing/spring physics
                    Flexible(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
