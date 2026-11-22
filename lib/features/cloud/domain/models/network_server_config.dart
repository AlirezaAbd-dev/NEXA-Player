import 'package:equatable/equatable.dart';

/// Supported protocols and cloud vendors for network audio streaming.
enum NetworkServerType {
  /// RFC 4918 Web Distributed Authoring and Versioning (Synology, QNAP, TrueNAS).
  webdav,

  /// Server Message Block / Samba local network file sharing.
  smb,

  /// Nextcloud / ownCloud self-hosted personal storage.
  nextcloud,

  /// Direct HTTP/HTTPS audio endpoint or Icecast/SHOUTcast stream.
  customHttp,
}

/// Authentication and endpoint profile for a network storage repository.
class NetworkServerConfig extends Equatable {
  const NetworkServerConfig({
    required this.id,
    required this.name,
    this.type = NetworkServerType.webdav,
    required this.host,
    this.port = 443,
    this.path = '/music',
    this.username,
    this.password,
    this.useSsl = true,
    this.isActive = true,
    this.lastConnected,
    this.trackCount = 0,
  });

  final String id;
  final String name;
  final NetworkServerType type;
  final String host;
  final int port;
  final String path;
  final String? username;
  final String? password;
  final bool useSsl;
  final bool isActive;
  final DateTime? lastConnected;
  final int trackCount;

  /// Builds a fully-qualified URI prefix for this server.
  Uri get baseUri {
    final scheme = useSsl ? 'https' : 'http';
    return Uri(
      scheme: scheme,
      host: host,
      port: port == (useSsl ? 443 : 80) ? null : port,
      path: path.startsWith('/') ? path : '/$path',
    );
  }

  NetworkServerConfig copyWith({
    String? id,
    String? name,
    NetworkServerType? type,
    String? host,
    int? port,
    String? path,
    String? username,
    String? password,
    bool? useSsl,
    bool? isActive,
    DateTime? lastConnected,
    int? trackCount,
  }) {
    return NetworkServerConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      host: host ?? this.host,
      port: port ?? this.port,
      path: path ?? this.path,
      username: username ?? this.username,
      password: password ?? this.password,
      useSsl: useSsl ?? this.useSsl,
      isActive: isActive ?? this.isActive,
      lastConnected: lastConnected ?? this.lastConnected,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'host': host,
        'port': port,
        'path': path,
        'username': username,
        'password': password,
        'useSsl': useSsl,
        'isActive': isActive,
        'lastConnected': lastConnected?.toIso8601String(),
        'trackCount': trackCount,
      };

  factory NetworkServerConfig.fromJson(Map<String, dynamic> json) =>
      NetworkServerConfig(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? 'NAS Server',
        type: NetworkServerType.values.firstWhere(
          (t) => t.name == (json['type'] as String?),
          orElse: () => NetworkServerType.webdav,
        ),
        host: json['host'] as String? ?? '192.168.1.1',
        port: json['port'] as int? ?? 443,
        path: json['path'] as String? ?? '/music',
        username: json['username'] as String?,
        password: json['password'] as String?,
        useSsl: json['useSsl'] as bool? ?? true,
        isActive: json['isActive'] as bool? ?? true,
        lastConnected: json['lastConnected'] != null
            ? DateTime.tryParse(json['lastConnected'] as String)
            : null,
        trackCount: json['trackCount'] as int? ?? 0,
      );

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        host,
        port,
        path,
        username,
        password,
        useSsl,
        isActive,
        lastConnected,
        trackCount,
      ];
}
