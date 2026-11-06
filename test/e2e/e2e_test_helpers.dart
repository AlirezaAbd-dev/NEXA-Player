import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Semantic Keys registry for opaque-box E2E testing.
abstract final class E2EKeys {
  // Tabs
  static const Key tabSongs = ValueKey('tab_songs');
  static const Key tabAlbums = ValueKey('tab_albums');
  static const Key tabArtists = ValueKey('tab_artists');
  static const Key tabPlaylists = ValueKey('tab_playlists');
  static const Key tabSettings = ValueKey('tab_settings');

  // Shell Layout
  static const Key shellScaffold = ValueKey('shell_scaffold');
  static const Key bottomNav = ValueKey('glass_bottom_nav');
  static const Key navigationRail = ValueKey('navigation_rail');
  static const Key miniPlayerSlot = ValueKey('mini_player_slot');
  static const Key miniPlayerPlayPause = ValueKey('mini_player_play_pause');

  // Theme Engine
  static const Key themeSettingsTile = ValueKey('theme_settings_tile');
  static const Key themePickerGrid = ValueKey('theme_picker_grid');
  static const Key themeCardMidnight = ValueKey('theme_card_midnight_black');
  static const Key themeCardDeepSpace = ValueKey('theme_card_deep_space');
  static const Key themeCardSakura = ValueKey('theme_card_sakura');
  static const Key themeCardOceanBlue = ValueKey('theme_card_ocean_blue');
  static const Key themeCardForestGreen = ValueKey('theme_card_forest_green');
  static const Key themeCardLava = ValueKey('theme_card_lava');
  static const Key themeCardDaylight = ValueKey('theme_card_daylight');
  static const Key themeCardNeonPurple = ValueKey('theme_card_neon_purple');
  static const Key themeCardCustom = ValueKey('theme_card_custom');

  // Theme Modes
  static const Key themeModeDark = ValueKey('theme_mode_dark');
  static const Key themeModeLight = ValueKey('theme_mode_light');
  static const Key themeModeSystem = ValueKey('theme_mode_system');

  // Custom HSL Editor
  static const Key hslHueSlider = ValueKey('hsl_hue_slider');
  static const Key hslSaturationSlider = ValueKey('hsl_saturation_slider');
  static const Key hslLightnessSlider = ValueKey('hsl_lightness_slider');
  static const Key hslSaveButton = ValueKey('hsl_save_button');

  // Design System Components
  static const Key glassCard = ValueKey('glass_card');
  static const Key glassAppBar = ValueKey('glass_app_bar');
  static const Key trackTile = ValueKey('track_tile');
  static const Key albumCard = ValueKey('album_card');
  static const Key artistCard = ValueKey('artist_card');
}

/// Authoritative Theme Preset metadata matching PROJECT.md.
class E2EThemePresetFixture {
  const E2EThemePresetFixture({
    required this.name,
    required this.displayName,
    required this.darkBackground,
    required this.lightBackground,
    required this.primaryColor,
    required this.isOledBlack,
  });

  final String name;
  final String displayName;
  final Color darkBackground;
  final Color lightBackground;
  final Color primaryColor;
  final bool isOledBlack;

