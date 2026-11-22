import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/cloud/cloud.dart';

void main() {
  group('NetworkCacheManagerImpl Tests', () {
    late Directory tempDir;
    late NetworkCacheManagerImpl cacheManager;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('nexa_cache_test_');
      cacheManager = NetworkCacheManagerImpl(customCacheDir: tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('Calculates zero cache size on empty directory', () async {
      final size = await cacheManager.getCurrentCacheSizeBytes();
      expect(size, 0);
    });

    test('Detects missing cache and handles removal gracefully', () async {
      const item = RemoteMediaItem(
        id: 'track_test_1',
        serverId: 's1',
        name: 'test.flac',
        remotePath: '/test.flac',
      );

      final cachedPath = await cacheManager.getCachedPath(item);
      expect(cachedPath, isNull);

      final removed = await cacheManager.removeCachedTrack('non_existent');
      expect(removed, isFalse);
    });

    test('Clears all cache files and enforces quota', () async {
      final cacheSubdir = Directory('${tempDir.path}/nexa_network_cache');
      await cacheSubdir.create(recursive: true);

      // Create dummy files
      final file1 = File('${cacheSubdir.path}/cache_1.flac');
      await file1.writeAsBytes(List.filled(1024 * 1024, 0)); // 1 MB

      final file2 = File('${cacheSubdir.path}/cache_2.flac');
      await file2.writeAsBytes(List.filled(1024 * 1024, 0)); // 1 MB

      final initialSize = await cacheManager.getCurrentCacheSizeBytes();
      expect(initialSize, 2 * 1024 * 1024);

      // Enforce quota of 1 MB (should trim oldest)
      await cacheManager.enforceQuota(1);
      final trimmedSize = await cacheManager.getCurrentCacheSizeBytes();
      expect(trimmedSize, lessThanOrEqualTo(1024 * 1024));

      // Clear all
      await cacheManager.clearAllCache();
      final clearedSize = await cacheManager.getCurrentCacheSizeBytes();
      expect(clearedSize, 0);
    });
  });
}
