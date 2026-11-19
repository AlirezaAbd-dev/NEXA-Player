import 'package:flutter/foundation.dart';

/// Target audio profile for an exported trimmed clip.
enum RingtoneTarget {
  ringtone('Phone Ringtone'),
  notification('Notification Sound'),
  alarm('Alarm Clock'),
  audioFile('Custom Audio File');

  const RingtoneTarget(this.label);
  final String label;
}

/// Boundary timestamps (in milliseconds) defining an audio selection for ringtone trimming.
@immutable
class RingtoneTrimRange {
  const RingtoneTrimRange({
    required this.startMs,
    required this.endMs,
  }) : assert(startMs >= 0, 'startMs must be non-negative'),
       assert(endMs > startMs, 'endMs must be greater than startMs');

  final int startMs;
  final int endMs;

  /// Total duration of the trimmed segment in milliseconds.
  int get durationMs => endMs - startMs;

  /// Duration formatted as mm:ss.
  String get formattedDuration {
    final totalSec = (durationMs / 1000).round();
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// Start timestamp formatted as mm:ss.
  String get formattedStart {
    final totalSec = (startMs / 1000).round();
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  /// End timestamp formatted as mm:ss.
  String get formattedEnd {
    final totalSec = (endMs / 1000).round();
    final mins = totalSec ~/ 60;
    final secs = totalSec % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  RingtoneTrimRange copyWith({int? startMs, int? endMs}) {
    return RingtoneTrimRange(
      startMs: startMs ?? this.startMs,
      endMs: endMs ?? this.endMs,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RingtoneTrimRange &&
          runtimeType == other.runtimeType &&
          startMs == other.startMs &&
          endMs == other.endMs;

  @override
  int get hashCode => Object.hash(startMs, endMs);

  @override
  String toString() => 'RingtoneTrimRange($formattedStart -> $formattedEnd [$formattedDuration])';
}
