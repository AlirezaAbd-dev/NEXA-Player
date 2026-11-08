import 'dart:async';

/// Interface for the playback sleep timer with smooth audio fade out.
abstract class ISleepTimerService {
  /// Stream emitting remaining duration every second while the timer is active.
  /// Emits null when inactive or canceled.
  Stream<Duration?> get remainingStream;

  /// Current remaining duration, or null if inactive.
  Duration? get remainingTime;

  /// Whether a sleep countdown is currently running.
  bool get isActive;

  /// Starts or resets the sleep timer to [duration].
  ///
  /// If [fadeOut] is true, audio volume is smoothly ducked during the final 30 seconds.
  /// When countdown concludes, [onCompleted] is invoked.
  void start(
    Duration duration, {
    bool fadeOut = true,
    void Function()? onCompleted,
  });

  /// Cancels any active countdown and restores standard volume.
  void cancel();

  /// Releases timer and internal streams.
  void dispose();
}
