import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../features/scanner/data/pure_dart_audio_metadata_reader.dart';
import '../../../features/scanner/domain/audio_metadata_reader.dart';
import '../../../shared/models/album.dart';
import '../../../shared/models/track.dart';

/// Priority preference for resolving local cover artwork when multiple tiers exist.
enum ArtworkSourcePreference {
  preferEmbedded,
  preferFolderAndDownloaded,
}

/// Callback extracting artwork natively (e.g. Android MediaMetadataRetriever + MediaStore).
typedef NativeArtworkExtractor = Future<String?> Function({
  required String? filePath,
  required String outputPath,
  int? albumId,
  int maxSize,
  bool preferEmbedded,
});

/// Abstract service resolving album/track cover art with deterministic multi-tier
/// priority and disk caching for 60fps list scrolling.
abstract interface class IArtworkResolutionService {
  /// Resolves a local displayable cover path (or remote URL if present) for [track].
  /// Returns `null` when no valid cover image exists across all local tiers.
  Future<String?> resolveTrackArtwork(
    Track track, {
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
    int? mediaStoreAlbumId,
    int maxSize = 512,
  });

  /// Resolves cover artwork for [album], inspecting existing URI and its [tracks].
  Future<String?> resolveAlbumArtwork(
    Album album, {
    List<Track> tracks = const [],
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
  });

  /// Persists pre-extracted [artworkBytes] for [trackId] / [cacheKey] into the
  /// compressed disk cache, returning the saved path if bytes are valid image data.
  Future<String?> cacheExtractedBytes(
    String cacheKey,
    Uint8List artworkBytes, {
    bool saveWithoutExtension = false,
  });

  /// Saves a user-chosen custom override cover for [trackId] (highest priority tier).
  Future<String?> saveCustomOverride(String trackId, Uint8List imageBytes);

  /// Removes any user custom override for [trackId].
  Future<void> clearCustomOverride(String trackId);

  /// Purges cached cover files from disk and clears in-memory negative/flight caches.
  Future<void> clearCache();
}

/// Callback invoked when artwork is lazily resolved and cached so SQLite can persist it.
typedef ArtworkPersister<T> = Future<void> Function(T item, String resolvedPath);

/// Multi-tier cover artwork resolution & disk cache pipeline:
/// 1. User custom override (`artwork_overrides/<trackId>.jpg`)
/// 2. Already resolved valid file path / disk cache (`artwork_cache/<key>`)
/// 3. Embedded tag artwork (native Android `MediaMetadataRetriever` / MediaStore
///    or isolated pure-Dart parser for ID3v2 APIC, FLAC PICTURE, MP4 `covr`)
/// 4. Local sibling folder art (`cover.jpg`, `folder.jpg`, `album.jpg`, `front.jpg`, etc.)
/// 5. Returns `null` cleanly so UI displays its procedural vinyl fallback.
class ArtworkResolutionService implements IArtworkResolutionService {
  ArtworkResolutionService({
    Future<Directory> Function()? cacheDirectoryProvider,
    IAudioMetadataReader? metadataReader,
    NativeArtworkExtractor? nativeExtractor,
    ArtworkPersister<Track>? onTrackArtworkResolved,
    ArtworkPersister<Album>? onAlbumArtworkResolved,
    bool saveWithoutExtension = false,
    bool enableNativePlatformChannel = true,
  })  : _cacheDirectoryProvider =
            cacheDirectoryProvider ?? getTemporaryDirectory,
        _metadataReader =
            metadataReader ?? const PureDartAudioMetadataReader(),
        _nativeExtractor = nativeExtractor ??
            (enableNativePlatformChannel && !kIsWeb && Platform.isAndroid
                ? _defaultAndroidNativeExtractor
                : null),
        _onTrackArtworkResolved = onTrackArtworkResolved,
        _onAlbumArtworkResolved = onAlbumArtworkResolved,
        _saveWithoutExtension = saveWithoutExtension;

  final Future<Directory> Function() _cacheDirectoryProvider;
  final IAudioMetadataReader _metadataReader;
  final NativeArtworkExtractor? _nativeExtractor;
  final ArtworkPersister<Track>? _onTrackArtworkResolved;
  final ArtworkPersister<Album>? _onAlbumArtworkResolved;
  final bool _saveWithoutExtension;

  final Map<String, Future<String?>> _inFlight = {};
  final Set<String> _negativeCache = {};
  Directory? _cachedRootDir;

