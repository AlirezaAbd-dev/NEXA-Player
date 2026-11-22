import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/remote_media_item.dart';
import '../../domain/services/i_network_cache_manager.dart';

/// LRU disk cache manager for offline playback and low-latency network streaming.
class NetworkCacheManagerImpl implements INetworkCacheManager {
  NetworkCacheManagerImpl({String? customCacheDir}) : _customCacheDir = customCacheDir;

  final String? _customCacheDir;
  Directory? _resolvedDir;

  Future<Directory> _getCacheDirectory() async {
    if (_resolvedDir != null) return _resolvedDir!;

    if (_customCacheDir != null) {
      final dir = Directory(p.join(_customCacheDir, 'nexa_network_cache'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _resolvedDir = dir;
      return dir;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(p.join(tempDir.path, 'nexa_network_cache'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _resolvedDir = dir;
      return dir;
    } catch (_) {
      // Fallback for isolated unit test environments without platform channels
      final dir = Directory(p.join(Directory.systemTemp.path, 'nexa_network_cache'));
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      _resolvedDir = dir;
      return dir;
    }
  }

  String _sanitizeFileName(String id, String ext) {
    final bytes = utf8.encode(id);
    var hash = 0;
    for (final b in bytes) {
      hash = (hash * 31 + b) & 0x7FFFFFFF;
    }
    final cleanExt = ext.isNotEmpty ? (ext.startsWith('.') ? ext : '.$ext') : '.mp3';
    return 'cache_${hash.toRadixString(16)}$cleanExt';
  }

  @override
  Future<String?> getCachedPath(RemoteMediaItem item) async {
    final dir = await _getCacheDirectory();
    final fileName = _sanitizeFileName(item.id, item.fileExtension);
    final file = File(p.join(dir.path, fileName));

    if (await file.exists() && await file.length() > 0) {
      try {
        await file.setLastModified(DateTime.now());
      } catch (_) {}
      return file.path;
    }
    return null;
  }

  @override
  Future<String> cacheTrack({
    required RemoteMediaItem item,
    required String streamUrl,
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  }) async {
    final existing = await getCachedPath(item);
    if (existing != null) {
      onProgress?.call(1.0);
      return existing;
    }

    final dir = await _getCacheDirectory();
    final fileName = _sanitizeFileName(item.id, item.fileExtension);
    final targetFile = File(p.join(dir.path, fileName));
    final partFile = File(p.join(dir.path, '$fileName.part'));

    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
      final request = await client.getUrl(Uri.parse(streamUrl));

      headers?.forEach((key, val) {
        request.headers.set(key, val);
      });

      final response = await request.close();
      if (response.statusCode != HttpStatus.ok && response.statusCode != HttpStatus.partialContent) {
        client.close();
        throw HttpException('Server returned HTTP ${response.statusCode} while caching track');
      }

      final contentLength = response.contentLength;
      var receivedBytes = 0;

      final sink = partFile.openWrite();
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (contentLength > 0 && onProgress != null) {
          onProgress(receivedBytes / contentLength);
        }
      }

      await sink.flush();
      await sink.close();
      client.close();

      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await partFile.rename(targetFile.path);
      onProgress?.call(1.0);

      return targetFile.path;
    } catch (e) {
      debugPrint('[NetworkCacheManager] Caching failure: $e');
      if (await partFile.exists()) {
        try {
          await partFile.delete();
        } catch (_) {}
      }
      rethrow;
    }
  }

  @override
  Future<bool> removeCachedTrack(String itemId) async {
    final dir = await _getCacheDirectory();
    const prefix = 'cache_';
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File && p.basename(entity.path).startsWith(prefix)) {
        // Test if this entity matches the hashed item ID
        final sanitized = _sanitizeFileName(itemId, '');
        final baseWithoutExt = sanitized.substring(0, sanitized.lastIndexOf('.'));
        if (p.basename(entity.path).contains(baseWithoutExt)) {
          await entity.delete();
          return true;
        }
      }
    }
    return false;
  }

  @override
  Future<void> clearAllCache() async {
    final dir = await _getCacheDirectory();
    final entities = await dir.list().toList();
    for (final entity in entities) {
      if (entity is File) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  @override
  Future<int> getCurrentCacheSizeBytes() async {
    final dir = await _getCacheDirectory();
    var totalBytes = 0;
    final entities = await dir.list().toList();

    for (final entity in entities) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }

  @override
  Future<void> enforceQuota(int maxMegabytes) async {
    final maxBytes = maxMegabytes * 1024 * 1024;
    var currentBytes = await getCurrentCacheSizeBytes();
    if (currentBytes <= maxBytes) return;

    final dir = await _getCacheDirectory();
    final files = <File>[];
    for (final entity in await dir.list().toList()) {
      if (entity is File && !entity.path.endsWith('.part')) {
        files.add(entity);
      }
    }

    // Sort by last modified ascending (oldest files first)
    files.sort((a, b) {
      final aMod = a.lastModifiedSync();
      final bMod = b.lastModifiedSync();
      return aMod.compareTo(bMod);
    });

    final targetLimit = (maxBytes * 0.8).round();
    for (final file in files) {
      if (currentBytes <= targetLimit) break;
      final len = await file.length();
      try {
        await file.delete();
        currentBytes -= len;
      } catch (_) {}
    }
  }
}
