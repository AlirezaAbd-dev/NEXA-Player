import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/phase2_keys.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/l10n/locale_controller.dart';

/// Top-level sub-tabs within the Library hub.
enum LibrarySubTab {
  songs('Songs', Icons.music_note_rounded, Phase2Keys.tabSongs, AppRoutes.songs),
  albums('Albums', Icons.album_rounded, Phase2Keys.tabAlbums, AppRoutes.albums),
  artists('Artists', Icons.person_rounded, Phase2Keys.tabArtists, AppRoutes.artists),
  folders('Folders', Icons.folder_rounded, Phase2Keys.tabFolders, AppRoutes.folders);

  const LibrarySubTab(this.label, this.icon, this.key, this.route);

  final String label;
  final IconData icon;
  final Key key;
  final String route;

  String localizedLabel(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      LibrarySubTab.songs => l10n.tabSongs,
      LibrarySubTab.albums => l10n.tabAlbums,
      LibrarySubTab.artists => l10n.tabArtists,
      LibrarySubTab.folders => l10n.tabFolders,
    };
  }
}

/// Borderless tonal segmented pill bar positioned at the top of Library views.
///
/// Features:
/// - Fast single-tap switching between Songs, Albums, Artists, and Folders.
/// - Preserves tab state through GoRouter branch navigation.
/// - Touch targets conforming to >= 48dp ergonomic accessibility standards.
/// - Borderless frosted glass pill indicators with active tonal elevation.
class LibrarySegmentedPillBar extends StatelessWidget implements PreferredSizeWidget {
  const LibrarySegmentedPillBar({
    super.key,
    required this.selectedTab,
    this.onTabSelected,
  });

  final LibrarySubTab selectedTab;
  final ValueChanged<LibrarySubTab>? onTabSelected;

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  void _onPillTap(BuildContext context, LibrarySubTab tab) {
    if (tab == selectedTab) return;
    HapticFeedback.selectionClick();
    if (onTabSelected != null) {
      onTabSelected!(tab);
    } else {
      context.go(tab.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 48.0,
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: LibrarySubTab.values.map((tab) {
              final isSelected = tab == selectedTab;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Material(
                  key: tab.key,
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onPillTap(context, tab),
                    borderRadius: BorderRadius.circular(20.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 8.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary.withOpacity(0.22)
                            : colorScheme.surface.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20.0),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary.withOpacity(0.55)
                              : Colors.white.withOpacity(0.08),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 16.0,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface.withOpacity(0.70),
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            tab.localizedLabel(context),
                            style: AppTypography.labelMedium.copyWith(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.85),
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
