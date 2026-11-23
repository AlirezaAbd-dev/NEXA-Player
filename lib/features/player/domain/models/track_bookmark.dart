import 'package:equatable/equatable.dart';

/// Immutable model representing a waveform micro-bookmark pin on a track.
class TrackBookmark extends Equatable {
  final String id;
  final String trackId;
  final Duration position;
  final String label;
  final int colorValue;
  final DateTime createdAt;

  const TrackBookmark({
    required this.id,
    required this.trackId,
    required this.position,
    this.label = '',
    this.colorValue = 0xFF00E5FF,
    required this.createdAt,
  });

  TrackBookmark copyWith({
    String? id,
    String? trackId,
    Duration? position,
    String? label,
    int? colorValue,
    DateTime? createdAt,
  }) {
    return TrackBookmark(
      id: id ?? this.id,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      label: label ?? this.label,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trackId': trackId,
        'positionMs': position.inMilliseconds,
        'label': label,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TrackBookmark.fromJson(Map<String, dynamic> json) => TrackBookmark(
        id: json['id'] as String,
        trackId: json['trackId'] as String,
        position: Duration(milliseconds: (json['positionMs'] as num).toInt()),
        label: json['label'] as String? ?? '',
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
      );

  @override
  List<Object?> get props => [id, trackId, position, label, colorValue, createdAt];
}

/// A-B loop segment bounded by two micro-bookmark pins.
class ABLoopRange extends Equatable {
  final String trackId;
  final Duration? start;
  final Duration? end;
  final bool isEnabled;

  const ABLoopRange({
    required this.trackId,
    this.start,
    this.end,
    this.isEnabled = false,
  });

  /// True when both points are defined and start is strictly before end.
  bool get isValid =>
      start != null &&
      end != null &&
      start! < end! &&
      (end! - start!) >= const Duration(milliseconds: 300);

  /// Formatted duration of the active loop segment.
  Duration get loopDuration =>
      isValid ? end! - start! : Duration.zero;

  /// Checks if playback should seamlessly wrap around to [start].
  bool shouldWrap(Duration current) =>
      isEnabled && isValid && current >= end!;

  /// Clamps or wraps position to the loop range.
  Duration checkPosition(Duration current) {
    if (shouldWrap(current)) {
      return start!;
    }
    return current;
  }

  ABLoopRange copyWith({
    String? trackId,
    Duration? start,
    Duration? end,
    bool? isEnabled,
    bool clearStart = false,
    bool clearEnd = false,
  }) {
    return ABLoopRange(
      trackId: trackId ?? this.trackId,
      start: clearStart ? null : (start ?? this.start),
      end: clearEnd ? null : (end ?? this.end),
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [trackId, start, end, isEnabled];
}
