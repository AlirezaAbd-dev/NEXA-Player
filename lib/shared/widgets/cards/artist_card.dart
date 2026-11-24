import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/shared/models/artist.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Layout orientation mode for [ArtistCard].
enum ArtistCardMode {
  /// Vertical layout with prominent circular avatar for grid collections.
  grid,

  /// Horizontal list layout for artist list views.
  list,
}

/// Borderless artist card with circular avatar,
/// subtle accent elevation, tactile spring feedback, and crisp typography.
class ArtistCard extends StatefulWidget {
  const ArtistCard({
    super.key,
    required this.name,
    this.artworkUri,
    this.trackCount,
    this.albumCount,
    this.mode = ArtistCardMode.list,
    this.avatarRadius = 24.0,
    this.heroTag,
    this.onTap,
    this.onLongPress,
    this.enableBlur = true,
  });

  /// Convenience factory constructing an [ArtistCard] from a domain [Artist].
  factory ArtistCard.fromArtist({
    Key? key,
    required Artist artist,
    ArtistCardMode mode = ArtistCardMode.list,
    double avatarRadius = 24.0,
    String? heroTag,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    bool enableBlur = true,
  }) {
    return ArtistCard(
      key: key,
      name: artist.name,
      artworkUri: artist.artworkUri,
      trackCount: artist.trackCount,
      albumCount: artist.albumCount,
      mode: mode,
      avatarRadius: avatarRadius,
      heroTag: heroTag,
      onTap: onTap,
      onLongPress: onLongPress,
      enableBlur: enableBlur,
    );
  }

  final String name;
  final String? artworkUri;
  final int? trackCount;
  final int? albumCount;
  final ArtistCardMode mode;
  final double avatarRadius;
  final String? heroTag;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enableBlur;

  @override
  State<ArtistCard> createState() => _ArtistCardState();
}

class _ArtistCardState extends State<ArtistCard> {
  bool _isPressed = false;

  String get _initials {
    final clean = widget.name.trim();
    if (clean.isEmpty) return '?';
    final parts = clean.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean.length >= 2 ? clean.substring(0, 2).toUpperCase() : clean[0].toUpperCase();
  }

  String get _subtitle {
    final parts = <String>[];
    if (widget.trackCount != null) {
      parts.add('${widget.trackCount} ${widget.trackCount == 1 ? "Track" : "Tracks"}');
    }
    if (widget.albumCount != null) {
      parts.add('${widget.albumCount} ${widget.albumCount == 1 ? "Album" : "Albums"}');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final borderRadius = BorderRadius.circular(16.0);

    // Typographic Monogram Avatar with custom deterministic gradient circle
    final hash = widget.name.hashCode.abs();
    final hue = (hash % 360).toDouble();
    final avatarBg1 = HSLColor.fromAHSL(1.0, hue, 0.40, isDark ? 0.22 : 0.88).toColor();
    final avatarBg2 = HSLColor.fromAHSL(1.0, (hue + 40) % 360, 0.45, isDark ? 0.12 : 0.78).toColor();
    final monogramColor = HSLColor.fromAHSL(1.0, hue, 0.70, isDark ? 0.90 : 0.25).toColor();

    Widget avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [avatarBg1, avatarBg2],
        ),
        boxShadow: [
          BoxShadow(
            color: avatarBg1.withOpacity(0.25),
            blurRadius: 10.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(2.0),
      child: CircleAvatar(
        radius: widget.avatarRadius,
        backgroundColor: Colors.transparent,
        child: widget.artworkUri != null && widget.artworkUri!.isNotEmpty
            ? ClipOval(
                child: NexaArtworkImage(
                  artworkUri: widget.artworkUri,
                  fit: BoxFit.cover,
                  width: widget.avatarRadius * 2,
                  height: widget.avatarRadius * 2,
                  cacheWidth: 160,
                  fallbackBuilder: (_) => Text(
                    _initials,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: monogramColor,
                      fontSize: widget.avatarRadius * 0.75,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              )
            : Text(
                _initials,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: monogramColor,
                  fontSize: widget.avatarRadius * 0.75,
                  letterSpacing: -0.5,
                ),
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
      // Direct-on-L0 Editorial Row: No repetitive boxed card containers
      content = Container(
        constraints: const BoxConstraints(minHeight: 70.0),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: _isPressed ? surfaceTokens.level2.withOpacity(0.4) : Colors.transparent,
        ),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: AppSpacing.md),
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
                  const SizedBox(height: 3.0),
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
      content = NexaSurface(
        level: NexaSurfaceLevel.l1,
        borderRadius: borderRadius,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
    }

    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${widget.name}, $_subtitle',
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
