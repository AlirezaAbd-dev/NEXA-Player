import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Pure coordinator calculating auto-scroll offsets and protecting manual user
/// scrolling across any song list in the app.
class ActiveTrackAutoScroller {
  ActiveTrackAutoScroller({
    this.itemExtent = 76.0,
    this.manualCooldown = const Duration(seconds: 3),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final double itemExtent;
  final Duration manualCooldown;
  final DateTime Function() _clock;

  DateTime? _cooldownUntil;

  /// Records manual user drag interaction, suppressing auto-follow temporarily.
  void registerManualScroll() {
    _cooldownUntil = _clock().add(manualCooldown);
  }

  /// Clears manual cooldown (e.g., when user taps "Jump to Playing").
  void clearCooldown() {
    _cooldownUntil = null;
  }

  /// Whether auto-scroll is currently suppressed due to recent manual drag.
  bool get isSuppressedByUser {
    final until = _cooldownUntil;
    if (until == null) return false;
    return _clock().isBefore(until);
  }

  /// Computes the clamped target scroll offset centering [itemIndex] above the
  /// bottom mini-player/dock area, or returns `null` if already comfortably in view.
  double? computeTargetOffset({
    required int itemIndex,
    required double currentPixels,
    required double viewportDimension,
    required double maxScrollExtent,
    double bottomOcclusionClearance = 124.0,
    bool forceScroll = false,
  }) {
    if (itemIndex < 0 || viewportDimension <= 0) return null;

    final itemTop = itemIndex * itemExtent;
    final itemBottom = itemTop + itemExtent;
    final itemCenter = itemTop + (itemExtent * 0.5);

    final visibleTop = currentPixels + 8.0;
    final visibleBottom =
        currentPixels + (viewportDimension - bottomOcclusionClearance).clamp(80.0, viewportDimension);

    if (!forceScroll && itemTop >= visibleTop && itemBottom <= visibleBottom) {
      return null;
    }

    final centered = itemCenter - (viewportDimension * 0.42);
    return centered.clamp(0.0, maxScrollExtent > 0 ? maxScrollExtent : 0.0);
  }

  /// Returns true when the visible viewport center is more than [thresholdItems]
  /// away from [activeItemIndex].
  bool isFarFromActive({
    required int activeItemIndex,
    required double currentPixels,
    required double viewportDimension,
    int thresholdItems = 10,
  }) {
    if (activeItemIndex < 0 || viewportDimension <= 0) return false;
    final centerIndex =
        ((currentPixels + viewportDimension * 0.5) / itemExtent).round();
    return (centerIndex - activeItemIndex).abs() > thresholdItems;
  }
}

/// Reusable wrapper providing smart active-track auto-scrolling, manual-scroll
/// protection (3s cooldown), reduced-motion fallback, and an optional floating
/// "Jump to Playing" pill whenever the user scrolls > 10 items away.
class ActiveTrackAutoScrollScope extends StatefulWidget {
  const ActiveTrackAutoScrollScope({
    super.key,
    required this.trackIds,
    required this.activeTrackId,
    required this.builder,
    this.controller,
    this.indexOffset = 0,
    this.itemExtent = 76.0,
    this.manualCooldown = const Duration(seconds: 3),
    this.clock,
    this.showJumpToPlayingChip = true,
    this.bottomChipPadding = 128.0,
  });

  final List<String> trackIds;
  final String? activeTrackId;
  final Widget Function(BuildContext context, ScrollController controller)
      builder;
  final ScrollController? controller;
  final int indexOffset;
  final double itemExtent;
  final Duration manualCooldown;
  final DateTime Function()? clock;
  final bool showJumpToPlayingChip;
  final double bottomChipPadding;

  @override
  State<ActiveTrackAutoScrollScope> createState() =>
      _ActiveTrackAutoScrollScopeState();
}

class _ActiveTrackAutoScrollScopeState
    extends State<ActiveTrackAutoScrollScope> {
  late ScrollController _scrollController;
  late ActiveTrackAutoScroller _coordinator;
  String? _lastTrackedId;
  bool _showJumpChip = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _coordinator = ActiveTrackAutoScroller(
      itemExtent: widget.itemExtent,
      manualCooldown: widget.manualCooldown,
      clock: widget.clock,
    );
    _lastTrackedId = widget.activeTrackId;
    _scrollController.addListener(_updateJumpChipVisibility);
  }

  @override
  void didUpdateWidget(ActiveTrackAutoScrollScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _scrollController.removeListener(_updateJumpChipVisibility);
        _scrollController.dispose();
      } else {
        oldWidget.controller!.removeListener(_updateJumpChipVisibility);
      }
      _scrollController = widget.controller ?? ScrollController();
      _scrollController.addListener(_updateJumpChipVisibility);
    }

