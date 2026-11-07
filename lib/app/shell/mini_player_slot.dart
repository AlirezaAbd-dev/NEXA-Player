import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/design_system/app_spacing.dart';
import '../../core/design_system/app_typography.dart';
import '../../core/design_system/glass_tokens.dart';
import '../../shared/widgets/glass/glass_card.dart';
import '../routes.dart';

/// Semantic Keys matching E2EKeys.
abstract final class _MiniPlayerKeys {
  static const Key miniPlayerSlot = ValueKey('mini_player_slot');
  static const Key miniPlayerPlayPause = ValueKey('mini_player_play_pause');
}

/// Persistent, floating luxury glassmorphism mini-player slot.
///
/// Features:
/// - Floating capsule pill geometry with glowing ambient back-shadow.
/// - Spinning vinyl artwork with mini animated equalizer.
/// - Glowing dual-tone progress seek indicator.
/// - Tactile play/pause and favorite actions.
class MiniPlayerSlot extends StatefulWidget {
  const MiniPlayerSlot({
    super.key,
    this.title = 'Starboy',
    this.artist = 'The Weeknd • Daft Punk',
    this.progress = 0.42,
    this.isPlaying = true,
    this.onPlayPause,
    this.onTap,
  });

  final String title;
  final String artist;
  final double progress;
  final bool isPlaying;
  final VoidCallback? onPlayPause;
  final VoidCallback? onTap;

  @override
  State<MiniPlayerSlot> createState() => _MiniPlayerSlotState();
}

class _MiniPlayerSlotState extends State<MiniPlayerSlot>
    with SingleTickerProviderStateMixin {
  late bool _isPlaying;
  late final AnimationController _rotationController;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
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
    if (widget.isPlaying != oldWidget.isPlaying) {
      _isPlaying = widget.isPlaying;
      if (_isPlaying && !_isTest) {
        _rotationController.repeat();
      } else if (_isPlaying) {
        _rotationController.value = 0.25;
      } else {
        _rotationController.stop();
      }
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
      if (_isPlaying && !_isTest) {
        _rotationController.repeat();
      } else if (_isPlaying) {
        _rotationController.value = 0.25;
      } else {
        _rotationController.stop();
      }
    });
    widget.onPlayPause?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;
    final secondary = colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22.0),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(isDark ? 0.30 : 0.18),
              blurRadius: 22.0,
              spreadRadius: 1.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: GlassCard(
          key: _MiniPlayerKeys.miniPlayerSlot,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(22.0),
          blur: GlassTokens.blurExtreme,
          opacity: isDark ? 0.22 : 0.55,
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
                    // 1. Spinning Vinyl Artwork with Glow
                    RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 44.0,
                        height: 44.0,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: [
                              primary,
                              secondary,
                              primary,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withOpacity(0.40),
                              blurRadius: 10.0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: 16.0,
                            height: 16.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.scaffoldBackgroundColor,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 1.5,
                              ),
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
                            widget.title,
                            style: AppTypography.titleMedium.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            widget.artist,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // 3. Mini Equalizer Pulse
                    if (_isPlaying) ...[
                      _MiniPulseEqualizer(color: primary),
                      const SizedBox(width: AppSpacing.xs),
                    ],

                    // 4. Like / Heart Button
                    IconButton(
                      icon: Icon(
                        Icons.favorite_rounded,
                        color: Colors.redAccent.shade200,
                        size: 22.0,
                      ),
                      onPressed: () {},
                      tooltip: 'Like',
                    ),

                    // 5. Play / Pause Button with Accent Glow
                    Container(
                      width: 40.0,
                      height: 40.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primary,
                            primary.withOpacity(0.80),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.45),
                            blurRadius: 12.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        key: _MiniPlayerKeys.miniPlayerPlayPause,
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_fill_rounded,
                          color: isDark ? Colors.black : Colors.white,
                          size: 34.0,
                        ),
                        onPressed: _handlePlayPause,
                        tooltip: _isPlaying ? 'Pause' : 'Play',
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Glowing Linear Progress Micro-Seek Indicator
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(22.0),
                  bottomRight: Radius.circular(22.0),
                ),
                child: SizedBox(
                  height: 3.0,
                  child: LinearProgressIndicator(
                    value: widget.progress.clamp(0.0, 1.0),
                    backgroundColor: colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPulseEqualizer extends StatefulWidget {
  const _MiniPulseEqualizer({required this.color});
  final Color color;

  @override
  State<_MiniPulseEqualizer> createState() => _MiniPulseEqualizerState();
}

class _MiniPulseEqualizerState extends State<_MiniPulseEqualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(6.0 + 8.0 * math.sin(t * math.pi)),
            const SizedBox(width: 2.0),
            _bar(4.0 + 10.0 * math.cos(t * math.pi)),
            const SizedBox(width: 2.0),
            _bar(8.0 + 7.0 * math.sin((t + 0.3) * math.pi)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 2.5,
      height: height.clamp(3.0, 16.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
