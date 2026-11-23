import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/design_system/nexa_surface_tokens.dart';

/// Interactive container providing Magnetic Swipe-to-Queue gestures for track items.
///
/// Thresholds:
/// - Short swipe right ($dx \ge 68\text{dp}$): Triggers [onPlayNext] with selection click haptic.
/// - Deep swipe right ($dx \ge 148\text{dp}$): Triggers [onAddToQueueEnd] with medium impact haptic.
/// - Swipe left ($dx \le -68\text{dp}$): Triggers [onSwipeLeft] with selection click haptic.
class SwipeableTrackTile extends StatefulWidget {
  const SwipeableTrackTile({
    required this.child,
    required this.onPlayNext,
    required this.onAddToQueueEnd,
    this.onSwipeLeft,
    super.key,
  });

  final Widget child;
  final VoidCallback onPlayNext;
  final VoidCallback onAddToQueueEnd;
  final VoidCallback? onSwipeLeft;

  @override
  State<SwipeableTrackTile> createState() => _SwipeableTrackTileState();
}

class _SwipeableTrackTileState extends State<SwipeableTrackTile>
    with SingleTickerProviderStateMixin {
  double _dragOffset = 0.0;
  bool _shortRightDetentTriggered = false;
  bool _deepRightDetentTriggered = false;
  bool _leftDetentTriggered = false;

  late final AnimationController _springController;
  late Animation<double> _springAnimation;

  static const double _shortRightThreshold = 68.0;
  static const double _deepRightThreshold = 148.0;
  static const double _leftThreshold = -68.0;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        setState(() {
          _dragOffset = _springAnimation.value;
        });
      });
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_springController.isAnimating) {
      _springController.stop();
    }

    setState(() {
      _dragOffset += details.primaryDelta ?? 0.0;
      // Damped rubber-banding past deep thresholds
      if (_dragOffset > _deepRightThreshold + 50.0) {
        _dragOffset = _deepRightThreshold + 50.0;
      } else if (_dragOffset < _leftThreshold - 50.0) {
        _dragOffset = _leftThreshold - 50.0;
      }

      // Magnetic Haptic Feedback Detents
      if (_dragOffset >= _deepRightThreshold) {
        if (!_deepRightDetentTriggered) {
          _deepRightDetentTriggered = true;
          HapticFeedback.mediumImpact();
        }
      } else if (_dragOffset >= _shortRightThreshold) {
        if (!_shortRightDetentTriggered) {
          _shortRightDetentTriggered = true;
          HapticFeedback.selectionClick();
        }
        _deepRightDetentTriggered = false;
      } else {
        _shortRightDetentTriggered = false;
        _deepRightDetentTriggered = false;
      }

      if (_dragOffset <= _leftThreshold) {
        if (!_leftDetentTriggered) {
          _leftDetentTriggered = true;
          HapticFeedback.selectionClick();
        }
      } else {
        _leftDetentTriggered = false;
      }
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final triggeredOffset = _dragOffset;

    if (triggeredOffset >= _deepRightThreshold) {
      widget.onAddToQueueEnd();
    } else if (triggeredOffset >= _shortRightThreshold) {
      widget.onPlayNext();
    } else if (triggeredOffset <= _leftThreshold && widget.onSwipeLeft != null) {
      widget.onSwipeLeft!();
    }

    // Reset detent flags and spring back to 0.0
    _shortRightDetentTriggered = false;
    _deepRightDetentTriggered = false;
    _leftDetentTriggered = false;

    _springAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _springController,
        curve: Curves.easeOutCubic,
      ),
    );

    _springController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = NexaSurfaceTokens.of(context);
    final isDraggingRight = _dragOffset > 0;
    final isDraggingLeft = _dragOffset < 0;

    return Stack(
      children: [
        // Background Actions Reveal
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: isDraggingRight
                  ? (_dragOffset >= _deepRightThreshold
                      ? const Color(0xFF7C4DFF).withOpacity(0.25)
                      : tokens.l4.withOpacity(0.20))
                  : (isDraggingLeft
                      ? const Color(0xFFFF3B30).withOpacity(0.20)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(16.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              mainAxisAlignment: isDraggingRight
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.end,
              children: [
                if (isDraggingRight) ...[
                  Icon(
                    _dragOffset >= _deepRightThreshold
                        ? Icons.queue_music_rounded
                        : Icons.playlist_play_rounded,
                    color: _dragOffset >= _deepRightThreshold
                        ? const Color(0xFFB388FF)
                        : tokens.l4,
                    size: 24.0,
                  ),
                  const SizedBox(width: 8.0),
                  Text(
                    _dragOffset >= _deepRightThreshold
                        ? 'Add to Queue End'
                        : 'Play Next',
                    style: TextStyle(
                      color: _dragOffset >= _deepRightThreshold
                          ? const Color(0xFFB388FF)
                          : tokens.l4,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                    ),
                  ),
                ] else if (isDraggingLeft) ...[
                  const Text(
                    'Favorite / Quick Action',
                    style: TextStyle(
                      color: Color(0xFFFF5252),
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  const Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF5252),
                    size: 22.0,
                  ),
                ],
              ],
            ),
          ),
        ),

        // Foreground Swiping Tile
        GestureDetector(
          onHorizontalDragUpdate: _onHorizontalDragUpdate,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Transform.translate(
            offset: Offset(_dragOffset, 0.0),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
