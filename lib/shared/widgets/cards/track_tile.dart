import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../../core/extensions/duration_x.dart';
import '../../models/track.dart';

/// Context menu actions available on [TrackTile].
enum TrackTileMenuAction {
  playNext,
  addToQueue,
  addToPlaylist,
  goToAlbum,
  goToArtist,
  share,
  details,
}

/// Modern music list item conforming to Spotify/Apple Music standards:
/// artwork thumbnail with rounded corners, title with ellipsis/marquee,
/// artist and album subtitle, duration string, and trailing overflow popup menu.
class TrackTile extends StatefulWidget {
  const TrackTile({
    super.key,
    required this.title,
    required this.artist,
    this.album,
    this.duration,
    this.artworkUri,
    this.trackNumber,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onLongPress,
    this.onMorePressed,
    this.onMenuActionSelected,
    this.onPlayNext,
    this.onAddToPlaylist,
    this.trailing,
    this.leading,
    this.enableBlur = true,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
  });

  /// Convenience factory constructing a [TrackTile] from a domain [Track].
  factory TrackTile.fromTrack({
    Key? key,
    required Track track,
    bool isPlaying = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    VoidCallback? onMorePressed,
    ValueChanged<TrackTileMenuAction>? onMenuActionSelected,
    VoidCallback? onPlayNext,
    VoidCallback? onAddToPlaylist,
    Widget? trailing,
    Widget? leading,
    bool enableBlur = true,
  }) {
    return TrackTile(
      key: key,
      title: track.title,
      artist: track.artist,
      album: track.album,
      duration: track.duration,
      artworkUri: track.artworkUri,
      trackNumber: track.trackNumber,
      isPlaying: isPlaying,
      isFavorite: track.isFavorite,
      onTap: onTap,
      onLongPress: onLongPress,
      onMorePressed: onMorePressed,
      onMenuActionSelected: onMenuActionSelected,
      onPlayNext: onPlayNext,
      onAddToPlaylist: onAddToPlaylist,
      trailing: trailing,
      leading: leading,
      enableBlur: enableBlur,
    );
  }

  final String title;
  final String artist;
  final String? album;
  final Duration? duration;
  final String? artworkUri;
  final int? trackNumber;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMorePressed;
  final ValueChanged<TrackTileMenuAction>? onMenuActionSelected;
  final VoidCallback? onPlayNext;
  final VoidCallback? onAddToPlaylist;
  final Widget? trailing;
  final Widget? leading;
  final bool enableBlur;
  final EdgeInsetsGeometry padding;

  @override
  State<TrackTile> createState() => _TrackTileState();
}

class _TrackTileState extends State<TrackTile> {
  bool _isPressed = false;

  String get _formattedDuration {
    if (widget.duration == null) return '';
    return widget.duration!.toMinutesSeconds(padMinutes: false);
  }

  String get _resolvedSubtitle {
    if (widget.album != null && widget.album!.trim().isNotEmpty) {
      return '${widget.artist} • ${widget.album}';
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
    final borderRadius = BorderRadius.circular(12.0);

    // Modern card background: clean dark surface or subtle accent tint when playing
    final cardBackgroundColor = widget.isPlaying
        ? primary.withOpacity(isDark ? 0.14 : 0.10)
        : (isDark ? const Color(0xFF141923).withOpacity(0.65) : surface.withOpacity(0.75));

    final borderColor = widget.isPlaying
        ? primary.withOpacity(0.50)
        : (isDark ? const Color(0x18FFFFFF) : const Color(0x0F000000));

    // Left Artwork Thumbnail
    Widget artworkWidget;
    if (widget.leading != null) {
      artworkWidget = widget.leading!;
    } else {
      artworkWidget = Container(
        width: 48.0,
        height: 48.0,
        decoration: BoxDecoration(
          color: widget.isPlaying
              ? primary.withOpacity(0.20)
              : (isDark ? const Color(0xFF1E2433) : primary.withOpacity(0.10)),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: widget.isPlaying
                ? primary.withOpacity(0.40)
                : (isDark ? const Color(0x1FFFFFFF) : Colors.transparent),
            width: 1.0,
          ),
          boxShadow: widget.isPlaying
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.25),
                    blurRadius: 10.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: widget.isPlaying
              ? Icon(Icons.volume_up_rounded, color: primary, size: 24.0)
              : (widget.trackNumber != null
                  ? Text(
                      '${widget.trackNumber}',
                      style: AppTypography.titleMedium.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(Icons.music_note_rounded, color: primary, size: 22.0)),
        ),
      );
    }

    // Trailing Section: Favorite Heart, Duration, More Menu
    Widget trailingSection;
    if (widget.trailing != null) {
      trailingSection = widget.trailing!;
    } else {
      trailingSection = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isFavorite) ...[
            Icon(
              Icons.favorite_rounded,
              color: Colors.redAccent.shade200,
              size: 20.0,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          if (_formattedDuration.isNotEmpty) ...[
            Text(
              _formattedDuration,
              style: AppTypography.bodySmall.copyWith(
                color: widget.isPlaying ? primary : onSurfaceVariant,
                fontWeight: widget.isPlaying ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          PopupMenuButton<TrackTileMenuAction>(
            icon: Icon(
              Icons.more_vert,
              size: 20.0,
              color: onSurfaceVariant,
            ),
            tooltip: 'Track actions',
            onOpened: widget.onMorePressed,
            onSelected: (action) {
              switch (action) {
                case TrackTileMenuAction.playNext:
                  widget.onPlayNext?.call();
                  break;
                case TrackTileMenuAction.addToPlaylist:
                  widget.onAddToPlaylist?.call();
                  break;
                default:
                  break;
              }
              widget.onMenuActionSelected?.call(action);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TrackTileMenuAction.playNext,
                child: Row(
                  children: [
                    Icon(Icons.playlist_play_rounded),
                    SizedBox(width: 8),
                    Text('Play next'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TrackTileMenuAction.addToQueue,
                child: Row(
                  children: [
                    Icon(Icons.queue_music_rounded),
                    SizedBox(width: 8),
                    Text('Add to queue'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TrackTileMenuAction.addToPlaylist,
                child: Row(
                  children: [
                    Icon(Icons.playlist_add_rounded),
                    SizedBox(width: 8),
                    Text('Add to playlist'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TrackTileMenuAction.goToAlbum,
                child: Row(
                  children: [
                    Icon(Icons.album_rounded),
                    SizedBox(width: 8),
                    Text('Go to album'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TrackTileMenuAction.goToArtist,
                child: Row(
                  children: [
                    Icon(Icons.person_rounded),
                    SizedBox(width: 8),
                    Text('Go to artist'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TrackTileMenuAction.share,
                child: Row(
                  children: [
                    Icon(Icons.share_rounded),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }

    Widget content = Container(
      constraints: const BoxConstraints(minHeight: AppConstants.trackTileHeight),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: 1.0,
        ),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.16),
                  blurRadius: 14.0,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          artworkWidget,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: widget.isPlaying ? primary : onSurface,
                    fontWeight:
                        widget.isPlaying ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
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
          const SizedBox(width: AppSpacing.xs),
          trailingSection,
        ],
      ),
    );

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
        label: '${widget.title} by ${widget.artist}, duration $_formattedDuration',
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
