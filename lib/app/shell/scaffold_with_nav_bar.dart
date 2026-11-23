import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../../features/player/presentation/screens/desktop_studio_dock.dart';
import '../../shared/widgets/glass/app_ambient_background.dart';
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

/// Responsive Scaffold with persistent bottom navigation, hardware keyboard shortcuts,
/// and adaptive 3-zone Desktop Studio layout (width >= 1200dp).
class ScaffoldWithNavBar extends ConsumerWidget {
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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event, WidgetRef ref) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    final notifier = ref.read(playerNotifierProvider.notifier);
    final playerState = ref.read(playerNotifierProvider);

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      if (playerState.isPlaying) {
        notifier.pause();
      } else {
        notifier.play();
      }
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyJ) {
      final newPos = playerState.position - const Duration(seconds: 10);
      notifier.seek(newPos < Duration.zero ? Duration.zero : newPos);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyL) {
      final newPos = playerState.position + const Duration(seconds: 10);
      notifier.seek(newPos > playerState.duration ? playerState.duration : newPos);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      notifier.skipNext();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      notifier.skipPrevious();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final isWideStudio = width >= 1200;

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

    final content = isDesktop
        ? Scaffold(
            key: _ShellKeys.shellScaffold,
            backgroundColor: Colors.transparent,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AppAmbientBackground(),
                Row(
                  children: [
                    // Zone 1: Navigation Rail for Desktop/Tablet
                    NavigationRail(
                      key: _ShellKeys.navigationRail,
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: (idx) => _onTap(context, idx),
                      labelType: NavigationRailLabelType.all,
                      backgroundColor:
                          theme.colorScheme.surface.withOpacity(0.35),
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
                          icon: Icon(Icons.music_note_rounded,
                              key: _ShellKeys.tabSongs),
                          label: Text('Songs'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.album_rounded,
                              key: _ShellKeys.tabAlbums),
                          label: Text('Albums'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_rounded,
                              key: _ShellKeys.tabArtists),
                          label: Text('Artists'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.playlist_play_rounded,
                              key: _ShellKeys.tabPlaylists),
                          label: Text('Playlists'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_rounded,
                              key: _ShellKeys.tabSettings),
                          label: Text('Settings'),
                        ),
                      ],
                    ),

                    // Zone 2: Main Content & Mini-Player Bottom Bar
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: navigationShell),
                          const MiniPlayerSlot(),
                        ],
                      ),
                    ),

                    // Zone 3: Dockable Studio Inspector (Width >= 1200dp)
                    if (isWideStudio) const DesktopStudioDock(),
                  ],
                ),
              ],
            ),
          )
        : Scaffold(
            key: _ShellKeys.shellScaffold,
            backgroundColor: Colors.transparent,
            extendBody: true,
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AppAmbientBackground(),
                navigationShell,
              ],
            ),
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

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(node, event, ref),
      child: content,
    );
  }
}