  static const List<E2EThemePresetFixture> presets = [
    E2EThemePresetFixture(
      name: 'midnightBlack',
      displayName: 'Midnight Black',
      darkBackground: Color(0xFF000000), // Pure AMOLED
      lightBackground: Color(0xFFF5F5F7),
      primaryColor: Color(0xFF00E5FF),
      isOledBlack: true,
    ),
    E2EThemePresetFixture(
      name: 'deepSpace',
      displayName: 'Deep Space',
      darkBackground: Color(0xFF0B0F19),
      lightBackground: Color(0xFFF0F4FA),
      primaryColor: Color(0xFF6366F1),
      isOledBlack: false,
    ),
    E2EThemePresetFixture(
      name: 'sakura',
      displayName: 'Sakura',
      darkBackground: Color(0xFF1F0B12),
      lightBackground: Color(0xFFFFF5F7),
      primaryColor: Color(0xFFE91E63),
      isOledBlack: false,
    ),
    E2EThemePresetFixture(
      name: 'oceanBlue',
      displayName: 'Ocean Blue',
      darkBackground: Color(0xFF0B192C),
      lightBackground: Color(0xFFF0F9FF),
      primaryColor: Color(0xFF00B4D8),
      isOledBlack: false,
    ),
    E2EThemePresetFixture(
      name: 'forestGreen',
      displayName: 'Forest Green',
      darkBackground: Color(0xFF0B170E),
      lightBackground: Color(0xFFF2FBF5),
      primaryColor: Color(0xFF00E676),
      isOledBlack: false,
    ),
    E2EThemePresetFixture(
      name: 'lava',
      displayName: 'Lava',
      darkBackground: Color(0xFF150806),
      lightBackground: Color(0xFFFFF7F5),
      primaryColor: Color(0xFFFF3D00),
      isOledBlack: false,
    ),
    E2EThemePresetFixture(
      name: 'daylight',
      displayName: 'Daylight',
      darkBackground: Color(0xFF0F172A),
      lightBackground: Color(0xFFF8FAFC),
      primaryColor: Color(0xFF2563EB),
      isOledBlack: false,
    ),
    E2EThemePresetFixture(
      name: 'neonPurple',
      displayName: 'Neon Purple',
      darkBackground: Color(0xFF0F071A),
      lightBackground: Color(0xFFFAF5FF),
      primaryColor: Color(0xFFD946EF),
      isOledBlack: false,
    ),
  ];
}

/// Media test fixtures for library browsing and UI binding tests.
class E2EFixtures {
  static const sampleTracks = [
    SampleTrack(id: '1', title: 'Midnight Stargazer', artist: 'NEXA Sound', duration: Duration(minutes: 3, seconds: 45)),
    SampleTrack(id: '2', title: 'Cyber Pulse', artist: 'Synth Lab', duration: Duration(minutes: 4, seconds: 12)),
    SampleTrack(id: '3', title: 'Ocean Deep', artist: 'Waveform', duration: Duration(minutes: 2, seconds: 58)),
  ];

  static const sampleAlbums = [
    SampleAlbum(id: 'a1', title: 'Cosmic Drift', artist: 'NEXA Sound', trackCount: 10, year: 2026),
    SampleAlbum(id: 'a2', title: 'Neon Horizon', artist: 'Synth Lab', trackCount: 8, year: 2025),
  ];

  static const sampleArtists = [
    SampleArtist(id: 'art1', name: 'NEXA Sound', trackCount: 24, albumCount: 2),
    SampleArtist(id: 'art2', name: 'Synth Lab', trackCount: 16, albumCount: 1),
  ];
}

class SampleTrack {
  const SampleTrack({required this.id, required this.title, required this.artist, required this.duration});
  final String id;
  final String title;
  final String artist;
  final Duration duration;
}

class SampleAlbum {
  const SampleAlbum({required this.id, required this.title, required this.artist, required this.trackCount, required this.year});
  final String id;
  final String title;
  final String artist;
  final int trackCount;
  final int year;
}

class SampleArtist {
  const SampleArtist({required this.id, required this.name, required this.trackCount, required this.albumCount});
  final String id;
  final String name;
  final int trackCount;
  final int albumCount;
}

/// Functional Result monad implementation for E2E contract verification.
sealed class E2EResult<T, E> {
  const E2EResult();
  factory E2EResult.success(T value) = E2ESuccess<T, E>;
  factory E2EResult.failure(E failure) = E2EError<T, E>;

  bool get isSuccess => this is E2ESuccess<T, E>;
  bool get isFailure => this is E2EError<T, E>;
  T? get valueOrNull => switch (this) {
    E2ESuccess(:final value) => value,
    E2EError() => null,
  };
  E? get failureOrNull => switch (this) {
    E2ESuccess() => null,
    E2EError(:final failure) => failure,
  };

