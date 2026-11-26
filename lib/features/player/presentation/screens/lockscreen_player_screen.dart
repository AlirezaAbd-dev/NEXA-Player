import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/features/player/data/services/lockscreen_service.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/typography/marquee_text.dart';

/// Stellio-style full-screen Lockscreen Player modal for high-contrast,
/// one-handed transport control when the screen wakes during active playback.
class LockscreenPlayerScreen extends ConsumerStatefulWidget {
  const LockscreenPlayerScreen({super.key});

  @override
  ConsumerState<LockscreenPlayerScreen> createState() =>
      _LockscreenPlayerScreenState();
}

class _LockscreenPlayerScreenState
    extends ConsumerState<LockscreenPlayerScreen> {
  late DateTime _now;
  Timer? _clockTimer;
  double? _scrubRatio;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    HapticFeedback.lightImpact();
    unawaited(LockscreenService.dismissLockscreen());
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _formatClock(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerNotifierProvider);
    final notifier = ref.read(playerNotifierProvider.notifier);
    final track = playerState.currentTrack;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;

    final durationMs = math.max(1, playerState.duration.inMilliseconds);
    final progress = (_scrubRatio ??
            (playerState.position.inMilliseconds / durationMs))
        .clamp(0.0, 1.0);
    final displayPosition = _scrubRatio != null
        ? Duration(milliseconds: (_scrubRatio! * durationMs).round())
        : playerState.position;

    return GestureDetector(
      key: const ValueKey('lockscreen_player_root'),
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) < -450) {
          _dismiss();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF06080E),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final artSize = (constraints.maxWidth * 0.62).clamp(160.0, 276.0);
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 1. Live Clock + Unlock / Dismiss Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatClock(_now),
                          key: const ValueKey('lockscreen_clock'),
                          style: AppTypography.headlineMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        TextButton.icon(
                          key: const ValueKey('lockscreen_dismiss_btn'),
                          onPressed: _dismiss,
                          icon: const Icon(
                            Icons.lock_open_rounded,
                            size: 18,
                            color: Colors.white70,
                          ),
                          label: Text(
                            context.l10n.unlockToDismiss,
                            style: AppTypography.labelMedium.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // 2. High-Contrast Artwork
                    Container(
                      width: artSize,
                      height: artSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24.0),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.28),
                            blurRadius: 36.0,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24.0),
                        child: NexaArtworkImage(
                          track: track,
                          artworkUri: track?.artworkUri,
                          width: artSize,
                          height: artSize,
                          cacheWidth: 720,
                          fallbackBuilder: (_) => Container(
                            color: const Color(0xFF141824),
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 64,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. Track Title, Artist & Seek Bar
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MarqueeText(
                          track?.title ?? 'NEXA Player',
                          style: AppTypography.headlineSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        MarqueeText(
                          track?.artistAndAlbum ?? '',
                          style: AppTypography.bodyMedium.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4.0,
                            activeTrackColor: primary,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                            thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 7.0,
                            ),
                          ),
                          child: Slider(
                            key: const ValueKey('lockscreen_seek_slider'),
                            value: progress,
                            onChanged: track == null
                                ? null
                                : (val) => setState(() => _scrubRatio = val),
                            onChangeEnd: track == null
                                ? null
                                : (val) {
                                    setState(() => _scrubRatio = null);
                                    notifier.seek(
                                      Duration(
                                        milliseconds:
                                            (val * durationMs).round(),
                                      ),
                                    );
                                  },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                displayPosition.toMinutesSeconds(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white60,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              Text(
                                playerState.duration.toMinutesSeconds(),
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white60,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // 4. One-Handed Ergonomic Transport Controls
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            IconButton(
                              key: const ValueKey('lockscreen_favorite_btn'),
                              iconSize: 26,
                              icon: Icon(
                                (track?.isFavorite ?? false)
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: (track?.isFavorite ?? false)
                                    ? Colors.redAccent
                                    : Colors.white70,
                              ),
                              onPressed: track == null
                                  ? null
                                  : () => notifier.toggleFavorite(track),
                            ),
                            IconButton(
                              key: const ValueKey('lockscreen_prev_btn'),
                              iconSize: 38,
                              icon: const Icon(
                                Icons.skip_previous_rounded,
                                color: Colors.white,
                              ),
                              onPressed: notifier.skipPrevious,
                            ),
                            FloatingActionButton.large(
                              key: const ValueKey('lockscreen_play_pause_btn'),
                              backgroundColor: primary,
                              foregroundColor: Colors.black,
                              elevation: 4,
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                if (playerState.isPlaying) {
                                  notifier.pause();
                                } else {
                                  notifier.play();
                                }
                              },
                              child: Icon(
                                playerState.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 40,
                              ),
                            ),
                            IconButton(
                              key: const ValueKey('lockscreen_next_btn'),
                              iconSize: 38,
                              icon: const Icon(
                                Icons.skip_next_rounded,
                                color: Colors.white,
                              ),
                              onPressed: notifier.skipNext,
                            ),
                            IconButton(
                              key: const ValueKey('lockscreen_close_icon_btn'),
                              iconSize: 26,
                              icon: const Icon(
                                Icons.keyboard_arrow_up_rounded,
                                color: Colors.white70,
                              ),
                              onPressed: _dismiss,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.swipeToUnlock,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
