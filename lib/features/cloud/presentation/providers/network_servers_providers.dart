import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/di/service_providers.dart';
import '../../data/repositories/network_servers_repository_impl.dart';
import '../../data/services/network_cache_manager_impl.dart';
import '../../data/services/webdav_storage_client.dart';
import '../../domain/models/network_server_config.dart';
import '../../domain/models/remote_media_item.dart';
import '../../domain/repositories/i_network_servers_repository.dart';
import '../../domain/services/i_network_cache_manager.dart';
import '../../domain/services/i_network_storage_client.dart';

/// Provides network storage client for WebDAV and HTTP endpoints.
final networkStorageClientProvider = Provider<INetworkStorageClient>((ref) {
  return WebdavStorageClient();
});

/// Provides local LRU disk cache manager for streamed audio.
final networkCacheManagerProvider = Provider<INetworkCacheManager>((ref) {
  return NetworkCacheManagerImpl();
});

/// Provides repository for persisting remote server endpoints.
final networkServersRepositoryProvider = Provider<INetworkServersRepository>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final repo = NetworkServersRepositoryImpl(storageService: storage);
  ref.onDispose(() {
    repo.dispose();
  });
  return repo;
});

/// Reactive stream of configured network servers.
final networkServersListProvider = StreamProvider<List<NetworkServerConfig>>((ref) {
  final repo = ref.watch(networkServersRepositoryProvider);
  return repo.watchServers();
});

/// Currently selected server for remote browsing.
final selectedServerIdProvider = StateProvider<String?>((ref) => null);

/// Current browsing directory path on the selected server.
final currentRemotePathProvider = StateProvider<String>((ref) => '/');

/// Parameter tuple for fetching remote directory items.
typedef DirectoryQueryParams = ({NetworkServerConfig server, String path});

/// Asynchronously fetches contents of a remote directory.
final remoteDirectoryItemsProvider =
    FutureProvider.family<List<RemoteMediaItem>, DirectoryQueryParams>(
        (ref, params) async {
  final client = ref.watch(networkStorageClientProvider);
  return client.listDirectory(server: params.server, remotePath: params.path);
});

/// Asynchronously calculates current disk cache usage in bytes.
final networkCacheSizeBytesProvider = FutureProvider<int>((ref) async {
  final cacheManager = ref.watch(networkCacheManagerProvider);
  return cacheManager.getCurrentCacheSizeBytes();
});