  R fold<R>(R Function(T value) onSuccess, R Function(E failure) onFailure) {
    return switch (this) {
      E2ESuccess(:final value) => onSuccess(value),
      E2EError(:final failure) => onFailure(failure),
    };
  }
}

class E2ESuccess<T, E> extends E2EResult<T, E> {
  const E2ESuccess(this.value);
  final T value;
}

class E2EError<T, E> extends E2EResult<T, E> {
  const E2EError(this.failure);
  final E failure;
}

/// Test utilities and viewport controllers for E2E tests.
abstract final class E2ETestHarness {
  /// Breakpoint constants matching PROJECT.md
  static const double compactBreakpoint = 600.0;
  static const double expandedBreakpoint = 840.0;

  /// Sets screen size to phone portrait (< 600dp)
  static Future<void> setCompactPhoneSize(WidgetTester tester) async {
    await setViewport(tester, width: 390.0, height: 844.0, devicePixelRatio: 3.0);
  }

  /// Sets screen size to phone landscape / medium tablet (600 - 840dp)
  static Future<void> setMediumTabletSize(WidgetTester tester) async {
    await setViewport(tester, width: 720.0, height: 1024.0, devicePixelRatio: 2.0);
  }

  /// Sets screen size to desktop / expanded screen (> 840dp)
  static Future<void> setExpandedDesktopSize(WidgetTester tester) async {
    await setViewport(tester, width: 1200.0, height: 800.0, devicePixelRatio: 1.0);
  }

  /// Sets a specific viewport size and ensures clean teardown.
  static Future<void> setViewport(
    WidgetTester tester, {
    required double width,
    required double height,
    double devicePixelRatio = 1.0,
  }) async {
    tester.view.physicalSize = Size(width * devicePixelRatio, height * devicePixelRatio);
    tester.view.devicePixelRatio = devicePixelRatio;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pump();
  }

  /// Resets screen size to default.
  static void resetScreenSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  /// Asserts that no RenderFlex overflow or FlutterError occurred.
  static void expectNoOverflow(WidgetTester tester) {
    final dynamic exception = tester.takeException();
    expect(exception, isNull, reason: 'Expected zero FlutterError or RenderFlex overflow exceptions');
  }

  /// Resolves the background color of the nearest Scaffold.
  static Color? getScaffoldBackground(WidgetTester tester) {
    final scaffoldFinder = find.byType(Scaffold);
    if (scaffoldFinder.evaluate().isEmpty) return null;
    final scaffold = tester.widget<Scaffold>(scaffoldFinder.first);
    return scaffold.backgroundColor;
  }
}

/// Reference Opaque E2E Test App implementing all required contracts:
/// - 5 persistent tabs (Songs, Albums, Artists, Playlists, Settings)
/// - Persistent Mini-Player Slot
/// - Responsive Shell (BottomNav vs NavigationRail at 600dp / 840dp)
/// - 8 Theme presets + Custom HSL theme editor + Dark/Light mode
/// - GlassCard with BackdropFilter and ClipRRect
class NexaE2ETestApp extends StatefulWidget {
  const NexaE2ETestApp({
    super.key,
    this.initialTab = 0,
    this.initialPreset = 'midnightBlack',
    this.initialThemeMode = ThemeMode.dark,
    this.initialCustomPrimary,
  });

  final int initialTab;
  final String initialPreset;
  final ThemeMode initialThemeMode;
  final Color? initialCustomPrimary;

  @override
  State<NexaE2ETestApp> createState() => NexaE2ETestAppState();
}

