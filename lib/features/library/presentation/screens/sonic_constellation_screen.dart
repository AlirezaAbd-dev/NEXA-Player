import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../domain/models/sonic_star_node.dart';
import '../../domain/services/sonic_constellation_analyzer.dart';

/// Semantic Keys for SonicConstellationScreen testing.
abstract final class SonicConstellationKeys {
  static const Key root = ValueKey('sonic_constellation_screen');
  static const Key lassoToggleButton = ValueKey('constellation_lasso_toggle');
  static const Key playSelectedButton = ValueKey('constellation_play_selected');
}

/// Borderless 2D celestial mood & tempo star map.
/// Tracks are plotted by tempo (X-axis) and acoustic energy (Y-axis).
/// Includes freehand lasso tool for creating instant spatial playlists.
class SonicConstellationScreen extends ConsumerStatefulWidget {
  const SonicConstellationScreen({super.key});

  @override
  ConsumerState<SonicConstellationScreen> createState() =>
      _SonicConstellationScreenState();
}

class _SonicConstellationScreenState
    extends ConsumerState<SonicConstellationScreen> {
  static const _analyzer = SonicConstellationAnalyzer();
  late List<SonicStarNode> _stars;

  SonicStarNode? _selectedStar;
  bool _isLassoMode = false;
  final List<Offset> _lassoPoints = [];
  List<SonicStarNode> _enclosedStars = [];

  @override
  void initState() {
    super.initState();
    _stars = _analyzer.generateSampleConstellation();
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isLassoMode) return;
    setState(() {
      _lassoPoints.clear();
      _lassoPoints.add(details.localPosition);
      _enclosedStars.clear();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isLassoMode) return;
    setState(() {
      _lassoPoints.add(details.localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details, Size size) {
    if (!_isLassoMode || _lassoPoints.length < 3) return;

    // Convert pixel lasso points to normalized [-1.0, 1.0] coordinates
    final normPolygon = _lassoPoints.map((p) {
      final nx = ((p.dx / size.width) * 2.0 - 1.0).clamp(-1.0, 1.0);
      final ny = (1.0 - (p.dy / size.height * 2.0)).clamp(-1.0, 1.0);
      return Offset(nx, ny);
    }).toList();

    final matched = _analyzer.filterStarsInLasso(_stars, normPolygon);
    HapticFeedback.mediumImpact();
    setState(() {
      _enclosedStars = matched;
    });
  }

  void _playStar(SonicStarNode star) {
    final track = Track(
      id: star.trackId,
      title: star.title,
      artist: star.artist,
      duration: const Duration(minutes: 3, seconds: 30),
    );
    ref.read(playerNotifierProvider.notifier).playTrack(track);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final surfaceTokens = theme.extension<NexaSurfaceTokens>();

    final telemetryStyle = surfaceTokens?.telemetryTextStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontFeatures: [FontFeature.tabularFigures()],
        );

    return Scaffold(
      key: SonicConstellationKeys.root,
      backgroundColor: const Color(0xFF070A10),
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Sonic Constellation',
        actions: [
          IconButton(
            key: SonicConstellationKeys.lassoToggleButton,
            icon: Icon(
              _isLassoMode ? Icons.gesture_rounded : Icons.gesture_outlined,
              color: _isLassoMode ? primary : colorScheme.onSurface.withOpacity(0.6),
            ),
            tooltip: _isLassoMode ? 'Exit Lasso Mode' : 'Draw Lasso Loop',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() {
                _isLassoMode = !_isLassoMode;
                _lassoPoints.clear();
                _enclosedStars.clear();
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);

          return Stack(
            children: [
              // Celestial Star Canvas
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: (d) => _onPanEnd(d, size),
                onTapUp: (details) {
                  if (_isLassoMode) return;
                  // Hit-test stars
                  for (final star in _stars) {
                    final sx = size.width * 0.5 + (star.x * size.width * 0.42);
                    final sy = size.height * 0.5 - (star.y * size.height * 0.38);
                    final dist = (details.localPosition - Offset(sx, sy)).distance;
                    if (dist < 28.0) {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedStar = star;
                      });
                      return;
                    }
                  }
                  setState(() => _selectedStar = null);
                },
                child: CustomPaint(
                  size: size,
                  painter: _ConstellationPainter(
                    stars: _stars,
                    selectedStar: _selectedStar,
                    lassoPoints: _lassoPoints,
                    isLassoMode: _isLassoMode,
                    primaryColor: primary,
                  ),
                ),
              ),

              // Bottom Sheet: Selected Star Peek or Enclosed Lasso Stars
              if (_selectedStar != null && !_isLassoMode)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 30,
                  child: NexaSurface(
                    tier: NexaSurfaceTier.l2,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Color(_selectedStar!.colorValue).withOpacity(0.24),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.star_rounded,
                            color: Color(_selectedStar!.colorValue),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedStar!.title,
                                style: AppTypography.titleSmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_selectedStar!.artist} • ${_selectedStar!.bpm.round()} BPM',
                                style: telemetryStyle.copyWith(
                                  fontSize: 11,
                                  color: colorScheme.onSurface.withOpacity(0.65),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          key: SonicConstellationKeys.playSelectedButton,
                          icon: Icon(
                            Icons.play_circle_fill_rounded,
                            color: primary,
                            size: 36,
                          ),
                          onPressed: () => _playStar(_selectedStar!),
                        ),
                      ],
                    ),
                  ),
                ),

              // Lasso Selection Result Pill
              if (_enclosedStars.isNotEmpty)
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  child: NexaSurface(
                    tier: NexaSurfaceTier.l3,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
                    child: Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Enclosed ${_enclosedStars.length} Stars in Constellation',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Created constellation playlist with ${_enclosedStars.length} tracks',
                                ),
                              ),
                            );
                            setState(() {
                              _lassoPoints.clear();
                              _enclosedStars.clear();
                              _isLassoMode = false;
                            });
                          },
                          child: Text(
                            'Play All',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<SonicStarNode> stars;
  final SonicStarNode? selectedStar;
  final List<Offset> lassoPoints;
  final bool isLassoMode;
  final Color primaryColor;

  _ConstellationPainter({
    required this.stars,
    required this.selectedStar,
    required this.lassoPoints,
    required this.isLassoMode,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Subtle Celestial Coordinate Grid Axes
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    // Center X & Y axes
    canvas.drawLine(
      Offset(size.width * 0.5, 60),
      Offset(size.width * 0.5, size.height - 40),
      gridPaint,
    );
    canvas.drawLine(
      Offset(20, size.height * 0.5),
      Offset(size.width - 20, size.height * 0.5),
      gridPaint,
    );

    // 2. Plot Stars
    for (final star in stars) {
      final sx = size.width * 0.5 + (star.x * size.width * 0.42);
      final sy = size.height * 0.5 - (star.y * size.height * 0.38);
      final offset = Offset(sx, sy);
      final starColor = Color(star.colorValue);
      final isSelected = selectedStar?.trackId == star.trackId;

      // Glow halo
      final glowPaint = Paint()
        ..color = starColor.withOpacity(isSelected ? 0.60 : 0.28)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 16.0 : 8.0);
      canvas.drawCircle(offset, isSelected ? 18.0 : 10.0, glowPaint);

      // Star core
      final corePaint = Paint()..color = isSelected ? Colors.white : starColor;
      canvas.drawCircle(offset, isSelected ? 6.5 : 4.5, corePaint);
    }

    // 3. User Freehand Lasso Loop
    if (lassoPoints.length > 1) {
      final path = Path()..moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (int i = 1; i < lassoPoints.length; i++) {
        path.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
      }

      final strokePaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      final fillPaint = Paint()
        ..color = primaryColor.withOpacity(0.12)
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter oldDelegate) {
    return oldDelegate.selectedStar != selectedStar ||
        oldDelegate.lassoPoints.length != lassoPoints.length ||
        oldDelegate.isLassoMode != isLassoMode;
  }
}
