import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../models/artist.dart';

/// Layout orientation mode for [ArtistCard].
enum ArtistCardMode {
  /// Horizontal list tile (standard).
  list,

  /// Centered vertical grid card.
  grid,
}

/// Reusable artist card with circular/rounded artwork avatar, artist name,
/// track/album count subtitle, and hero tag support.
class ArtistCard extends StatelessWidget {
  const ArtistCard({
    super.key,
    required this.name,
    this.artworkUri,
    this.trackCount = 0,
    this.albumCount = 0,
    this.mode = ArtistCardMode.list,
    this.heroTag,
    this.onTap,
    this.enableBlur = true,
    this.avatarRadius = 24.0,
  });

  /// Convenience factory constructing an [ArtistCard] from a domain [Artist].
  factory ArtistCard.fromArtist({
    Key? key,
    required Artist artist,
    ArtistCardMode mode = ArtistCardMode.list,
    String? heroTag,
    VoidCallback? onTap,
    bool enableBlur = true,
    double avatarRadius = 24.0,
  }) {
    return ArtistCard(
      key: key,
      name: artist.name,
      artworkUri: artist.artworkUri,
      trackCount: artist.trackCount,
      albumCount: artist.albumCount,
      mode: mode,
      heroTag: heroTag,
      onTap: onTap,
      enableBlur: enableBlur,
      avatarRadius: avatarRadius,
    );
  }

  final String name;
  final String? artworkUri;
  final int trackCount;
  final int albumCount;
  final ArtistCardMode mode;
  final String? heroTag;
  final VoidCallback? onTap;
  final bool enableBlur;
  final double avatarRadius;

  String get _subtitle {
    final tLabel = trackCount == 1 ? '1 Track' : '$trackCount Tracks';
    final aLabel = albumCount == 1 ? '1 Album' : '$albumCount Albums';
    return '$tLabel • $aLabel';
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

    Widget avatar = CircleAvatar(
      radius: avatarRadius,
      backgroundColor: primary.withOpacity(0.20),
      child: Icon(
        Icons.person,
        color: primary,
        size: avatarRadius * 1.1,
      ),
    );

    if (heroTag != null) {
      avatar = Hero(
        tag: heroTag!,
        child: avatar,
      );
    }

    Widget content;

    if (mode == ArtistCardMode.list) {
      content = Container(
        constraints: const BoxConstraints(minHeight: AppConstants.trackTileHeight),
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
            avatar,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    _subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: onSurfaceVariant.withOpacity(0.6),
            ),
          ],
        ),
      );
    } else {
      // Grid Mode
      content = Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            avatar,
            const SizedBox(height: AppSpacing.sm),
            Text(
              name,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2.0),
            Text(
              _subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
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
        label: 'Artist $name, $_subtitle',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: borderRadius,
            child: content,
          ),
        ),
      ),
    );
  }
}
