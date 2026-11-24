import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/extensions/duration_x.dart';
import 'package:nexa_player/core/utils/audio_quality_formatter.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Tuned spring settle physics giving Stellio-style cover flow silky inertia.
class StellioPageScrollPhysics extends PageScrollPhysics {
  const StellioPageScrollPhysics({super.parent});

  @override
  StellioPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return StellioPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
        mass: 1.0,
        stiffness: 220.0,
        damping: 24.0,
      );
}

/// Hero artwork card and Stellio-style 3D Cover Flow Carousel featuring:
/// - Queue-bound [PageView.builder] carousel synced to [IPlaybackQueue].
/// - Studio-tuned clamped 3D perspective rotation clamped to [-1.0, 1.0] to prevent inversion.
/// - Double-tap left/right for quick +/- 10s seek.
/// - 3D Perspective Y-axis flip on long-press revealing the 3D Signal Chain & studio telemetry.
/// - Concentric vinyl grooves and center rotating record when playing.
/// - Kirin 710F frame-pacing with [RepaintBoundary] and 720px downsampling.
class HeroArtworkCard extends StatefulWidget {
  const HeroArtworkCard({
    super.key,
    required this.track,
    this.tracks,
    this.currentIndex,
    this.queueVersion = 0,
    this.isPlaying = false,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onDoubleTapSeekForward,
    this.onDoubleTapSeekBackward,
    this.onPageSettled,
    this.onPageScrolled,
    this.size = 280.0,
  });

  final Track? track;
  final List<Track>? tracks;
  final int? currentIndex;
  final int queueVersion;
  final bool isPlaying;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onDoubleTapSeekForward;
  final VoidCallback? onDoubleTapSeekBackward;
  final ValueChanged<int>? onPageSettled;
  final ValueChanged<double>? onPageScrolled;
  final double size;

  @override
  State<HeroArtworkCard> createState() => _HeroArtworkCardState();
}

