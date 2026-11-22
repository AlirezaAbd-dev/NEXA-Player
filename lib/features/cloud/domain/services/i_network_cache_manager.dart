import '../models/remote_media_item.dart';

/// Contract for managing local LRU disk caching of streamed network tracks.
abstract interface class INetworkCacheManager {
  /// Checks whether [item] is currently stored on disk and returns the local file path if present.
  Future<String?> getCachedPath(RemoteMediaItem item);

  /// Downloads [item] from [streamUrl] into the local cache directory and returns the absolute local path.
  Future<String> cacheTrack({
    required RemoteMediaItem item,
    required String streamUrl,
    Map<String, String>? headers,
    void Function(double progress)? onProgress,
  });

  /// Deletes a specific cached file.
  Future<bool> removeCachedTrack(String itemId);

  /// Clears all files in the network streaming cache directory.
  Future<void> clearAllCache();

  /// Calculates total bytes consumed by the network streaming cache.
  Future<int> getCurrentCacheSizeBytes();

  /// Enforces maximum quota constraint by deleting oldest accessed cached tracks.
  Future<void> enforceQuota(int maxMegabytes);
}
