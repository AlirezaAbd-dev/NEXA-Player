import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Layout orientation mode for [AlbumCard].
enum AlbumCardMode {
  /// Vertical layout tailored for grid collections (childAspectRatio <= 0.75).
  grid,

  /// Horizontal list layout for album lists.
  list,
}

/// Borderless album card with authentic 1:1 artwork sleeve,
/// rich vinyl disc detailing, tactile spring feedback, and crisp typography.
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
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    final cardRadius = BorderRadius.circular(16.0);
    final artworkRadius = BorderRadius.circular(16.0);

    // Deterministic palette generation for procedural sleeve
    final hash = (widget.title.hashCode ^ widget.artist.hashCode).abs();
    final hue = (hash % 360).toDouble();
    final sleeveBgStart = HSLColor.fromAHSL(1.0, hue, 0.35, isDark ? 0.18 : 0.92).toColor();
    final sleeveBgEnd = HSLColor.fromAHSL(1.0, (hue + 40) % 360, 0.45, isDark ? 0.08 : 0.82).toColor();
    final sleeveAccent = HSLColor.fromAHSL(1.0, hue, 0.70, isDark ? 0.65 : 0.45).toColor();

    // 1:1 Album Artwork Sleeve with rich generative detailing
    Widget artworkPlaceholder = ClipRRect(
      borderRadius: artworkRadius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: artworkRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              sleeveBgStart,
              sleeveBgEnd,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
              blurRadius: 12.0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Vinyl grooves rings
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0x20FFFFFF) : const Color(0x15000000),
                  width: 1.0,
                ),
              ),
              margin: const EdgeInsets.all(12.0),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? const Color(0x18FFFFFF) : const Color(0x10000000),
                  width: 1.0,
                ),
              ),
              margin: const EdgeInsets.all(22.0),
            ),

            // Center album badge with sleeve accent
            Container(
              width: widget.mode == AlbumCardMode.grid ? 46.0 : 36.0,
              height: widget.mode == AlbumCardMode.grid ? 46.0 : 36.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surface.withOpacity(isDark ? 0.85 : 0.95),
                boxShadow: [
                  BoxShadow(
                    color: sleeveAccent.withOpacity(0.35),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Icon(
                Icons.album,
                size: widget.mode == AlbumCardMode.grid ? 28.0 : 22.0,
                color: sleeveAccent,
              ),
            ),
          ],
        ),
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
      // Borderless L0 Canvas Grid Item: Artwork sleeve sits cleanly on canvas
      content = SizedBox(
        width: widget.width,
        height: widget.height,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: artworkPlaceholder,
            ),
            const SizedBox(height: 10.0),
            Text(
              widget.title,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: onSurface,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3.0),
            Text(
              widget.artist,
              style: AppTypography.bodySmall.copyWith(
                color: onSurfaceVariant,
                fontSize: 12.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.trackCount != null && widget.trackCount! > 0) ...[
              const SizedBox(height: 4.0),
              Text(
                '${widget.year != null ? '${widget.year} • ' : ''}${widget.trackCount == 1 ? '1 track' : '${widget.trackCount} tracks'} • FLAC',
                style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                  color: onSurfaceVariant.withOpacity(0.65),
                  fontWeight: FontWeight.w500,
                  fontSize: 10.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      );
    } else {
      // Borderless L1 Surface List Item
      content = NexaSurface(
        level: NexaSurfaceLevel.l1,
        borderRadius: cardRadius,
        child: SizedBox(
          width: widget.width,
          height: widget.height ?? 80.0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 56.0,
                  height: 56.0,
                  child: artworkPlaceholder,
                ),
                const SizedBox(width: AppSpacing.md),
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
                if (widget.trackCount != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 3.0,
                    ),
                    decoration: BoxDecoration(
                      color: surfaceTokens.level2,
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      '${widget.trackCount} tracks',
                      style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (widget.onPlayTap != null) ...[
                  const SizedBox(width: AppSpacing.xs),
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
          ),
        ),
      );
    }

    if (widget.enableBlur && widget.mode == AlbumCardMode.list) {
      content = ClipRRect(
        borderRadius: cardRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: GlassTokens.blurSubtle,
            sigmaY: GlassTokens.blurSubtle,
          ),
          child: content,
        ),
      );
    }

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${widget.title} by ${widget.artist}',
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                borderRadius: cardRadius,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
