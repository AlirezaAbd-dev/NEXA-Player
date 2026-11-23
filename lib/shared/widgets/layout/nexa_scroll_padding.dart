import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';

/// Computes unified scroll padding that respects system safe areas
/// and dynamic floating shell chrome (Mini-Player + Floating Nav Dock).
///
/// Ensures the bottom-most list item or button clears all floating chrome
/// with at least [extraBottom] (default 16dp) padding, while adjusting
/// automatically when the mini-player hides or sub-routes push.
EdgeInsets nexaScrollPadding(
  BuildContext context, {
  double horizontal = AppSpacing.md,
  double top = 12.0,
  double extraBottom = AppSpacing.md,
}) {
  return EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    MediaQuery.paddingOf(context).bottom + extraBottom,
  );
}

/// A reusable sliver that provides bottom spacing equal to
/// the dynamic bottom inset ([MediaQuery.paddingOf(context).bottom]) + [extraBottom].
///
/// Use at the end of [CustomScrollView.slivers] to ensure the last sliver item
/// clears floating shell chrome cleanly.
class NexaBottomInsetSliver extends StatelessWidget {
  const NexaBottomInsetSliver({
    super.key,
    this.extraBottom = AppSpacing.md,
  });

  final double extraBottom;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return SliverToBoxAdapter(
      child: SizedBox(height: bottomPadding + extraBottom),
    );
  }
}
