import 'package:equatable/equatable.dart';
import '../../../../shared/models/track.dart';
import 'cast_device.dart';

/// Active transport state of a remote network casting session.
enum CastPlaybackStatus {
  idle,
  connecting,
  connected,
  playing,
  paused,
  buffering,
  stopped,
  disconnected,
  error,
}

/// Snapshot of remote playback telemetry from a connected network renderer.
class CastPlaybackState extends Equatable {
  const CastPlaybackState({
    this.device,
    CastDevice? connectedDevice,
    this.status = CastPlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.errorMessage,
  }) : _connectedDevice = connectedDevice;

  final CastDevice? device;
  final CastDevice? _connectedDevice;

  CastDevice? get connectedDevice => _connectedDevice ?? device;

  final CastPlaybackStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final double volume;
  final String? errorMessage;

  bool get isCasting =>
      connectedDevice != null &&
      status != CastPlaybackStatus.idle &&
      status != CastPlaybackStatus.disconnected;
  bool get isPlaying => status == CastPlaybackStatus.playing;

  CastPlaybackState copyWith({
    CastDevice? device,
    CastDevice? connectedDevice,
    CastPlaybackStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    double? volume,
    String? errorMessage,
  }) {
    final dev = connectedDevice ?? device ?? this.connectedDevice;
    return CastPlaybackState(
      device: dev,
      connectedDevice: dev,
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        connectedDevice,
        status,
        currentTrack,
        position,
        duration,
        volume,
        errorMessage,
      ];
}
