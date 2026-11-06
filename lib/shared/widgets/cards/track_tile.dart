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

/// Reusable music list item conforming to Poweramp/Stellio standards:
/// artwork thumbnail with rounded corners, title with ellipsis/marquee,
/// artist and album subtitle, duration string, and trailing overflow popup menu.
class TrackTile extends StatelessWidget {
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
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
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

  String get _resolvedSubtitle {
    if (album != null && album!.trim().isNotEmpty) {
      return '$artist • $album';
    }
    return artist;
  }

  String get _formattedDuration {
    if (duration == null) return '';
    return duration!.toMinutesSeconds(padMinutes: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final borderRadius = BorderRadius.circular(GlassTokens.radiusMedium);

    final cardBackgroundColor = isPlaying
        ? primary.withOpacity(isDark ? 0.20 : 0.14)
        : surface.withOpacity(isDark ? 0.12 : 0.08);

    final borderColor = isPlaying
        ? primary.withOpacity(0.60)
        : (isDark ? GlassTokens.borderColorLight : GlassTokens.borderColorDark);

    Widget artworkWidget;
    if (leading != null) {
      artworkWidget = leading!;
    } else {
      artworkWidget = Container(
        width: 48.0,
        height: 48.0,
        decoration: BoxDecoration(
          color: primary.withOpacity(isPlaying ? 0.25 : 0.15),
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Center(
          child: isPlaying
              ? Icon(Icons.volume_up_rounded, color: primary, size: 24.0)
              : (trackNumber != null
                  ? Text(
                      '$trackNumber',
                      style: AppTypography.titleMedium.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : Icon(Icons.music_note_rounded, color: primary, size: 24.0)),
        ),
      );
    }

    Widget trailingSection;
    if (trailing != null) {
      trailingSection = trailing!;
    } else {
      trailingSection = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_formattedDuration.isNotEmpty) ...[
            Text(
              _formattedDuration,
              style: AppTypography.bodySmall.copyWith(
                color: isPlaying ? primary : onSurfaceVariant,
                fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
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
            onOpened: onMorePressed,
            onSelected: (action) {
              switch (action) {
                case TrackTileMenuAction.playNext:
                  onPlayNext?.call();
                  break;
                case TrackTileMenuAction.addToPlaylist:
                  onAddToPlaylist?.call();
                  break;
                default:
                  break;
              }
              onMenuActionSelected?.call(action);
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
      padding: padding,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor,
          width: GlassTokens.borderWidth,
        ),
        boxShadow: isPlaying
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.18),
                  blurRadius: 16.0,
                  offset: const Offset(0, 4),
                ),
              ]
            : GlassTokens.elevationLow,
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
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    color: isPlaying ? primary : onSurface,
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.w600,
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
          const SizedBox(width: AppSpacing.xs),
          trailingSection,
        ],
      ),
    );

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
        label: '$title by $artist, duration $_formattedDuration',
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