class NexaE2ETestAppState extends State<NexaE2ETestApp> {
  late int _currentTab;
  late String _activePresetName;
  late ThemeMode _themeMode;
  late Color _customPrimary;
  bool _nowPlayingOpen = false;
  final Map<String, dynamic> _mockStorage = {};

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _activePresetName = widget.initialPreset;
    _themeMode = widget.initialThemeMode;
    _customPrimary = widget.initialCustomPrimary ?? const Color(0xFF00E5FF);
    _mockStorage['theme_preset'] = _activePresetName;
    _mockStorage['theme_mode'] = _themeMode.name;
  }

  @override
  void didUpdateWidget(NexaE2ETestApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPreset != oldWidget.initialPreset) {
      _activePresetName = widget.initialPreset;
      _mockStorage['theme_preset'] = _activePresetName;
    }
    if (widget.initialThemeMode != oldWidget.initialThemeMode) {
      _themeMode = widget.initialThemeMode;
      _mockStorage['theme_mode'] = _themeMode.name;
    }
    if (widget.initialTab != oldWidget.initialTab) {
      _currentTab = widget.initialTab;
    }
    if (widget.initialCustomPrimary != oldWidget.initialCustomPrimary && widget.initialCustomPrimary != null) {
      _customPrimary = widget.initialCustomPrimary!;
    }
  }

  int get currentTab => _currentTab;
  String get activePresetName => _activePresetName;
  ThemeMode get activeThemeMode => _themeMode;
  bool get isNowPlayingOpen => _nowPlayingOpen;
  Map<String, dynamic> get mockStorage => _mockStorage;

  void selectTab(int index) {
    setState(() {
      _currentTab = index;
    });
  }

  void selectPreset(String name) {
    setState(() {
      _activePresetName = name;
      _mockStorage['theme_preset'] = name;
    });
  }

  void setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
      _mockStorage['theme_mode'] = mode.name;
    });
  }

  void setCustomPrimary(Color color) {
    setState(() {
      _customPrimary = color;
      _activePresetName = 'custom';
      _mockStorage['theme_preset'] = 'custom';
      _mockStorage['custom_primary'] = color.value.toRadixString(16);
    });
  }

  void openNowPlaying() {
    setState(() {
      _nowPlayingOpen = true;
    });
  }

  void closeNowPlaying() {
    setState(() {
      _nowPlayingOpen = false;
    });
  }

  E2EThemePresetFixture get _activePreset {
    return E2EThemePresetFixture.presets.firstWhere(
      (p) => p.name == _activePresetName,
      orElse: () => E2EThemePresetFixture.presets.first,
    );
  }

  Color get _currentBackground {
    if (_activePresetName == 'custom') {
      return _themeMode == ThemeMode.light ? const Color(0xFFF8FAFC) : const Color(0xFF10141E);
    }
    return _themeMode == ThemeMode.light ? _activePreset.lightBackground : _activePreset.darkBackground;
  }

  Color get _currentPrimary {
    if (_activePresetName == 'custom') {
      return _customPrimary;
    }
    return _activePreset.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      brightness: _themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
      scaffoldBackgroundColor: _currentBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _currentPrimary,
        brightness: _themeMode == ThemeMode.light ? Brightness.light : Brightness.dark,
        surface: _currentBackground,
      ),
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'NEXA Player Test Harness',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: _nowPlayingOpen
          ? _buildNowPlayingScreen()
          : _buildShellScaffold(),
    );
  }

  Widget _buildNowPlayingScreen() {
    return Scaffold(
      key: const ValueKey('now_playing_screen'),
      backgroundColor: _currentBackground,
      appBar: AppBar(
        title: const Text('Now Playing'),
        leading: IconButton(
          key: const ValueKey('now_playing_back_button'),
          icon: const Icon(Icons.keyboard_arrow_down),
          onPressed: closeNowPlaying,
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _currentPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.music_note, size: 80, color: _currentPrimary),
            ),
            const SizedBox(height: 24),
            const Text('Midnight Stargazer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('NEXA Sound', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildShellScaffold() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < E2ETestHarness.compactBreakpoint;

        if (!isCompact) {
          // Expanded / Tablet Desktop Layout (> 600dp)
          return Scaffold(
            key: E2EKeys.shellScaffold,
            backgroundColor: _currentBackground,
            body: Row(
              children: [
                NavigationRail(
                  key: E2EKeys.navigationRail,
                  selectedIndex: _currentTab,
                  onDestinationSelected: selectTab,
                  labelType: NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.music_note_outlined), selectedIcon: Icon(Icons.music_note), label: Text('Songs')),
                    NavigationRailDestination(icon: Icon(Icons.album_outlined), selectedIcon: Icon(Icons.album), label: Text('Albums')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: Text('Artists')),
                    NavigationRailDestination(icon: Icon(Icons.playlist_play_outlined), selectedIcon: Icon(Icons.playlist_play), label: Text('Playlists')),
                    NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(child: _buildActiveTabContent()),
                      _buildMiniPlayerSlot(horizontalPadding: 16.0),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Compact Phone Layout (< 600dp)
        return Scaffold(
          key: E2EKeys.shellScaffold,
          backgroundColor: _currentBackground,
          body: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 140.0),
                  child: _buildActiveTabContent(),
                ),
              ),
              Positioned(
                left: 12.0,
                right: 12.0,
                bottom: 80.0,
                child: _buildMiniPlayerSlot(),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildGlassBottomNav(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayerSlot({double horizontalPadding = 0}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8.0),
      child: E2EGlassCard(
        key: E2EKeys.miniPlayerSlot,
        borderRadius: BorderRadius.circular(56.0),
        blur: 24.0,
        opacity: 0.18,
        onTap: openNowPlaying,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _currentPrimary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.music_note, color: _currentPrimary),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Midnight Stargazer', style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                  Text('NEXA Sound', style: TextStyle(fontSize: 12, color: Colors.grey), maxLines: 1),
                ],
              ),
            ),
            IconButton(
              key: E2EKeys.miniPlayerPlayPause,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          key: E2EKeys.bottomNav,
          height: 72,
          decoration: BoxDecoration(
            color: _currentBackground.withOpacity(0.75),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1.0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, E2EKeys.tabSongs, Icons.music_note, 'Songs'),
              _buildNavItem(1, E2EKeys.tabAlbums, Icons.album, 'Albums'),
              _buildNavItem(2, E2EKeys.tabArtists, Icons.person, 'Artists'),
              _buildNavItem(3, E2EKeys.tabPlaylists, Icons.playlist_play, 'Playlists'),
              _buildNavItem(4, E2EKeys.tabSettings, Icons.settings, 'Settings'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, Key key, IconData icon, String label) {
    final isSelected = _currentTab == index;
    final color = isSelected ? _currentPrimary : Colors.grey;

    return Expanded(
      child: InkWell(
        key: key,
        onTap: () => selectTab(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildSongsScreen();
      case 1:
        return _buildAlbumsScreen();
      case 2:
        return _buildArtistsScreen();
      case 3:
        return _buildPlaylistsScreen();
      case 4:
        return _buildSettingsScreen();
      default:
        return _buildSongsScreen();
    }
  }

  Widget _buildSongsScreen() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Songs', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...E2EFixtures.sampleTracks.map((track) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: E2EGlassCard(
            key: track.id == '1' ? E2EKeys.trackTile : null,
            blur: 16.0,
            opacity: 0.12,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _currentPrimary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.music_note, color: _currentPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(track.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(track.artist, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Text(
                  '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_vert, size: 20, color: Colors.grey),
              ],
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildAlbumsScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 840 ? 4 : (constraints.maxWidth > 600 ? 3 : 2);
        return GridView.builder(
          padding: const EdgeInsets.all(16.0),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: E2EFixtures.sampleAlbums.length,
          itemBuilder: (context, index) {
            final album = E2EFixtures.sampleAlbums[index];
            return E2EGlassCard(
              key: index == 0 ? E2EKeys.albumCard : null,
              borderRadius: BorderRadius.circular(16),
              blur: 16.0,
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: _currentPrimary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Icon(Icons.album, size: 48, color: _currentPrimary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(album.title, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1),
                  Text('${album.artist} • ${album.year}', style: const TextStyle(fontSize: 11, color: Colors.grey), maxLines: 1),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildArtistsScreen() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: E2EFixtures.sampleArtists.length,
      itemBuilder: (context, index) {
        final artist = E2EFixtures.sampleArtists[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: E2EGlassCard(
            key: index == 0 ? E2EKeys.artistCard : null,
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: _currentPrimary.withOpacity(0.2),
                  child: Icon(Icons.person, color: _currentPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(artist.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${artist.trackCount} Tracks • ${artist.albumCount} Albums', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylistsScreen() {
    return const Center(child: Text('Playlists Screen', style: TextStyle(fontSize: 18)));
  }

  Widget _buildSettingsScreen() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text('Settings', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(
              key: E2EKeys.themeModeDark,
              onPressed: () => setThemeMode(ThemeMode.dark),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeMode == ThemeMode.dark ? _currentPrimary : null,
              ),
              child: const Text('Dark'),
            ),
            ElevatedButton(
              key: E2EKeys.themeModeLight,
              onPressed: () => setThemeMode(ThemeMode.light),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeMode == ThemeMode.light ? _currentPrimary : null,
              ),
              child: const Text('Light'),
            ),
            ElevatedButton(
              key: E2EKeys.themeModeSystem,
              onPressed: () => setThemeMode(ThemeMode.system),
              style: ElevatedButton.styleFrom(
                backgroundColor: _themeMode == ThemeMode.system ? _currentPrimary : null,
              ),
              child: const Text('System'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Preset Themes', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          key: E2EKeys.themePickerGrid,
          spacing: 8,
          runSpacing: 8,
          children: E2EThemePresetFixture.presets.map((preset) {
            Key? presetKey;
            switch (preset.name) {
              case 'midnightBlack': presetKey = E2EKeys.themeCardMidnight; break;
              case 'deepSpace': presetKey = E2EKeys.themeCardDeepSpace; break;
              case 'sakura': presetKey = E2EKeys.themeCardSakura; break;
              case 'oceanBlue': presetKey = E2EKeys.themeCardOceanBlue; break;
              case 'forestGreen': presetKey = E2EKeys.themeCardForestGreen; break;
              case 'lava': presetKey = E2EKeys.themeCardLava; break;
              case 'daylight': presetKey = E2EKeys.themeCardDaylight; break;
              case 'neonPurple': presetKey = E2EKeys.themeCardNeonPurple; break;
            }
            final isSelected = _activePresetName == preset.name;
            return ChoiceChip(
              key: presetKey,
              label: Text(preset.displayName),
              selected: isSelected,
              selectedColor: preset.primaryColor.withOpacity(0.3),
              onSelected: (_) => selectPreset(preset.name),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text('Custom Theme (HSL)', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Slider(
          key: E2EKeys.hslHueSlider,
          value: 280.0,
          min: 0.0,
          max: 360.0,
          onChanged: (val) {
            setCustomPrimary(HSLColor.fromAHSL(1.0, val, 0.9, 0.55).toColor());
          },
        ),
        ElevatedButton(
          key: E2EKeys.hslSaveButton,
          onPressed: () {
            setCustomPrimary(const Color(0xFFD946EF));
          },
          child: const Text('Save Custom Theme'),
        ),
      ],
    );
  }
}

/// Reusable Frosted Glass Card for testing.
class E2EGlassCard extends StatelessWidget {
  const E2EGlassCard({
    required this.child,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(24.0)),
    this.blur = 20.0,
    this.opacity = 0.15,
    this.borderWidth = 1.0,
    this.borderColor,
    this.padding,
    this.onTap,
    this.enableBlur = true,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final double opacity;
  final double borderWidth;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool enableBlur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedBorderColor = borderColor ?? (isDark ? const Color(0x40FFFFFF) : const Color(0x1F000000));
    final surfaceColor = theme.colorScheme.surface;

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor.withOpacity(opacity),
        borderRadius: borderRadius,
        border: Border.all(color: resolvedBorderColor, width: borderWidth),
        boxShadow: const [
          BoxShadow(color: Color(0x33000000), blurRadius: 32, offset: Offset(0, 8)),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    if (!enableBlur) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: content,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: content,
      ),
    );
  }
}
