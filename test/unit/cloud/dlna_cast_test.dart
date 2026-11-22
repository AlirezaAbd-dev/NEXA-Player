import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/cloud/cloud.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  group('UpnpSsdpDiscoveryService Tests', () {
    late UpnpSsdpDiscoveryService discovery;

    setUp(() {
      discovery = UpnpSsdpDiscoveryService(enableMockFallbacks: true);
    });

    tearDown(() async {
      await discovery.dispose();
    });

    test('Loads default mock renderers when discovery starts', () async {
      expect(discovery.currentDevices, isEmpty);

      await discovery.startDiscovery(timeout: const Duration(milliseconds: 50));
      expect(discovery.currentDevices.length, greaterThanOrEqualTo(2));
      expect(
        discovery.currentDevices.any((d) => d.id == 'nexa_cast_living_room'),
        isTrue,
      );
    });

    test('Allows manually registering custom renderers', () async {
      const customDevice = CastDevice(
        id: 'office_hi_fi',
        name: 'Office Marantz SACD',
        host: '192.168.1.200',
        port: 1900,
        serviceType: CastServiceType.dlna,
      );

      discovery.registerDevice(customDevice);
      expect(discovery.currentDevices.any((d) => d.id == 'office_hi_fi'), isTrue);
    });
  });

  group('DlnaAvTransportController Tests', () {
    late DlnaAvTransportController controller;

    setUp(() {
      controller = DlnaAvTransportController();
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('Connects to target device and sets status to connected', () async {
      const device = CastDevice(
        id: 'speaker_1',
        name: 'Denon AVR',
        host: '192.168.1.155',
      );

      final success = await controller.connect(device);
      expect(success, isTrue);
      expect(controller.state.connectedDevice?.id, 'speaker_1');
      expect(controller.state.status, CastPlaybackStatus.connected);
    });

    test('playTrack updates playback state and manages transport', () async {
      const device = CastDevice(
        id: 'speaker_1',
        name: 'Denon AVR',
        host: '192.168.1.155',
      );
      await controller.connect(device);

      const track = Track(
        id: 'track_1',
        title: 'Lossless Symphony',
        artist: 'Beethoven',
        duration: Duration(minutes: 6),
        filePath: 'http://192.168.1.100/song.flac',
      );

      await controller.playTrack(track);
      expect(controller.state.status, CastPlaybackStatus.playing);
      expect(controller.state.currentTrack?.title, 'Lossless Symphony');

      await controller.pause();
      expect(controller.state.status, CastPlaybackStatus.paused);

      await controller.play();
      expect(controller.state.status, CastPlaybackStatus.playing);

      await controller.seek(const Duration(seconds: 45));
      expect(controller.state.position, const Duration(seconds: 45));

      controller.setVolume(0.75);
      expect(controller.state.volume, 0.75);

      await controller.stop();
      expect(controller.state.status, CastPlaybackStatus.stopped);

      await controller.disconnect();
      expect(controller.state.status, CastPlaybackStatus.disconnected);
      expect(controller.state.connectedDevice, isNull);
    });
  });
}