    if (widget.activeTrackId != _lastTrackedId) {
      _lastTrackedId = widget.activeTrackId;
      _maybeScrollToActive(force: false);
    }
    _updateJumpChipVisibility();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateJumpChipVisibility);
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  int get _activeEffectiveIndex {
    final activeId = widget.activeTrackId;
    if (activeId == null) return -1;
    final idx = widget.trackIds.indexOf(activeId);
    if (idx < 0) return -1;
    return widget.indexOffset + idx;
  }

  void _updateJumpChipVisibility() {
    if (!mounted || !widget.showJumpToPlayingChip) return;
    if (!_scrollController.hasClients) {
      if (_showJumpChip) setState(() => _showJumpChip = false);
      return;
    }
    final activeIdx = _activeEffectiveIndex;
    final shouldShow = activeIdx >= 0 &&
        _coordinator.isFarFromActive(
          activeItemIndex: activeIdx,
          currentPixels: _scrollController.position.pixels,
          viewportDimension: _scrollController.position.viewportDimension,
        );
    if (shouldShow != _showJumpChip) {
      setState(() => _showJumpChip = shouldShow);
    }
  }

  void _maybeScrollToActive({required bool force}) {
    if (widget.activeTrackId == null) return;
    if (!force && _coordinator.isSuppressedByUser) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final activeIdx = _activeEffectiveIndex;
      if (activeIdx < 0) return;

      final pos = _scrollController.position;
      final target = _coordinator.computeTargetOffset(
        itemIndex: activeIdx,
        currentPixels: pos.pixels,
        viewportDimension: pos.viewportDimension,
        maxScrollExtent: pos.maxScrollExtent,
        forceScroll: force,
      );
      if (target == null) return;

      final disableAnimations = MediaQuery.disableAnimationsOf(context);
      if (disableAnimations) {
        _scrollController.jumpTo(target);
      } else {
        _scrollController.animateTo(
          target,
          duration: const Duration(milliseconds: 380),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final listChild = NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _coordinator.registerManualScroll();
        } else if (notification is UserScrollNotification &&
            notification.direction != ScrollDirection.idle) {
          _coordinator.registerManualScroll();
        }
        return false;
      },
      child: widget.builder(context, _scrollController),
    );

    if (!widget.showJumpToPlayingChip) {
      return listChild;
    }

    return Stack(
      children: [
        listChild,
        if (_showJumpChip)
          Positioned(
            right: 16.0,
            bottom: MediaQuery.paddingOf(context).bottom +
                widget.bottomChipPadding,
            child: NexaSurface(
              level: NexaSurfaceLevel.l3,
              borderRadius: BorderRadius.circular(20.0),
              child: InkWell(
                key: const ValueKey('jump_to_playing_chip'),
                borderRadius: BorderRadius.circular(20.0),
                onTap: () {
                  _coordinator.clearCooldown();
                  _maybeScrollToActive(force: true);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        size: 16.0,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 6.0),
                      Text(
                        'Jump to Playing',
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
