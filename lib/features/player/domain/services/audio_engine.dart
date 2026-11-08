import 'dart:async';
import '../../../../shared/models/track.dart';
import '../entities/playback_state.dart';

/// Pure abstraction for the low-level audio decoder and playback engine.
abstract class IAudioEngine {
  /// Stream emitting real-time playback operational status changes.
  Stream<PlaybackStatus> get statusStream;

  /// Stream emitting playback elapsed position changes.
  Stream<Duration> get positionStream;

  /// Stream emitting total duration updates for the loaded track.
  Stream<Duration> get durationStream;

  /// Stream emitting buffered position updates for remote or streamed audio.
  Stream<Duration> get bufferedPositionStream;

  /// Stream emitting volume changes (0.0 to 1.0).
  Stream<double> get volumeStream;

  /// Stream emitting playback speed changes.
  Stream<double> get speedStream;

  /// Current operational status.
  PlaybackStatus get status;

  /// Current elapsed position.
  Duration get position;

  /// Current track total duration.
  Duration get duration;

  /// Current volume level (0.0 to 1.0).
  double get volume;

  /// Current playback speed multiplier.
  double get speed;

  /// Loads [track] into the audio engine pipeline.
  ///
  /// If [autoPlay] is true, playback starts immediately once buffering completes.
  Future<void> load(Track track, {bool autoPlay = true});

  /// Starts or resumes audio playback.
  Future<void> play();

  /// Pauses audio playback at the current position.
  Future<void> pause();

  /// Stops audio playback and resets position to start.
  Future<void> stop();

  /// Seeks playback to the requested [position].
  Future<void> seek(Duration position);

  /// Sets audio output volume between 0.0 and 1.0 with optional smoothing.
  Future<void> setVolume(double volume);

  /// Sets playback speed multiplier (e.g. 0.5 to 2.0).
  Future<void> setSpeed(double speed);

  /// Enables or disables continuous looping of the single track.
  Future<void> setLoopMode(bool loop);

  /// Releases all underlying decoders, streams, and platform resources.
  Future<void> dispose();
}
