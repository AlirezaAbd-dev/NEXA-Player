import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dynamic, luminous ambient aurora mesh background.
///
/// Provides fluid, multi-layered glowing chromatic orbs behind the UI canvas.
/// This gives all frosted glass widgets ([GlassCard], [GlassAppBar], [GlassBottomNav],
/// [TrackTile], [AlbumCard]) rich, colorful light to refract and blur via [BackdropFilter],
/// delivering true next-gen VisionOS/iOS 18 style glassmorphism.
class AppAmbientBackground extends StatefulWidget {
  const AppAmbientBackground({
    super.key,
    this.primaryColor,
    this.secondaryColor,
    this.tertiaryColor,
    this.child,
    this.animate = true,
  });

  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? tertiaryColor;
  final Widget? child;
  final bool animate;

  @override
  State<AppAmbientBackground> createState() => _AppAmbientBackgroundState();
}

class _AppAmbientBackgroundState extends State<AppAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // Gently loop animation if enabled and not in widget test
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (widget.animate && !isTest) {
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primary = widget.primaryColor ?? theme.colorScheme.primary;
    final secondary = widget.secondaryColor ?? theme.colorScheme.secondary;
    final tertiary = widget.tertiaryColor ??
        (isDark ? const Color(0xFF7928CA) : const Color(0xFF6366F1));

    final baseScaffold = theme.scaffoldBackgroundColor;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base solid canvas
        Container(color: baseScaffold),

        // 2. Animated Aurora Chromatic Blobs
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final phase1 = math.sin(t * math.pi * 2);
            final phase2 = math.cos(t * math.pi * 2);

            return CustomPaint(
              painter: _AuroraMeshPainter(
                primary: primary,
                secondary: secondary,
                tertiary: tertiary,
                isDark: isDark,
                phase1: phase1,
                phase2: phase2,
              ),
              size: Size.infinite,
            );
          },
        ),

        // 3. Child content if supplied
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _AuroraMeshPainter extends CustomPainter {
  const _AuroraMeshPainter({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.isDark,
    required this.phase1,
    required this.phase2,
  });

  final Color primary;
  final Color secondary;
  final Color tertiary;
  final bool isDark;
  final double phase1;
  final double phase2;

  @override
  void paint(Canvas canvas, Size size) {
    // Blob 1: Top-Right Primary Accent Glow (drifting)
    final center1 = Offset(
      size.width * (0.80 + phase1 * 0.08),
      size.height * (0.15 + phase2 * 0.06),
    );
    final radius1 = size.width * 0.70;
    final paint1 = Paint()
      ..shader = RadialGradient(
        colors: [
          primary.withOpacity(isDark ? 0.35 : 0.22),
          primary.withOpacity(isDark ? 0.12 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center1, radius: radius1));
    canvas.drawCircle(center1, radius1, paint1);

    // Blob 2: Mid-Left Deep Indigo / Tertiary Orb
    final center2 = Offset(
      size.width * (0.15 - phase2 * 0.07),
      size.height * (0.45 + phase1 * 0.08),
    );
    final radius2 = size.width * 0.85;
    final paint2 = Paint()
      ..shader = RadialGradient(
        colors: [
          tertiary.withOpacity(isDark ? 0.30 : 0.18),
          tertiary.withOpacity(isDark ? 0.08 : 0.04),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center2, radius: radius2));
    canvas.drawCircle(center2, radius2, paint2);

    // Blob 3: Bottom-Right Secondary Cyan/Electric Glow (behind mini player)
    final center3 = Offset(
      size.width * (0.75 + phase2 * 0.06),
      size.height * (0.85 + phase1 * 0.05),
    );
    final radius3 = size.width * 0.75;
    final paint3 = Paint()
      ..shader = RadialGradient(
        colors: [
          secondary.withOpacity(isDark ? 0.28 : 0.16),
          secondary.withOpacity(isDark ? 0.06 : 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center3, radius: radius3));
    canvas.drawCircle(center3, radius3, paint3);

    // Blob 4: Top-Left Subtle Highlight
    final center4 = Offset(
      size.width * (0.20 + phase1 * 0.05),
      size.height * (0.08 - phase2 * 0.04),
    );
    final radius4 = size.width * 0.55;
    final paint4 = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? Colors.cyanAccent : Colors.lightBlueAccent)
              .withOpacity(isDark ? 0.18 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center4, radius: radius4));
    canvas.drawCircle(center4, radius4, paint4);
  }

  @override
  bool shouldRepaint(covariant _AuroraMeshPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.tertiary != tertiary ||
        oldDelegate.isDark != isDark ||
        oldDelegate.phase1 != phase1 ||
        oldDelegate.phase2 != phase2;
  }
}
