import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../shared/models/track.dart';

/// Embedded micro-HTTP streaming server for relaying local audio files to DLNA renderers.
class LocalAudioStreamProxy {
  LocalAudioStreamProxy({this.preferredPort = 0});

  final int preferredPort;
  HttpServer? _server;
  String? _localIp;
  final Map<String, String> _trackPathRegistry = {};

  /// Current base streaming URL, e.g. `http://192.168.1.100:8282`.
  String? get baseUrl {
    if (_server == null || _localIp == null) return null;
    return 'http://$_localIp:${_server!.port}';
  }

  /// Whether the streaming server is actively bound and listening.
  bool get isRunning => _server != null;

  /// Starts the embedded HTTP server and identifies the primary local network IP.
  Future<void> start() async {
    if (_server != null) return;

    try {
      _localIp = await _findPrimaryLocalIp();
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        preferredPort,
        shared: true,
      );
      _server!.listen(_handleHttpRequest, onError: (e) {
        debugPrint('[LocalAudioStreamProxy] Server error: $e');
      });
      debugPrint('[LocalAudioStreamProxy] Listening at $baseUrl');
    } catch (e) {
      debugPrint('[LocalAudioStreamProxy] Failed to bind HTTP server: $e');
    }
  }

  /// Registers a track with the proxy and returns the HTTP stream URL to send to DLNA renderers.
  String registerTrack(Track track) {
    if (track.filePath != null) {
      _trackPathRegistry[track.id] = track.filePath!;
    }
    final base = baseUrl ?? 'http://127.0.0.1:${_server?.port ?? 8282}';
    final ext = _resolveFileExtension(track.filePath ?? '');
    return '$base/stream/${Uri.encodeComponent(track.id)}$ext';
  }

  /// Handles incoming HTTP audio streaming requests with Range byte-seeking support.
  Future<void> _handleHttpRequest(HttpRequest request) async {
    final pathSegments = request.uri.pathSegments;
    if (pathSegments.isEmpty || pathSegments.first != 'stream') {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('NEXA Audio Proxy: Route not found')
        ..close();
      return;
    }

    final rawTrackId = pathSegments.length > 1 ? pathSegments[1] : '';
    // Strip optional extension if present
    final trackId = rawTrackId.contains('.')
        ? rawTrackId.substring(0, rawTrackId.lastIndexOf('.'))
        : rawTrackId;

    final filePath = _trackPathRegistry[trackId];
    if (filePath == null) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Track not found in streaming proxy registry')
        ..close();
      return;
    }

    final file = File(filePath);
    if (!await file.exists()) {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Underlying audio file missing on device')
        ..close();
      return;
    }

    final totalLength = await file.length();
    final mimeType = _resolveMimeType(filePath);
    final rangeHeader = request.headers.value(HttpHeaders.rangeHeader);

    request.response.headers
      ..set(HttpHeaders.acceptRangesHeader, 'bytes')
      ..set(HttpHeaders.contentTypeHeader, mimeType)
      ..set('Access-Control-Allow-Origin', '*');

    if (rangeHeader != null && rangeHeader.startsWith('bytes=')) {
      final rangeSpec = rangeHeader.substring(6).split('-').first;
      final start = int.tryParse(rangeSpec) ?? 0;
      final end = totalLength - 1;

      request.response
        ..statusCode = HttpStatus.partialContent
        ..headers.set(HttpHeaders.contentRangeHeader, 'bytes $start-$end/$totalLength')
        ..headers.set(HttpHeaders.contentLengthHeader, '${end - start + 1}');

      await request.response.addStream(file.openRead(start, end + 1));
    } else {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(HttpHeaders.contentLengthHeader, '$totalLength');

      await request.response.addStream(file.openRead());
    }

    await request.response.close();
  }

  /// Finds the local LAN IPv4 address suitable for DLNA speaker streaming.
  Future<String> _findPrimaryLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );

      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && !addr.address.startsWith('169.254')) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }

  String _resolveFileExtension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot != -1) {
      return path.substring(dot);
    }
    return '.mp3';
  }

  String _resolveMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.flac')) return 'audio/flac';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.m4a') || lower.endsWith('.aac')) return 'audio/mp4';
    if (lower.endsWith('.ogg') || lower.endsWith('.opus')) return 'audio/ogg';
    return 'audio/mpeg';
  }

  /// Closes the server and releases resources.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _trackPathRegistry.clear();
  }

  /// Disposes the proxy.
  Future<void> dispose() async {
    await stop();
  }
}