  static const MethodChannel _mediaStoreChannel =
      MethodChannel('com.nexa.player/media_store');

  /// Ordered filename candidates (case-insensitive) for local folder artwork.
  static const List<String> folderCoverCandidates = [
    'cover',
    'folder',
    'album',
    'front',
    'artwork',
    'albumart',
  ];

  static const Set<String> _supportedImageExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  };

  static Future<String?> _defaultAndroidNativeExtractor({
    required String? filePath,
    required String outputPath,
    int? albumId,
    int maxSize = 512,
    bool preferEmbedded = true,
  }) async {
    try {
      return await _mediaStoreChannel.invokeMethod<String>(
        'extractEmbeddedArtwork',
        {
          'filePath': filePath,
          'outputPath': outputPath,
          'albumId': albumId,
          'maxSize': maxSize,
          'preferEmbedded': preferEmbedded,
        },
      );
    } catch (_) {
      return null;
    }
  }

  Future<Directory> _rootDir() async {
    if (_cachedRootDir != null) return _cachedRootDir!;
    final base = await _cacheDirectoryProvider();
    _cachedRootDir = base;
    return base;
  }

  Future<Directory> _cacheDir() async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, 'artwork_cache'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> _overridesDir() async {
    final root = await _rootDir();
    final dir = Directory(p.join(root.path, 'artwork_overrides'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _sanitizeKey(String raw) =>
      raw.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  Future<String> _buildCacheFilePath(
    String key, {
    bool? withoutExtension,
  }) async {
    final dir = await _cacheDir();
    final useExtensionless = withoutExtension ?? _saveWithoutExtension;
    final sanitized = _sanitizeKey(key);
    return p.join(
      dir.path,
      useExtensionless ? sanitized : '$sanitized.jpg',
    );
  }

  String _trackCacheKey(Track track) {
    final albumPart = track.album.isNotEmpty && track.album != 'Unknown Album'
        ? '${track.artist}__${track.album}'.hashCode.abs().toString()
        : '';
    if (albumPart.isNotEmpty) {
      return 'trk_${track.id}_alb_$albumPart';
    }
    return 'trk_${track.id}';
  }

  @override
  Future<String?> resolveTrackArtwork(
    Track track, {
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
    int? mediaStoreAlbumId,
    int maxSize = 512,
  }) {
    final inFlightKey = '${track.id}__${preference.name}__$maxSize';
    final existingFuture = _inFlight[inFlightKey];
    if (existingFuture != null) return existingFuture;

    final future = _resolveTrackArtworkInternal(
      track,
      preference: preference,
      mediaStoreAlbumId: mediaStoreAlbumId,
      maxSize: maxSize,
    ).whenComplete(() {
      _inFlight.remove(inFlightKey);
    });

    _inFlight[inFlightKey] = future;
    return future;
  }

  Future<String?> _resolveTrackArtworkInternal(
    Track track, {
    required ArtworkSourcePreference preference,
    int? mediaStoreAlbumId,
    required int maxSize,
  }) async {
    // Tier 1: User custom override cover (always wins, even if cached/embedded exists)
    final overridePath = await _findValidOverride(track.id);
    if (overridePath != null) return overridePath;

    // Tier 2: Existing valid artworkUri on track (network URL or readable valid local file)
    final existingUri = track.artworkUri;
    if (existingUri != null && existingUri.isNotEmpty) {
      if (existingUri.startsWith('http://') || existingUri.startsWith('https://')) {
        return existingUri;
      }
      final existingFile = File(_stripFileScheme(existingUri));
      if (await _isValidCachedImageFile(existingFile)) {
        return existingFile.path;
      }
    }

    // Tier 2b: Disk cache lookup by track key
    final cacheKey = _trackCacheKey(track);
    final diskCached = await _findExistingCachedFile(cacheKey);
    if (diskCached != null) return diskCached;

    // Short-circuit repeated negative lookups when audio file hasn't changed
    final negativeKey = '${track.id}|${track.filePath ?? ''}';
    if (_negativeCache.contains(negativeKey)) {
      return null;
    }

    // Tiers 3 & 4: Resolve either embedded-first or folder-first per preference
    String? resolved;
    if (preference == ArtworkSourcePreference.preferFolderAndDownloaded) {
      resolved = await _resolveFolderCover(track.filePath, cacheKey);
      resolved ??= await _resolveEmbeddedOrNative(
        track,
        cacheKey: cacheKey,
        mediaStoreAlbumId: mediaStoreAlbumId,
        maxSize: maxSize,
        preferEmbedded: false,
      );
    } else {
      resolved = await _resolveEmbeddedOrNative(
        track,
        cacheKey: cacheKey,
        mediaStoreAlbumId: mediaStoreAlbumId,
        maxSize: maxSize,
        preferEmbedded: true,
      );
      resolved ??= await _resolveFolderCover(track.filePath, cacheKey);
    }

    if (resolved == null) {
      _negativeCache.add(negativeKey);
    } else if (_onTrackArtworkResolved != null && resolved != track.artworkUri) {
      unawaited(_onTrackArtworkResolved(track, resolved).catchError((_) {}));
    }
    return resolved;
  }

  @override
  Future<String?> resolveAlbumArtwork(
    Album album, {
    List<Track> tracks = const [],
    ArtworkSourcePreference preference = ArtworkSourcePreference.preferEmbedded,
  }) async {
    final existingUri = album.artworkUri;
    if (existingUri != null && existingUri.isNotEmpty) {
      if (existingUri.startsWith('http://') || existingUri.startsWith('https://')) {
        return existingUri;
      }
      final file = File(_stripFileScheme(existingUri));
      if (await _isValidCachedImageFile(file)) {
        return file.path;
      }
    }

    final albumKey = 'alb_${album.id}';
    final cachedAlbum = await _findExistingCachedFile(albumKey);
    if (cachedAlbum != null) {
      if (_onAlbumArtworkResolved != null && cachedAlbum != album.artworkUri) {
        unawaited(_onAlbumArtworkResolved(album, cachedAlbum).catchError((_) {}));
      }
      return cachedAlbum;
    }

    for (final track in tracks) {
      final trackArt = await resolveTrackArtwork(
        track,
        preference: preference,
      );
      if (trackArt != null) {
        if (_onAlbumArtworkResolved != null && trackArt != album.artworkUri) {
          unawaited(_onAlbumArtworkResolved(album, trackArt).catchError((_) {}));
        }
        return trackArt;
      }
    }
    return null;
  }

  Future<String?> _findValidOverride(String trackId) async {
    final overridesDir = await _overridesDir();
    final safeId = _sanitizeKey(trackId);
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp', '']) {
      final candidate = File(p.join(overridesDir.path, '$safeId$ext'));
      if (await _isValidCachedImageFile(candidate)) {
        return candidate.path;
      }
    }
    return null;
  }

  Future<String?> _findExistingCachedFile(String cacheKey) async {
    final withExt = File(await _buildCacheFilePath(cacheKey, withoutExtension: false));
    if (await _isValidCachedImageFile(withExt)) return withExt.path;

    final withoutExt = File(await _buildCacheFilePath(cacheKey, withoutExtension: true));
    if (await _isValidCachedImageFile(withoutExt)) return withoutExt.path;
    return null;
  }

  Future<String?> _resolveEmbeddedOrNative(
    Track track, {
    required String cacheKey,
    int? mediaStoreAlbumId,
    required int maxSize,
    required bool preferEmbedded,
  }) async {
    final outputPath = await _buildCacheFilePath(cacheKey);
    final extractor = _nativeExtractor;
    if (extractor != null) {
      final nativePath = await extractor(
        filePath: track.filePath,
        outputPath: outputPath,
        albumId: mediaStoreAlbumId,
        maxSize: maxSize,
        preferEmbedded: preferEmbedded,
      );
      if (nativePath != null) {
        final f = File(nativePath);
        if (await _isValidCachedImageFile(f)) {
          return f.path;
        }
      }
    }

    // Pure-Dart off-UI extraction fallback (handles Linux/desktop & unit tests cleanly)
    final filePath = track.filePath;
    if (filePath == null || filePath.isEmpty) return null;
    final audioFile = File(filePath);
    if (!await audioFile.exists()) return null;

    try {
      final statSize = await audioFile.length();
      // Guard memory on Kirin 710F: never read huge 500MB WAV/FLAC entirely into RAM for cover art
      if (statSize < 12 || statSize > 32 * 1024 * 1024) return null;

      final Uint8List? artBytes = await _extractPureDartIsolate(
        audioFile.path,
        _metadataReader,
      );
      if (artBytes != null &&
          PureDartAudioMetadataReader.hasValidImageSignature(artBytes)) {
        return cacheExtractedBytes(cacheKey, artBytes);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  static Future<Uint8List?> _extractPureDartIsolate(
    String path,
    IAudioMetadataReader reader,
  ) async {
    final file = File(path);
    // Run inside an isolate for large files when reader is stateless const PureDartAudioMetadataReader
    if (reader is PureDartAudioMetadataReader) {
      return compute(_isolateReadEmbeddedArtwork, path);
    }
    final meta = await reader.extract(file);
    return meta.artworkBytes;
  }

  static Future<Uint8List?> _isolateReadEmbeddedArtwork(String path) async {
    try {
      final file = File(path);
      final meta = await const PureDartAudioMetadataReader().extract(file);
      return meta.artworkBytes;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveFolderCover(String? trackFilePath, String cacheKey) async {
    if (trackFilePath == null || trackFilePath.isEmpty) return null;
    final parentDir = File(trackFilePath).parent;
    if (!await parentDir.exists()) return null;

    try {
      final entries = await parentDir.list(followLinks: false).toList();
      final filesByLowerName = <String, File>{};
      for (final entity in entries) {
        if (entity is File) {
          filesByLowerName[p.basename(entity.path).toLowerCase()] = entity;
        }
      }

      for (final baseName in folderCoverCandidates) {
        for (final ext in ['.jpg', '.jpeg', '.png', '.webp']) {
          final candidate = filesByLowerName['$baseName$ext'];
          if (candidate != null && await _isValidCachedImageFile(candidate)) {
            final bytes = await candidate.readAsBytes();
            final cached = await cacheExtractedBytes(cacheKey, bytes);
            return cached ?? candidate.path;
          }
        }
      }

      // Secondary pass: accept any single cover-looking image file if exact names absent
      for (final entry in filesByLowerName.entries) {
        final ext = p.extension(entry.key);
        if (_supportedImageExtensions.contains(ext) &&
            (entry.key.contains('cover') ||
                entry.key.contains('front') ||
                entry.key.contains('album'))) {
          if (await _isValidCachedImageFile(entry.value)) {
            final bytes = await entry.value.readAsBytes();
            final cached = await cacheExtractedBytes(cacheKey, bytes);
            return cached ?? entry.value.path;
          }
        }
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  @override
  Future<String?> cacheExtractedBytes(
    String cacheKey,
    Uint8List artworkBytes, {
    bool saveWithoutExtension = false,
  }) async {
    if (!PureDartAudioMetadataReader.hasValidImageSignature(artworkBytes)) {
      return null;
    }
    try {
      final outputPath = await _buildCacheFilePath(
        cacheKey,
        withoutExtension: saveWithoutExtension || _saveWithoutExtension,
      );
      final target = File(outputPath);
      final tmp = File('$outputPath.tmp');
      await tmp.writeAsBytes(artworkBytes, flush: true);
      if (await target.exists()) {
        await target.delete();
      }
      await tmp.rename(target.path);
      return target.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> saveCustomOverride(String trackId, Uint8List imageBytes) async {
    if (!PureDartAudioMetadataReader.hasValidImageSignature(imageBytes)) {
      return null;
    }
    try {
      await clearCustomOverride(trackId);
      final dir = await _overridesDir();
      final outPath = p.join(dir.path, '${_sanitizeKey(trackId)}.jpg');
      final tmp = File('$outPath.tmp');
      await tmp.writeAsBytes(imageBytes, flush: true);
      final target = await tmp.rename(outPath);
      _negativeCache.removeWhere((k) => k.startsWith('$trackId|'));
      return target.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> clearCustomOverride(String trackId) async {
    final dir = await _overridesDir();
    final safeId = _sanitizeKey(trackId);
    for (final ext in ['.jpg', '.jpeg', '.png', '.webp', '']) {
      final candidate = File(p.join(dir.path, '$safeId$ext'));
      if (await candidate.exists()) {
        await candidate.delete();
      }
    }
  }

  @override
  Future<void> clearCache() async {
    _negativeCache.clear();
    _inFlight.clear();
    final dir = await _cacheDir();
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File) {
          await entity.delete();
        }
      }
    }
  }

  Future<bool> _isValidCachedImageFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final len = await file.length();
      if (len < 12) return false;
      final headerBytes = await file.openRead(0, 12).fold<List<int>>(
            [],
            (prev, chunk) => prev..addAll(chunk),
          );
      return PureDartAudioMetadataReader.hasValidImageSignature(
        Uint8List.fromList(headerBytes),
      );
    } catch (_) {
      return false;
    }
  }

  String _stripFileScheme(String uri) =>
      uri.startsWith('file://') ? uri.substring(7) : uri;
}
