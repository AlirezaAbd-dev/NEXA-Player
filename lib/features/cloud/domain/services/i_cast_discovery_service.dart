import '../models/cast_device.dart';

/// Contract for scanning local network subnets to discover media casting renderers.
abstract interface class ICastDiscoveryService {
  /// Reactive stream emitting newly discovered and updated casting devices.
  Stream<List<CastDevice>> get devicesStream;

  /// Current snapshot of discovered casting receivers.
  List<CastDevice> get currentDevices;

  /// Starts active SSDP M-SEARCH broadcast over local network interfaces.
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 5)});

  /// Halts active socket discovery listening.
  Future<void> stopDiscovery();

  /// Releases network sockets and broadcast controllers.
  Future<void> dispose();
}
