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
    _resolvedUri =
        widget.artworkUri ?? widget.track?.artworkUri ?? widget.album?.artworkUri;
    _maybeResolveLazily();
  }

  @override
  void didUpdateWidget(NexaArtworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextUri =
        widget.artworkUri ?? widget.track?.artworkUri ?? widget.album?.artworkUri;
    final oldUri = oldWidget.artworkUri ??
        oldWidget.track?.artworkUri ??
        oldWidget.album?.artworkUri;
    if (oldUri != nextUri ||
        oldWidget.track?.id != widget.track?.id ||
        oldWidget.album?.id != widget.album?.id) {
      _resolvedUri = nextUri;
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

  static const int _maxCacheEntries = 500;
  static const int _maxConcurrentResolutions = 3;
  static final Set<String> _missingFilesCache = <String>{};
  static int _activeResolutions = 0;

  static void _rememberMissingFile(String path) {
    if (_missingFilesCache.length >= _maxCacheEntries) {
      _missingFilesCache.clear();
    }
    _missingFilesCache.add(path);
  }

  void _maybeResolveLazily() {
    if (_resolutionAttempted) return;
    final current = _resolvedUri;
    if (current != null && current.isNotEmpty) {
      if (current.startsWith('http://') || current.startsWith('https://')) {
        return;
      }
      final clean = _stripFileScheme(current);
      if (!_missingFilesCache.contains(clean)) {
        // Verify asynchronously off the UI isolate rather than blocking with existsSync.
        File(clean).exists().then((exists) {
          if (exists) return;
          _rememberMissingFile(clean);
          if (mounted) {
            _resolveFromService();
          }
        });
        return;
      }
    }

    _resolveFromService();
  }

  void _resolveFromService() {
    if (_resolutionAttempted) return;
    final service = _effectiveService;
    if (service == null) return;
    if (widget.track == null && widget.album == null) return;
    if (_activeResolutions >= _maxConcurrentResolutions) return;

    _resolutionAttempted = true;
    _activeResolutions++;
    Future<String?>? future;
    if (widget.track != null) {
      future = service.resolveTrackArtwork(widget.track!);
    } else if (widget.album != null) {
      future = service.resolveAlbumArtwork(
        widget.album!,
        tracks: widget.albumTracks,
      );
    }

    if (future == null) {
      _activeResolutions = (_activeResolutions - 1).clamp(0, _maxConcurrentResolutions);
      return;
    }

    future.then((resolved) {
      if (!mounted) return;
      if (resolved != null && resolved.isNotEmpty && resolved != _resolvedUri) {
        _missingFilesCache.remove(_stripFileScheme(resolved));
        setState(() {
          _resolvedUri = resolved;
        });
      }
    }).whenComplete(() {
      _activeResolutions = (_activeResolutions - 1).clamp(0, _maxConcurrentResolutions);
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
        final clean = _stripFileScheme(uri);
        if (_missingFilesCache.contains(clean)) {
          content = widget.fallbackBuilder(context);
        } else {
          content = Image.file(
            File(clean),
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            errorBuilder: (_, __, ___) {
              _rememberMissingFile(clean);
              return widget.fallbackBuilder(context);
            },
          );
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
