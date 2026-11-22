import '../../../../shared/models/track.dart';
import '../models/cast_device.dart';
import '../models/cast_playback_state.dart';

/// Contract for controlling remote playback, volume, and track queuing on network renderers.
abstract interface class ICastController {
  /// Stream broadcasting real-time remote player state changes.
  Stream<CastPlaybackState> get stateStream;

  /// Current snapshot of casting state.
  CastPlaybackState get state;

  /// Establishes remote session with target [device].
  Future<bool> connect(CastDevice device);

  /// Disconnects active session and halts remote playback.
  Future<void> disconnect();

  /// Transmits track URL and metadata to remote renderer.
  Future<void> playTrack(Track track, {String? streamUrl});

  /// Resumes remote playback.
  Future<void> play();

  /// Pauses remote playback.
  Future<void> pause();

  /// Stops remote playback and resets position.
  Future<void> stop();

  /// Seeks to [position] on the remote player.
  Future<void> seek(Duration position);

  /// Sets master volume on the remote renderer (0.0 to 1.0).
  Future<void> setVolume(double volume);
}
