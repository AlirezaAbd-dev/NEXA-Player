import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/glass_tokens.dart';
import '../../../core/design_system/nexa_surface_tokens.dart';
import '../../../core/extensions/duration_x.dart';
import '../../../core/utils/contrast_validator.dart';
import '../../models/track.dart';
import '../typography/bidi_text.dart';
import 'nexa_artwork_image.dart';

/// Context menu actions available on [TrackTile].
enum TrackTileMenuAction {
  playNext,
  addToQueue,
  addToPlaylist,
  goToAlbum,
  goToArtist,
  share,
  details,
  editTags,
  trimRingtone,
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
    this.track,
    this.trackNumber,
    this.isPlaying = false,
    this.isPlaybackActive = true,
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
    bool isPlaybackActive = true,
    bool showTrackNumber = false,
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
      track: track,
      trackNumber: showTrackNumber ? track.trackNumber : null,
      isPlaying: isPlaying,
      isPlaybackActive: isPlaybackActive,
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
  final Track? track;
  final int? trackNumber;
  final bool isPlaying;
  final bool isPlaybackActive;
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
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final tokens = NexaSurfaceTokens.of(context);
    final borderRadius = BorderRadius.circular(16.0);

    // Borderless styling: soft L2 tinted pill for active playing track, transparent on L0 canvas when inactive
    final cardBackgroundColor = widget.isPlaying
        ? Color.alphaBlend(primary.withOpacity(0.10), tokens.l2)
        : Colors.transparent;
    final activeTitleColor = ContrastValidator.ensureContrast(
      primary,
      widget.isPlaying ? cardBackgroundColor : tokens.l0,
    );

    // Left Artwork Thumbnail: 44x44dp, 10dp radius rounded album art thumbnail
    Widget artworkWidget;
    if (widget.leading != null) {
      artworkWidget = widget.leading!;
    } else {
      final hasTrackNumber = widget.trackNumber != null;
      Widget thumbnailContent;

      final hasArtworkSource =
          (widget.artworkUri != null && widget.artworkUri!.isNotEmpty) ||
              widget.track != null;

      if (hasArtworkSource && (!hasTrackNumber || widget.artworkUri != null)) {
        thumbnailContent = NexaArtworkImage(
          artworkUri: widget.artworkUri,
          track: widget.track,
          width: 44.0,
          height: 44.0,
          cacheWidth: 160,
          borderRadius: BorderRadius.circular(10.0),
          fallbackBuilder: (_) => hasTrackNumber && !widget.isPlaying
              ? Text(
                  '${widget.trackNumber}',
                  style: AppTypography.titleMedium.copyWith(
                    color: primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : _buildArtworkFallback(primary, tokens),
        );
      } else if (hasTrackNumber && !widget.isPlaying) {
        thumbnailContent = Text(
          '${widget.trackNumber}',
          style: AppTypography.titleMedium.copyWith(
            color: primary,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        thumbnailContent = _buildArtworkFallback(primary, tokens);
      }

      artworkWidget = Container(
        width: 44.0,
        height: 44.0,
        decoration: BoxDecoration(
          color: widget.isPlaying
              ? primary.withOpacity(0.18)
              : (isDark ? tokens.l1 : primary.withOpacity(0.08)),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: widget.isPlaying
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.20),
                    blurRadius: 10.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          alignment: Alignment.center,
          children: [
            thumbnailContent,
            if (widget.isPlaying) ...[
              Container(
                color: Colors.black.withOpacity(0.45),
                alignment: Alignment.center,
                child: AnimatedEqualizerGlyph(
                  color: primary,
                  isActive: widget.isPlaybackActive,
                  width: 20.0,
                  height: 20.0,
                ),
              ),
              const Opacity(
                opacity: 0.0,
                child: Icon(Icons.volume_up_rounded, size: 0.0),
              ),
            ],
          ],
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
              const PopupMenuItem(
                value: TrackTileMenuAction.editTags,
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded),
                    SizedBox(width: 8),
                    Text('Edit tags & cover'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: TrackTileMenuAction.trimRingtone,
                child: Row(
                  children: [
                    Icon(Icons.content_cut_rounded),
                    SizedBox(width: 8),
                    Text('Trim ringtone'),
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
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.12),
                  blurRadius: 12.0,
                  offset: const Offset(0, 2),
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
                BidiText(
                  widget.title,
                  style: AppTypography.titleMedium.copyWith(
                    color: widget.isPlaying ? activeTitleColor : onSurface,
                    fontWeight:
                        widget.isPlaying ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3.0),
                BidiText(
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

  Widget _buildArtworkFallback(Color primary, NexaSurfaceTokens tokens) {
    return Container(
      decoration: BoxDecoration(
        color: tokens.l2,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens.l2,
            tokens.l1,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          color: primary.withOpacity(0.85),
          size: 20.0,
        ),
      ),
    );
  }
}

/// Compact 3-bar animated equalizer glyph indicating active playback.
///
/// Automatically freezes under `MediaQuery.disableAnimationsOf(context)` for WCAG accessibility.
class AnimatedEqualizerGlyph extends StatefulWidget {
  const AnimatedEqualizerGlyph({
    super.key,
    this.color,
    this.isActive = true,
    this.width = 18.0,
    this.height = 18.0,
  });

  final Color? color;
  final bool isActive;
  final double width;
  final double height;

  @override
  State<AnimatedEqualizerGlyph> createState() => _AnimatedEqualizerGlyphState();
}

class _AnimatedEqualizerGlyphState extends State<AnimatedEqualizerGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(AnimatedEqualizerGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = widget.color ?? theme.colorScheme.primary;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    if (reduceMotion || !widget.isActive) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(0.4, primary),
            _buildBar(0.85, primary),
            _buildBar(0.5, primary),
          ],
        ),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final h1 = 0.3 + 0.6 * math.sin(val * math.pi);
        final h2 = 0.4 + 0.55 * math.cos(val * math.pi);
        final h3 = 0.35 + 0.6 * math.sin((val + 0.5) * math.pi).abs();

        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(h1.clamp(0.2, 1.0), primary),
              _buildBar(h2.clamp(0.2, 1.0), primary),
              _buildBar(h3.clamp(0.2, 1.0), primary),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double heightFraction, Color color) {
    return Container(
      width: 3.0,
      height: widget.height * heightFraction,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }
}
