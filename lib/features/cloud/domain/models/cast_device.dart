import 'package:equatable/equatable.dart';

/// Communication protocol used by the remote audio casting receiver.
enum CastServiceType {
  /// Universal Plug and Play / Digital Living Network Alliance AVTransport.
  dlna,

  /// Google Cast / Chromecast Audio protocol.
  chromecast,

  /// Mock network audio sink for testing and simulator environments.
  mock,
}

/// Represents an audio rendering target discovered on the local network.
class CastDevice extends Equatable {
  const CastDevice({
    required this.id,
    required this.name,
    required this.host,
    this.port = 1900,
    this.serviceType = CastServiceType.dlna,
    this.locationXmlUrl,
    this.avTransportControlUrl,
    this.renderingControlUrl,
    this.manufacturer,
    this.modelName,
    this.iconUrl,
    this.isConnected = false,
  });

  final String id;
  final String name;
  final String host;
  final int port;
  final CastServiceType serviceType;
  final String? locationXmlUrl;
  final String? avTransportControlUrl;
  final String? renderingControlUrl;
  final String? manufacturer;
  final String? modelName;
  final String? iconUrl;
  final bool isConnected;

  CastDevice copyWith({
    String? id,
    String? name,
    String? host,
    int? port,
    CastServiceType? serviceType,
    String? locationXmlUrl,
    String? avTransportControlUrl,
    String? renderingControlUrl,
    String? manufacturer,
    String? modelName,
    String? iconUrl,
    bool? isConnected,
  }) {
    return CastDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      host: host ?? this.host,
      port: port ?? this.port,
      serviceType: serviceType ?? this.serviceType,
      locationXmlUrl: locationXmlUrl ?? this.locationXmlUrl,
      avTransportControlUrl:
          avTransportControlUrl ?? this.avTransportControlUrl,
      renderingControlUrl: renderingControlUrl ?? this.renderingControlUrl,
      manufacturer: manufacturer ?? this.manufacturer,
      modelName: modelName ?? this.modelName,
      iconUrl: iconUrl ?? this.iconUrl,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'host': host,
        'port': port,
        'serviceType': serviceType.name,
        'locationXmlUrl': locationXmlUrl,
        'avTransportControlUrl': avTransportControlUrl,
        'renderingControlUrl': renderingControlUrl,
        'manufacturer': manufacturer,
        'modelName': modelName,
        'iconUrl': iconUrl,
        'isConnected': isConnected,
      };

  factory CastDevice.fromJson(Map<String, dynamic> json) => CastDevice(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'Network Audio Speaker',
        host: json['host'] as String? ?? '127.0.0.1',
        port: json['port'] as int? ?? 1900,
        serviceType: CastServiceType.values.firstWhere(
          (t) => t.name == (json['serviceType'] as String?),
          orElse: () => CastServiceType.dlna,
        ),
        locationXmlUrl: json['locationXmlUrl'] as String?,
        avTransportControlUrl: json['avTransportControlUrl'] as String?,
        renderingControlUrl: json['renderingControlUrl'] as String?,
        manufacturer: json['manufacturer'] as String?,
        modelName: json['modelName'] as String?,
        iconUrl: json['iconUrl'] as String?,
        isConnected: json['isConnected'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        host,
        port,
        serviceType,
        locationXmlUrl,
        avTransportControlUrl,
        renderingControlUrl,
        manufacturer,
        modelName,
        iconUrl,
        isConnected,
      ];
}
