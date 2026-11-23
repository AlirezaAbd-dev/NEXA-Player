import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/theme/dynamic_palette_providers.dart';
import '../../../../shared/models/track.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../providers/auto_providers.dart';

/// Distraction-free, high-contrast driving dashboard engineered for vehicle cradles.
class CarModeScreen extends ConsumerStatefulWidget {
  const CarModeScreen({super.key, this.onExit});

  final VoidCallback? onExit;

  @override
  ConsumerState<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends ConsumerState<CarModeScreen> {
  static const Track _fallbackTrack = Track(
    id: 'car_fallback_1',
    title: 'Starboy (Driving Mix)',
    artist: 'The Weeknd • Daft Punk',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 50),
  );

  void _seekBy(Duration delta) {
    HapticFeedback.lightImpact();
    final playerState = ref.read(playerNotifierProvider);
    final newPos = playerState.position + delta;
    final clamped = Duration(
      milliseconds: newPos.inMilliseconds.clamp(
        0,
        playerState.duration.inMilliseconds,
      ),
    );
    ref.read(playerNotifierProvider.notifier).seek(clamped);
  }

  void _showQueueDrawer(BuildContext context, Color accent) {
    HapticFeedback.selectionClick();
    final queue = ref.read(playbackQueueProvider).state.tracks;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF090D14),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'UP NEXT QUEUE',
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: queue.isEmpty
                      ? Center(
                          child: Text(
                            'No upcoming tracks in queue',
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        )
                      : ListView.separated(
                          itemCount: queue.length,
                          separatorBuilder: (_, __) =>
                              const Divider(color: Colors.white12, height: 1),
                          itemBuilder: (ctx, index) {
                            final track = queue[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: const Color(0xFF1B2335),
                                ),
                                child: Icon(Icons.music_note_rounded, color: accent),
                              ),
                              title: Text(
                                track.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                track.artist,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.65),
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                ref.read(playerNotifierProvider.notifier).playTrack(track);
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final autoSettings = ref.watch(autoSettingsProvider);
    final isPlaying = playerState.isPlaying;

    final track = playerState.currentTrack ?? _fallbackTrack;
    final isFavorite = track.isFavorite;

    final isDynamicEnabled = ref.watch(dynamicThemeEnabledProvider);
    final dynamicPalette = ref.watch(activeDynamicPaletteProvider);
    final accent = isDynamicEnabled
        ? dynamicPalette.primary
        : Theme.of(context).colorScheme.primary;

    final totalMs = playerState.duration.inMilliseconds > 0
        ? playerState.duration.inMilliseconds
        : 1;
    final progress =
        (playerState.position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black, // Pure AMOLED Pitch Black for Glare-Free Driving
      body: SafeArea(
        child: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            return Stack(
              children: [
                // Main Car Mode Dashboard Canvas with Blind Gestures
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    final notifier = ref.read(playerNotifierProvider.notifier);
                    if (isPlaying) {
                      notifier.pause();
                    } else {
                      notifier.play();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v > 250) {
                      // Swipe right: previous track
                      HapticFeedback.lightImpact();
                      ref.read(playerNotifierProvider.notifier).skipPrevious();
                    } else if (v < -250) {
                      // Swipe left: next track
                      HapticFeedback.lightImpact();
                      ref.read(playerNotifierProvider.notifier).skipNext();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                    child: isLandscape
                        ? _buildLandscapeLayout(
                            track: track,
                            isPlaying: isPlaying,
                            isFavorite: isFavorite,
                            position: playerState.position,
                            duration: playerState.duration,
                            progress: progress,
                            accent: accent,
                            autoSettings: autoSettings,
                          )
                        : _buildPortraitLayout(
                            track: track,
                            isPlaying: isPlaying,
                            isFavorite: isFavorite,
                            position: playerState.position,
                            duration: playerState.duration,
                            progress: progress,
                            accent: accent,
                            autoSettings: autoSettings,
                          ),
                  ),
                ),

                // Top Header HUD Bar
                Positioned(
                  top: 0,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Car Mode Badge & Digital Clock
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.directions_car_rounded,
                                  size: 16,
                                  color: accent,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'CAR MODE',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Exit Button
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                          size: 32,
                        ),
                        tooltip: 'Exit Car Mode',
                        onPressed: () {
                          if (widget.onExit != null) {
                            widget.onExit!();
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            context.pop();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitLayout({
    required Track track,
    required bool isPlaying,
    required bool isFavorite,
    required Duration position,
    required Duration duration,
    required double progress,
    required Color accent,
    required dynamic autoSettings,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(height: 48),

        // 1. Oversized Track Title & Artist
        Column(
          children: [
            Text(
              track.title,
              style: AppTypography.titleLarge.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              track.artist,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 18,
                color: Colors.white.withOpacity(0.70),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (track.album.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                track.album,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.45),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),

        // 2. High-Visibility Scrubber Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.0,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 3. Ultra-Large Primary Controls (Skip Prev, Giant Play/Pause, Skip Next)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Skip Previous
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF182030),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 42,
                color: Colors.white,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(playerNotifierProvider.notifier).skipPrevious();
                },
                tooltip: 'Previous Track',
              ),
            ),

            // Center Giant Play/Pause Button
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.50),
                    blurRadius: 28.0,
                    spreadRadius: 2.0,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                  size: 54,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  final notifier = ref.read(playerNotifierProvider.notifier);
                  if (isPlaying) {
                    notifier.pause();
                  } else {
                    notifier.play();
                  }
                },
                tooltip: isPlaying ? 'Pause' : 'Play',
              ),
            ),

            // Skip Next
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFF182030),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 42,
                color: Colors.white,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(playerNotifierProvider.notifier).skipNext();
                },
                tooltip: 'Next Track',
              ),
            ),
          ],
        ),

        // 4. Secondary Driving Actions (+/- 15s Jump, Favorite, Quick Queue Drawer)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Rewind 15s
            IconButton(
              icon: const Icon(Icons.replay_10_rounded),
              iconSize: 34,
              color: Colors.white70,
              onPressed: () => _seekBy(const Duration(seconds: -15)),
              tooltip: 'Rewind 15s',
            ),

            // Favorite Button
            IconButton(
              icon: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? const Color(0xFFFF4081) : Colors.white70,
                size: 34,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(playerNotifierProvider.notifier).toggleFavorite();
              },
              tooltip: 'Favorite',
            ),

            // Forward 15s
            IconButton(
              icon: const Icon(Icons.forward_10_rounded),
              iconSize: 34,
              color: Colors.white70,
              onPressed: () => _seekBy(const Duration(seconds: 15)),
              tooltip: 'Forward 15s',
            ),

            // Quick Queue Drawer Button
            IconButton(
              icon: const Icon(Icons.queue_music_rounded),
              iconSize: 34,
              color: accent,
              onPressed: () => _showQueueDrawer(context, accent),
              tooltip: 'Queue Drawer',
            ),
          ],
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildLandscapeLayout({
    required Track track,
    required bool isPlaying,
    required bool isFavorite,
    required Duration position,
    required Duration duration,
    required double progress,
    required Color accent,
    required dynamic autoSettings,
  }) {
    return Row(
      children: [
        // Left Column: Large Metadata & Scrubber
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                style: AppTypography.titleLarge.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                track.artist,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 20,
                  color: Colors.white.withOpacity(0.75),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (track.album.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  track.album,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 24),

              // Scrubber
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8.0,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.60),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(width: 32),

        // Right Column: Giant Controls & Quick Drawer
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Main Primary Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Prev
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFF182030),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 40,
                      color: Colors.white,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(playerNotifierProvider.notifier).skipPrevious();
                      },
                      tooltip: 'Previous Track',
                    ),
                  ),

                  // Giant Play/Pause
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent,
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.50),
                          blurRadius: 24.0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 50,
                      ),
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        final notifier = ref.read(playerNotifierProvider.notifier);
                        if (isPlaying) {
                          notifier.pause();
                        } else {
                          notifier.play();
                        }
                      },
                      tooltip: isPlaying ? 'Pause' : 'Play',
                    ),
                  ),

                  // Next
                  Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Color(0xFF182030),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 40,
                      color: Colors.white,
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(playerNotifierProvider.notifier).skipNext();
                      },
                      tooltip: 'Next Track',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Secondary Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded),
                    iconSize: 32,
                    color: Colors.white70,
                    onPressed: () => _seekBy(const Duration(seconds: -15)),
                    tooltip: 'Rewind 15s',
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite ? const Color(0xFFFF4081) : Colors.white70,
                      size: 32,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(playerNotifierProvider.notifier).toggleFavorite();
                    },
                    tooltip: 'Favorite',
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded),
                    iconSize: 32,
                    color: Colors.white70,
                    onPressed: () => _seekBy(const Duration(seconds: 15)),
                    tooltip: 'Forward 15s',
                  ),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded),
                    iconSize: 32,
                    color: accent,
                    onPressed: () => _showQueueDrawer(context, accent),
                    tooltip: 'Queue Drawer',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
