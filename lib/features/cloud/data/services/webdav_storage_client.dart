import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/network_server_config.dart';
import '../../domain/models/remote_media_item.dart';
import '../../domain/services/i_network_storage_client.dart';

/// WebDAV (RFC 4918) and custom HTTP storage client for browsing and streaming remote music collections.
class WebdavStorageClient implements INetworkStorageClient {
  WebdavStorageClient({this.timeout = const Duration(seconds: 10)});

  final Duration timeout;

  @override
  Future<bool> testConnection(NetworkServerConfig server) async {
    if (server.host == 'demo.nexa.local') {
      return true;
    }

    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final uri = server.baseUri;
      final request = await client.openUrl('PROPFIND', uri);

      _applyHeaders(request, server);
      request.headers.set('Depth', '0');

      final response = await request.close();
      client.close();

      return response.statusCode == HttpStatus.ok ||
          response.statusCode == 207 || // 207 Multi-Status
          response.statusCode == HttpStatus.noContent;
    } catch (e) {
      debugPrint('[WebdavStorageClient] Connection test failed: $e');
      return false;
    }
  }

  @override
  Future<List<RemoteMediaItem>> listDirectory({
    required NetworkServerConfig server,
    required String remotePath,
  }) async {
    // Return high-fidelity mock audio directory for demo servers or simulated test environments
    if (server.host == 'demo.nexa.local') {
      return _getDemoDirectory(server, remotePath);
    }

    try {
      final client = HttpClient()..connectionTimeout = timeout;
      final effectivePath = _normalizePath(server.path, remotePath);
      final uri = server.baseUri.replace(path: effectivePath);

      final request = await client.openUrl('PROPFIND', uri);
      _applyHeaders(request, server);
      request.headers.set('Depth', '1');
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/xml; charset="utf-8"');

      const propfindXml = '<?xml version="1.0" encoding="utf-8" ?>\r\n'
          '<d:propfind xmlns:d="DAV:">\r\n'
          '  <d:prop>\r\n'
          '    <d:displayname/>\r\n'
          '    <d:resourcetype/>\r\n'
          '    <d:getcontentlength/>\r\n'
          '    <d:getcontenttype/>\r\n'
          '    <d:getlastmodified/>\r\n'
          '  </d:prop>\r\n'
          '</d:propfind>';

      request.write(propfindXml);
      final response = await request.close();

      if (response.statusCode != 207 && response.statusCode != 200) {
        client.close();
        return [];
      }

      final responseXml = await response.transform(utf8.decoder).join();
      client.close();

      return _parsePropfindResponse(responseXml, server, effectivePath);
    } catch (e) {
      debugPrint('[WebdavStorageClient] Error listing directory: $e');
      return [];
    }
  }

  @override
  String getStreamUrl({
    required NetworkServerConfig server,
    required RemoteMediaItem item,
  }) {
    if (item.remotePath.startsWith('http://') || item.remotePath.startsWith('https://')) {
      return item.remotePath;
    }

    final normalized = item.remotePath.startsWith('/') ? item.remotePath : '/${item.remotePath}';
    final uri = server.baseUri.replace(path: normalized);

    if (server.username != null && server.username!.isNotEmpty) {
      final encodedUser = Uri.encodeComponent(server.username!);
      final encodedPass = Uri.encodeComponent(server.password ?? '');
      return uri.replace(userInfo: '$encodedUser:$encodedPass').toString();
    }

    return uri.toString();
  }

  @override
  Map<String, String> getAuthHeaders(NetworkServerConfig server) {
    if (server.username != null && server.username!.isNotEmpty) {
      final credentials = '${server.username}:${server.password ?? ''}';
      final encoded = base64Encode(utf8.encode(credentials));
      return {'Authorization': 'Basic $encoded'};
    }
    return {};
  }

  void _applyHeaders(HttpClientRequest request, NetworkServerConfig server) {
    if (server.username != null && server.username!.isNotEmpty) {
      final credentials = '${server.username}:${server.password ?? ''}';
      final encoded = base64Encode(utf8.encode(credentials));
      request.headers.set(HttpHeaders.authorizationHeader, 'Basic $encoded');
    }
  }

  String _normalizePath(String serverBasePath, String relativeSubPath) {
    var base = serverBasePath.endsWith('/')
        ? serverBasePath.substring(0, serverBasePath.length - 1)
        : serverBasePath;
    if (!base.startsWith('/')) base = '/$base';

    var sub = relativeSubPath;
    if (sub.startsWith('/')) sub = sub.substring(1);

    if (sub.isEmpty) return base;
    return '$base/$sub';
  }

  List<RemoteMediaItem> _parsePropfindResponse(
    String xml,
    NetworkServerConfig server,
    String requestedPath,
  ) {
    final items = <RemoteMediaItem>[];
    final responseRegex = RegExp(r'<[a-zA-Z]*:?response>([\s\S]*?)<\/[a-zA-Z]*:?response>', caseSensitive: false);
    final hrefRegex = RegExp(r'<[a-zA-Z]*:?href>(.*?)<\/[a-zA-Z]*:?href>', caseSensitive: false);
    final displayNameRegex = RegExp(r'<[a-zA-Z]*:?displayname>(.*?)<\/[a-zA-Z]*:?displayname>', caseSensitive: false);
    final isCollectionRegex = RegExp(r'<[a-zA-Z]*:?collection\s*\/?>', caseSensitive: false);
    final contentLengthRegex = RegExp(r'<[a-zA-Z]*:?getcontentlength>(.*?)<\/[a-zA-Z]*:?getcontentlength>', caseSensitive: false);
    final contentTypeRegex = RegExp(r'<[a-zA-Z]*:?getcontenttype>(.*?)<\/[a-zA-Z]*:?getcontenttype>', caseSensitive: false);
    final lastModifiedRegex = RegExp(r'<[a-zA-Z]*:?getlastmodified>(.*?)<\/[a-zA-Z]*:?getlastmodified>', caseSensitive: false);

    for (final match in responseRegex.allMatches(xml)) {
      final block = match.group(1) ?? '';
      final rawHref = hrefRegex.firstMatch(block)?.group(1)?.trim() ?? '';
      if (rawHref.isEmpty) continue;

      final decodedHref = Uri.decodeFull(rawHref);

      // Skip self / requested root directory
      final cleanHref = decodedHref.endsWith('/') ? decodedHref.substring(0, decodedHref.length - 1) : decodedHref;
      final cleanReq = requestedPath.endsWith('/') ? requestedPath.substring(0, requestedPath.length - 1) : requestedPath;
      if (cleanHref == cleanReq || cleanHref.isEmpty) continue;

      final isDir = isCollectionRegex.hasMatch(block);
      final rawDisplayName = displayNameRegex.firstMatch(block)?.group(1)?.trim();
      final name = rawDisplayName != null && rawDisplayName.isNotEmpty
          ? rawDisplayName
          : cleanHref.split('/').last;

      if (!isDir && !_isAudioFile(name)) {
        continue;
      }

      final rawLen = contentLengthRegex.firstMatch(block)?.group(1)?.trim();
      final size = rawLen != null ? int.tryParse(rawLen) : null;
      final mime = contentTypeRegex.firstMatch(block)?.group(1)?.trim();
      final rawDate = lastModifiedRegex.firstMatch(block)?.group(1)?.trim();
      final date = rawDate != null ? DateTime.tryParse(rawDate) : null;

      final id = '${server.id}_${Uri.encodeComponent(cleanHref)}';

      items.add(RemoteMediaItem(
        id: id,
        serverId: server.id,
        name: name,
        remotePath: cleanHref,
        isDirectory: isDir,
        sizeBytes: size,
        mimeType: mime,
        lastModified: date,
      ));
    }

    return items;
  }

  bool _isAudioFile(String name) {
    final lower = name.toLowerCase();
    const extensions = [
      '.flac',
      '.mp3',
      '.wav',
      '.m4a',
      '.aac',
      '.ogg',
      '.opus',
      '.dsf',
      '.dff',
      '.alac',
      '.aiff',
    ];
    return extensions.any((ext) => lower.endsWith(ext));
  }

  List<RemoteMediaItem> _getDemoDirectory(NetworkServerConfig server, String remotePath) {
    if (remotePath == '/' || remotePath == '/music' || remotePath.isEmpty) {
      return [
        RemoteMediaItem(
          id: '${server.id}_dsd_master',
          serverId: server.id,
          name: 'Hi-Res DSD Master Vault',
          remotePath: '/music/Hi-Res DSD Master Vault',
          isDirectory: true,
        ),
        RemoteMediaItem(
          id: '${server.id}_flac_studio',
          serverId: server.id,
          name: 'FLAC 24-bit 96kHz Lossless',
          remotePath: '/music/FLAC 24-bit 96kHz Lossless',
          isDirectory: true,
        ),
        RemoteMediaItem(
          id: '${server.id}_cyber_pulse',
          serverId: server.id,
          name: '01 - Cybernetic Pulse.flac',
          remotePath: '/music/01 - Cybernetic Pulse.flac',
          title: 'Cybernetic Pulse',
          artist: 'Aethelgard',
          album: 'Synthetic Horizons',
          sizeBytes: 42100500,
          duration: const Duration(minutes: 4, seconds: 12),
        ),
        RemoteMediaItem(
          id: '${server.id}_obsidian_rift',
          serverId: server.id,
          name: '02 - Obsidian Rift (DSD 5.6MHz).dsf',
          remotePath: '/music/02 - Obsidian Rift (DSD 5.6MHz).dsf',
          title: 'Obsidian Rift',
          artist: 'Kroma Ensemble',
          album: 'Obsidian Acoustics',
          sizeBytes: 98500200,
          duration: const Duration(minutes: 6, seconds: 45),
        ),
        RemoteMediaItem(
          id: '${server.id}_quantum_drift',
          serverId: server.id,
          name: '03 - Quantum Drift.mp3',
          remotePath: '/music/03 - Quantum Drift.mp3',
          title: 'Quantum Drift',
          artist: 'Solaris Wave',
          album: 'Deep Space Broadcast',
          sizeBytes: 12450000,
          duration: const Duration(minutes: 3, seconds: 28),
        ),
      ];
    } else {
      return [
        RemoteMediaItem(
          id: '${server.id}_track_a',
          serverId: server.id,
          name: 'Track A - Velvet Resonance.flac',
          remotePath: '$remotePath/Track A - Velvet Resonance.flac',
          title: 'Velvet Resonance',
          artist: 'NEXA Acoustic Lab',
          album: 'Acoustic Studio Live',
          sizeBytes: 38200100,
          duration: const Duration(minutes: 5, seconds: 15),
        ),
        RemoteMediaItem(
          id: '${server.id}_track_b',
          serverId: server.id,
          name: 'Track B - Nocturne in Emerald.wav',
          remotePath: '$remotePath/Track B - Nocturne in Emerald.wav',
          title: 'Nocturne in Emerald',
          artist: 'NEXA Acoustic Lab',
          album: 'Acoustic Studio Live',
          sizeBytes: 55400000,
          duration: const Duration(minutes: 4, seconds: 50),
        ),
      ];
    }
  }
}
