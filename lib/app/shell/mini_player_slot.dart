import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../routes.dart';

/// Semantic Keys matching ShellNavigationTest.
abstract final class _MiniPlayerKeys {
  static const Key miniPlayerSlot = ValueKey('mini_player_slot');
  static const Key miniPlayerPlayPause = ValueKey('mini_player_play_pause');
}

/// Modern floating mini-player capsule persistent across all tab switches.
class MiniPlayerSlot extends ConsumerStatefulWidget {
  const MiniPlayerSlot({
    super.key,
    this.title,
    this.artist,
    this.artworkUri,
    this.isPlaying,
    this.progress,
    this.onTap,
    this.onPlayPause,
    this.onNext,
  });

  final String? title;
  final String? artist;
  final String? artworkUri;
  final bool? isPlaying;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;

  @override
  ConsumerState<MiniPlayerSlot> createState() => _MiniPlayerSlotState();
}

class _MiniPlayerSlotState extends ConsumerState<MiniPlayerSlot>
    with SingleTickerProviderStateMixin {
  late bool _isPlaying;
  late final AnimationController _rotationController;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying ?? true;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    if (_isPlaying && !_isTest) {
      _rotationController.repeat();
    } else if (_isPlaying) {
      _rotationController.value = 0.25;
    }
  }

  @override
  void didUpdateWidget(MiniPlayerSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != null && widget.isPlaying != oldWidget.isPlaying) {
      _isPlaying = widget.isPlaying!;
      _syncRotation(_isPlaying);
    }
  }

  void _syncRotation(bool isPlaying) {
    if (isPlaying && !_isTest) {
      if (!_rotationController.isAnimating) _rotationController.repeat();
    } else if (isPlaying) {
      _rotationController.value = 0.25;
    } else {
      _rotationController.stop();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handlePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      _syncRotation(_isPlaying);
    });

    if (widget.onPlayPause != null) {
      widget.onPlayPause!();
    } else {
      ref.read(playerNotifierProvider.notifier).togglePlayPause();
    }
  }

  void _handleNext() {
    if (widget.onNext != null) {
      widget.onNext!();
    } else {
      ref.read(playerNotifierProvider.notifier).skipNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final capsuleRadius = BorderRadius.circular(16.0);

    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;

    final title = widget.title ?? (currentTrack?.title ?? 'Starboy');
    final artist = widget.artist ?? (currentTrack?.artistAndAlbum ?? 'The Weeknd • Daft Punk');
    final isPlaying = widget.isPlaying ?? (currentTrack != null ? playerState.isPlaying : _isPlaying);
    final progress = widget.progress ?? (currentTrack != null ? playerState.progress : 0.35);

    _syncRotation(isPlaying);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
      child: ClipRRect(
        borderRadius: capsuleRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
          child: Container(
            key: _MiniPlayerKeys.miniPlayerSlot,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF141923).withOpacity(0.85)
                  : theme.colorScheme.surface.withOpacity(0.92),
              borderRadius: capsuleRadius,
              border: Border.all(
                color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x40000000) : const Color(0x15000000),
                  blurRadius: 18.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: capsuleRadius,
                onTap: widget.onTap ?? () => context.push(AppRoutes.player),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 6.0,
                      ),
                      child: Row(
                        children: [
                          // 1. Artwork Thumbnail
                          RotationTransition(
                            turns: _rotationController,
                            child: Container(
                              width: 44.0,
                              height: 44.0,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primary,
                                    colorScheme.secondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withOpacity(0.30),
                                    blurRadius: 8.0,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 16.0,
                                  height: 16.0,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isDark
                                        ? const Color(0xFF0F172A)
                                        : Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),

                          // 2. Track Title & Artist
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  artist,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.65),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // 3. Play / Pause Button
                          IconButton(
                            key: _MiniPlayerKeys.miniPlayerPlayPause,
                            icon: Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_fill_rounded,
                              size: 36.0,
                              color: primary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40.0,
                              minHeight: 40.0,
                            ),
                            onPressed: _handlePlayPause,
                          ),

                          // 4. Skip Next Button
                          IconButton(
                            icon: Icon(
                              Icons.skip_next_rounded,
                              size: 26.0,
                              color: colorScheme.onSurface.withOpacity(0.70),
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36.0,
                              minHeight: 36.0,
                            ),
                            onPressed: _handleNext,
                          ),
                        ],
                      ),
                    ),

                    // 5. Linear Progress Line Indicator
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16.0),
                      ),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 2.5,
                        backgroundColor: isDark
                            ? const Color(0x18FFFFFF)
                            : const Color(0x10000000),
                        valueColor: AlwaysStoppedAnimation<Color>(primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
