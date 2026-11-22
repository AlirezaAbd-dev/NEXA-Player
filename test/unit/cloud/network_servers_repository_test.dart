import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/cloud/cloud.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

class InMemoryStorageService implements IStorageService {
  final Map<String, dynamic> _data = {};

  @override
  Future<Result<void, StorageFailure>> setString(String key, String value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Result<String?, StorageFailure> getString(String key) {
    return Result.success(_data[key] as String?);
  }

  @override
  Future<Result<void, StorageFailure>> setBool(String key, bool value) async {
    _data[key] = value;
    return const Result.success(null);
  }

  @override
  Result<bool?, StorageFailure> getBool(String key) {
    return Result.success(_data[key] as bool?);
  }

  @override
  Future<Result<void, StorageFailure>> remove(String key) async {
    _data.remove(key);
    return const Result.success(null);
  }

  @override
  Future<Result<void, StorageFailure>> clear() async {
    _data.clear();
    return const Result.success(null);
  }
}

void main() {
  group('NetworkServersRepositoryImpl Tests', () {
    late InMemoryStorageService storage;
    late NetworkServersRepositoryImpl repo;

    setUp(() {
      storage = InMemoryStorageService();
      repo = NetworkServersRepositoryImpl(storageService: storage);
    });

    tearDown(() {
      repo.dispose();
    });

    test('Initializes with default demo servers if storage is empty', () async {
      final servers = await repo.getServers();
      expect(servers, isNotEmpty);
      expect(servers.any((s) => s.id == 'nexa_demo_synology'), isTrue);
    });

    test('Saves new server and updates existing', () async {
      const newServer = NetworkServerConfig(
        id: 'nas_custom',
        name: 'Custom TrueNAS Vault',
        host: '192.168.1.99',
        type: NetworkServerType.webdav,
      );

      await repo.saveServer(newServer);
      final list = await repo.getServers();
      expect(list.any((s) => s.id == 'nas_custom'), isTrue);

      final fetched = await repo.getServerById('nas_custom');
      expect(fetched?.name, 'Custom TrueNAS Vault');

      // Update
      final updated = newServer.copyWith(name: 'Updated TrueNAS');
      await repo.saveServer(updated);
      final refetched = await repo.getServerById('nas_custom');
      expect(refetched?.name, 'Updated TrueNAS');
    });

    test('Deletes server correctly', () async {
      final initial = await repo.getServers();
      final idToDelete = initial.first.id;

      await repo.deleteServer(idToDelete);
      final remaining = await repo.getServers();
      expect(remaining.any((s) => s.id == idToDelete), isFalse);
    });
  });
}
