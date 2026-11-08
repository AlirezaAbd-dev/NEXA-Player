import 'dart:async';
import '../../domain/services/sleep_timer_service.dart';

/// Concrete implementation of [ISleepTimerService] with periodic tick emission
/// and callback hooks for gradual audio attenuation.
class SleepTimerServiceImpl implements ISleepTimerService {
  SleepTimerServiceImpl({
    void Function(double volumeMultiplier)? onVolumeFade,
  }) : _onVolumeFade = onVolumeFade;

  final void Function(double volumeMultiplier)? _onVolumeFade;
  final _controller = StreamController<Duration?>.broadcast();

  Timer? _ticker;
  Duration? _remaining;
  bool _fadeOut = true;
  void Function()? _onCompleted;

  @override
  Stream<Duration?> get remainingStream => _controller.stream;

  @override
  Duration? get remainingTime => _remaining;

  @override
  bool get isActive => _ticker != null && _ticker!.isActive;

  @override
  void start(
    Duration duration, {
    bool fadeOut = true,
    void Function()? onCompleted,
  }) {
    cancel();

    if (duration <= Duration.zero) {
      onCompleted?.call();
      return;
    }

    _remaining = duration;
    _fadeOut = fadeOut;
    _onCompleted = onCompleted;
    _emit(_remaining);

    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining == null || _remaining! <= Duration.zero) {
        _finish();
        return;
      }

      _remaining = _remaining! - const Duration(seconds: 1);

      if (_remaining! <= Duration.zero) {
        _finish();
      } else {
        _emit(_remaining);
        _applyFadeIfNeeded();
      }
    });
  }

  void _applyFadeIfNeeded() {
    if (!_fadeOut || _onVolumeFade == null || _remaining == null) return;

    // Apply linear fade during the final 30 seconds
    const fadeWindow = Duration(seconds: 30);
    if (_remaining! < fadeWindow) {
      final totalFadeMs = fadeWindow.inMilliseconds;
      final currentRemainingMs = _remaining!.inMilliseconds;
      final multiplier = (currentRemainingMs / totalFadeMs).clamp(0.0, 1.0);
      _onVolumeFade(multiplier);
    }
  }

  void _finish() {
    _ticker?.cancel();
    _ticker = null;
    _remaining = null;
    _emit(null);
    _onVolumeFade?.call(1.0); // Reset volume multiplier
    _onCompleted?.call();
  }

  @override
  void cancel() {
    if (_ticker != null) {
      _ticker?.cancel();
      _ticker = null;
      _remaining = null;
      _emit(null);
      _onVolumeFade?.call(1.0); // Restore volume
    }
  }

  void _emit(Duration? value) {
    if (!_controller.isClosed) {
      _controller.add(value);
    }
  }

  @override
  void dispose() {
    cancel();
    _controller.close();
  }
}
