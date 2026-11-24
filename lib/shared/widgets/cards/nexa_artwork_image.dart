import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/shared/models/album.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Displays artwork from either network URLs or local cached files, with
/// optional lazy off-thread extraction fallback via [IArtworkResolutionService]
/// when [artworkUri] is null, empty, or unreadable.
///
/// Works safely with or without GetIt / ProviderScope in isolated widget tests,
/// and constrains memory decoding via [cacheWidth] for smooth 60fps scrolling.
class NexaArtworkImage extends StatefulWidget {
  const NexaArtworkImage({
    super.key,
    required this.fallbackBuilder,
    this.artworkUri,
    this.track,
    this.album,
    this.albumTracks = const [],
    this.artworkService,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheWidth = 200,
    this.borderRadius,
  });

  final String? artworkUri;
  final Track? track;
  final Album? album;
  final List<Track> albumTracks;
  final IArtworkResolutionService? artworkService;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int cacheWidth;
  final BorderRadius? borderRadius;
  final WidgetBuilder fallbackBuilder;

  @override
  State<NexaArtworkImage> createState() => _NexaArtworkImageState();
}

class _NexaArtworkImageState extends State<NexaArtworkImage> {
  String? _resolvedUri;
  bool _resolutionAttempted = false;

  @override
  void initState() {
    super.initState();
    _resolvedUri = widget.artworkUri;
    _maybeResolveLazily();
  }

  @override
  void didUpdateWidget(NexaArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artworkUri != widget.artworkUri ||
        oldWidget.track?.id != widget.track?.id ||
        oldWidget.album?.id != widget.album?.id) {
      _resolvedUri = widget.artworkUri;
      _resolutionAttempted = false;
      _maybeResolveLazily();
    }
  }

  IArtworkResolutionService? get _effectiveService {
    if (widget.artworkService != null) return widget.artworkService;
    if (getIt.isRegistered<IArtworkResolutionService>()) {
      return getIt<IArtworkResolutionService>();
    }
    return null;
  }

  void _maybeResolveLazily() {
    if (_resolutionAttempted) return;
    final current = _resolvedUri;
    if (current != null && current.isNotEmpty) {
      if (current.startsWith('http://') || current.startsWith('https://')) {
        return;
      }
      final file = File(_stripFileScheme(current));
      if (file.existsSync()) return;
    }

    final service = _effectiveService;
    if (service == null) return;
    if (widget.track == null && widget.album == null) return;

    _resolutionAttempted = true;
    Future<String?>? future;
    if (widget.track != null) {
      future = service.resolveTrackArtwork(widget.track!);
    } else if (widget.album != null) {
      future = service.resolveAlbumArtwork(
        widget.album!,
        tracks: widget.albumTracks,
      );
    }

    future?.then((resolved) {
      if (!mounted) return;
      if (resolved != null && resolved.isNotEmpty && resolved != _resolvedUri) {
        setState(() {
          _resolvedUri = resolved;
        });
      }
    });
  }

  static String _stripFileScheme(String uri) =>
      uri.startsWith('file://') ? uri.substring(7) : uri;

  @override
  Widget build(BuildContext context) {
    final uri = _resolvedUri;
    Widget content;

    if (uri != null && uri.isNotEmpty) {
      if (uri.startsWith('http://') || uri.startsWith('https://')) {
        content = Image.network(
          uri,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          cacheWidth: widget.cacheWidth,
          errorBuilder: (_, __, ___) => widget.fallbackBuilder(context),
        );
      } else {
        final file = File(_stripFileScheme(uri));
        if (file.existsSync()) {
          content = Image.file(
            file,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            errorBuilder: (_, __, ___) => widget.fallbackBuilder(context),
          );
        } else {
          content = widget.fallbackBuilder(context);
        }
      }
    } else {
      content = widget.fallbackBuilder(context);
    }

    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        child: content,
      );
    }
    return content;
  }
}
