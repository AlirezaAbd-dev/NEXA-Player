import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_card.dart';

/// Full-screen Now Playing screen with rotating art, waveform preview, and controls.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen> {
  bool _isPlaying = true;
  bool _isShuffle = false;
  int _repeatMode = 0; // 0 = off, 1 = all, 2 = one
  double _position = 42.0;
  final double _duration = 230.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Now Playing',
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 28),
          onPressed: () => context.pop(),
          tooltip: 'Dismiss',
        ),
        actions: const [
          IconButton(
            icon: Icon(Icons.queue_music_rounded),
            onPressed: null,
            tooltip: 'Queue',
          ),
          IconButton(
            icon: Icon(Icons.more_vert_rounded),
            onPressed: null,
            tooltip: 'Options',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.primary.withOpacity(0.25),
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 1. Album Art Showcase
                Center(
                  child: Hero(
                    tag: 'now_playing_art',
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(GlassTokens.radiusLarge),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                        boxShadow: GlassTokens.elevationMedium,
                      ),
                      child: const Icon(
                        Icons.album_rounded,
                        size: 140,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // 2. Track Title & Artist
                Column(
                  children: [
                    Text(
                      'Starboy',
                      style: AppTypography.displayMedium.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'The Weeknd • Daft Punk',
                      style: AppTypography.titleLarge.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),

                // 3. Waveform / Seek Bar Placeholder
                GlassCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                          activeTrackColor: colorScheme.primary,
                          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.12),
                          thumbColor: colorScheme.primary,
                        ),
                        child: Slider(
                          value: _position,
                          max: _duration,
                          onChanged: (val) => setState(() => _position = val),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0:${_position.toInt().toString().padLeft(2, '0')}',
                              style: AppTypography.labelSmall,
                            ),
                            const Text(
                              '3:50',
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                        color: _isShuffle ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: () => setState(() => _isShuffle = !_isShuffle),
                      tooltip: 'Shuffle',
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded, size: 38),
                      onPressed: () {},
                      tooltip: 'Previous',
                    ),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                        boxShadow: GlassTokens.elevationLow,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 36,
                          color: colorScheme.onPrimary,
                        ),
                        onPressed: () => setState(() => _isPlaying = !_isPlaying),
                        tooltip: _isPlaying ? 'Pause' : 'Play',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded, size: 38),
                      onPressed: () {},
                      tooltip: 'Next',
                    ),
                    IconButton(
                      icon: Icon(
                        _repeatMode == 0
                            ? Icons.repeat_rounded
                            : _repeatMode == 1
                                ? Icons.repeat_on_rounded
                                : Icons.repeat_one_rounded,
                        color: _repeatMode > 0 ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.6),
                      ),
                      onPressed: () => setState(() => _repeatMode = (_repeatMode + 1) % 3),
                      tooltip: 'Repeat',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
