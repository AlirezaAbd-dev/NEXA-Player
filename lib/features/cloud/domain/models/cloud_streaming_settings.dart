import 'package:equatable/equatable.dart';

/// Configuration options for cloud streaming, DLNA casting, and network caching.
class CloudStreamingSettings extends Equatable {
  const CloudStreamingSettings({
    this.maxCacheMb = 1024,
    this.autoDiscoverCast = true,
    this.losslessStreaming = true,
    this.bufferAheadSeconds = 15,
    this.streamOverMobileData = false,
    this.lastConnectedCastDeviceId,
  });

  /// Maximum disk quota reserved for streaming cache in megabytes.
  final int maxCacheMb;

  /// Automatically scans local WiFi for UPnP/DLNA renderers on app launch.
  final bool autoDiscoverCast;

  /// Prefer uncompressed lossless FLAC/WAV streaming without downsampling.
  final bool losslessStreaming;

  /// Number of seconds ahead to pre-buffer for seamless playback.
  final int bufferAheadSeconds;

  /// Allow remote cloud/NAS streaming when connected to cellular mobile networks.
  final bool streamOverMobileData;

  /// ID of the most recently used network casting speaker.
  final String? lastConnectedCastDeviceId;

  CloudStreamingSettings copyWith({
    int? maxCacheMb,
    bool? autoDiscoverCast,
    bool? losslessStreaming,
    int? bufferAheadSeconds,
    bool? streamOverMobileData,
    String? lastConnectedCastDeviceId,
  }) {
    return CloudStreamingSettings(
      maxCacheMb: maxCacheMb ?? this.maxCacheMb,
      autoDiscoverCast: autoDiscoverCast ?? this.autoDiscoverCast,
      losslessStreaming: losslessStreaming ?? this.losslessStreaming,
      bufferAheadSeconds: bufferAheadSeconds ?? this.bufferAheadSeconds,
      streamOverMobileData: streamOverMobileData ?? this.streamOverMobileData,
      lastConnectedCastDeviceId:
          lastConnectedCastDeviceId ?? this.lastConnectedCastDeviceId,
    );
  }

  Map<String, dynamic> toJson() => {
        'maxCacheMb': maxCacheMb,
        'autoDiscoverCast': autoDiscoverCast,
        'losslessStreaming': losslessStreaming,
        'bufferAheadSeconds': bufferAheadSeconds,
        'streamOverMobileData': streamOverMobileData,
        'lastConnectedCastDeviceId': lastConnectedCastDeviceId,
      };

  factory CloudStreamingSettings.fromJson(Map<String, dynamic> json) =>
      CloudStreamingSettings(
        maxCacheMb: json['maxCacheMb'] as int? ?? 1024,
        autoDiscoverCast: json['autoDiscoverCast'] as bool? ?? true,
        losslessStreaming: json['losslessStreaming'] as bool? ?? true,
        bufferAheadSeconds: json['bufferAheadSeconds'] as int? ?? 15,
        streamOverMobileData: json['streamOverMobileData'] as bool? ?? false,
        lastConnectedCastDeviceId:
            json['lastConnectedCastDeviceId'] as String?,
      );

  @override
  List<Object?> get props => [
        maxCacheMb,
        autoDiscoverCast,
        losslessStreaming,
        bufferAheadSeconds,
        streamOverMobileData,
        lastConnectedCastDeviceId,
      ];
}
