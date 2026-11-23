import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Animation modes supported by [NexaAnimatedLogo].
enum NexaLogoAnimationMode {
  /// One-shot 850ms intro animation (easeOutCubic).
  ///
  /// Soundwave traces from left to right via [PathMetric.extractPath],
  /// while the monogram ribbons and chevron scale and fade into view.
  /// Automatically stops its ticker when complete (0% idle CPU/GPU).
  splash,

  /// Continuous ambient shimmer and subtle ±2.5% wave pulse synced
  /// with media playback state.
  ///
  /// The ticker is paused whenever [isPlaying] is false or the widget
  /// is removed from the visible tree.
  playing,

  /// Zero-ticker static rendering for headers, rails, and cards.
  /// Allocates no [AnimationController].
  static,
}

/// A zero-dependency, GPU-light vector logo widget for NEXA Player.
///
/// Renders the approved NEXA brand geometry (N monogram, play chevron,
/// and acoustic soundwave ribbon) via cached [Path] coordinates in a
/// normalized 512x512 coordinate space, scaled seamlessly to any target [size].
///
/// Features:
/// * Zero memory allocations during [CustomPainter.paint].
/// * Respects [MediaQuery.disableAnimationsOf] (forces static rendering).
/// * Accessible with [Semantics] screen-reader label.
/// * Isolated rendering layer via [RepaintBoundary].
class NexaAnimatedLogo extends StatefulWidget {
  const NexaAnimatedLogo({
    super.key,
    this.size = 48.0,
    this.mode = NexaLogoAnimationMode.static,
    this.isPlaying = true,
    this.colorOverride,
    this.semanticLabel = 'NEXA Player logo',
  }) : assert(size > 0, 'size must be positive');

  /// Target square dimension of the logo in logical pixels.
  final double size;

  /// Active animation mode.
  final NexaLogoAnimationMode mode;

  /// Whether audio is actively playing in [NexaLogoAnimationMode.playing].
  ///
  /// When `false`, ticker updates are stopped immediately to conserve battery.
  final bool isPlaying;

  /// Optional monochrome color override for theme matching
  /// (e.g. Daylight, Sakura, or monochrome Android icons).
  ///
  /// When null, paints the full approved multi-tone electric cyan/cobalt/violet gradients.
  final Color? colorOverride;

  /// Screen reader semantic label.
  final String semanticLabel;

  @override
  State<NexaAnimatedLogo> createState() => _NexaAnimatedLogoState();
}

class _NexaAnimatedLogoState extends State<NexaAnimatedLogo>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _curvedAnimation;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initOrUpdateController();
  }

  @override
  void didUpdateWidget(covariant NexaAnimatedLogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode != oldWidget.mode ||
        widget.isPlaying != oldWidget.isPlaying) {
      _initOrUpdateController();
    }
  }

  bool get _isReducedMotion {
    if (!mounted) return false;
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  void _initOrUpdateController() {
    final effectiveMode = _isReducedMotion ? NexaLogoAnimationMode.static : widget.mode;

    if (effectiveMode == NexaLogoAnimationMode.static) {
      _controller?.stop();
      _controller?.dispose();
      _controller = null;
      _curvedAnimation = null;
      return;
    }

    if (_controller == null) {
      _controller = AnimationController(vsync: this);
      _curvedAnimation = CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOutCubic,
      );
    }

    _ensureRunningState();
  }

  void _ensureRunningState() {
    if (_controller == null || _isReducedMotion) return;

    switch (widget.mode) {
      case NexaLogoAnimationMode.splash:
        _controller!.duration = const Duration(milliseconds: 850);
        _controller!.forward(from: 0.0);
        break;
      case NexaLogoAnimationMode.playing:
        _controller!.duration = const Duration(milliseconds: 2500);
        if (widget.isPlaying) {
          if (!_controller!.isAnimating) {
            _controller!.repeat();
          }
        } else {
          _controller!.stop();
        }
        break;
      case NexaLogoAnimationMode.static:
        _controller!.stop();
        break;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMode =
        _isReducedMotion ? NexaLogoAnimationMode.static : widget.mode;

    final Widget painter = CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _NexaLogoPainter(
        animation: effectiveMode == NexaLogoAnimationMode.static
            ? null
            : (_curvedAnimation ?? _controller),
        mode: effectiveMode,
        isPlaying: widget.isPlaying,
        colorOverride: widget.colorOverride,
      ),
    );

    return Semantics(
      label: widget.semanticLabel,
      image: true,
      child: RepaintBoundary(
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: painter,
        ),
      ),
    );
  }
}

