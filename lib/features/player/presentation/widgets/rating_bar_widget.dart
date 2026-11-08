import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive 5-star rating widget with animated star filling and haptic response.
class RatingBarWidget extends StatefulWidget {
  const RatingBarWidget({
    super.key,
    this.initialRating = 4,
    this.onRatingChanged,
    this.starSize = 20.0,
    this.starColor,
  });

  final int initialRating;
  final ValueChanged<int>? onRatingChanged;
  final double starSize;
  final Color? starColor;

  @override
  State<RatingBarWidget> createState() => _RatingBarWidgetState();
}

class _RatingBarWidgetState extends State<RatingBarWidget> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating.clamp(0, 5);
  }

  @override
  void didUpdateWidget(RatingBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRating != oldWidget.initialRating) {
      _rating = widget.initialRating.clamp(0, 5);
    }
  }

  void _setRating(int stars) {
    HapticFeedback.selectionClick();
    setState(() => _rating = stars);
    widget.onRatingChanged?.call(stars);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.starColor ?? const Color(0xFFFBBF24); // Amber
    final inactiveColor = theme.colorScheme.onSurface.withOpacity(0.25);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isFilled = starValue <= _rating;

        return GestureDetector(
          onTap: () => _setRating(starValue == _rating ? 0 : starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: Icon(
              isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
              color: isFilled ? activeColor : inactiveColor,
              size: widget.starSize,
            ),
          ),
        );
      }),
    );
  }
}
