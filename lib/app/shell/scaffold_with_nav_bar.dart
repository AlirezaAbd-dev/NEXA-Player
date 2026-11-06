import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/glass/glass_bottom_nav.dart';
import 'mini_player_slot.dart';

/// Semantic Keys matching E2EKeys.
abstract final class _ShellKeys {
  static const Key shellScaffold = ValueKey('shell_scaffold');
  static const Key bottomNav = ValueKey('glass_bottom_nav');
  static const Key navigationRail = ValueKey('navigation_rail');
  static const Key tabSongs = ValueKey('tab_songs');
  static const Key tabAlbums = ValueKey('tab_albums');
  static const Key tabArtists = ValueKey('tab_artists');
  static const Key tabPlaylists = ValueKey('tab_playlists');
  static const Key tabSettings = ValueKey('tab_settings');
}

/// Responsive Scaffold with persistent bottom navigation and mini-player slot.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    final navItems = [
      const GlassNavItem(
        icon: Icons.music_note_rounded,
        label: 'Songs',
        key: _ShellKeys.tabSongs,
      ),
      const GlassNavItem(
        icon: Icons.album_rounded,
        label: 'Albums',
        key: _ShellKeys.tabAlbums,
      ),
      const GlassNavItem(
        icon: Icons.person_rounded,
        label: 'Artists',
        key: _ShellKeys.tabArtists,
      ),
      const GlassNavItem(
        icon: Icons.playlist_play_rounded,
        label: 'Playlists',
        key: _ShellKeys.tabPlaylists,
      ),
      const GlassNavItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        key: _ShellKeys.tabSettings,
      ),
    ];

    if (isDesktop) {
      return Scaffold(
        key: _ShellKeys.shellScaffold,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Row(
          children: [
            // 1. Navigation Rail for Desktop/Tablet
            NavigationRail(
              key: _ShellKeys.navigationRail,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (idx) => _onTap(context, idx),
              labelType: NavigationRailLabelType.all,
              backgroundColor: theme.colorScheme.surface.withOpacity(0.5),
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: theme.colorScheme.primary,
                  size: 32.0,
                ),
              ),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.music_note_rounded, key: _ShellKeys.tabSongs),
                  label: Text('Songs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.album_rounded, key: _ShellKeys.tabAlbums),
                  label: Text('Albums'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_rounded, key: _ShellKeys.tabArtists),
                  label: Text('Artists'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.playlist_play_rounded, key: _ShellKeys.tabPlaylists),
                  label: Text('Playlists'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_rounded, key: _ShellKeys.tabSettings),
                  label: Text('Settings'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),

            // 2. Main Content & Mini-Player Bottom Bar
            Expanded(
              child: Column(
                children: [
                  Expanded(child: navigationShell),
                  const MiniPlayerSlot(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Handheld View
    return Scaffold(
      key: _ShellKeys.shellScaffold,
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Persistent Mini-Player Slot
            const MiniPlayerSlot(),

            // Persistent Glass Bottom Nav
            Padding(
              padding: const EdgeInsets.fromLTRB(12.0, 0, 12.0, 8.0),
              child: GlassBottomNav(
                key: _ShellKeys.bottomNav,
                currentIndex: navigationShell.currentIndex,
                onTap: (idx) => _onTap(context, idx),
                items: navItems,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
