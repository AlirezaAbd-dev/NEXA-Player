import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../routes.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../../features/player/presentation/screens/desktop_studio_dock.dart';
import '../../core/design_system/nexa_surface_tokens.dart';
import '../../shared/widgets/branding/nexa_animated_logo.dart';
import '../../shared/widgets/glass/app_ambient_background.dart';
import '../../shared/widgets/glass/nexa_floating_nav_dock.dart';
import 'mini_player_slot.dart';

/// Semantic Keys matching E2EKeys.
abstract final class _ShellKeys {
  static const Key shellScaffold = ValueKey('shell_scaffold');
  static const Key bottomNav = ValueKey('glass_bottom_nav');
  static const Key navigationRail = ValueKey('navigation_rail');
  static const Key tabLibrary = ValueKey('tab_library');
  static const Key tabSongs = ValueKey('tab_songs');
  static const Key tabAlbums = ValueKey('tab_albums');
  static const Key tabArtists = ValueKey('tab_artists');
  static const Key tabFolders = ValueKey('tab_folders');
  static const Key tabPlaylists = ValueKey('tab_playlists');
  static const Key tabSearch = ValueKey('tab_search');
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

  void _onBottomNavTap(int index) {
    if (index == 0) {
      if (navigationShell.currentIndex > 3) {
        navigationShell.goBranch(0);
      }
    } else if (index == 1) {
      navigationShell.goBranch(4);
    } else if (index == 2) {
      navigationShell.goBranch(5);
    } else if (index == 3) {
      navigationShell.goBranch(6);
    }
  }

