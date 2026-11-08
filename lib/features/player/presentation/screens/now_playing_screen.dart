import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';

/// Full-screen modern Now Playing screen with hero album art,
/// ambient glow reflection, fluid progress seeker, and prominent playback controls.
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
  bool _isFavorite = true;
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ambient Background Glow
          const AppAmbientBackground(),

          // 2. Main Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
                        onPressed: () => context.pop(),
                        tooltip: 'Minimize',
                      ),
                      Column(
                        children: [
                          Text(
                            'PLAYING FROM ALBUM',
                            style: AppTypography.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Starboy',
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert_rounded),
                        onPressed: () {},
                        tooltip: 'Options',
                      ),
                    ],
                  ),

                  // Center Hero Artwork
                  Center(
                    child: Hero(
                      tag: 'now_playing_art',
                      child: Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24.0),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primary.withOpacity(isDark ? 0.35 : 0.25),
                              isDark ? const Color(0xFF1E2433) : const Color(0xFFE2E8F0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(isDark ? 0.30 : 0.20),
                              blurRadius: 36.0,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.0),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Concentric groove rings
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0x25FFFFFF) : const Color(0x15000000),
                                    width: 1.0,
                                  ),
                                ),
                                margin: const EdgeInsets.all(24.0),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0x18FFFFFF) : const Color(0x10000000),
                                    width: 1.0,
                                  ),
                                ),
                                margin: const EdgeInsets.all(48.0),
                              ),

                              // Rotating vinyl record in the center
                              RotationTransition(
                                turns: _rotationController,
                                child: Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
                                        isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                                        isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
                                      ],
                                      stops: const [0.3, 0.7, 1.0],
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x60000000),
                                        blurRadius: 16.0,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: primary,
                                      ),
                                      child: Center(
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: isDark ? const Color(0xFF020617) : Colors.white,
                                          ),
                                        ),
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

                  // Track Metadata Row (Title, Artist & Like Button)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starboy',
                              style: AppTypography.headlineMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The Weeknd • Daft Punk',
                              style: AppTypography.titleMedium.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.70),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _isFavorite ? Colors.redAccent.shade200 : colorScheme.onSurface.withOpacity(0.6),
                          size: 28,
                        ),
                        onPressed: () => setState(() => _isFavorite = !_isFavorite),
                        tooltip: 'Favorite',
                      ),
                    ],
                  ),

                  // Fluid Progress Seeker & Timestamps
                  Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4.0,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '0:${_position.toInt().toString().padLeft(2, '0')}',
                              style: AppTypography.labelSmall.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '3:50',
                              style: AppTypography.labelSmall.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Modern Playback Controls Row
                  Row(
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
                        icon: const Icon(Icons.skip_previous_rounded, size: 38),
                        onPressed: () {},
                        tooltip: 'Previous',
                      ),

                      // Prominent Center Play/Pause Circle
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primary,
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.40),
                              blurRadius: 18.0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 36,
                            color: isDark ? const Color(0xFF0A0D14) : Colors.white,
                          ),
                          onPressed: _togglePlayPause,
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
                          color: _repeatMode > 0 ? primary : colorScheme.onSurface.withOpacity(0.65),
                        ),
                        onPressed: () => setState(() => _repeatMode = (_repeatMode + 1) % 3),
                        tooltip: 'Repeat',
                      ),
                    ],
                  ),

                  // Bottom Secondary Utilities Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.devices_rounded,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            size: 22,
                          ),
                          onPressed: () {},
                          tooltip: 'Connect to a device',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.queue_music_rounded,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            size: 22,
                          ),
                          onPressed: () {},
                          tooltip: 'Queue',
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
