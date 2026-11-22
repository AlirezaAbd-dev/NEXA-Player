import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/app/app.dart';
import 'package:nexa_player/app/router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_controller.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/theme/theme_state.dart';
import 'package:nexa_player/features/auto/auto.dart';
import 'package:nexa_player/features/equalizer/domain/services/equalizer_service.dart';
import 'package:nexa_player/features/library/presentation/screens/album_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/screens/folders_tab_screen.dart';
import 'package:nexa_player/features/lyrics/lyrics.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:nexa_player/features/playlists/presentation/screens/ringtone_trimmer_screen.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/standby_mode_screen.dart';
import 'package:nexa_player/features/search/search.dart';
import 'package:nexa_player/features/settings/settings.dart';
import 'package:nexa_player/features/visualizer/visualizer.dart';
import 'package:nexa_player/features/widgets/widgets.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kOutDirPath =
    '/home/alirezaabd/.gemini/antigravity/brain/9a4e382c-d6b7-45ad-83c1-21f1a8158d7f/screenshots';

Future<void> _loadFonts() async {
  final fontLoaderRoboto = FontLoader('Roboto');
  final regularBytes = File(
          '/home/alirezaabd/development/flutter/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf')
      .readAsBytesSync();
  final boldBytes = File(
          '/home/alirezaabd/development/flutter/bin/cache/artifacts/material_fonts/Roboto-Bold.ttf')
      .readAsBytesSync();
  final mediumBytes = File(
          '/home/alirezaabd/development/flutter/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf')
      .readAsBytesSync();

  fontLoaderRoboto.addFont(Future.value(ByteData.view(regularBytes.buffer)));
  fontLoaderRoboto.addFont(Future.value(ByteData.view(boldBytes.buffer)));
  fontLoaderRoboto.addFont(Future.value(ByteData.view(mediumBytes.buffer)));
  await fontLoaderRoboto.load();

  final fontLoaderAhem = FontLoader('Ahem');
  fontLoaderAhem.addFont(Future.value(ByteData.view(regularBytes.buffer)));
  fontLoaderAhem.addFont(Future.value(ByteData.view(boldBytes.buffer)));
  fontLoaderAhem.addFont(Future.value(ByteData.view(mediumBytes.buffer)));
  await fontLoaderAhem.load();

  final fontLoaderIcons = FontLoader('MaterialIcons');
  final iconBytes = File(
          '/home/alirezaabd/development/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
      .readAsBytesSync();
  fontLoaderIcons.addFont(Future.value(ByteData.view(iconBytes.buffer)));
  await fontLoaderIcons.load();
}

Future<void> _captureWidget({
  required WidgetTester tester,
  required Widget widget,
  required String filename,
  Size size = const Size(393 * 2.0, 852 * 2.0),
  double pixelRatio = 2.0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = pixelRatio;

  final repaintKey = GlobalKey();

  await tester.pumpWidget(
    RepaintBoundary(
      key: repaintKey,
      child: widget,
    ),
  );

  await tester.pump(const Duration(milliseconds: 600));

  await tester.runAsync(() async {
    final boundary =
        repaintKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    final file = File('$_kOutDirPath/$filename');
    file.writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Generated $filename (${bytes.length} bytes)');
  });
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await configureDependencies();
    final outDir = Directory(_kOutDirPath);
    if (!outDir.existsSync()) {
      outDir.createSync(recursive: true);
    }
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('Generate all high-fidelity NEXA Player UI screenshots',
      (tester) async {
    await tester.runAsync(() async {
      await _loadFonts();
    });

    addTearDown(tester.view.resetPhysicalSize);
    tester.platformDispatcher.platformBrightnessTestValue = ui.Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    // =========================================================================
    // 1. Navigation Shell Tabs (Songs, Albums, Artists, Playlists, Settings)
    // =========================================================================

    // 1.1 Songs Tab Screen (Default Midnight Black Dark Preset)
    appRouter.go(AppRoutes.songs);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '01_songs_tab.png',
    );

    // 1.2 Albums Tab Screen
    appRouter.go(AppRoutes.albums);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '02_albums_grid.png',
    );

    // 1.3 Artists Tab Screen
    appRouter.go(AppRoutes.artists);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '04_artists_tab.png',
    );

    // 1.4 Playlists Tab Screen
    appRouter.go(AppRoutes.playlists);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '06_playlists_tab.png',
    );

    // 1.5 Settings Hub Screen
    appRouter.go(AppRoutes.settings);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '09_settings_hub.png',
    );

    // =========================================================================
    // 2. Settings Subroutes (Scanner Settings, Theme Picker, Custom Editor, Showcase)
    // =========================================================================

    // 2.1 Scanner Settings Screen
    appRouter.go(AppRoutes.scannerSettings);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '10_scanner_settings.png',
    );

    // 2.2 Theme Picker Screen
    appRouter.go(AppRoutes.themePicker);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '11_theme_picker.png',
    );

    // 2.3 Custom Theme Editor Screen
    appRouter.go(AppRoutes.customTheme);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '12_custom_theme_editor.png',
    );

    // 2.4 Design System Showcase Screen
    appRouter.go(AppRoutes.designSystem);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '13_design_system_showcase.png',
    );

    // 2.5 Full-Screen Now Playing Screen
    appRouter.go(AppRoutes.player);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '14_now_playing_screen.png',
    );

    // 2.6 Full-Screen Equalizer & DSP Engine Screen
    if (getIt.isRegistered<IEqualizerService>()) {
      await getIt<IEqualizerService>().applyPreset('rock');
    }
    appRouter.go(AppRoutes.equalizer);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '18_equalizer_dsp_screen.png',
    );

    // =========================================================================
    // 3. Detail Screens (Album Detail, Artist Detail, Playlist Detail, Folders Tab)
    // =========================================================================

    final darkTheme = AppTheme.buildTheme(
      preset: ThemePreset.midnightBlack,
      mode: ThemeMode.dark,
      fontFamily: 'Roboto',
    );

    // 3.1 Album Detail Screen ("Random Access Memories")
    const sampleAlbum = Album(
      id: 'alb-ram',
      title: 'Random Access Memories',
      artist: 'Daft Punk',
      year: 2013,
      trackCount: 13,
    );
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const AlbumDetailScreen(album: sampleAlbum),
        ),
      ),
      filename: '03_album_detail.png',
    );

    // 3.2 Artist Detail Screen ("The Weeknd")
    const sampleArtist = Artist(
      id: 'art-the-weeknd',
      name: 'The Weeknd',
      trackCount: 32,
      albumCount: 5,
    );
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const ArtistDetailScreen(artist: sampleArtist),
        ),
      ),
      filename: '05_artist_detail.png',
    );

    // 3.3 Playlist Detail Screen ("Smart Playlists")
    final samplePlaylist = Playlist(
      id: 'pl-smart',
      name: 'Smart Playlists',
      trackCount: 3,
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(1000),
    );
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: PlaylistDetailScreen(playlist: samplePlaylist),
        ),
      ),
      filename: '07_playlist_detail.png',
    );

    // 3.4 Folders Tab Screen (Local Folder Hierarchy)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const FoldersTabScreen(),
        ),
      ),
      filename: '08_folders_tab.png',
    );

    // 3.5 Ringtone Trimmer Screen (Phase 6 Audio Slicing)
    const sampleTrack = Track(
      id: 'trk-ringtone',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(seconds: 243),
      filePath: '/music/m83/midnight_city.mp3',
    );
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const RingtoneTrimmerScreen(track: sampleTrack),
        ),
      ),
      filename: '19_ringtone_trimmer_screen.png',
    );

    // 3.6 Synced Lyrics Karaoke Screen (Phase 7 Lyrics System)
    const sampleLyrics = Lyrics(
      trackId: 'trk-ringtone',
      isSynced: true,
      source: LyricsSource.lrclib,
      lines: [
        LyricLine(timestamp: Duration(seconds: 15), text: 'Waiting in a car'),
        LyricLine(timestamp: Duration(seconds: 18), text: 'Waiting for a ride in the dark'),
        LyricLine(timestamp: Duration(seconds: 22), text: 'The night city grows'),
        LyricLine(timestamp: Duration(seconds: 26), text: 'Look and see her eyes, they glow'),
        LyricLine(timestamp: Duration(seconds: 30), text: 'Waiting in a car'),
        LyricLine(timestamp: Duration(seconds: 34), text: 'Waiting for a ride in the dark'),
        LyricLine(timestamp: Duration(seconds: 38), text: 'The night city grows'),
      ],
    );
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        overrides: [
          currentTrackProvider.overrideWithValue(sampleTrack),
          activeLyricIndexProvider.overrideWithValue(2),
          trackLyricsProvider(sampleTrack).overrideWith((ref) => Future.value(sampleLyrics)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const LyricsScreen(),
        ),
      ),
      filename: '20_lyrics_screen.png',
    );

    // 3.7 Cross-Library Search Screen (Phase 8 Search & Filter)
    const searchSampleTrack1 = Track(
      id: 'trk-search-1',
      title: 'Starboy (feat. Daft Punk)',
      artist: 'The Weeknd',
      album: 'Starboy',
      duration: Duration(seconds: 230),
      filePath: '/music/starboy.mp3',
    );
    const searchSampleTrack2 = Track(
      id: 'trk-search-2',
      title: 'I Feel It Coming',
      artist: 'The Weeknd',
      album: 'Starboy',
      duration: Duration(seconds: 269),
      filePath: '/music/feel_it.mp3',
    );
    const searchSampleAlbum = Album(
      id: 'alb-search-1',
      title: 'Starboy',
      artist: 'The Weeknd',
      year: 2016,
      trackCount: 18,
    );
    const searchSampleArtist = Artist(
      id: 'art-search-1',
      name: 'The Weeknd',
      trackCount: 18,
      albumCount: 1,
    );
    const searchDemoResult = SearchResult(
      query: 'Starboy',
      tracks: [searchSampleTrack1, searchSampleTrack2],
      albums: [searchSampleAlbum],
      artists: [searchSampleArtist],
    );

    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        overrides: [
          searchQueryProvider.overrideWith((ref) => 'Starboy'),
          searchCategoryProvider.overrideWith((ref) => SearchResultCategory.all),
          searchResultsProvider.overrideWith((ref) => Future.value(searchDemoResult)),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const SearchScreen(),
        ),
      ),
      filename: '21_search_screen.png',
    );

    // 3.7 Settings In-Hub Live Search
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        overrides: [
          settingsSearchQueryProvider.overrideWith((ref) => 'crossfade'),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const SettingsHubScreen(),
        ),
      ),
      filename: '22_settings_hub_search.png',
    );

    // 3.8 Audio Settings Screen (Full Hardware & Output Configurations)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        overrides: [
          audioSettingsProvider.overrideWith((ref) {
            final s = AudioSettingsNotifier(getIt<ISettingsService>());
            s.update(const AudioSettings(
              crossfadeEnabled: true,
              crossfadeDurationSeconds: 4,
              sampleRate: '96',
              bitDepth: '24',
              audioOutput: 'usb_dac',
              replayGainMode: 'smart',
              replayGainPreampDb: 3.5,
            ));
            return s;
          }),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const AudioSettingsScreen(),
        ),
      ),
      filename: '23_audio_settings.png',
    );

    // 3.14 Visualizer & Spectrum Engine Settings (Phase 10)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const VisualizerSettingsScreen(),
        ),
      ),
      filename: '24_visualizer_spectrum.png',
    );

    // 3.15 Homescreen Widgets Showcase & Customizer (Phase 12)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const WidgetShowcaseScreen(),
        ),
      ),
      filename: '25_homescreen_widgets.png',
    );

    // 3.16 Ambient Bedside Standby Turntable & Clock Mode (Phase 12)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const StandbyModeScreen(),
        ),
      ),
      filename: '26_standby_bedside_mode.png',
    );

    // 3.17 In-App Car Mode Driving Dashboard (Phase 13)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const CarModeScreen(),
        ),
      ),
      filename: '27_car_mode_dashboard.png',
    );

    // 3.18 Wear OS Smartwatch Remote Companion (Phase 13)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const WearCompanionScreen(),
        ),
      ),
      filename: '28_wear_os_companion.png',
    );

    // 3.19 Auto & Wearable Settings (Phase 13)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const AutoWearableSettingsScreen(),
        ),
      ),
      filename: '29_auto_wearable_settings.png',
    );

    // 3.20 About & Audiophile Specs Screen (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const AboutSettingsScreen(),
        ),
      ),
      filename: '30_about_settings.png',
    );

    // 3.21 Album Art & Covers Cache Settings (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const AlbumArtSettingsScreen(),
        ),
      ),
      filename: '31_album_art_settings.png',
    );

    // 3.22 Gesture & Headset Controls Settings (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const ControlSettingsScreen(),
        ),
      ),
      filename: '32_control_settings.png',
    );

    // 3.23 Lock Screen & Notifications Settings (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const NotificationsSettingsScreen(),
        ),
      ),
      filename: '33_notifications_settings.png',
    );

    // 3.24 Power Saving & Audio Focus Settings (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const PowerSavingSettingsScreen(),
        ),
      ),
      filename: '34_power_saving_settings.png',
    );

    // 3.25 Privacy & Storage Backup Settings (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const PrivacyStorageSettingsScreen(),
        ),
      ),
      filename: '35_privacy_storage_settings.png',
    );

    // 3.26 Metadata & Lyrics Provider Settings (Phase 9)
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: darkTheme,
          home: const MetadataLyricsSettingsScreen(),
        ),
      ),
      filename: '36_metadata_lyrics_settings.png',
    );

    // =========================================================================
    // 4. Multi-Theme Variations (Daylight Light Mode & Sakura Pink Preset)
    // =========================================================================

    // 4.1 Songs Tab in Daylight (Light Theme Mode)
    tester.platformDispatcher.platformBrightnessTestValue = ui.Brightness.light;
    appRouter.go(AppRoutes.songs);
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        overrides: [
          themeControllerProvider.overrideWith(() => _PresetThemeController(
                ThemePreset.daylight,
                ThemeMode.light,
              )),
        ],
        child: const NexaPlayerApp(),
      ),
      filename: '15_daylight_theme_songs.png',
    );
    tester.platformDispatcher.platformBrightnessTestValue = ui.Brightness.dark;

    // 4.2 Albums Tab in Sakura (Pink/Crimson Accent Preset)
    appRouter.go(AppRoutes.albums);
    await _captureWidget(
      tester: tester,
      widget: ProviderScope(
        overrides: [
          themeControllerProvider.overrideWith(() => _PresetThemeController(
                ThemePreset.sakura,
                ThemeMode.dark,
              )),
        ],
        child: const NexaPlayerApp(),
      ),
      filename: '16_sakura_theme_albums.png',
    );

    // =========================================================================
    // 5. Responsive Desktop/Tablet Layout (NavigationRail + Expanded Viewport)
    // =========================================================================
    appRouter.go(AppRoutes.albums);
    await _captureWidget(
      tester: tester,
      widget: const ProviderScope(child: NexaPlayerApp()),
      filename: '17_desktop_layout.png',
      size: const Size(1200 * 2.0, 800 * 2.0),
    );
  });
}

class _PresetThemeController extends ThemeController {
  _PresetThemeController(this._preset, this._mode);
  final ThemePreset _preset;
  final ThemeMode _mode;

  @override
  ThemeState build() => ThemeState(preset: _preset, themeMode: _mode);
}
