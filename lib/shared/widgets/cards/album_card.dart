import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../models/album.dart';

/// Layout orientation mode for [AlbumCard].
enum AlbumCardMode {
  /// Vertical layout tailored for grid collections (childAspectRatio: 0.72).
  grid,

  /// Horizontal list layout for album lists.
  list,
}

/// Next-generation frosted glass album card supporting vinyl depth,
/// diagonal specular sheen, tactile spring animations, and high contrast typography.
class AlbumCard extends StatefulWidget {
  const AlbumCard({
    super.key,
    required this.title,
    required this.artist,
    this.artworkUri,
    this.year,
    this.trackCount,
    this.mode = AlbumCardMode.grid,
    this.heroTag,
    this.onTap,
    this.onPlayTap,
    this.onLongPress,
    this.enableBlur = true,
    this.width,
    this.height,
  });

  /// Convenience factory constructing an [AlbumCard] from a domain [Album].
  factory AlbumCard.fromAlbum({
    Key? key,
    required Album album,
    AlbumCardMode mode = AlbumCardMode.grid,
    String? heroTag,
    VoidCallback? onTap,
    VoidCallback? onPlayTap,
    VoidCallback? onLongPress,
    bool enableBlur = true,
    double? width,
    double? height,
  }) {
    return AlbumCard(
      key: key,
      title: album.title,
      artist: album.artist,
      artworkUri: album.artworkUri,
      year: album.year,
      trackCount: album.trackCount,
      mode: mode,
      heroTag: heroTag,
      onTap: onTap,
      onPlayTap: onPlayTap,
      onLongPress: onLongPress,
      enableBlur: enableBlur,
      width: width,
      height: height,
    );
  }

  final String title;
  final String artist;
  final String? artworkUri;
  final int? year;
  final int? trackCount;
  final AlbumCardMode mode;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onPlayTap;
  final VoidCallback? onLongPress;
  final bool enableBlur;
  final double? width;
  final double? height;

  @override
  State<AlbumCard> createState() => _AlbumCardState();
}

class _AlbumCardState extends State<AlbumCard> {
  bool _isPressed = false;

  String get _resolvedSubtitle {
    if (widget.year != null) {
      return '${widget.artist} • ${widget.year}';
    }
    return widget.artist;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(GlassTokens.radiusCard);

    final resolvedBorderColor = GlassTokens.resolveBorderColor(context);

    // High-fidelity Vinyl & Artwork Sleeve
    Widget artworkPlaceholder = ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Rich multi-stop cover gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withOpacity(isDark ? 0.40 : 0.65),
                  secondary.withOpacity(isDark ? 0.25 : 0.45),
                  surface.withOpacity(isDark ? 0.35 : 0.80),
                ],
              ),
            ),
          ),

          // 2. Vinyl disc peeking out from sleeve
          Positioned(
            right: -16.0,
            top: 10.0,
            bottom: 10.0,
            width: 70.0,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark ? const Color(0xFF1E293B) : const Color(0xFF334155),
                    isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    isDark ? const Color(0xFF020617) : const Color(0xFF0F172A),
                  ],
                  stops: const [0.35, 0.70, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x40000000),
                    blurRadius: 8.0,
                    offset: Offset(-2, 0),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 22.0,
                  height: 22.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                  ),
                  child: Center(
                    child: Container(
                      width: 6.0,
                      height: 6.0,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 3. Center musical icon badge
          Center(
            child: Container(
              width: 52.0,
              height: 52.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surface.withOpacity(isDark ? 0.40 : 0.75),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.30 : 0.60),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 14.0,
                  ),
                ],
              ),
              child: Icon(
                Icons.album,
                size: widget.mode == AlbumCardMode.grid ? 32.0 : 24.0,
                color: primary,
              ),
            ),
          ),

          // 4. Diagonal jewel-case gloss sheen
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.22 : 0.50),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (widget.heroTag != null) {
      artworkPlaceholder = Hero(
        tag: widget.heroTag!,
        child: artworkPlaceholder,
      );
    }

    Widget content;

    if (widget.mode == AlbumCardMode.grid) {
      content = Container(
        width: widget.width ?? 180.0,
        height: widget.height,
        padding: const EdgeInsets.all(AppSpacing.xs),
        decoration: BoxDecoration(
          gradient: GlassTokens.glassSurfaceGradient(
            context,
            opacity: isDark ? 0.16 : 0.45,
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: resolvedBorderColor,
            width: GlassTokens.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.12),
              blurRadius: 16.0,
              offset: const Offset(0, 4),
            ),
            ...GlassTokens.elevationLow,
          ],
        ),
        child: Stack(
          children: [
            // Inner specular top reflection
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius,
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(isDark ? 0.30 : 0.60),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: artworkPlaceholder,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2.0),
                Text(
                  _resolvedSubtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.trackCount != null && widget.trackCount! > 0) ...[
                  const SizedBox(height: 4.0),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(6.0),
                      border: Border.all(
                        color: primary.withOpacity(0.30),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      widget.trackCount == 1 ? '1 Track' : '${widget.trackCount} Tracks',
                      style: AppTypography.labelSmall.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      );
    } else {
      // List Mode
      content = Container(
        width: widget.width,
        height: widget.height ?? 80.0,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          gradient: GlassTokens.glassSurfaceGradient(
            context,
            opacity: isDark ? 0.16 : 0.45,
          ),
          borderRadius: borderRadius,
          border: Border.all(
            color: resolvedBorderColor,
            width: GlassTokens.borderWidth,
          ),
          boxShadow: GlassTokens.elevationLow,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 56.0,
              height: 56.0,
              child: artworkPlaceholder,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    _resolvedSubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (widget.onPlayTap != null) ...[
              IconButton(
                icon: Icon(
                  Icons.play_circle_filled_rounded,
                  color: primary,
                  size: 32.0,
                ),
                onPressed: widget.onPlayTap,
              ),
            ],
          ],
        ),
      );
    }

    if (widget.enableBlur) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.blurSubtle,
            sigmaY: GlassTokens.blurSubtle,
          ),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: content,
      );
    }

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: 'Album ${widget.title} by ${widget.artist}',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                borderRadius: borderRadius,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
