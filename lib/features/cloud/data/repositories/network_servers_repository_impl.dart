import 'dart:async';
import 'dart:convert';
import '../../../../core/constants/storage_keys.dart';
import '../../../../shared/services/storage/storage_service.dart';
import '../../domain/models/network_server_config.dart';
import '../../domain/repositories/i_network_servers_repository.dart';

/// Concrete implementation of [INetworkServersRepository] persisting remote endpoints to [IStorageService].
class NetworkServersRepositoryImpl implements INetworkServersRepository {
  NetworkServersRepositoryImpl({required IStorageService storageService})
      : _storageService = storageService {
    _init();
  }

  final IStorageService _storageService;
  final StreamController<List<NetworkServerConfig>> _controller =
      StreamController<List<NetworkServerConfig>>.broadcast();

  List<NetworkServerConfig> _cachedServers = [];

  void _init() {
    final rawJson = _storageService.getString(StorageKeys.networkServersList).valueOrNull;
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        _cachedServers = decoded
            .map((item) => NetworkServerConfig.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cachedServers = _getDefaultDemoServers();
      }
    } else {
      _cachedServers = _getDefaultDemoServers();
      _persist();
    }
  }

  List<NetworkServerConfig> _getDefaultDemoServers() {
    return [
      const NetworkServerConfig(
        id: 'nexa_demo_synology',
        name: 'Synology DiskStation (Master Vault)',
        type: NetworkServerType.webdav,
        host: 'demo.nexa.local',
        port: 5006,
        path: '/music',
        trackCount: 24,
      ),
      const NetworkServerConfig(
        id: 'nexa_demo_nextcloud',
        name: 'Nextcloud Audiophile Cloud',
        type: NetworkServerType.nextcloud,
        host: 'demo.nexa.local',
        port: 443,
        path: '/remote.php/dav/files/user/Music',
        trackCount: 42,
      ),
    ];
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_cachedServers.map((s) => s.toJson()).toList());
    await _storageService.setString(StorageKeys.networkServersList, encoded);
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_cachedServers));
    }
  }

  @override
  Future<List<NetworkServerConfig>> getServers() async {
    return List.unmodifiable(_cachedServers);
  }

  @override
  Stream<List<NetworkServerConfig>> watchServers() async* {
    yield List.unmodifiable(_cachedServers);
    yield* _controller.stream;
  }

  @override
  Future<void> saveServer(NetworkServerConfig server) async {
    final index = _cachedServers.indexWhere((s) => s.id == server.id);
    if (index >= 0) {
      _cachedServers[index] = server;
    } else {
      _cachedServers.add(server);
    }
    await _persist();
  }

  @override
  Future<void> deleteServer(String id) async {
    _cachedServers.removeWhere((s) => s.id == id);
    await _persist();
  }

  @override
  Future<NetworkServerConfig?> getServerById(String id) async {
    try {
      return _cachedServers.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  void dispose() {
    _controller.close();
  }
}
