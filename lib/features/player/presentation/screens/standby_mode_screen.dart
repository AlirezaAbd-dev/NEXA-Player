import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/theme/dynamic_palette_providers.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/cards/nexa_artwork_image.dart';
import '../../../visualizer/visualizer.dart';
import '../providers/player_providers.dart';

/// Ambient Standby / Bedside Turntable screen for overnight and desk docking.
///
/// Features:
/// - True AMOLED #000000 backdrop for zero panel glow and maximum power efficiency.
/// - Adaptive Landscape (nightstand dock) & Portrait layouts.
/// - Giant spinning analog turntable with swinging tonearm.
/// - Ambient glowing digital clock with anti-burn-in micro-drift.
/// - Auto-dimming HUD (dims controls after 5 seconds of touch inactivity).
/// - Integrated real-time audio spectrum visualizer.
class StandbyModeScreen extends ConsumerStatefulWidget {
  const StandbyModeScreen({super.key, this.onExit});

  final VoidCallback? onExit;

  @override
  ConsumerState<StandbyModeScreen> createState() => _StandbyModeScreenState();
}

class _StandbyModeScreenState extends ConsumerState<StandbyModeScreen>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _tonearmController;
  late final AnimationController _driftController;

  Timer? _clockTimer;
  Timer? _hudHideTimer;
  DateTime _currentTime = DateTime.now();
  bool _hudVisible = true;
  double _dimFactor = 1.0; // 1.0 = standard, 0.5 = bedside dim, 0.25 = ultra-dim

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _tonearmController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Anti-burn-in micro-drift oscillation (subtle 3px wander over 60 seconds)
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat(reverse: true);

    // Time ticker for digital bedside clock
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });

    _resetHudTimer();

    // Start rotation if already playing and animations are not disabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnim = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      final isPlaying = ref.read(isPlayingProvider);
      if (isPlaying && !disableAnim) {
        _spinController.repeat();
        _tonearmController.forward();
      }
    });
  }

  void _resetHudTimer() {
    _hudHideTimer?.cancel();
    if (!_hudVisible) {
      setState(() => _hudVisible = true);
    }
    _hudHideTimer = Timer(const Duration(seconds: 6), () {
      if (mounted && _hudVisible) {
        setState(() => _hudVisible = false);
      }
    });
  }

  void _cycleDimLevel() {
    HapticFeedback.selectionClick();
    setState(() {
      if (_dimFactor >= 0.9) {
        _dimFactor = 0.50; // Bedside dim
      } else if (_dimFactor >= 0.45) {
        _dimFactor = 0.25; // Ultra dim / stealth
      } else {
        _dimFactor = 1.0; // Full brightness
      }
    });
    _resetHudTimer();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _hudHideTimer?.cancel();
    _spinController.dispose();
    _tonearmController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  String _formatTwoDigits(int n) => n.toString().padLeft(2, '0');

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = ref.watch(isPlayingProvider);
    final playerState = ref.watch(playerNotifierProvider);
    final currentTrack = playerState.currentTrack;

    // React to play/pause transitions
    if (isPlaying && !_spinController.isAnimating) {
      _spinController.repeat();
      _tonearmController.forward();
    } else if (!isPlaying && _spinController.isAnimating) {
      _spinController.stop();
      _tonearmController.reverse();
    }

    // Dynamic Palette vs Theme
    final isDynamicEnabled = ref.watch(dynamicThemeEnabledProvider);
    final dynamicPalette = ref.watch(activeDynamicPaletteProvider);
    final baseAccent = isDynamicEnabled
        ? dynamicPalette.primary
        : Theme.of(context).colorScheme.primary;

    // Apply Dimming
    final accentColor = baseAccent.withOpacity(
        (baseAccent.opacity * _dimFactor).clamp(0.2, 1.0));

    final totalMs = playerState.duration.inMilliseconds > 0
        ? playerState.duration.inMilliseconds
        : 1;
    final progress =
        (playerState.position.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black, // Pure AMOLED Black
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _resetHudTimer,
        onDoubleTap: () {
          HapticFeedback.lightImpact();
          final notifier = ref.read(playerNotifierProvider.notifier);
          if (isPlaying) {
            notifier.pause();
          } else {
            notifier.play();
          }
          _resetHudTimer();
        },
        child: AnimatedBuilder(
          animation: _driftController,
          builder: (context, child) {
            // Anti-burn-in micro-drift: Wander by -2.5 to +2.5 pixels
            final driftX = math.sin(_driftController.value * 2 * math.pi) * 2.5;
            final driftY = math.cos(_driftController.value * 2 * math.pi) * 2.0;

            return Transform.translate(
              offset: Offset(driftX, driftY),
              child: child,
            );
          },
          child: OrientationBuilder(
            builder: (context, orientation) {
              final isLandscape = orientation == Orientation.landscape;

              return Stack(
                children: [
                  // 1. Main Interactive Layout
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12.0,
                      ),
                      child: isLandscape
                          ? _buildLandscapeLayout(
                              track: currentTrack,
                              isPlaying: isPlaying,
                              position: playerState.position,
                              duration: playerState.duration,
                              progress: progress,
                              accentColor: accentColor,
                            )
                          : _buildPortraitLayout(
                              track: currentTrack,
                              isPlaying: isPlaying,
                              position: playerState.position,
                              duration: playerState.duration,
                              progress: progress,
                              accentColor: accentColor,
                            ),
                    ),
                  ),

                  // 2. Floating Auto-Dimming Header HUD Controls
                  AnimatedOpacity(
                    opacity: _hudVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.close_fullscreen_rounded,
                                color: Colors.white70,
                                size: 24,
                              ),
                              tooltip: 'Exit Standby Mode',
                              onPressed: () {
                                if (widget.onExit != null) {
                                  widget.onExit!();
                                } else if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  context.pop();
                                }
                              },
                            ),
                            Row(
                              children: [
                                // Dimming Level Button
                                IconButton(
                                  icon: Icon(
                                    _dimFactor <= 0.3
                                        ? Icons.brightness_3_rounded
                                        : _dimFactor <= 0.6
                                            ? Icons.brightness_medium_rounded
                                            : Icons.brightness_high_rounded,
                                    color: accentColor,
                                    size: 22,
                                  ),
                                  tooltip: 'Cycle Dim Level',
                                  onPressed: _cycleDimLevel,
                                ),
                                const SizedBox(width: 4),
                                // Fullscreen Lock Indicator
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'STANDBY',
                                    style: AppTypography.bodySmall.copyWith(
                                      fontSize: 10,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
  }

  Widget _buildDigitalClock(Color accentColor) {
    final hours = _formatTwoDigits(_currentTime.hour);
    final minutes = _formatTwoDigits(_currentTime.minute);
    final seconds = _formatTwoDigits(_currentTime.second);

    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final weekday = weekdayNames[_currentTime.weekday - 1];
    final month = monthNames[_currentTime.month - 1];
    final dateStr = '$weekday, $month ${_currentTime.day}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$hours:$minutes',
                style: TextStyle(
                  fontSize: 68,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 2.0,
                  color: Colors.white.withOpacity(0.95 * _dimFactor),
                  shadows: [
                    Shadow(
                      color: accentColor.withOpacity(0.35 * _dimFactor),
                      blurRadius: 24.0,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                seconds,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: accentColor.withOpacity(0.85 * _dimFactor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          dateStr.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.0,
            color: Colors.white.withOpacity(0.50 * _dimFactor),
          ),
        ),
      ],
    );
  }

  Widget _buildTurntable({
    required double size,
    required Color accentColor,
    Track? currentTrack,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Turntable Outer Platter Rim
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0A0D14),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.20 * _dimFactor),
                  blurRadius: 32.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
          ),

          // Spinning Vinyl Disc
          AnimatedBuilder(
            animation: _spinController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _spinController.value * 2 * math.pi,
                child: child,
              );
            },
            child: Container(
              width: size * 0.92,
              height: size * 0.92,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Color(0xFF141822),
                    Color(0xFF07090E),
                    Color(0xFF161B26),
                    Color(0xFF090C12),
                  ],
                  stops: [0.15, 0.45, 0.75, 1.0],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Vinyl Micro-grooves (subtle tonal rings without raw borders)
                  for (final fraction in [0.78, 0.64, 0.50, 0.36])
                    Container(
                      width: size * 0.92 * fraction,
                      height: size * 0.92 * fraction,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF273147).withOpacity(0.06 * _dimFactor),
                      ),
                    ),

                  // Center Vinyl Label with Track Cover Art
                  Container(
                    width: size * 0.38,
                    height: size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.40 * _dimFactor),
                          blurRadius: 14.0,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: _dimFactor.clamp(0.25, 1.0),
                            child: NexaArtworkImage(
                              track: currentTrack,
                              artworkUri: currentTrack?.artworkUri,
                              width: size * 0.38,
                              height: size * 0.38,
                              cacheWidth: 320,
                              fallbackBuilder: (_) => Container(
                                color: accentColor,
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              width: size * 0.08,
                              height: size * 0.08,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Analog Tonearm (Pivots smoothly toward the record when playing)
          Positioned(
            top: 4,
            right: 4,
            child: AnimatedBuilder(
              animation: _tonearmController,
              builder: (context, child) {
                final angle = math.sin(_tonearmController.value * math.pi / 2) * 0.28;
                return Transform.rotate(
                  angle: angle,
                  alignment: Alignment.topRight,
                  child: child,
                );
              },
              child: SizedBox(
                width: size * 0.35,
                height: size * 0.65,
                child: CustomPaint(
                  painter: _TonearmPainter(
                    armColor: const Color(0xFF90A4AE).withOpacity(_dimFactor),
                    headColor: accentColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout({
    required dynamic track,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required double progress,
    required Color accentColor,
  }) {
    final title = track?.title ?? 'No Track Playing';
    final artist = track?.artist ?? 'Select music to play';

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(height: 36),

        // 1. Digital Nightstand Clock
        _buildDigitalClock(accentColor),

        // 2. Spinning Vinyl Turntable
        _buildTurntable(
          size: 230,
          accentColor: accentColor,
          currentTrack: track as Track?,
        ),

        // 3. Track Details & Scrubber
        Column(
          children: [
            Text(
              title,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white.withOpacity(0.95 * _dimFactor),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 3),
            Text(
              artist,
              style: AppTypography.bodyMedium.copyWith(
                fontSize: 13,
                color: Colors.white.withOpacity(0.60 * _dimFactor),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtle Seek Line
            SizedBox(
              width: 240,
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3.0,
                      backgroundColor: Colors.white.withOpacity(0.08),
                      valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(position),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.40 * _dimFactor),
                        ),
                      ),
                      Text(
                        _formatDuration(duration),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.40 * _dimFactor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        // 4. Mini Ambient Spectrum Visualizer
        SizedBox(
          height: 36,
          width: 220,
          child: SpectrumVisualizerWidget(
            height: 36,
            accentColor: accentColor,
          ),
        ),

        // 5. Minimal Playback HUD Controls
        AnimatedOpacity(
          opacity: _hudVisible ? 1.0 : 0.25,
          duration: const Duration(milliseconds: 300),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 32,
                color: Colors.white.withOpacity(0.85 * _dimFactor),
                onPressed: () {
                  ref.read(playerNotifierProvider.notifier).skipPrevious();
                  _resetHudTimer();
                },
              ),
              const SizedBox(width: 16),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.45 * _dimFactor),
                      blurRadius: 16.0,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: () {
                    final notifier = ref.read(playerNotifierProvider.notifier);
                    if (isPlaying) {
                      notifier.pause();
                    } else {
                      notifier.play();
                    }
                    _resetHudTimer();
                  },
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 32,
                color: Colors.white.withOpacity(0.85 * _dimFactor),
                onPressed: () {
                  ref.read(playerNotifierProvider.notifier).skipNext();
                  _resetHudTimer();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout({
    required dynamic track,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required double progress,
    required Color accentColor,
  }) {
    final title = track?.title ?? 'No Track Playing';
    final artist = track?.artist ?? 'Select music to play';

    return Row(
      children: [
        // Left Column: Nightstand Clock & Ambient Visualizer
        Expanded(
          flex: 5,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDigitalClock(accentColor),
              const SizedBox(height: 24),
              SizedBox(
                height: 48,
                width: 240,
                child: SpectrumVisualizerWidget(
                  height: 48,
                  accentColor: accentColor,
                ),
              ),
            ],
          ),
        ),

        // Right Column: Spinning Turntable, Track Info & Playback Controls
        Expanded(
          flex: 6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTurntable(
                size: 190,
                accentColor: accentColor,
                currentTrack: track as Track?,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.95 * _dimFactor),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                artist,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.60 * _dimFactor),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Scrubber
              SizedBox(
                width: 260,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3.0,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.40 * _dimFactor),
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.40 * _dimFactor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    iconSize: 26,
                    color: Colors.white.withOpacity(0.85 * _dimFactor),
                    onPressed: () {
                      ref.read(playerNotifierProvider.notifier).skipPrevious();
                      _resetHudTimer();
                    },
                  ),
                  const SizedBox(width: 14),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentColor,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.40 * _dimFactor),
                          blurRadius: 12.0,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.black,
                        size: 24,
                      ),
                      onPressed: () {
                        final notifier = ref.read(playerNotifierProvider.notifier);
                        if (isPlaying) {
                          notifier.pause();
                        } else {
                          notifier.play();
                        }
                        _resetHudTimer();
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    iconSize: 26,
                    color: Colors.white.withOpacity(0.85 * _dimFactor),
                    onPressed: () {
                      ref.read(playerNotifierProvider.notifier).skipNext();
                      _resetHudTimer();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for the analog turntable tonearm and cartridge.
class _TonearmPainter extends CustomPainter {
  const _TonearmPainter({
    required this.armColor,
    required this.headColor,
  });

  final Color armColor;
  final Color headColor;

  @override
  void paint(Canvas canvas, Size size) {
    final armPaint = Paint()
      ..color = armColor
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final basePaint = Paint()
      ..color = const Color(0xFF37474F)
      ..style = PaintingStyle.fill;

    final headPaint = Paint()
      ..color = headColor
      ..style = PaintingStyle.fill;

    // Tonearm base pivot
    final pivot = Offset(size.width - 12, 12);
    canvas.drawCircle(pivot, 9, basePaint);

    // Arm Path
    final path = Path()
      ..moveTo(pivot.dx, pivot.dy)
      ..lineTo(pivot.dx - 18, size.height * 0.55)
      ..lineTo(size.width * 0.20, size.height - 18);

    canvas.drawPath(path, armPaint);

    // Cartridge / Headshell
    final headRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.20 - 4, size.height - 14),
        width: 14,
        height: 10,
      ),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(headRect, headPaint);
  }

  @override
  bool shouldRepaint(covariant _TonearmPainter oldDelegate) {
    return oldDelegate.armColor != armColor || oldDelegate.headColor != headColor;
  }
}
