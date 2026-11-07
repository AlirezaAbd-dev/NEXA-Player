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

/// Reusable artist card with glowing circular avatar ring, artist name,
/// discography metadata badges, and tactile spring interactions.
class ArtistCard extends StatefulWidget {
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

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  bool _isPressed = false;

  String get _subtitle {
    final tLabel = widget.trackCount == 1 ? '1 Track' : '${widget.trackCount} Tracks';
    final aLabel = widget.albumCount == 1 ? '1 Album' : '${widget.albumCount} Albums';
    return '$tLabel • $aLabel';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(GlassTokens.radiusCard);

    final resolvedBorderColor = GlassTokens.resolveBorderColor(context);

    // Glowing avatar with chromatic ring
    Widget avatar = Container(
      width: widget.avatarRadius * 2.2,
      height: widget.avatarRadius * 2.2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary,
            secondary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.35),
            blurRadius: 14.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.0),
      child: CircleAvatar(
        radius: widget.avatarRadius,
        backgroundColor: theme.scaffoldBackgroundColor,
        child: Icon(
          Icons.person,
          color: primary,
          size: widget.avatarRadius * 1.1,
        ),
      ),
    );

    if (widget.heroTag != null) {
      avatar = Hero(
        tag: widget.heroTag!,
        child: avatar,
      );
    }

    Widget content;

    if (widget.mode == ArtistCardMode.list) {
      content = Container(
        constraints: const BoxConstraints(minHeight: AppConstants.trackTileHeight),
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
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.08),
              blurRadius: 12.0,
              offset: const Offset(0, 3),
            ),
            ...GlassTokens.elevationLow,
          ],
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
                    widget.name,
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
              color: onSurfaceVariant.withOpacity(0.7),
            ),
          ],
        ),
      );
    } else {
      // Grid Mode
      content = Container(
        padding: const EdgeInsets.all(AppSpacing.md),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.name,
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
        label: 'Artist ${widget.name}, $_subtitle',
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
