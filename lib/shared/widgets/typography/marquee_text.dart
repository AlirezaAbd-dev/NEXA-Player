import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/utils/tag_encoding_decoder.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

/// News-ticker / marquee scrolling text widget that activates **only** when the
/// single-line text exceeds the available horizontal width.
///
/// Supports automatic Bidi direction detection (LTR English & RTL Persian/Arabic),
/// Persian font fallback, soft horizontal edge fading, and reduced-motion fallback.
class MarqueeText extends StatefulWidget {
  const MarqueeText(
    this.text, {
    super.key,
    this.style,
    this.textDirection,
    this.gap = 48.0,
    this.velocity = 36.0,
    this.pauseDuration = const Duration(milliseconds: 1400),
    this.enabled = true,
  });

  final String text;
  final TextStyle? style;
  final TextDirection? textDirection;
  final double gap;
  final double velocity;
  final Duration pauseDuration;
  final bool enabled;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _pauseTimer;
  double _activeCycleDistance = 0.0;
  String _activeSignature = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addStatusListener(_handleAnimationStatus);
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.enabled != widget.enabled ||
        oldWidget.style != widget.style) {
      _stopMarquee();
      _activeSignature = '';
    }
  }

  @override
  void dispose() {
    _pauseTimer?.cancel();
    _controller.removeStatusListener(_handleAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      _controller.value = 0.0;
      _scheduleNextScroll();
    }
  }

  void _stopMarquee() {
    _pauseTimer?.cancel();
    _pauseTimer = null;
    if (_controller.isAnimating || _controller.value != 0.0) {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  void _syncMarquee(String signature, double cycleDistance) {
    if (_activeSignature == signature) return;
    _activeSignature = signature;
    _activeCycleDistance = cycleDistance;
    _stopMarquee();
    _scheduleNextScroll();
  }

  void _scheduleNextScroll() {
    _pauseTimer?.cancel();
    if (!mounted || !widget.enabled || _activeCycleDistance <= 0) return;
    final scrollMs = ((_activeCycleDistance / widget.velocity) * 1000)
        .round()
        .clamp(600, 60000);
    _controller.duration = Duration(milliseconds: scrollMs);

    _pauseTimer = Timer(widget.pauseDuration, () {
      if (!mounted || !widget.enabled || _activeCycleDistance <= 0) return;
      _controller.forward(from: 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayText = TagEncodingDecoder.repairMojibake(widget.text);
    final effectiveDirection =
        widget.textDirection ?? TagEncodingDecoder.detectBidiDirection(displayText);
    final effectiveStyle = (widget.style ?? DefaultTextStyle.of(context).style)
        .copyWith(
      fontFamilyFallback:
          widget.style?.fontFamilyFallback ?? AppTypography.persianFontFallback,
    );
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textPainter = TextPainter(
          text: TextSpan(text: displayText, style: effectiveStyle),
          maxLines: 1,
          textDirection: effectiveDirection,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();

        final maxWidth =
            constraints.maxWidth.isFinite ? constraints.maxWidth : textPainter.width;
        final overflows = textPainter.width > maxWidth + 0.5;

        if (!overflows || !widget.enabled || reduceMotion) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _activeSignature.isNotEmpty) {
              _activeSignature = '';
              _stopMarquee();
            }
          });
          return BidiText(
            widget.text,
            style: widget.style,
            textDirection: effectiveDirection,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        final cycleDistance = textPainter.width + widget.gap;
        final signature = '$displayText|${maxWidth.toStringAsFixed(1)}';
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _syncMarquee(signature, cycleDistance);
          }
        });

        final lineHeight = textPainter.height;
        final isRtl = effectiveDirection == TextDirection.rtl;

        return ClipRect(
          child: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Colors.transparent,
                Colors.white,
                Colors.white,
                Colors.transparent,
              ],
              stops: [0.0, 0.04, 0.94, 1.0],
            ).createShader(bounds),
            blendMode: BlendMode.dstIn,
            child: SizedBox(
              width: maxWidth,
              height: lineHeight,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final dx = _controller.value * cycleDistance;
                  return Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      Positioned(
                        top: 0,
                        left: isRtl ? null : -dx,
                        right: isRtl ? -dx : null,
                        child: Text(
                          displayText,
                          style: effectiveStyle,
                          textDirection: effectiveDirection,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: isRtl ? null : cycleDistance - dx,
                        right: isRtl ? cycleDistance - dx : null,
                        child: ExcludeSemantics(
                          child: Text(
                            displayText,
                            style: effectiveStyle,
                            textDirection: effectiveDirection,
                            maxLines: 1,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
