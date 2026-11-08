import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../models/album.dart';

/// Layout orientation mode for [AlbumCard].
enum AlbumCardMode {
  /// Vertical layout tailored for grid collections (childAspectRatio <= 0.65).
  grid,

  /// Horizontal list layout for album lists.
  list,
}

/// Modern album card with authentic 1:1 artwork sleeve,
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
    final cardRadius = BorderRadius.circular(16.0);
    final artworkRadius = BorderRadius.circular(12.0);

    final resolvedBorderColor = isDark
        ? const Color(0x18FFFFFF)
        : const Color(0x0F000000);

    // 1:1 Album Artwork Sleeve
    Widget artworkPlaceholder = ClipRRect(
      borderRadius: artworkRadius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: artworkRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(isDark ? 0.35 : 0.25),
              isDark ? const Color(0xFF1E2433) : const Color(0xFFE2E8F0),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x25000000),
              blurRadius: 10.0,
              offset: Offset(0, 4),
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

            // Center album badge
            Container(
              width: widget.mode == AlbumCardMode.grid ? 46.0 : 36.0,
              height: widget.mode == AlbumCardMode.grid ? 46.0 : 36.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: surface.withOpacity(isDark ? 0.85 : 0.95),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              child: Icon(
                Icons.album,
                size: widget.mode == AlbumCardMode.grid ? 28.0 : 22.0,
                color: primary,
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
      content = Container(
        width: widget.width ?? 180.0,
        height: widget.height,
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141923).withOpacity(0.65) : surface.withOpacity(0.75),
          borderRadius: cardRadius,
          border: Border.all(
            color: resolvedBorderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x35000000) : const Color(0x10000000),
              blurRadius: 12.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1.0,
              child: artworkPlaceholder,
            ),
            const SizedBox(height: 8.0),
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
              const SizedBox(height: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: primary.withOpacity(isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(6.0),
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
      );
    } else {
      // List Mode
      content = Container(
        width: widget.width,
        height: widget.height ?? 80.0,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141923).withOpacity(0.65) : surface.withOpacity(0.75),
          borderRadius: cardRadius,
          border: Border.all(
            color: resolvedBorderColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x35000000) : const Color(0x10000000),
              blurRadius: 10.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
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
                  color: primary.withOpacity(isDark ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  '${widget.trackCount} tracks',
                  style: AppTypography.labelSmall.copyWith(
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
      );
    }

    if (widget.enableBlur) {
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
    } else {
      content = ClipRRect(
        borderRadius: cardRadius,
        child: content,
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