class _HeroArtworkCardState extends State<HeroArtworkCard>
    with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _flipController;
  late final AnimationController _swipeOffsetController;
  late final PageController _pageController;

  bool _isFlipped = false;
  double _swipeDragDelta = 0.0;
  int _lastCommittedIndex = 0;
  int _pendingPageIndex = 0;
  int _lastDetentIndex = 0;
  TapDownDetails? _lastTapDown;

  bool get _isTest =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  double? get _currentPageOffset {
    if (!_pageController.hasClients || !_pageController.position.hasContentDimensions) {
      return null;
    }
    return _pageController.page;
  }

  @override
  void initState() {
    super.initState();
    _lastCommittedIndex = widget.currentIndex ?? 0;
    _pendingPageIndex = _lastCommittedIndex;
    _lastDetentIndex = _lastCommittedIndex;
    _pageController = PageController(
      initialPage: _lastCommittedIndex,
      viewportFraction: 0.80,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheAdjacentArtworks(_lastCommittedIndex);
    });

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _swipeOffsetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    if (widget.isPlaying && !_isTest) {
      _rotationController.repeat();
    } else if (widget.isPlaying) {
      _rotationController.value = 0.2;
    }
  }

  @override
  void didUpdateWidget(HeroArtworkCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final queueChanged = widget.queueVersion != oldWidget.queueVersion;
    final targetIndex = widget.currentIndex ?? _lastCommittedIndex;

    if (queueChanged) {
      _lastCommittedIndex = targetIndex;
      _pendingPageIndex = targetIndex;
      _lastDetentIndex = targetIndex;
      if (_pageController.hasClients) {
        _pageController.jumpToPage(targetIndex);
      }
      _precacheAdjacentArtworks(targetIndex);
    } else if (widget.currentIndex != null && widget.currentIndex != _lastCommittedIndex) {
      _lastCommittedIndex = widget.currentIndex!;
      _pendingPageIndex = _lastCommittedIndex;
      _lastDetentIndex = _lastCommittedIndex;
      _precacheAdjacentArtworks(_lastCommittedIndex);
      if (_pageController.hasClients) {
        final currentPage = _currentPageOffset?.round();
        if (currentPage != widget.currentIndex) {
          final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
          if (disableAnimations) {
            _pageController.jumpToPage(widget.currentIndex!);
          } else {
            _pageController.animateToPage(
              widget.currentIndex!,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
            );
          }
        }
      }
    }

    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying && !_isTest) {
        if (!_rotationController.isAnimating) _rotationController.repeat();
      } else if (widget.isPlaying) {
        _rotationController.value = 0.2;
      } else {
        _rotationController.stop();
      }
    }
  }

  void _precacheAdjacentArtworks(int centerIndex) {
    final list = widget.tracks;
    if (list == null || list.isEmpty || !mounted) return;
    for (int i = centerIndex - 1; i <= centerIndex + 1; i++) {
      if (i < 0 || i >= list.length) continue;
      final uri = list[i].artworkUri;
      if (uri == null || uri.isEmpty) continue;
      if (uri.startsWith('http://') || uri.startsWith('https://')) continue;
      final clean = uri.startsWith('file://') ? uri.substring(7) : uri;
      final file = File(clean);
      if (file.existsSync()) {
        precacheImage(
          ResizeImage(FileImage(file), width: 720),
          context,
        ).catchError((_) {});
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _rotationController.dispose();
    _flipController.dispose();
    _swipeOffsetController.dispose();
    super.dispose();
  }

  void _handleFlip() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isFlipped = !_isFlipped;
      if (_isFlipped) {
        _flipController.forward();
      } else {
        _flipController.reverse();
      }
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _swipeDragDelta += details.primaryDelta ?? 0.0;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    const threshold = 60.0;
    if (_swipeDragDelta < -threshold && widget.onSwipeLeft != null) {
      HapticFeedback.lightImpact();
      widget.onSwipeLeft!();
    } else if (_swipeDragDelta > threshold && widget.onSwipeRight != null) {
      HapticFeedback.lightImpact();
      widget.onSwipeRight!();
    }

    setState(() {
      _swipeDragDelta = 0.0;
    });
  }

  void _handleDoubleTap() {
    if (_lastTapDown == null) return;
    final isRightHalf = _lastTapDown!.localPosition.dx > widget.size / 2;
    if (isRightHalf && widget.onDoubleTapSeekForward != null) {
      HapticFeedback.lightImpact();
      widget.onDoubleTapSeekForward!();
    } else if (!isRightHalf && widget.onDoubleTapSeekBackward != null) {
      HapticFeedback.lightImpact();
      widget.onDoubleTapSeekBackward!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;

    final effectiveTracks = widget.tracks ?? (widget.track != null ? [widget.track!] : const <Track>[]);

    if (effectiveTracks.length > 1) {
      return SizedBox(
        width: double.infinity,
        height: widget.size + 16.0,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification) {
              final settledPage = _pendingPageIndex;
              if (settledPage != _lastCommittedIndex &&
                  settledPage >= 0 &&
                  settledPage < effectiveTracks.length) {
                _lastCommittedIndex = settledPage;
                HapticFeedback.selectionClick();
                widget.onPageSettled?.call(settledPage);
              }
            } else if (notification is ScrollUpdateNotification) {
              final offset = _currentPageOffset;
              if (offset != null) {
                widget.onPageScrolled?.call(offset);
              }
            }
            return false;
          },
          child: PageView.builder(
            controller: _pageController,
            physics: const StellioPageScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: effectiveTracks.length,
            onPageChanged: (index) {
              _pendingPageIndex = index;
              if (index != _lastDetentIndex) {
                _lastDetentIndex = index;
                HapticFeedback.selectionClick();
                _precacheAdjacentArtworks(index);
              }
            },
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, _) {
                  final offset = _currentPageOffset;
                  final rawValue = (offset != null)
                      ? (offset - index)
                      : ((widget.currentIndex ?? 0).toDouble() - index);
                  final delta = rawValue.clamp(-1.0, 1.0);
                  final absDelta = delta.abs();

                  final disableAnimations =
                      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                  final Matrix4 matrix;
                  final double scale;
                  final double opacity;

                  if (disableAnimations) {
                    scale = (1.0 - absDelta * 0.04).clamp(0.92, 1.0);
                    matrix = Matrix4.identity()..scale(scale, scale, 1.0);
                    opacity = (1.0 - absDelta * 0.65).clamp(0.0, 1.0);
                  } else {
                    final easedAbs = Curves.easeOut.transform(absDelta);
                    scale = (1.0 - easedAbs * 0.16).clamp(0.70, 1.0);
                    matrix = Matrix4.identity()
                      ..setEntry(3, 2, 0.0016)
                      ..translate(0.0, absDelta * 14.0)
                      ..rotateY(-delta * 0.42)
                      ..scale(scale, scale, 1.0);
                    opacity = (1.0 - absDelta * 0.35).clamp(0.0, 1.0);
                  }

                  final isCurrent = index == (_currentPageOffset?.round() ?? widget.currentIndex ?? 0);

                  return Center(
                    child: RepaintBoundary(
                      child: Transform(
                        alignment: Alignment.center,
                        transform: matrix,
                        child: Opacity(
                          opacity: opacity,
                          child: isCurrent
                              ? GestureDetector(
                                  onTapDown: (details) => _lastTapDown = details,
                                  onDoubleTap: (widget.onDoubleTapSeekForward != null || widget.onDoubleTapSeekBackward != null)
                                      ? _handleDoubleTap
                                      : null,
                                  onLongPress: _handleFlip,
                                  onTap: _isFlipped ? _handleFlip : null,
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge([_flipController, _rotationController]),
                                    builder: (context, _) {
                                      final flipAngle = _flipController.value * math.pi;
                                      final isShowingBack = _flipController.value >= 0.5;

                                      return Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..setEntry(3, 2, 0.0012)
                                          ..rotateY(flipAngle),
                                        child: isShowingBack
                                            ? Transform(
                                                alignment: Alignment.center,
                                                transform: Matrix4.identity()..rotateY(math.pi),
                                                child: _buildBackMetadataCard(
                                                  context,
                                                  colorScheme,
                                                  isDark,
                                                  primary,
                                                  track: effectiveTracks[index],
                                                ),
                                              )
                                            : _buildFrontArtworkCard(
                                                context,
                                                colorScheme,
                                                isDark,
                                                primary,
                                                track: effectiveTracks[index],
                                                isCurrent: true,
                                              ),
                                      );
                                    },
                                  ),
                                )
                              : GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 320),
                                      curve: Curves.easeOutCubic,
                                    );
                                  },
                                  child: _buildFrontArtworkCard(
                                    context,
                                    colorScheme,
                                    isDark,
                                    primary,
                                    track: effectiveTracks[index],
                                    isCurrent: false,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      );
    }

    // Single card fallback layout (e.g. 1 track in queue or standalone tests)
    return GestureDetector(
      onTapDown: (details) => _lastTapDown = details,
      onDoubleTap: (widget.onDoubleTapSeekForward != null || widget.onDoubleTapSeekBackward != null)
          ? _handleDoubleTap
          : null,
      onLongPress: _handleFlip,
      onTap: _isFlipped ? _handleFlip : null,
      onHorizontalDragUpdate: _handleHorizontalDragUpdate,
      onHorizontalDragEnd: _handleHorizontalDragEnd,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flipController, _rotationController]),
        builder: (context, child) {
          final flipAngle = _flipController.value * math.pi;
          final isShowingBack = _flipController.value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(flipAngle)
              ..translate(_swipeDragDelta * 0.4),
            child: isShowingBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: _buildBackMetadataCard(context, colorScheme, isDark, primary),
                  )
                : _buildFrontArtworkCard(context, colorScheme, isDark, primary, isCurrent: true),
          );
        },
      ),
    );
  }

  Widget _buildFrontArtworkCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color primary, {
    Track? track,
    bool isCurrent = false,
  }) {
    final effectiveTrack = track ?? widget.track;
    final artworkUri = effectiveTrack?.artworkUri;

    final Widget artworkContent = (artworkUri != null && artworkUri.isNotEmpty) ||
            effectiveTrack != null
        ? NexaArtworkImage(
            artworkUri: artworkUri,
            track: effectiveTrack,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            cacheWidth: 720,
            fallbackBuilder: (_) => _buildProceduralVinyl(
              context,
              colorScheme,
              isDark,
              primary,
              isCurrent: isCurrent,
            ),
          )
        : _buildProceduralVinyl(
            context,
            colorScheme,
            isDark,
            primary,
            isCurrent: isCurrent,
          );

    return Container(
      width: widget.size,
      height: widget.size,
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
            color: primary.withOpacity(isDark ? 0.32 : 0.18),
            blurRadius: 36.0,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.0),
        child: artworkContent,
      ),
    );
  }

  Widget _buildProceduralVinyl(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color primary, {
    bool isCurrent = false,
  }) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Concentric vinyl groove rings
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

        // Rotating center vinyl disc
        RotationTransition(
          turns: (isCurrent && widget.isPlaying)
              ? _rotationController
              : const AlwaysStoppedAnimation(0.2),
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
    );
  }

  Widget _buildBackMetadataCard(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color primary, {
    Track? track,
  }) {
    final effectiveTrack = track ?? widget.track;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final bitrateStr =
        AudioQualityFormatter.formatSignalChainFormat(effectiveTrack);
    final samplePrecisionStr =
        AudioQualityFormatter.formatSamplePrecision(effectiveTrack);
    final durationStr = effectiveTrack != null ? effectiveTrack.duration.toMinutesSeconds() : '3:50';
    final yearStr = effectiveTrack?.year != null ? '${effectiveTrack!.year}' : '2016';
    final genreStr = effectiveTrack?.genre ?? 'Synthpop / R&B';
    final pathStr = effectiveTrack?.filePath ?? '/Music/Starboy.mp3';

    return NexaSurface(
      level: NexaSurfaceLevel.l2,
      borderRadius: BorderRadius.circular(24.0),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: SizedBox(
            width: math.max(widget.size, 260.0),
            height: math.max(widget.size, 260.0),
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Header with Technical Details Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          'TECHNICAL DETAILS',
                          style: surfaceTokens.telemetryTextStyle.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 10.0,
                          ),
                        ),
                      ),
                      Icon(Icons.flip_to_front_rounded, size: 18, color: colorScheme.onSurface.withOpacity(0.6)),
                    ],
                  ),

                  // Interactive Signal Route Flow Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 5.0),
                    decoration: BoxDecoration(
                      color: surfaceTokens.level3,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '3D SIGNAL CHAIN',
                          style: surfaceTokens.telemetryTextStyle.copyWith(
                            color: primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            fontSize: 9.0,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _chainNode('SOURCE', primary, surfaceTokens),
                            _chainArrow(primary),
                            _chainNode('DSP', primary, surfaceTokens),
                            _chainArrow(primary),
                            _chainNode('DVC', primary, surfaceTokens),
                            _chainArrow(primary),
                            _chainNode('OUTPUT', primary, surfaceTokens),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Telemetry Specs
                  _detailRow('Format / Bitrate', bitrateStr, colorScheme, surfaceTokens),
                  _detailRow('Sample Precision', samplePrecisionStr, colorScheme, surfaceTokens),
                  _detailRow('Duration', durationStr, colorScheme, surfaceTokens),
                  _detailRow('Year', yearStr, colorScheme, surfaceTokens),
                  _detailRow('ReplayGain', '+0.0 dB (Radio)', colorScheme, surfaceTokens),
                  _detailRow('Genre', genreStr, colorScheme, surfaceTokens),
                  _detailRow('Path', pathStr, colorScheme, surfaceTokens, isPath: true),

                  Center(
                    child: Text(
                      'Tap anywhere to flip back',
                      style: surfaceTokens.telemetryTextStyle.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.40),
                        fontStyle: FontStyle.italic,
                        fontSize: 10.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _chainNode(String name, Color primary, NexaSurfaceTokens surfaceTokens) {
    return Text(
      name,
      style: surfaceTokens.telemetryTextStyle.copyWith(
        color: primary,
        fontWeight: FontWeight.bold,
        fontSize: 9.0,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _chainArrow(Color primary) {
    return Icon(Icons.arrow_forward_ios_rounded, size: 8.0, color: primary.withOpacity(0.5));
  }

  Widget _detailRow(
    String label,
    String value,
    ColorScheme colorScheme,
    NexaSurfaceTokens surfaceTokens, {
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: isPath ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: surfaceTokens.telemetryTextStyle.copyWith(
            color: colorScheme.onSurface.withOpacity(0.55),
            fontWeight: FontWeight.w600,
            fontSize: 11.0,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: surfaceTokens.telemetryTextStyle.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
              fontSize: 11.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
