import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/equalizer/presentation/screens/equalizer_screen.dart';
import '../features/library/presentation/screens/albums_tab_screen.dart';
import '../features/library/presentation/screens/artists_tab_screen.dart';
import '../features/library/presentation/screens/folders_tab_screen.dart';
import '../features/library/presentation/screens/songs_tab_screen.dart';
import '../features/lyrics/lyrics.dart';
import '../features/player/presentation/screens/now_playing_screen.dart';
import '../features/player/presentation/screens/standby_mode_screen.dart';
import '../features/playlists/presentation/screens/playlists_tab_screen.dart';
import '../features/playlists/presentation/screens/ringtone_trimmer_screen.dart';
import '../features/search/search.dart';
import '../features/settings/settings.dart';
import '../features/themes/presentation/screens/custom_theme_editor_screen.dart';
import '../features/themes/presentation/screens/theme_picker_screen.dart';
import '../features/visualizer/visualizer.dart';
import '../features/widgets/widgets.dart';
import '../features/auto/auto.dart';
import '../features/cloud/cloud.dart';
import '../shared/models/track.dart';
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

        // Tab 3: Folders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.folders,
              builder: (context, state) => const FoldersTabScreen(),
              routes: [
                GoRoute(
                  path: ':encodedPath',
                  builder: (context, state) {
                    final encoded = state.pathParameters['encodedPath'];
                    return FoldersTabScreen(
                      initialPath: encoded != null ? Uri.decodeComponent(encoded) : null,
                    );
                  },
                ),
              ],
            ),
          ],
        ),

        // Tab 4: Playlists
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.playlists,
              builder: (context, state) => const PlaylistsTabScreen(),
            ),
          ],
        ),

        // Tab 5: Search
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.search,
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),

        // Tab 6: Settings (with subroutes)
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
                GoRoute(
                  path: 'audio',
                  builder: (context, state) =>
                      const AudioSettingsScreen(),
                ),
                GoRoute(
                  path: 'controls',
                  builder: (context, state) =>
                      const ControlSettingsScreen(),
                ),
                GoRoute(
                  path: 'album-art',
                  builder: (context, state) =>
                      const AlbumArtSettingsScreen(),
                ),
                GoRoute(
                  path: 'metadata',
                  builder: (context, state) =>
                      const MetadataLyricsSettingsScreen(),
                ),
                GoRoute(
                  path: 'power-saving',
                  builder: (context, state) =>
                      const PowerSavingSettingsScreen(),
                ),
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) =>
                      const NotificationsSettingsScreen(),
                ),
                GoRoute(
                  path: 'privacy',
                  builder: (context, state) =>
                      const PrivacyStorageSettingsScreen(),
                ),
                GoRoute(
                  path: 'visualizer',
                  builder: (context, state) =>
                      const VisualizerSettingsScreen(),
                ),
                GoRoute(
                  path: 'about',
                  builder: (context, state) =>
                      const AboutSettingsScreen(),
                ),
                GoRoute(
                  path: 'auto',
                  builder: (context, state) =>
                      const AutoWearableSettingsScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),

    // 2. Full-Screen Now Playing Route (Non-opaque modal transition with gesture dismiss support)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.player,
      pageBuilder: (context, state) => CustomTransitionPage<void>(
        key: state.pageKey,
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(curved),
            child: FadeTransition(
              opacity: curved,
              child: child,
            ),
          );
        },
        child: const NowPlayingScreen(),
      ),
    ),

    // 3. Full-Screen Equalizer Route
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.equalizer,
      builder: (context, state) => const EqualizerScreen(),
    ),

    // 4. Full-Screen Ringtone Trimmer Route
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.ringtoneTrimmer,
      builder: (context, state) {
        final track = state.extra as Track? ??
            const Track(
              id: 'demo-track',
              title: 'Ringtone Audio',
              artist: 'NEXA',
              album: 'Audio',
              duration: Duration(seconds: 180),
              filePath: '/storage/emulated/0/Music/demo.mp3',
            );
        return RingtoneTrimmerScreen(track: track);
      },
    ),

    // 5. Full-Screen Synced Lyrics Route
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.lyrics,
      builder: (context, state) => const LyricsScreen(),
    ),

    // 7. Full-Screen Homescreen Widgets Showcase & Customizer
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.widgets,
      builder: (context, state) => const WidgetShowcaseScreen(),
    ),

    // 8. Full-Screen Ambient Standby Bedside Turntable Mode
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.standby,
      builder: (context, state) => const StandbyModeScreen(),
    ),

    // 9. In-App Driving Car Mode HUD
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.carMode,
      builder: (context, state) => const CarModeScreen(),
    ),

    // 10. Wear OS & Smartwatch Remote Companion
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.wear,
      builder: (context, state) => const WearCompanionScreen(),
    ),

    // 11. Cloud & Network Streaming Hub (Phase 14)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.cloud,
      builder: (context, state) => const CloudStreamingHubScreen(),
    ),

    // 12. Remote Network Storage Browser (WebDAV / NAS)
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.cloudBrowse,
      builder: (context, state) {
        final serverId = state.uri.queryParameters['serverId'] ?? '';
        return NetworkServerBrowserScreen(serverId: serverId);
      },
    ),

    // 13. Audiophile Web Radio Broadcasts
    GoRoute(
      parentNavigatorKey: _rootNavigatorKey,
      path: AppRoutes.cloudRadio,
      builder: (context, state) => const WebRadioScreen(),
    ),
  ],
);
