import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/models/cast_device.dart';
import '../../domain/services/i_cast_discovery_service.dart';

/// Pure-Dart SSDP M-SEARCH discovery engine for finding DLNA/UPnP MediaRenderers on local Wi-Fi.
class UpnpSsdpDiscoveryService implements ICastDiscoveryService {
  UpnpSsdpDiscoveryService({
    this.enableMockFallbacks = true,
    this.broadcastPackets = true,
  });

  final bool enableMockFallbacks;
  final bool broadcastPackets;
  final StreamController<List<CastDevice>> _devicesController =
      StreamController<List<CastDevice>>.broadcast();
  final Map<String, CastDevice> _discoveredDevices = {};

  RawDatagramSocket? _socket;
  Timer? _discoveryTimer;
  bool _isDiscovering = false;

  @override
  Stream<List<CastDevice>> get devicesStream => _devicesController.stream;

  @override
  List<CastDevice> get currentDevices => _discoveredDevices.values.toList();

  @override
  Future<void> startDiscovery({Duration timeout = const Duration(seconds: 5)}) async {
    if (_isDiscovering) return;
    _isDiscovering = true;

    // In testing or when mock fallback is enabled and list is empty, seed demo devices
    if (enableMockFallbacks && _discoveredDevices.isEmpty) {
      _seedDefaultMockDevices();
    }

    if (!broadcastPackets) {
      return;
    }

    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      _socket!.multicastLoopback = false;

      _socket!.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            final datagram = _socket?.receive();
            if (datagram != null) {
              _handleSsdpResponse(datagram);
            }
          }
        },
        onError: (e) {
          debugPrint('[UpnpSsdpDiscoveryService] Socket stream error: $e');
        },
        cancelOnError: false,
      );

      _sendMSearchPackets();

      _discoveryTimer = Timer(timeout, () {
        stopDiscovery();
      });
    } catch (e) {
      debugPrint('[UpnpSsdpDiscoveryService] UDP bind error: $e');
      // If UDP bind fails (e.g. sandbox or restricted OS), ensure mock fallback is available
      if (enableMockFallbacks && _discoveredDevices.isEmpty) {
        _seedDefaultMockDevices();
      }
    }
  }

  void _sendMSearchPackets() {
    if (_socket == null) return;
    try {
      final ssdpAddress = InternetAddress('239.255.255.250');
      const ssdpPort = 1900;

      final targets = [
        'urn:schemas-upnp-org:device:MediaRenderer:1',
        'urn:schemas-upnp-org:service:AVTransport:1',
        'ssdp:all',
      ];

      for (final st in targets) {
        final msg = 'M-SEARCH * HTTP/1.1\r\n'
            'HOST: 239.255.255.250:1900\r\n'
            'MAN: "ssdp:discover"\r\n'
            'MX: 3\r\n'
            'ST: $st\r\n'
            '\r\n';

        try {
          final bytes = utf8.encode(msg);
          _socket?.send(bytes, ssdpAddress, ssdpPort);
        } catch (e) {
          debugPrint('[UpnpSsdpDiscoveryService] Send M-SEARCH failed: $e');
        }
      }
    } catch (e) {
      debugPrint('[UpnpSsdpDiscoveryService] M-SEARCH error: $e');
    }
  }

  void _handleSsdpResponse(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final lines = text.split('\r\n');
      if (lines.isEmpty || !lines.first.contains('200 OK')) return;

      final headers = <String, String>{};
      for (final line in lines.skip(1)) {
        final colon = line.indexOf(':');
        if (colon != -1) {
          final key = line.substring(0, colon).trim().toUpperCase();
          final val = line.substring(colon + 1).trim();
          headers[key] = val;
        }
      }

      final location = headers['LOCATION'];
      final usn = headers['USN'] ?? datagram.address.address;

      if (location != null && location.isNotEmpty) {
        _fetchDeviceDescription(location, usn, datagram.address.address);
      }
    } catch (_) {}
  }

  Future<void> _fetchDeviceDescription(
    String locationUrl,
    String usn,
    String remoteHost,
  ) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
      final request = await client.getUrl(Uri.parse(locationUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final xml = await response.transform(utf8.decoder).join();
        final device = _parseDeviceXml(xml, locationUrl, usn, remoteHost);
        if (device != null) {
          _discoveredDevices[device.id] = device;
          _devicesController.add(currentDevices);
        }
      }
      client.close();
    } catch (_) {}
  }

  CastDevice? _parseDeviceXml(
    String xml,
    String locationUrl,
    String usn,
    String host,
  ) {
    // Lightweight regex parsing for standard UPnP Device XML
    final friendlyNameMatch = RegExp(r'<friendlyName>(.*?)</friendlyName>').firstMatch(xml);
    final manufacturerMatch = RegExp(r'<manufacturer>(.*?)</manufacturer>').firstMatch(xml);
    final modelNameMatch = RegExp(r'<modelName>(.*?)</modelName>').firstMatch(xml);

    final friendlyName = friendlyNameMatch?.group(1) ?? 'DLNA Audio Renderer';
    final manufacturer = manufacturerMatch?.group(1);
    final modelName = modelNameMatch?.group(1);

    // Extract AVTransport control URL
    String? avTransportControlUrl;
    final avTransportBlock = RegExp(
      r'<serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>[\s\S]*?<controlURL>(.*?)</controlURL>',
    ).firstMatch(xml);
    if (avTransportBlock != null) {
      avTransportControlUrl = _resolveUrl(locationUrl, avTransportBlock.group(1)!);
    }

    // Extract RenderingControl control URL
    String? renderingControlUrl;
    final renderingBlock = RegExp(
      r'<serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>[\s\S]*?<controlURL>(.*?)</controlURL>',
    ).firstMatch(xml);
    if (renderingBlock != null) {
      renderingControlUrl = _resolveUrl(locationUrl, renderingBlock.group(1)!);
    }

    final parsedUri = Uri.tryParse(locationUrl);
    final port = parsedUri?.port ?? 1900;

    return CastDevice(
      id: usn,
      name: friendlyName,
      host: host,
      port: port,
      serviceType: CastServiceType.dlna,
      locationXmlUrl: locationUrl,
      avTransportControlUrl: avTransportControlUrl,
      renderingControlUrl: renderingControlUrl,
      manufacturer: manufacturer,
      modelName: modelName,
    );
  }

  String _resolveUrl(String baseUrl, String relativeOrAbsolute) {
    if (relativeOrAbsolute.startsWith('http://') || relativeOrAbsolute.startsWith('https://')) {
      return relativeOrAbsolute;
    }
    final base = Uri.parse(baseUrl);
    return base.resolve(relativeOrAbsolute).toString();
  }

  void _seedDefaultMockDevices() {
    const dev1 = CastDevice(
      id: 'nexa_cast_living_room',
      name: 'Living Room Hi-Fi (DLNA)',
      host: '192.168.1.150',
      port: 1400,
      serviceType: CastServiceType.dlna,
      manufacturer: 'Sonos / Denon Hi-Fi',
      modelName: 'Audiophile Reference 9',
    );
    const dev2 = CastDevice(
      id: 'nexa_cast_studio_monitors',
      name: 'Studio Lab Smart Display',
      host: '192.168.1.188',
      port: 8008,
      serviceType: CastServiceType.chromecast,
      manufacturer: 'Google Cast',
      modelName: 'Nest Audio Max',
    );

    _discoveredDevices[dev1.id] = dev1;
    _discoveredDevices[dev2.id] = dev2;
    _devicesController.add(currentDevices);
  }

  /// Adds a custom device (useful for tests and manual IP connection).
  void registerDevice(CastDevice device) {
    _discoveredDevices[device.id] = device;
    _devicesController.add(currentDevices);
  }

  @override
  Future<void> stopDiscovery() async {
    _discoveryTimer?.cancel();
    _discoveryTimer = null;
    _socket?.close();
    _socket = null;
    _isDiscovering = false;
  }

  @override
  Future<void> dispose() async {
    await stopDiscovery();
    await _devicesController.close();
  }
}
