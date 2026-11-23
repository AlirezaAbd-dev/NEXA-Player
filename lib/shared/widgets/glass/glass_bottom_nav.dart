import 'package:flutter/material.dart';
import 'nexa_floating_nav_dock.dart';

export 'nexa_floating_nav_dock.dart';

/// Modern floating bottom navigation bar for the shell tabs.
///
/// Backwards-compatible facade routing to [NexaFloatingNavDock] — the sleek,
/// sculptural, borderless "Floating Acoustic Dock" designed for flagship audiophile
/// playback control.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onDoubleTap,
    this.items = NexaFloatingNavDock.defaultDestinations,
    this.height = 60.0,
    this.blur = 20.0,
    this.opacity,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.0,
    this.selectedColor,
    this.unselectedColor,
    this.enableBlur = true,
    this.showGlow = false,
    this.animationDuration = const Duration(milliseconds: 260),
    this.animationCurve = Curves.easeOutCubic,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final ValueChanged<int>? onDoubleTap;
  final List<NexaNavDestination> items;
  final double height;
  final double blur;
  final double? opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool enableBlur;
  final bool showGlow;
  final Duration animationDuration;
  final Curve animationCurve;

  /// Default 4 balanced destinations matching DEF-06 audiophile shell.
  static const List<NexaNavDestination> defaultTabs =
      NexaFloatingNavDock.defaultDestinations;

  @override
  Widget build(BuildContext context) {
    return NexaFloatingNavDock(
      key: key ?? const ValueKey('glass_bottom_nav'),
      currentIndex: currentIndex,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      items: items,
      height: height,
      blur: blur,
      backgroundColor: backgroundColor,
      selectedColor: selectedColor,
      unselectedColor: unselectedColor,
      enableBlur: enableBlur,
    );
  }
}
