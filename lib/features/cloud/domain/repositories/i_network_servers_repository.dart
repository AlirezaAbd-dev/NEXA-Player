import '../models/network_server_config.dart';

/// Contract for persistent storage and retrieval of user-configured network servers and cloud drives.
abstract interface class INetworkServersRepository {
  /// Retrieves all configured network storage servers.
  Future<List<NetworkServerConfig>> getServers();

  /// Reactive stream emitting server configuration changes.
  Stream<List<NetworkServerConfig>> watchServers();

  /// Adds or updates a network server profile.
  Future<void> saveServer(NetworkServerConfig server);

  /// Deletes a network server profile by [id].
  Future<void> deleteServer(String id);

  /// Retrieves a specific server configuration by [id], or null if not found.
  Future<NetworkServerConfig?> getServerById(String id);
}
