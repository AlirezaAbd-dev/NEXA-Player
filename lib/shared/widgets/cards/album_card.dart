import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../models/album.dart';

/// Layout orientation mode for [AlbumCard].
enum AlbumCardMode {
  /// Vertical layout tailored for grid collections (childAspectRatio: 0.8).
  grid,

  /// Horizontal list layout for album lists.
  list,
}

/// Reusable album card supporting both grid and list view modes with glass details
/// overlay, year and track count badges, and hero tag support.
class AlbumCard extends StatelessWidget {
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

  String get _resolvedSubtitle {
    if (year != null) {
      return '$artist • $year';
    }
    return artist;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(GlassTokens.radiusCard);

    Widget artworkPlaceholder = Container(
      decoration: BoxDecoration(
        color: primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Center(
        child: Icon(
          Icons.album,
          size: mode == AlbumCardMode.grid ? 48.0 : 32.0,
          color: primary,
        ),
      ),
    );

    if (heroTag != null) {
      artworkPlaceholder = Hero(
        tag: heroTag!,
        child: artworkPlaceholder,
      );
    }

    Widget content;

    if (mode == AlbumCardMode.grid) {
      content = Container(
        width: width ?? 180.0,
        height: height,
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: surface.withOpacity(isDark ? 0.14 : 0.08),
            borderRadius: borderRadius,
            border: Border.all(
              color: isDark ? GlassTokens.borderColorLight : GlassTokens.borderColorDark,
              width: GlassTokens.borderWidth,
            ),
            boxShadow: GlassTokens.elevationLow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: artworkPlaceholder,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title,
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
              if (trackCount != null && trackCount! > 0) ...[
                const SizedBox(height: 4.0),
                Text(
                  trackCount == 1 ? '1 Track' : '$trackCount Tracks',
                  style: AppTypography.labelSmall.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
    } else {
      // List Mode
      content = Container(
        width: width,
        height: height ?? 80.0,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: surface.withOpacity(isDark ? 0.14 : 0.08),
          borderRadius: borderRadius,
          border: Border.all(
            color: isDark ? GlassTokens.borderColorLight : GlassTokens.borderColorDark,
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
                    title,
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
            if (onPlayTap != null) ...[
              IconButton(
                icon: Icon(Icons.play_circle_filled_rounded, color: primary, size: 32.0),
                onPressed: onPlayTap,
              ),
            ],
          ],
        ),
      );
    }

    if (enableBlur) {
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
        label: 'Album $title by $artist',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: borderRadius,
            child: content,
          ),
        ),
      ),
    );
  }
}
