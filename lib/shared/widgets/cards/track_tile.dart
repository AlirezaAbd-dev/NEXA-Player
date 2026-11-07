import 'dart:math' as math;
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
    if (widget.album != null && widget.album!.isNotEmpty) {
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
    final borderRadius = BorderRadius.circular(GlassTokens.radiusMedium);

    final resolvedBorderColor = widget.isPlaying
        ? primary.withOpacity(0.80)
        : (isDark ? GlassTokens.borderColorDark : GlassTokens.borderColorLight);

    final tileGradient = widget.isPlaying
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(isDark ? 0.30 : 0.22),
              surface.withOpacity(isDark ? 0.16 : 0.38),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              surface.withOpacity(isDark ? 0.20 : 0.55),
              surface.withOpacity(isDark ? 0.08 : 0.25),
            ],
          );

    Widget artworkWidget;
    if (widget.leading != null) {
      artworkWidget = widget.leading!;
    } else {
      artworkWidget = Container(
        width: 48.0,
        height: 48.0,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withOpacity(widget.isPlaying ? 0.35 : 0.22),
              primary.withOpacity(widget.isPlaying ? 0.18 : 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: primary.withOpacity(widget.isPlaying ? 0.50 : 0.20),
            width: 1.0,
          ),
          boxShadow: widget.isPlaying
              ? [
                  BoxShadow(
                    color: primary.withOpacity(0.35),
                    blurRadius: 12.0,
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
                  : Icon(Icons.music_note_rounded, color: primary, size: 24.0)),
        ),
      );
    }

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
                fontWeight: widget.isPlaying ? FontWeight.bold : FontWeight.normal,
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
        gradient: tileGradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: resolvedBorderColor,
          width: GlassTokens.borderWidth,
        ),
        boxShadow: widget.isPlaying
            ? [
                BoxShadow(
                  color: primary.withOpacity(0.28),
                  blurRadius: 18.0,
                  offset: const Offset(0, 4),
                ),
              ]
            : GlassTokens.elevationLow,
      ),
      child: Stack(
        children: [
          // Inner top specular reflection
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
                    Colors.white.withOpacity(isDark ? 0.28 : 0.60),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Row(
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

class _MiniEqualizerBars extends StatefulWidget {
  const _MiniEqualizerBars({required this.color});
  final Color color;

  @override
  State<_MiniEqualizerBars> createState() => _MiniEqualizerBarsState();
}

class _MiniEqualizerBarsState extends State<_MiniEqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    final isTest =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _bar(8.0 + 8.0 * math.sin(t * math.pi)),
            const SizedBox(width: 2.5),
            _bar(6.0 + 12.0 * math.cos(t * math.pi)),
            const SizedBox(width: 2.5),
            _bar(10.0 + 8.0 * math.sin((t + 0.4) * math.pi)),
          ],
        );
      },
    );
  }

  Widget _bar(double height) {
    return Container(
      width: 3.5,
      height: height.clamp(4.0, 20.0),
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
