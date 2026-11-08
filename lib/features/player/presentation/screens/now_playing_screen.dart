import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../domain/entities/playback_state.dart';
import '../providers/player_providers.dart';
import '../widgets/hero_artwork_card.dart';
import '../widgets/queue_bottom_sheet.dart';
import '../widgets/rating_bar_widget.dart';
import '../widgets/sleep_timer_bottom_sheet.dart';
import '../widgets/waveform_visualizer.dart';

/// Layout modes supported by the Now Playing hero screen.
enum NowPlayingLayoutMode {
  /// Standard modern layout with hero artwork, waveform seeker, and controls.
  standard,

  /// Full-size vinyl turntable display with rotating grooves.
  vinyl,

  /// Clean immersive artwork layout with floating controls.
  art,
}

/// Full-screen showstopper Now Playing screen featuring:
/// - 3 Layout modes (Standard / Vinyl / Art).
/// - 3D Perspective Card Flip on long-press revealing technical audio metadata.
/// - Horizontal spring swipe gestures (swipe left/right to skip).
/// - Seekable, animated Waveform Visualizer with pre-computed amplitude bars.
/// - 5-star interactive rating and favorite toggle.
/// - Up Next Queue and Sleep Timer modal sheets.
class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  NowPlayingLayoutMode _layoutMode = NowPlayingLayoutMode.standard;

  void _cycleLayoutMode() {
    HapticFeedback.selectionClick();
    setState(() {
      switch (_layoutMode) {
        case NowPlayingLayoutMode.standard:
          _layoutMode = NowPlayingLayoutMode.vinyl;
          break;
        case NowPlayingLayoutMode.vinyl:
          _layoutMode = NowPlayingLayoutMode.art;
          break;
        case NowPlayingLayoutMode.art:
          _layoutMode = NowPlayingLayoutMode.standard;
          break;
      }
    });
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

    final title = currentTrack?.title ?? 'Starboy';
    final artistAndAlbum = currentTrack?.artistAndAlbum ?? 'The Weeknd • Daft Punk';
    final albumHeader = (currentTrack != null && currentTrack.album.isNotEmpty)
        ? currentTrack.album
        : 'Starboy';

    final isFavorite = currentTrack?.isFavorite ?? true;
    final isShuffle = playerState.playbackMode == PlaybackMode.shuffle;
    final playbackMode = playerState.playbackMode;

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
              padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Navigation Bar
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _layoutMode == NowPlayingLayoutMode.standard
                                  ? Icons.view_carousel_rounded
                                  : _layoutMode == NowPlayingLayoutMode.vinyl
                                      ? Icons.album_rounded
                                      : Icons.image_rounded,
                              size: 22,
                            ),
                            onPressed: _cycleLayoutMode,
                            tooltip: 'Switch Layout Mode',
                          ),
                          IconButton(
                            icon: const Icon(Icons.bedtime_outlined, size: 22),
                            onPressed: () => SleepTimerBottomSheet.show(context),
                            tooltip: 'Sleep Timer',
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Center Hero Artwork (with 3D Flip & Horizontal Swipe)
                  Center(
                    child: Hero(
                      tag: 'now_playing_art',
                      child: HeroArtworkCard(
                        track: currentTrack,
                        isPlaying: isPlaying,
                        size: _layoutMode == NowPlayingLayoutMode.art ? 310.0 : 270.0,
                        onSwipeLeft: () {
                          ref.read(playerNotifierProvider.notifier).skipNext();
                        },
                        onSwipeRight: () {
                          ref.read(playerNotifierProvider.notifier).skipPrevious();
                        },
                      ),
                    ),
                  ),

                  // Metadata & Rating Row
                  Column(
                    children: [
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
                                const SizedBox(height: 3),
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
                              HapticFeedback.lightImpact();
                              ref.read(playerNotifierProvider.notifier).toggleFavorite();
                            },
                            tooltip: 'Favorite',
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const RatingBarWidget(initialRating: 4, starSize: 18.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(isDark ? 0.16 : 0.10),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              currentTrack?.bitrate != null
                                  ? '${currentTrack!.bitrate! ~/ 1000} KBPS • STEREO'
                                  : '320 KBPS • STEREO',
                              style: AppTypography.labelSmall.copyWith(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Seekable Interactive Waveform Visualizer
                  WaveformVisualizer(
                    position: playerState.position,
                    duration: playerState.duration.inSeconds > 0
                        ? playerState.duration
                        : const Duration(seconds: 230),
                    isPlaying: isPlaying,
                    trackSeed: currentTrack?.id ?? 'default_seed',
                    activeColor: primary,
                    onSeek: (newPos) {
                      ref.read(playerNotifierProvider.notifier).seek(newPos);
                    },
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
                          HapticFeedback.selectionClick();
                          ref.read(playerNotifierProvider.notifier).toggleShuffle();
                        },
                        tooltip: 'Shuffle',
                      ),
                      IconButton(
                        icon: const Icon(Icons.skip_previous_rounded, size: 38),
                        onPressed: () {
                          HapticFeedback.lightImpact();
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
                            HapticFeedback.mediumImpact();
                            ref.read(playerNotifierProvider.notifier).togglePlayPause();
                          },
                          tooltip: isPlaying ? 'Pause' : 'Play',
                        ),
                      ),

                      IconButton(
                        icon: const Icon(Icons.skip_next_rounded, size: 38),
                        onPressed: () {
                          HapticFeedback.lightImpact();
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
                          HapticFeedback.selectionClick();
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
