import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/cloud/cloud.dart';

void main() {
  group('NetworkServerConfig Model Tests', () {
    test('Constructs default baseUri correctly for HTTPS and custom ports', () {
      const configSsl = NetworkServerConfig(
        id: 'nas_1',
        name: 'Synology NAS',
        host: '192.168.1.150',
        port: 443,
        path: '/music',
        useSsl: true,
      );
      expect(configSsl.baseUri.toString(), 'https://192.168.1.150/music');

      const configCustomPort = NetworkServerConfig(
        id: 'nas_2',
        name: 'TrueNAS',
        host: 'nas.home.local',
        port: 5006,
        path: 'audio/flac',
        useSsl: true,
      );
      expect(configCustomPort.baseUri.toString(), 'https://nas.home.local:5006/audio/flac');

      const configHttp = NetworkServerConfig(
        id: 'nas_3',
        name: 'OpenWrt Samba',
        host: '192.168.1.1',
        port: 8080,
        path: '/shares/music',
        useSsl: false,
      );
      expect(configHttp.baseUri.toString(), 'http://192.168.1.1:8080/shares/music');
    });

    test('Serializes to and from JSON losslessly', () {
      final original = NetworkServerConfig(
        id: 'srv_test',
        name: 'Master Vault',
        type: NetworkServerType.nextcloud,
        host: 'cloud.nexa.audio',
        port: 8443,
        path: '/remote.php/webdav/Music',
        username: 'audiophile',
        password: 'secret_password_123',
        useSsl: true,
        isActive: true,
        lastConnected: DateTime(2026, 11, 22, 18, 30),
        trackCount: 1540,
      );

      final json = original.toJson();
      final reconstructed = NetworkServerConfig.fromJson(json);

      expect(reconstructed.id, original.id);
      expect(reconstructed.name, original.name);
      expect(reconstructed.type, NetworkServerType.nextcloud);
      expect(reconstructed.host, original.host);
      expect(reconstructed.port, original.port);
      expect(reconstructed.username, original.username);
      expect(reconstructed.password, original.password);
      expect(reconstructed.useSsl, true);
      expect(reconstructed.trackCount, 1540);
    });

    test('copyWith updates specified fields correctly', () {
      const original = NetworkServerConfig(
        id: 'srv_1',
        name: 'Initial Name',
        host: '10.0.0.1',
      );

      final updated = original.copyWith(name: 'Updated Name', port: 5005);
      expect(updated.name, 'Updated Name');
      expect(updated.port, 5005);
      expect(updated.host, '10.0.0.1');
    });
  });

  group('RemoteMediaItem Model Tests', () {
    test('Correctly extracts audio file extensions', () {
      const flacItem = RemoteMediaItem(
        id: '1',
        serverId: 's1',
        name: '01 - Track.FLAC',
        remotePath: '/music/01 - Track.FLAC',
      );
      expect(flacItem.fileExtension, 'flac');

      const dsdItem = RemoteMediaItem(
        id: '2',
        serverId: 's1',
        name: 'Symphony_No_9.DSF',
        remotePath: '/music/Symphony_No_9.DSF',
      );
      expect(dsdItem.fileExtension, 'dsf');

      const folderItem = RemoteMediaItem(
        id: '3',
        serverId: 's1',
        name: 'FLAC Albums',
        remotePath: '/music/FLAC Albums',
        isDirectory: true,
      );
      expect(folderItem.fileExtension, '');
    });

    test('toTrack maps remote item into executable Track entity', () {
      const item = RemoteMediaItem(
        id: 'track_101',
        serverId: 'srv_master',
        name: '04 - Celestial Dream.wav',
        remotePath: '/HiRes/04 - Celestial Dream.wav',
        title: 'Celestial Dream',
        artist: 'Aurora Sound',
        album: 'Astral Echoes',
        duration: Duration(minutes: 5, seconds: 12),
        sizeBytes: 88400100,
      );

      final track = item.toTrack(streamUrl: 'https://nas.local/HiRes/04.wav');
      expect(track.id, 'track_101');
      expect(track.title, 'Celestial Dream');
      expect(track.artist, 'Aurora Sound');
      expect(track.album, 'Astral Echoes');
      expect(track.filePath, 'https://nas.local/HiRes/04.wav');
      expect(track.fileSize, 88400100);
      expect(track.duration, const Duration(minutes: 5, seconds: 12));
    });

    test('toTrack prefers cachedLocalPath when isCached is true', () {
      const item = RemoteMediaItem(
        id: 'track_cached',
        serverId: 'srv_master',
        name: 'Cached Song.flac',
        remotePath: '/Music/Cached Song.flac',
        isCached: true,
        cachedLocalPath: '/data/user/0/cache/cache_123.flac',
      );

      final track = item.toTrack(streamUrl: 'https://nas.local/Music/Cached.flac');
      expect(track.filePath, '/data/user/0/cache/cache_123.flac');
    });
  });

  group('CastDevice & CastPlaybackState Tests', () {
    test('CastDevice JSON and equality', () {
      const dev = CastDevice(
        id: 'sonos_kitchen',
        name: 'Kitchen Sonos Era 300',
        host: '192.168.1.180',
        port: 1400,
        serviceType: CastServiceType.dlna,
        manufacturer: 'Sonos',
      );

      final json = dev.toJson();
      final fromJson = CastDevice.fromJson(json);

      expect(fromJson.id, 'sonos_kitchen');
      expect(fromJson.name, 'Kitchen Sonos Era 300');
      expect(fromJson.serviceType, CastServiceType.dlna);
      expect(fromJson.manufacturer, 'Sonos');
    });

    test('CastPlaybackState computed getters and status', () {
      const state = CastPlaybackState(
        connectedDevice: CastDevice(
          id: 'dev_1',
          name: 'Living Room Hi-Fi',
          host: '192.168.1.150',
        ),
        status: CastPlaybackStatus.playing,
      );

      expect(state.isCasting, true);
      expect(state.isPlaying, true);

      final paused = state.copyWith(status: CastPlaybackStatus.paused);
      expect(paused.isCasting, true);
      expect(paused.isPlaying, false);

      final disconnected = state.copyWith(status: CastPlaybackStatus.disconnected);
      expect(disconnected.isCasting, false);
    });
  });

  group('CloudStreamingSettings Tests', () {
    test('Default settings and JSON serialization', () {
      const settings = CloudStreamingSettings();
      expect(settings.maxCacheMb, 1024);
      expect(settings.autoDiscoverCast, true);
      expect(settings.losslessStreaming, true);

      final json = settings.toJson();
      final parsed = CloudStreamingSettings.fromJson(json);
      expect(parsed.maxCacheMb, 1024);
      expect(parsed.autoDiscoverCast, true);
    });
  });
}
