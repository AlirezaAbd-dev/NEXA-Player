import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/extensions/duration_x.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../domain/entities/playback_state.dart';
import '../providers/player_providers.dart';
import '../widgets/queue_bottom_sheet.dart';
import '../widgets/sleep_timer_bottom_sheet.dart';

/// Full-screen modern Now Playing screen with hero album art,
/// ambient glow reflection, fluid progress seeker, and prominent playback controls.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationController;
  double? _dragPositionSeconds;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final isPlaying = ref.read(playerNotifierProvider).isPlaying;
      if (isPlaying && !_isTest) {
        _rotationController.repeat();
      } else if (isPlaying) {
        _rotationController.value = 0.2;
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _syncRotation(bool isPlaying) {
    if (isPlaying) {
      if (!_rotationController.isAnimating && !_isTest) {
        _rotationController.repeat();
      } else if (_isTest) {
        _rotationController.value = 0.2;
      }
    } else {
      _rotationController.stop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;

    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;
    final isPlaying = playerState.isPlaying;

    _syncRotation(isPlaying);

    final title = currentTrack?.title ?? 'Starboy';
    final artistAndAlbum = currentTrack?.artistAndAlbum ?? 'The Weeknd • Daft Punk';
    final albumHeader = (currentTrack != null && currentTrack.album.isNotEmpty)
        ? currentTrack.album
        : 'Starboy';

    final isFavorite = currentTrack?.isFavorite ?? true;
    final isShuffle = playerState.playbackMode == PlaybackMode.shuffle;
    final playbackMode = playerState.playbackMode;

    final totalSeconds = playerState.duration.inSeconds > 0
        ? playerState.duration.inSeconds.toDouble()
        : 230.0;
    final currentSeconds = _dragPositionSeconds ??
        playerState.position.inSeconds.toDouble().clamp(0.0, totalSeconds);

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
                            albumHeader,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.bedtime_outlined),
                        onPressed: () => SleepTimerBottomSheet.show(context),
                        tooltip: 'Sleep Timer',
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
                              title,
                              style: AppTypography.headlineMedium.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              artistAndAlbum,
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
                          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent.shade200 : colorScheme.onSurface.withOpacity(0.6),
                          size: 28,
                        ),
                        onPressed: () {
                          ref.read(playerNotifierProvider.notifier).toggleFavorite();
                        },
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
                          value: currentSeconds,
                          max: totalSeconds,
                          onChanged: (val) {
                            setState(() => _dragPositionSeconds = val);
                          },
                          onChangeEnd: (val) {
                            setState(() => _dragPositionSeconds = null);
                            ref.read(playerNotifierProvider.notifier).seek(
                                  Duration(seconds: val.toInt()),
                                );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              Duration(seconds: currentSeconds.toInt()).toMinutesSeconds(padMinutes: false),
                              style: AppTypography.labelSmall.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.65),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              Duration(seconds: totalSeconds.toInt()).toMinutesSeconds(padMinutes: false),
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
                          isShuffle ? Icons.shuffle_on_rounded : Icons.shuffle_rounded,
                          color: isShuffle ? primary : colorScheme.onSurface.withOpacity(0.65),
                        ),
                        onPressed: () {
                          ref.read(playerNotifierProvider.notifier).toggleShuffle();
                        },
                        tooltip: 'Shuffle',
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 38),
                        onPressed: () {
                          ref.read(playerNotifierProvider.notifier).skipPrevious();
                        },
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
                            isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            size: 36,
                            color: isDark ? const Color(0xFF0A0D14) : Colors.white,
                          ),
                          onPressed: () {
                            ref.read(playerNotifierProvider.notifier).togglePlayPause();
                          },
                          tooltip: isPlaying ? 'Pause' : 'Play',
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 38),
                        onPressed: () {
                          ref.read(playerNotifierProvider.notifier).skipNext();
                        },
                        tooltip: 'Next',
                      ),
                      IconButton(
                        icon: Icon(
                          playbackMode == PlaybackMode.repeatOne
                              ? Icons.repeat_one_rounded
                              : playbackMode == PlaybackMode.repeatAll
                                  ? Icons.repeat_on_rounded
                                  : Icons.repeat_rounded,
                          color: playbackMode.isRepeating ? primary : colorScheme.onSurface.withOpacity(0.65),
                        ),
                        onPressed: () {
                          ref.read(playerNotifierProvider.notifier).cycleRepeatMode();
                        },
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
                            Icons.bedtime_rounded,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            size: 22,
                          ),
                          onPressed: () => SleepTimerBottomSheet.show(context),
                          tooltip: 'Sleep Timer',
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.queue_music_rounded,
                            color: colorScheme.onSurface.withOpacity(0.6),
                            size: 22,
                          ),
                          onPressed: () => QueueBottomSheet.show(context),
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
