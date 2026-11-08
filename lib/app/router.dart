import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/equalizer/presentation/screens/equalizer_screen.dart';
import '../features/library/presentation/screens/albums_tab_screen.dart';
import '../features/library/presentation/screens/artists_tab_screen.dart';
import '../features/library/presentation/screens/songs_tab_screen.dart';
import '../features/player/presentation/screens/now_playing_screen.dart';
import '../features/playlists/presentation/screens/playlists_tab_screen.dart';
import '../features/settings/presentation/screens/design_system_showcase_screen.dart';
import '../features/settings/presentation/screens/scanner_settings_screen.dart';
import '../features/settings/presentation/screens/settings_hub_screen.dart';
import '../features/themes/presentation/screens/custom_theme_editor_screen.dart';
import '../features/themes/presentation/screens/theme_picker_screen.dart';
import 'routes.dart';
import 'shell/scaffold_with_nav_bar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');

/// Central GoRouter configuration managing shell tabs and full-screen routes.
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.songs,
  routes: [
    // 1. Stateful Shell Route for Persistent Bottom Navigation & Mini-Player
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0: Songs
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.songs,
              builder: (context, state) => const SongsTabScreen(),
            ),
          ],
        ),

        // Tab 1: Albums
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.albums,
              builder: (context, state) => const AlbumsTabScreen(),
            ),
          ],
        ),

        // Tab 2: Artists
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.artists,
              builder: (context, state) => const ArtistsTabScreen(),
            ),
          ],
        ),

        // Tab 3: Playlists
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.playlists,
              builder: (context, state) => const PlaylistsTabScreen(),
            ),
          ],
        ),

        // Tab 4: Settings (with subroutes)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsHubScreen(),
              routes: [
                GoRoute(
                  path: 'theme',
                  builder: (context, state) => const ThemePickerScreen(),
                  routes: [
                    GoRoute(
                      path: 'custom',
                      builder: (context, state) =>
                          const CustomThemeEditorScreen(),
                    ),
                  ],
                ),
                GoRoute(
                  path: 'design-system',
                  builder: (context, state) =>
                      const DesignSystemShowcaseScreen(),
                ),
                GoRoute(
                  path: 'scanner',
                  builder: (context, state) =>
                      const ScannerSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 2. Full-Screen Now Playing Route
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.player,
      builder: (context, state) => const NowPlayingScreen(),
    ),

    // 3. Full-Screen Equalizer Route
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.equalizer,
      builder: (context, state) => const EqualizerScreen(),
    ),
  ],
);
