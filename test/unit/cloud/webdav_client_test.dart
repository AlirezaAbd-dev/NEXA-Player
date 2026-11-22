import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/cloud/cloud.dart';

void main() {
  group('WebdavStorageClient Tests', () {
    late WebdavStorageClient client;

    setUp(() {
      client = WebdavStorageClient();
    });

    test('Generates authenticated stream URLs and basic auth headers', () {
      const server = NetworkServerConfig(
        id: 'srv_1',
        name: 'QNAP Vault',
        host: 'qnap.local',
        port: 8080,
        path: '/Music',
        username: 'audiophile',
        password: 'vault_password',
        useSsl: false,
      );

      const item = RemoteMediaItem(
        id: 'track_1',
        serverId: 'srv_1',
        name: '01 - Overture.flac',
        remotePath: '/Music/HiRes/01 - Overture.flac',
      );

      final streamUrl = client.getStreamUrl(server: server, item: item);
      expect(
        streamUrl,
        'http://audiophile:vault_password@qnap.local:8080/Music/HiRes/01%20-%20Overture.flac',
      );

      final headers = client.getAuthHeaders(server);
      expect(headers['Authorization'], startsWith('Basic '));
    });

    test('Returns mock directory structure for demo servers', () async {
      const demoServer = NetworkServerConfig(
        id: 'demo_srv',
        name: 'Demo Vault',
        host: 'demo.nexa.local',
        path: '/music',
      );

      final isReachable = await client.testConnection(demoServer);
      expect(isReachable, isTrue);

      final rootItems = await client.listDirectory(server: demoServer, remotePath: '/music');
      expect(rootItems, isNotEmpty);
      expect(rootItems.any((item) => item.isDirectory), isTrue);
      expect(rootItems.any((item) => !item.isDirectory), isTrue);

      final subItems = await client.listDirectory(
        server: demoServer,
        remotePath: '/music/Hi-Res DSD Master Vault',
      );
      expect(subItems.length, greaterThanOrEqualTo(2));
      expect(subItems.every((item) => !item.isDirectory), isTrue);
    });
  });
}