  void _onRailTap(int index) {
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
    final isDark = theme.brightness == Brightness.dark;
    final tokens = NexaSurfaceTokens.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 800;
    final isWideStudio = width >= 1200;

    // Check whether a track is actively loaded
    final playerState = ref.watch(playerNotifierProvider);
    final hasActiveTrack = playerState.currentTrack != null;

    // Sub-Screen Route Honesty: hide bottom navigation on pushed subroutes
    String currentPath = '';
    try {
      currentPath = GoRouterState.of(context).uri.path;
    } catch (_) {}

    const rootTabPaths = {
      AppRoutes.songs,
      AppRoutes.albums,
      AppRoutes.artists,
      AppRoutes.folders,
      AppRoutes.playlists,
      AppRoutes.search,
      AppRoutes.settings,
    };

    final isSubScreen =
        currentPath.isNotEmpty && !rootTabPaths.contains(currentPath);
    final showBottomNav = !isDesktop && !isSubScreen;

    // Dynamic Bottom Inset Calculation:
    // Floating Nav Pill height: 68.0 + 8.0 bottom padding = 76.0dp
    // Mini-player height: 66.0dp
    // Inter-gap between nav pill and mini-player: 4.0dp
    const double navBarTotalHeight = 76.0;
    const double miniPlayerTotalHeight = 66.0;
    const double interGap = 4.0;

    double bottomChromeInset = 0.0;
    if (!isDesktop) {
      if (showBottomNav && hasActiveTrack) {
        bottomChromeInset =
            navBarTotalHeight + miniPlayerTotalHeight + interGap;
      } else if (showBottomNav && !hasActiveTrack) {
        bottomChromeInset = navBarTotalHeight;
      } else if (!showBottomNav && hasActiveTrack) {
        bottomChromeInset = miniPlayerTotalHeight;
      } else {
        bottomChromeInset = 0.0;
      }
    }

    final mq = MediaQuery.of(context);
    final wrappedNavigationShell = MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(
          bottom: mq.padding.bottom + bottomChromeInset,
        ),
      ),
      child: navigationShell,
    );

    // 4-Tab Balanced Bottom Navigation
    final navItems = [
      const NexaNavDestination(
        icon: Icons.library_music_outlined,
        selectedIcon: Icons.library_music_rounded,
        label: 'Library',
        key: _ShellKeys.tabLibrary,
      ),
      const NexaNavDestination(
        icon: Icons.queue_music_outlined,
        selectedIcon: Icons.queue_music_rounded,
        label: 'Playlists',
        key: _ShellKeys.tabPlaylists,
      ),
      const NexaNavDestination(
        icon: Icons.search_outlined,
        selectedIcon: Icons.search_rounded,
        label: 'Search',
        key: _ShellKeys.tabSearch,
      ),
      const NexaNavDestination(
        icon: Icons.tune_outlined,
        selectedIcon: Icons.tune_rounded,
        label: 'Settings',
        key: _ShellKeys.tabSettings,
      ),
    ];

    int bottomNavIndex = 0;
    if (navigationShell.currentIndex <= 3) {
      bottomNavIndex = 0;
    } else if (navigationShell.currentIndex == 4) {
      bottomNavIndex = 1;
    } else if (navigationShell.currentIndex == 5) {
      bottomNavIndex = 2;
    } else if (navigationShell.currentIndex == 6) {
      bottomNavIndex = 3;
    }

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
                      selectedIndex: navigationShell.currentIndex.clamp(0, 6),
                      onDestinationSelected: _onRailTap,
                      labelType: isWideStudio
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      extended: isWideStudio,
                      minWidth: 80.0,
                      minExtendedWidth: 220.0,
                      backgroundColor: tokens.l1,
                      indicatorColor:
                          theme.colorScheme.primary.withOpacity(isDark ? 0.16 : 0.12),
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      useIndicator: true,
                      leading: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const NexaAnimatedLogo(
                              size: 28,
                              mode: NexaLogoAnimationMode.static,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'NEXA',
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.music_note_outlined,
                              key: _ShellKeys.tabSongs),
                          selectedIcon: Icon(Icons.music_note_rounded),
                          label: Text('Songs'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.album_outlined,
                              key: _ShellKeys.tabAlbums),
                          selectedIcon: Icon(Icons.album_rounded),
                          label: Text('Albums'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline,
                              key: _ShellKeys.tabArtists),
                          selectedIcon: Icon(Icons.person_rounded),
                          label: Text('Artists'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.folder_outlined,
                              key: _ShellKeys.tabFolders),
                          selectedIcon: Icon(Icons.folder_rounded),
                          label: Text('Folders'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.queue_music_outlined,
                              key: _ShellKeys.tabPlaylists),
                          selectedIcon: Icon(Icons.queue_music_rounded),
                          label: Text('Playlists'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.search_outlined,
                              key: _ShellKeys.tabSearch),
                          selectedIcon: Icon(Icons.search_rounded),
                          label: Text('Search'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.tune_outlined,
                              key: _ShellKeys.tabSettings),
                          selectedIcon: Icon(Icons.tune_rounded),
                          label: Text('Settings'),
                        ),
                      ],
                    ),

                    // Zone 2: Main Content & Mini-Player Bottom Bar
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: wrappedNavigationShell),
                          if (hasActiveTrack) const MiniPlayerSlot(),
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
            body: Stack(
              fit: StackFit.expand,
              children: [
                const AppAmbientBackground(),
                wrappedNavigationShell,
                // Atmospheric Bottom Scrim
                if (showBottomNav || hasActiveTrack)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 160.0,
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              tokens.l0.withOpacity(0.85),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                // Floating bottom chrome overlay with tight hit test box
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasActiveTrack) const MiniPlayerSlot(),
                        AnimatedSwitcher(
                          duration: disableAnimations
                              ? Duration.zero
                              : const Duration(milliseconds: 240),
                          transitionBuilder: (child, animation) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0.0, 1.2),
                                end: Offset.zero,
                              ).animate(CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeOutCubic,
                              )),
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            );
                          },
                          child: showBottomNav
                              ? Padding(
                                  key: const ValueKey('dock_visible_container'),
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 0, 16.0, 16.0),
                                  child: NexaFloatingNavDock(
                                    key: _ShellKeys.bottomNav,
                                    currentIndex: bottomNavIndex,
                                    onTap: _onBottomNavTap,
                                    items: navItems,
                                  ),
                                )
                              : const SizedBox.shrink(
                                  key: ValueKey('dock_hidden_shrink'),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(node, event, ref),
      child: content,
    );
  }
}
