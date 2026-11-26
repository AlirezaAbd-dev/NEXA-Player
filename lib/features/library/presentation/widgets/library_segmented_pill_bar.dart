import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/constants/phase2_keys.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/nexa_surface_tokens.dart';
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
class LibrarySegmentedPillBar extends StatefulWidget
    implements PreferredSizeWidget {
  const LibrarySegmentedPillBar({
    super.key,
    required this.selectedTab,
    this.onTabSelected,
  });

  final LibrarySubTab selectedTab;
  final ValueChanged<LibrarySubTab>? onTabSelected;

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  State<LibrarySegmentedPillBar> createState() =>
      _LibrarySegmentedPillBarState();
}

class _LibrarySegmentedPillBarState extends State<LibrarySegmentedPillBar> {
  final Map<LibrarySubTab, GlobalKey> _tabKeys = {
    for (final tab in LibrarySubTab.values) tab: GlobalKey(),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(LibrarySegmentedPillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedTab != widget.selectedTab) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
    }
  }

  void _scrollToSelected() {
    if (!mounted) return;
    final tabCtx = _tabKeys[widget.selectedTab]?.currentContext;
    if (tabCtx == null) return;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    Scrollable.ensureVisible(
      tabCtx,
      alignment: 0.5,
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPillTap(BuildContext context, LibrarySubTab tab) {
    if (tab == widget.selectedTab) return;
    HapticFeedback.selectionClick();
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(tab);
    } else {
      context.go(tab.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tokens = NexaSurfaceTokens.of(context);

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
              final isSelected = tab == widget.selectedTab;

              return Padding(
                key: _tabKeys[tab],
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
                            : tokens.l2,
                        borderRadius: BorderRadius.circular(20.0),
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
