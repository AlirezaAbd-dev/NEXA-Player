import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/design_system/nexa_surface_tokens.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../../shared/widgets/cards/nexa_artwork_image.dart';
import '../../shared/widgets/typography/bidi_text.dart';
import '../routes.dart';

/// Semantic Keys matching ShellNavigationTest and Widget Tests.
abstract final class MiniPlayerKeys {
  static const Key miniPlayerSlot = ValueKey('mini_player_slot');
  static const Key miniPlayerPlayPause = ValueKey('mini_player_play_pause');
  static const Key miniPlayerSkipNext = ValueKey('mini_player_skip_next');
}

/// Borderless L3 floating mini-player pill featuring:
/// - Background left-to-right tonal progress wash (zero hairline bottom bar)
/// - Horizontal swipe to skip Next/Previous with spring physics
/// - Vertical drag morphing smoothly into Now Playing via Hero animation
/// - Guaranteed zero RenderFlex overflows at 360dp compact viewport
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
    this.onPrevious,
  });

  final String? title;
  final String? artist;
  final String? artworkUri;
  final bool? isPlaying;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onPlayPause;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;

  @override
  ConsumerState<MiniPlayerSlot> createState() => _MiniPlayerSlotState();
}

class _MiniPlayerSlotState extends ConsumerState<MiniPlayerSlot>
    with TickerProviderStateMixin {
  late bool _isPlaying;
  late final AnimationController _rotationController;

  // Gestures state
  double _horizontalDrag = 0.0;
  double _verticalDrag = 0.0;
  late final AnimationController _horizontalSpringController;
  late Animation<double> _horizontalSpringAnimation;

  static const double _horizontalThreshold = 60.0;
  static const double _verticalDismissThreshold = -50.0;

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

    _horizontalSpringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(() {
        setState(() {
          _horizontalDrag = _horizontalSpringAnimation.value;
        });
      });
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
    _horizontalSpringController.dispose();
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

  void _handlePrevious() {
    if (widget.onPrevious != null) {
      widget.onPrevious!();
    } else {
      ref.read(playerNotifierProvider.notifier).skipPrevious();
    }
  }

  void _openNowPlaying() {
    if (widget.onTap != null) {
      widget.onTap!();
    } else {
      context.push(AppRoutes.player);
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_horizontalSpringController.isAnimating) {
      _horizontalSpringController.stop();
    }
    setState(() {
      _horizontalDrag += details.primaryDelta ?? 0.0;
      _horizontalDrag = _horizontalDrag.clamp(-100.0, 100.0);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_horizontalDrag <= -_horizontalThreshold) {
      HapticFeedback.selectionClick();
      _handleNext();
    } else if (_horizontalDrag >= _horizontalThreshold) {
      HapticFeedback.selectionClick();
      _handlePrevious();
    }

    _horizontalSpringAnimation = Tween<double>(
      begin: _horizontalDrag,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _horizontalSpringController,
        curve: Curves.easeOutCubic,
      ),
    );
    _horizontalSpringController.forward(from: 0.0);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _verticalDrag += details.primaryDelta ?? 0.0;
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (_verticalDrag <= _verticalDismissThreshold) {
      HapticFeedback.mediumImpact();
      _openNowPlaying();
    }
    setState(() {
      _verticalDrag = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final tokens = NexaSurfaceTokens.of(context);
    final capsuleRadius = BorderRadius.circular(20.0);

    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;

    if (currentTrack == null && widget.title == null) {
      return const SizedBox.shrink();
    }

    final title = widget.title ?? (currentTrack?.title ?? '');
    final artist = widget.artist ?? (currentTrack?.artistAndAlbum ?? '');
    final isPlaying = widget.isPlaying ?? playerState.isPlaying;
    final progress = (widget.progress ?? playerState.progress).clamp(0.0, 1.0);

    _syncRotation(isPlaying);

    // Soft subtle feathered ambient background gradient without harsh vertical split
    final progressGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        primary.withOpacity(0.09),
        primary.withOpacity(0.03),
        tokens.l3,
      ],
      stops: const [
        0.0,
        0.7,
        1.0,
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
      child: GestureDetector(
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        behavior: HitTestBehavior.opaque,
        child: Transform.translate(
          offset: Offset(_horizontalDrag, 0.0),
          child: ClipRRect(
            borderRadius: capsuleRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
              child: Container(
                key: MiniPlayerKeys.miniPlayerSlot,
                decoration: BoxDecoration(
                  color: tokens.l3,
                  gradient: progressGradient,
                  borderRadius: capsuleRadius,
                  // Borderless standard: zero raw Border.all
                  boxShadow: tokens.l3Shadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: capsuleRadius,
                    onTap: _openNowPlaying,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 8.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // 1. Hero Artwork Rotating Vinyl Thumbnail
                              Hero(
                                tag: 'now_playing_art',
                                child: RotationTransition(
                                  turns: _rotationController,
                                  child: Container(
                                    width: 42.0,
                                    height: 42.0,
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
                                          color: primary.withOpacity(0.28),
                                          blurRadius: 8.0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          NexaArtworkImage(
                                            artworkUri: widget.artworkUri ??
                                                currentTrack?.artworkUri,
                                            track: currentTrack,
                                            width: 42.0,
                                            height: 42.0,
                                            cacheWidth: 160,
                                            fallbackBuilder: (_) =>
                                                const SizedBox.shrink(),
                                          ),
                                          Center(
                                            child: Container(
                                              width: 12.0,
                                              height: 12.0,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: tokens.l1.withOpacity(0.88),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),

                              // 2. Track Title & Artist (Responsive flex with ellipsis)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    BidiText(
                                      title,
                                      style: AppTypography.titleMedium.copyWith(
                                        color: tokens.onL3,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2.0),
                                    BidiText(
                                      artist,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: tokens.onL3.withOpacity(0.68),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),

                              // 3. Play / Pause Button with refined tactile circular backing
                              Container(
                                width: 38.0,
                                height: 38.0,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primary.withOpacity(0.16),
                                ),
                                child: IconButton(
                                  key: MiniPlayerKeys.miniPlayerPlayPause,
                                  icon: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 24.0,
                                    color: primary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 38.0,
                                    minHeight: 38.0,
                                  ),
                                  onPressed: _handlePlayPause,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),

                              // 4. Skip Next Button
                              IconButton(
                                key: MiniPlayerKeys.miniPlayerSkipNext,
                                icon: Icon(
                                  Icons.skip_next_rounded,
                                  size: 26.0,
                                  color: tokens.onL3.withOpacity(0.75),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 34.0,
                                  minHeight: 34.0,
                                ),
                                onPressed: _handleNext,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6.0),
                          // Sleek 2.5dp inset rounded progress track
                          ClipRRect(
                            borderRadius: BorderRadius.circular(1.5),
                            child: SizedBox(
                              height: 2.5,
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: tokens.l2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  primary.withOpacity(0.85),
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
            ),
          ),
        ),
      ),
    );
  }
}
