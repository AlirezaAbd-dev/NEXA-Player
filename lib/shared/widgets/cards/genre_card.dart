import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../models/genre.dart';

/// Reusable genre card with dynamic color gradient, subtle musical watermark,
/// genre title, track count badge, and frosted glass border.
class GenreCard extends StatelessWidget {
  const GenreCard({
    super.key,
    required this.title,
    this.trackCount = 0,
    this.gradientColors,
    this.icon = Icons.music_note_rounded,
    this.heroTag,
    this.onTap,
    this.enableBlur = true,
    this.height = 110.0,
  });

  /// Convenience factory constructing a [GenreCard] from a domain [Genre].
  factory GenreCard.fromGenre({
    Key? key,
    required Genre genre,
    IconData icon = Icons.music_note_rounded,
    String? heroTag,
    VoidCallback? onTap,
    bool enableBlur = true,
    double height = 110.0,
  }) {
    return GenreCard(
      key: key,
      title: genre.name,
      trackCount: genre.trackCount,
      gradientColors: genre.gradientColors,
      icon: icon,
      heroTag: heroTag,
      onTap: onTap,
      enableBlur: enableBlur,
      height: height,
    );
  }

  final String title;
  final int trackCount;
  final List<Color>? gradientColors;
  final IconData icon;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool enableBlur;
  final double height;

  LinearGradient _resolveGradient() {
    if (gradientColors != null && gradientColors!.length >= 2) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors!,
      );
    }

    const curatedGradients = <List<Color>>[
      [Color(0xFF00E5FF), Color(0xFF651FFF)], // Cyan to Electric Violet
      [Color(0xFFFF3D00), Color(0xFFFF9100)], // Lava to Orange
      [Color(0xFF00E676), Color(0xFF00B0FF)], // Emerald to Azure
      [Color(0xFFE040FB), Color(0xFF7C4DFF)], // Magenta to Violet
      [Color(0xFF2979FF), Color(0xFF00E5FF)], // Royal Blue to Cyan
      [Color(0xFFFF1744), Color(0xFFF50057)], // Ruby to Hot Pink
      [Color(0xFFFFAB00), Color(0xFFFF3D00)], // Amber to Fire
    ];

    final index = (title.hashCode.abs()) % curatedGradients.length;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: curatedGradients[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(GlassTokens.radiusCard);
    final gradient = _resolveGradient();

    Widget cardBody = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: GlassTokens.borderColorLight,
          width: GlassTokens.borderWidth,
        ),
        boxShadow: GlassTokens.elevationLow,
      ),
      child: Stack(
        children: [
          // Subtle musical watermark graphic in background
          Positioned(
            right: -8.0,
            bottom: -8.0,
            child: Transform.rotate(
              angle: -0.25,
              child: Icon(
                icon,
                size: 72.0,
                color: Colors.white.withOpacity(0.18),
              ),
            ),
          ),
          // Content overlay with frosted glass tint
          Positioned.fill(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.15),
                borderRadius: borderRadius,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 8.0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.0,
                      ),
                    ),
                    child: Text(
                      trackCount == 1 ? '1 Track' : '$trackCount Tracks',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (enableBlur) {
      cardBody = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.blurSubtle,
            sigmaY: GlassTokens.blurSubtle,
          ),
          child: cardBody,
        ),
      );
    } else {
      cardBody = ClipRRect(
        borderRadius: borderRadius,
        child: cardBody,
      );
    }

    if (heroTag != null) {
      cardBody = Hero(
        tag: heroTag!,
        child: cardBody,
      );
    }

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: 'Genre $title, $trackCount tracks',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: cardBody,
          ),
        ),
      ),
    );
  }
}
