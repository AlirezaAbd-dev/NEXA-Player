import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';

/// Semantic destination item model for [GlassBottomNav].
class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.key,
    this.tooltip,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final Key? key;
  final String? tooltip;
}

/// Modern floating bottom navigation bar for the shell tabs.
///
/// Features:
/// - Floating capsule geometry with hairline border and soft blur.
/// - Active tab accent indicator and subtle pill highlight.
/// - Smooth animated transitions ([Curves.easeInOutCubic]).
/// - Zero pixel overflow on all viewport widths (320dp+).
/// - Pre-configured default destinations matching NEXA Player's 5 shell tabs.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.items = GlassBottomNav.defaultTabs,
    this.height = 68.0,
    this.blur = GlassTokens.blurExtreme,
    this.opacity = GlassTokens.opacityNav,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = GlassTokens.borderWidth,
    this.selectedColor,
    this.unselectedColor,
    this.enableBlur = true,
    this.showGlow = true,
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeInOutCubic,
  }) : super(key: key ?? const ValueKey('glass_bottom_nav'));

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;
  final double height;
  final double blur;
  final double opacity;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final Color? selectedColor;
  final Color? unselectedColor;
  final bool enableBlur;
  final bool showGlow;
  final Duration animationDuration;
  final Curve animationCurve;

  /// Default 5 tabs conforming to PROJECT.md shell route specification.
  static const List<GlassNavItem> defaultTabs = [
    GlassNavItem(
      key: ValueKey('tab_songs'),
      icon: Icons.music_note_outlined,
      selectedIcon: Icons.music_note,
      label: 'Songs',
    ),
    GlassNavItem(
      key: ValueKey('tab_albums'),
      icon: Icons.album_outlined,
      selectedIcon: Icons.album,
      label: 'Albums',
    ),
    GlassNavItem(
      key: ValueKey('tab_artists'),
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Artists',
    ),
    GlassNavItem(
      key: ValueKey('tab_playlists'),
      icon: Icons.playlist_play_outlined,
      selectedIcon: Icons.playlist_play,
      label: 'Playlists',
    ),
    GlassNavItem(
      key: ValueKey('tab_settings'),
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeAccent = selectedColor ?? theme.colorScheme.primary;
    final inactiveColor =
        unselectedColor ?? theme.colorScheme.onSurface.withOpacity(0.60);

    final resolvedBorderColor = borderColor ??
        (isDark ? const Color(0x20FFFFFF) : const Color(0x10000000));

    final effectiveBackgroundColor = backgroundColor ??
        (isDark
            ? const Color(0xFF141923).withOpacity(0.88)
            : theme.colorScheme.surface.withOpacity(0.92));

    final navRadius = BorderRadius.circular(24.0);

    Widget navContainer = Container(
      height: height,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: navRadius,
        border: borderWidth > 0
            ? Border.all(
                color: resolvedBorderColor,
                width: borderWidth,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x40000000) : const Color(0x15000000),
            blurRadius: 18.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;

            return Expanded(
              child: Tooltip(
                message: item.tooltip ?? item.label,
                child: InkWell(
                  key: item.key,
                  onTap: () => onTap(index),
                  borderRadius: navRadius,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: animationDuration,
                          curve: animationCurve,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 3.0,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? activeAccent.withOpacity(isDark ? 0.20 : 0.14)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Icon(
                            isSelected
                                ? (item.selectedIcon ?? item.icon)
                                : item.icon,
                            color: isSelected ? activeAccent : inactiveColor,
                            size: 24.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        AnimatedDefaultTextStyle(
                          duration: animationDuration,
                          curve: animationCurve,
                          style: AppTypography.labelSmall.copyWith(
                            fontFamily: 'Roboto',
                            color: isSelected ? activeAccent : inactiveColor,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );

    if (enableBlur && blur > 0) {
      return ClipRRect(
        borderRadius: navRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: navContainer,
        ),
      );
    }

    return ClipRRect(
      borderRadius: navRadius,
      child: navContainer,
    );
  }
}
