import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/theme/dynamic_palette_providers.dart';
import '../../../../shared/models/track.dart';
import '../../../lyrics/presentation/providers/lyrics_providers.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../domain/models/widget_config.dart';
import '../providers/widget_providers.dart';
import '../widgets/compact_widget_card.dart';
import '../widgets/hero_vinyl_widget_card.dart';
import '../widgets/karaoke_widget_card.dart';
import '../widgets/square_widget_card.dart';

/// Interactive showcase and customization screen for homescreen widgets.
class WidgetShowcaseScreen extends ConsumerWidget {
  const WidgetShowcaseScreen({super.key});

  static const Track _sampleTrack = Track(
    id: 'sample_widget_track',
    title: 'Cybernetic Echoes',
    artist: 'NEXA Acoustic Engine',
    album: 'Obsidian Soundscapes Vol. 1',
    duration: Duration(minutes: 4, seconds: 5),
    filePath: '/music/cybernetic_echoes.flac',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final config = ref.watch(widgetConfigProvider);
    final selectedFormFactor = ref.watch(selectedWidgetFormFactorProvider);

    // Audio Player State
    final playerState = ref.watch(playerNotifierProvider);
    final isDynamicEnabled = ref.watch(dynamicThemeEnabledProvider);
    final dynamicPalette = ref.watch(activeDynamicPaletteProvider);

    final track = playerState.currentTrack ?? _sampleTrack;
    final isPlaying = playerState.isPlaying;
    final position = playerState.position > Duration.zero
        ? playerState.position
        : const Duration(seconds: 42);
    final duration = playerState.duration > Duration.zero
        ? playerState.duration
        : const Duration(minutes: 4, seconds: 5);

    // Active accent color (dynamic Monet vs theme primary)
    final accentColor = (config.adaptiveColors && isDynamicEnabled)
        ? (dynamicPalette.primary)
        : theme.colorScheme.primary;

    // Synced lyrics for Karaoke widget
    final lyricsAsync = ref.watch(currentTrackLyricsProvider);
    final lyricLines = lyricsAsync.valueOrNull?.lines;

    return Scaffold(
      backgroundColor: const Color(0xFF070A0F),
      appBar: AppBar(
        title: const Text('Homescreen Widgets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.nightlight_round),
            tooltip: 'Launch Standby Bedside Mode',
            onPressed: () => context.push(AppRoutes.standby),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Live Preview Sandbox Canvas
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.0),
                gradient: const RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.1,
                  colors: [
                    Color(0xFF161F33),
                    Color(0xFF090D14),
                  ],
                ),
                border: Border.all(
                  color: accentColor.withOpacity(0.25),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: 20.0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Homescreen Header Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.widgets_rounded,
                            size: 16,
                            color: accentColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'LIVE HOMESCREEN PREVIEW',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 10,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isPlaying
                              ? const Color(0x3300E676)
                              : Colors.white12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPlaying ? 'PLAYING' : 'READY',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isPlaying
                                ? const Color(0xFF00E676)
                                : Colors.white60,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // The Selected Active Widget Card
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildSelectedWidget(
                      selectedFormFactor: selectedFormFactor,
                      track: track,
                      isPlaying: isPlaying,
                      position: position,
                      duration: duration,
                      lyricLines: lyricLines,
                      accentColor: accentColor,
                      config: config,
                      ref: ref,
                      context: context,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Form Factor Selector
            Text(
              'Widget Form Factor',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFormFactorChip(
                    context: context,
                    ref: ref,
                    label: '4×1 Compact',
                    icon: Icons.view_headline_rounded,
                    formFactor: WidgetFormFactor.compact,
                    isSelected: selectedFormFactor == WidgetFormFactor.compact,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 8),
                  _buildFormFactorChip(
                    context: context,
                    ref: ref,
                    label: '4×2 Hero Vinyl',
                    icon: Icons.album_rounded,
                    formFactor: WidgetFormFactor.heroVinyl,
                    isSelected: selectedFormFactor == WidgetFormFactor.heroVinyl,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 8),
                  _buildFormFactorChip(
                    context: context,
                    ref: ref,
                    label: '2×2 Square',
                    icon: Icons.grid_view_rounded,
                    formFactor: WidgetFormFactor.square,
                    isSelected: selectedFormFactor == WidgetFormFactor.square,
                    accentColor: accentColor,
                  ),
                  const SizedBox(width: 8),
                  _buildFormFactorChip(
                    context: context,
                    ref: ref,
                    label: '4×3 Karaoke',
                    icon: Icons.lyrics_rounded,
                    formFactor: WidgetFormFactor.karaokeLyrics,
                    isSelected:
                        selectedFormFactor == WidgetFormFactor.karaokeLyrics,
                    accentColor: accentColor,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Customizer Controls Section
            Text(
              'Customization & Appearance',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0F1420),
                borderRadius: BorderRadius.circular(18.0),
                border: Border.all(color: Colors.white10),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Opacity Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Background Opacity',
                        style: AppTypography.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        '${(config.backgroundOpacity * 100).toInt()}%',
                        style: AppTypography.bodySmall
                            .copyWith(color: accentColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: config.backgroundOpacity,
                    min: 0.20,
                    max: 1.0,
                    activeColor: accentColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      ref
                          .read(widgetConfigProvider.notifier)
                          .updateBackgroundOpacity(val);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 16),

                  // Corner Radius Slider
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Corner Curvature',
                        style: AppTypography.bodyMedium
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        '${config.cornerRadius.toInt()} px',
                        style: AppTypography.bodySmall
                            .copyWith(color: accentColor),
                      ),
                    ],
                  ),
                  Slider(
                    value: config.cornerRadius,
                    min: 8.0,
                    max: 36.0,
                    activeColor: accentColor,
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      ref
                          .read(widgetConfigProvider.notifier)
                          .updateCornerRadius(val);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 16),

                  // Ambient Glow Toggle
                  SwitchListTile(
                    title: const Text(
                      'Ambient Neon Glow',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Cast soft dynamic glow matching album cover art',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                    value: config.showGlow,
                    activeColor: accentColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      ref.read(widgetConfigProvider.notifier).toggleGlow(val);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 16),

                  // Spinning Vinyl Toggle
                  SwitchListTile(
                    title: const Text(
                      'Peeking Vinyl Disc',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Display spinning analog vinyl in hero cards',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                    value: config.showVinyl,
                    activeColor: accentColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      ref.read(widgetConfigProvider.notifier).toggleVinyl(val);
                    },
                  ),
                  const Divider(color: Colors.white10, height: 16),

                  // Dynamic Monet Palette Toggle
                  SwitchListTile(
                    title: const Text(
                      'Monet Dynamic Colors',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    subtitle: Text(
                      'Adapt widget accent colors to active album artwork',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 12,
                      ),
                    ),
                    value: config.adaptiveColors,
                    activeColor: accentColor,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      ref
                          .read(widgetConfigProvider.notifier)
                          .toggleAdaptiveColors(val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Standby Mode Quick Launch Card
            InkWell(
              onTap: () => context.push(AppRoutes.standby),
              borderRadius: BorderRadius.circular(16.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      accentColor.withOpacity(0.18),
                      const Color(0xFF101624),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: accentColor.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.nightlight_round,
                        color: accentColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambient Bedside Standby Mode',
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'OLED-optimized clock, spinning turntable & visualizer',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.65),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 5. Native Widget Setup Guide Card
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1420),
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How to add to Android Homescreen',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildStepItem('1', 'Long-press any empty area on your phone homescreen.'),
                  _buildStepItem('2', 'Select "Widgets" from the popup menu.'),
                  _buildStepItem('3', 'Scroll to "NEXA Player" and choose 4×1, 4×2, 2×2, or 4×3.'),
                  _buildStepItem('4', 'Drag and drop onto your screen. Enjoy uninterrupted audio!'),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStepItem(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white12,
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.75),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFactorChip({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required IconData icon,
    required WidgetFormFactor formFactor,
    required bool isSelected,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: () {
        ref.read(selectedWidgetFormFactorProvider.notifier).state = formFactor;
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.20)
              : const Color(0xFF131826),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white12,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? accentColor : Colors.white60,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedWidget({
    required WidgetFormFactor selectedFormFactor,
    required Track track,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required List<dynamic>? lyricLines,
    required Color accentColor,
    required WidgetConfig config,
    required WidgetRef ref,
    required BuildContext context,
  }) {
    void handlePlayPause() {
      final notifier = ref.read(playerNotifierProvider.notifier);
      if (isPlaying) {
        notifier.pause();
      } else {
        notifier.play();
      }
    }

    void handleNext() {
      ref.read(playerNotifierProvider.notifier).skipNext();
    }

    void handlePrevious() {
      ref.read(playerNotifierProvider.notifier).skipPrevious();
    }

    void handleTap() {
      context.push(AppRoutes.nowPlaying);
    }

    switch (selectedFormFactor) {
      case WidgetFormFactor.compact:
        return CompactWidgetCard(
          key: const ValueKey('compact_card'),
          track: track,
          isPlaying: isPlaying,
          position: position,
          duration: duration,
          accentColor: accentColor,
          config: config,
          onPlayPause: handlePlayPause,
          onNext: handleNext,
          onPrevious: handlePrevious,
          onTap: handleTap,
        );
      case WidgetFormFactor.heroVinyl:
        return HeroVinylWidgetCard(
          key: const ValueKey('hero_vinyl_card'),
          track: track,
          isPlaying: isPlaying,
          position: position,
          duration: duration,
          accentColor: accentColor,
          config: config,
          onPlayPause: handlePlayPause,
          onNext: handleNext,
          onPrevious: handlePrevious,
          onTap: handleTap,
        );
      case WidgetFormFactor.square:
        return Center(
          key: const ValueKey('square_card'),
          child: SquareWidgetCard(
            track: track,
            isPlaying: isPlaying,
            position: position,
            duration: duration,
            accentColor: accentColor,
            config: config,
            onPlayPause: handlePlayPause,
            onNext: handleNext,
            onPrevious: handlePrevious,
            onTap: handleTap,
          ),
        );
      case WidgetFormFactor.karaokeLyrics:
        return KaraokeWidgetCard(
          key: const ValueKey('karaoke_card'),
          track: track,
          isPlaying: isPlaying,
          position: position,
          duration: duration,
          lyricLines: lyricLines?.cast(),
          accentColor: accentColor,
          config: config,
          onPlayPause: handlePlayPause,
          onNext: handleNext,
          onPrevious: handlePrevious,
          onTap: handleTap,
        );
    }
  }
}
