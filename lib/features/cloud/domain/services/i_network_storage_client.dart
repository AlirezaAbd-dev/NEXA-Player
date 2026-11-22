import '../models/network_server_config.dart';
import '../models/remote_media_item.dart';

/// Contract for browsing remote directories and streaming music from network storage servers.
abstract interface class INetworkStorageClient {
  /// Tests network reachability and authentication with the given [server] configuration.
  Future<bool> testConnection(NetworkServerConfig server);

  /// Lists directory contents at [remotePath] on the target [server].
  Future<List<RemoteMediaItem>> listDirectory({
    required NetworkServerConfig server,
    required String remotePath,
  });

  /// Resolves an authenticated HTTP/HTTPS streaming URL for the target [item].
  String getStreamUrl({
    required NetworkServerConfig server,
    required RemoteMediaItem item,
  });

  /// Resolves authentication headers (e.g. Basic Auth or Bearer) required to stream [item].
  Map<String, String> getAuthHeaders(NetworkServerConfig server);
}