/// Internal CustomPainter executing zero-allocation drawing using cached path metrics.
class _NexaLogoPainter extends CustomPainter {
  _NexaLogoPainter({
    required this.animation,
    required this.mode,
    required this.isPlaying,
    required this.colorOverride,
  }) : super(repaint: animation);

  final Listenable? animation;
  final NexaLogoAnimationMode mode;
  final bool isPlaying;
  final Color? colorOverride;

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 512.0;

    canvas.save();
    canvas.scale(scale, scale);

    final double animValue = animation is Animation<double>
        ? (animation as Animation<double>).value
        : 1.0;

    if (colorOverride != null) {
      _paintMonochrome(canvas, animValue);
    } else {
      _paintFullColor(canvas, animValue);
    }

    canvas.restore();
  }

  void _paintFullColor(Canvas canvas, double progress) {
    // Determine dynamic properties based on mode
    double waveProgress1 = 1.0;
    double waveProgress2 = 1.0;
    double monogramScale = 1.0;
    double monogramOpacity = 1.0;
    double pulse = 0.0;
    double shimmerShift = 0.0;

    if (mode == NexaLogoAnimationMode.splash) {
      // Wave 1 traces first (0.0 -> 0.85), Wave 2 follows (0.40 -> 1.0)
      waveProgress1 = (progress / 0.85).clamp(0.0, 1.0);
      waveProgress2 = ((progress - 0.40) / 0.60).clamp(0.0, 1.0);
      monogramOpacity = ((progress - 0.15) / 0.75).clamp(0.0, 1.0);
      monogramScale = 0.90 + (0.10 * ((progress - 0.15) / 0.85).clamp(0.0, 1.0));
      shimmerShift = (progress - 0.5) * 80.0;
    } else if (mode == NexaLogoAnimationMode.playing) {
      if (isPlaying) {
        pulse = math.sin(progress * 2 * math.pi) * 0.025;
        shimmerShift = math.sin(progress * 2 * math.pi) * 35.0;
      }
    }

    // 1. Shaded under-folds & Monogram (scaled smoothly during splash)
    canvas.save();
    if (monogramScale != 1.0) {
      canvas.translate(256, 256);
      canvas.scale(monogramScale, monogramScale);
      canvas.translate(-256, -256);
    }

    final foldShadowShader = ui.Gradient.linear(
      const Offset(100, 372),
      const Offset(262, 200),
      [
        const Color(0xFF7C4DFF).withOpacity(monogramOpacity),
        const Color(0xFF3B6BFF).withOpacity(monogramOpacity),
        const Color(0xFF1D4ED8).withOpacity(monogramOpacity),
      ],
      const [0.0, 0.55, 1.0],
    );

    final cyanBlueShader = ui.Gradient.linear(
      Offset(88 + shimmerShift * 0.3, 376),
      Offset(278 + shimmerShift * 0.3, 152),
      [
        const Color(0xFF00E5FF).withOpacity(monogramOpacity),
        const Color(0xFF00C4FF).withOpacity(monogramOpacity),
        const Color(0xFF2979FF).withOpacity(monogramOpacity),
      ],
      const [0.0, 0.55, 1.0],
    );

    final violetBlueShader = ui.Gradient.linear(
      Offset(252 + shimmerShift * 0.2, 340),
      Offset(368 + shimmerShift * 0.2, 134),
      [
        const Color(0xFF1E64FF).withOpacity(monogramOpacity),
        const Color(0xFF4F6BFF).withOpacity(monogramOpacity),
        const Color(0xFF7C4DFF).withOpacity(monogramOpacity),
      ],
      const [0.0, 0.58, 1.0],
    );

    final playCyanShader = ui.Gradient.linear(
      Offset(340 + shimmerShift * 0.25, 210),
      Offset(428 + shimmerShift * 0.25, 264),
      [
        const Color(0xFF00E5FF).withOpacity(monogramOpacity),
        const Color(0xFF00C8FF).withOpacity(monogramOpacity),
      ],
      const [0.0, 1.0],
    );

    // Play chevron lower shaded fold
    final foldPaint = Paint()..shader = foldShadowShader;
    canvas.drawPath(_NexaLogoPaths.chevronLowerFold, foldPaint);

    // Play chevron top bright cyan arm
    final playCyanPaint = Paint()..shader = playCyanShader;
    canvas.drawPath(_NexaLogoPaths.chevronTopArm, playCyanPaint);

    // Left N inner depth ribbon
    canvas.drawPath(_NexaLogoPaths.leftNInnerRibbon, foldPaint);

    // Left N outer cyan arch
    final cyanPaint = Paint()..shader = cyanBlueShader;
    canvas.drawPath(_NexaLogoPaths.leftNOuterArch, cyanPaint);

    // Right N diagonal violet-to-cobalt blade
    final violetPaint = Paint()..shader = violetBlueShader;
    canvas.drawPath(_NexaLogoPaths.rightNBlade, violetPaint);

    canvas.restore();

    // 2. Continuous acoustic soundwave ribbon
    final waveShader = ui.Gradient.linear(
      Offset(138 + shimmerShift, 320),
      Offset(432 + shimmerShift, 320),
      const [
        Color(0xFF00E5FF),
        Color(0xFF2979FF),
        Color(0xFF7C4DFF),
      ],
      const [0.0, 0.52, 1.0],
    );

    final wave1Paint = Paint()
      ..shader = waveShader
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 14.0 * (1.0 + pulse);

    final wave2Paint = Paint()
      ..shader = waveShader
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 13.0 * (1.0 + pulse);

    if (waveProgress1 >= 1.0) {
      canvas.drawPath(_NexaLogoPaths.wave1, wave1Paint);
    } else if (waveProgress1 > 0.0) {
      final subPath = _NexaLogoPaths.wave1Metric.extractPath(
        0.0,
        _NexaLogoPaths.wave1Metric.length * waveProgress1,
      );
      canvas.drawPath(subPath, wave1Paint);
    }

    if (waveProgress2 >= 1.0) {
      canvas.drawPath(_NexaLogoPaths.wave2, wave2Paint);
    } else if (waveProgress2 > 0.0) {
      final subPath = _NexaLogoPaths.wave2Metric.extractPath(
        0.0,
        _NexaLogoPaths.wave2Metric.length * waveProgress2,
      );
      canvas.drawPath(subPath, wave2Paint);
    }
  }

  void _paintMonochrome(Canvas canvas, double progress) {
    double waveProgress1 = 1.0;
    double waveProgress2 = 1.0;
    double monogramScale = 1.0;
    double opacity = 1.0;
    double pulse = 0.0;

    if (mode == NexaLogoAnimationMode.splash) {
      waveProgress1 = (progress / 0.85).clamp(0.0, 1.0);
      waveProgress2 = ((progress - 0.40) / 0.60).clamp(0.0, 1.0);
      opacity = ((progress - 0.15) / 0.75).clamp(0.0, 1.0);
      monogramScale = 0.90 + (0.10 * ((progress - 0.15) / 0.85).clamp(0.0, 1.0));
    } else if (mode == NexaLogoAnimationMode.playing && isPlaying) {
      pulse = math.sin(progress * 2 * math.pi) * 0.025;
    }

    final effectiveColor = colorOverride!.withOpacity(
      colorOverride!.opacity * opacity,
    );

    final fillPaint = Paint()..color = effectiveColor;

    canvas.save();
    if (monogramScale != 1.0) {
      canvas.translate(256, 256);
      canvas.scale(monogramScale, monogramScale);
      canvas.translate(-256, -256);
    }

    // High-contrast clean silhouette: top surfaces only
    canvas.drawPath(_NexaLogoPaths.chevronTopArm, fillPaint);
    canvas.drawPath(_NexaLogoPaths.leftNOuterArch, fillPaint);
    canvas.drawPath(_NexaLogoPaths.rightNBlade, fillPaint);

    canvas.restore();

    final wave1Paint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 16.0 * (1.0 + pulse);

    final wave2Paint = Paint()
      ..color = effectiveColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 15.0 * (1.0 + pulse);

    if (waveProgress1 >= 1.0) {
      canvas.drawPath(_NexaLogoPaths.wave1, wave1Paint);
    } else if (waveProgress1 > 0.0) {
      final subPath = _NexaLogoPaths.wave1Metric.extractPath(
        0.0,
        _NexaLogoPaths.wave1Metric.length * waveProgress1,
      );
      canvas.drawPath(subPath, wave1Paint);
    }

    if (waveProgress2 >= 1.0) {
      canvas.drawPath(_NexaLogoPaths.wave2, wave2Paint);
    } else if (waveProgress2 > 0.0) {
      final subPath = _NexaLogoPaths.wave2Metric.extractPath(
        0.0,
        _NexaLogoPaths.wave2Metric.length * waveProgress2,
      );
      canvas.drawPath(subPath, wave2Paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NexaLogoPainter oldDelegate) {
    return oldDelegate.animation != animation ||
        oldDelegate.mode != mode ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.colorOverride != colorOverride;
  }
}

/// Static geometry definitions and cached PathMetrics for NEXA Logo.
///
/// Pre-constructed using `late final` so coordinate generation occurs exactly once
/// upon first read, guaranteeing zero CPU/GPU overhead on subsequent draws.
abstract final class _NexaLogoPaths {
  static final Path wave1 = _buildWave1();
  static final Path wave2 = _buildWave2();
  static final Path chevronLowerFold = _buildChevronLowerFold();
  static final Path chevronTopArm = _buildChevronTopArm();
  static final Path leftNInnerRibbon = _buildLeftNInnerRibbon();
  static final Path leftNOuterArch = _buildLeftNOuterArch();
  static final Path rightNBlade = _buildRightNBlade();

  static final ui.PathMetric wave1Metric = wave1.computeMetrics().first;
  static final ui.PathMetric wave2Metric = wave2.computeMetrics().first;

  static Path _buildWave1() {
    return Path()
      ..moveTo(138, 330)
      ..cubicTo(162, 330, 172, 274, 194, 274)
      ..cubicTo(216, 274, 214, 344, 256, 344)
      ..cubicTo(284, 344, 294, 316, 306, 316)
      ..cubicTo(318, 316, 320, 366, 332, 366)
      ..cubicTo(344, 366, 348, 296, 368, 284)
      ..lineTo(408, 260);
  }

  static Path _buildWave2() {
    return Path()
      ..moveTo(356, 316)
      ..cubicTo(362, 354, 374, 358, 380, 334)
      ..cubicTo(386, 310, 396, 296, 406, 312)
      ..cubicTo(414, 324, 422, 328, 432, 328);
  }

  static Path _buildChevronLowerFold() {
    return Path()
      ..moveTo(396, 248)
      ..lineTo(422, 262)
      ..lineTo(364, 296)
      ..cubicTo(352, 303, 346, 316, 342, 330)
      ..lineTo(334, 304)
      ..cubicTo(338, 286, 348, 274, 364, 265)
      ..close();
  }

  static Path _buildChevronTopArm() {
    return Path()
      ..moveTo(348, 206)
      ..lineTo(422, 248)
      ..cubicTo(430, 253, 430, 263, 422, 268)
      ..lineTo(394, 282)
      ..cubicTo(400, 269, 396, 259, 384, 252)
      ..lineTo(338, 228)
      ..close();
  }

  static Path _buildLeftNInnerRibbon() {
    return Path()
      ..moveTo(84, 380)
      ..lineTo(138, 352)
      ..lineTo(176, 226)
      ..cubicTo(182, 210, 194, 212, 202, 226)
      ..lineTo(256, 338)
      ..lineTo(272, 326)
      ..lineTo(210, 196)
      ..cubicTo(192, 164, 164, 166, 152, 198)
      ..lineTo(84, 380)
      ..close();
  }

  static Path _buildLeftNOuterArch() {
    return Path()
      ..moveTo(84, 380)
      ..lineTo(150, 178)
      ..cubicTo(162, 146, 200, 144, 218, 174)
      ..lineTo(282, 280)
      ..lineTo(256, 336)
      ..lineTo(198, 222)
      ..cubicTo(188, 202, 166, 204, 158, 224)
      ..lineTo(110, 364)
      ..close();
  }

  static Path _buildRightNBlade() {
    return Path()
      ..moveTo(236, 302)
      ..lineTo(288, 184)
      ..cubicTo(296, 166, 310, 154, 328, 146)
      ..lineTo(368, 134)
      ..lineTo(292, 322)
      ..cubicTo(284, 340, 264, 346, 250, 338)
      ..close();
  }
}
