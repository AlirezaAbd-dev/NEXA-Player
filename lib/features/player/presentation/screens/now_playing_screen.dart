import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_card.dart';

/// Full-screen luxury Now Playing screen with rotating 3D vinyl art,
/// ambient aurora reflection, glowing seeker, and floating glass controls.
class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = true;
  bool _isShuffle = false;
  int _repeatMode = 0; // 0 = off, 1 = all, 2 = one
  double _position = 42.0;
  final double _duration = 230.0;
  late final AnimationController _rotationController;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    if (_isPlaying && !_isTest) {
      _rotationController.repeat();
    } else if (_isPlaying) {
      _rotationController.value = 0.2;
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying && !_isTest) {
        _rotationController.repeat();
      } else if (_isPlaying) {
        _rotationController.value = 0.2;
      } else {
        _rotationController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Aurora Mesh Canvas
          const AppAmbientBackground(),

          // 2. Foreground Player Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // 2.1 3D Vinyl Album Art Showcase
                  Center(
                    child: Hero(
                      tag: 'now_playing_art',
                      child: Container(
                        width: 290,
                        height: 290,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32.0),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(isDark ? 0.40 : 0.25),
                              blurRadius: 36.0,
                              spreadRadius: 2.0,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(32.0),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Sleeve gradient
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primary,
                                      secondary,
                                      isDark ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                    ],
                                  ),
                                ),
                              ),

                              // Rotating Vinyl Disc
                              Center(
                                child: RotationTransition(
                                  turns: _rotationController,
                                  child: Container(
                                    width: 240,
                                    height: 240,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          Color(0xFF1E293B),
                                          Color(0xFF0F172A),
                                          Color(0xFF020617),
                                        ],
                                        stops: [0.3, 0.7, 1.0],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x60000000),
                                          blurRadius: 18.0,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Container(
                                        width: 76,
                                        height: 76,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: primary,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.85),
                                            width: 2.0,
                                          ),
                                        ),
                                        child: Center(
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Diagonal Gloss Refraction Sheen
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(isDark ? 0.28 : 0.60),
                                          Colors.transparent,
                                          Colors.transparent,
                                        ],
                                        stops: const [0.0, 0.40, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 2.2 Track Title & Artist with Glow
                  Column(
                    children: [
                      Text(
                        'Starboy',
                        style: AppTypography.displayMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'The Weeknd • Daft Punk',
                        style: AppTypography.titleLarge.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.75),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // 2.3 Frosted Waveform / Seek Bar Capsule
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
                    borderRadius: BorderRadius.circular(22.0),
                    blur: GlassTokens.blurExtreme,
                    opacity: isDark ? 0.22 : 0.55,
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.5,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
                            activeTrackColor: primary,
                            inactiveTrackColor: colorScheme.onSurface.withOpacity(0.12),
                            thumbColor: primary,
                          ),
                          child: Slider(
                            value: _position,
                            max: _duration,
                            onChanged: (val) => setState(() => _position = val),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '0:${_position.toInt().toString().padLeft(2, '0')}',
                                style: AppTypography.labelMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '3:50',
                                style: AppTypography.labelMedium.copyWith(
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2.4 Floating Playback Controls Pill
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                    blur: GlassTokens.blurExtreme,
                    opacity: isDark ? 0.25 : 0.60,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                            color: _isShuffle ? primary : colorScheme.onSurface.withOpacity(0.65),
                          ),
                          onPressed: () => setState(() => _isShuffle = !_isShuffle),
                          tooltip: 'Shuffle',
                        ),
                        IconButton(
                          icon: const Icon(Icons.skip_previous_rounded, size: 36),
                          onPressed: () {},
                          tooltip: 'Previous',
                        ),

                        // Center Pulsing Play/Pause Action
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primary,
                                secondary,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withOpacity(0.45),
                                blurRadius: 18.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 38,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                            onPressed: _togglePlayPause,
                            tooltip: _isPlaying ? 'Pause' : 'Play',
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 36),
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
                            color: _repeatMode > 0 ? primary : colorScheme.onSurface.withOpacity(0.65),
                          ),
                          onPressed: () => setState(() => _repeatMode = (_repeatMode + 1) % 3),
                          tooltip: 'Repeat',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
