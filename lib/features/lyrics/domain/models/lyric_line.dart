import 'package:equatable/equatable.dart';

/// Represents a single line of lyrics with an optional timestamp.
class LyricLine extends Equatable {
  const LyricLine({
    required this.timestamp,
    required this.text,
    this.translation,
  });

  /// Timestamp when this line starts in the audio stream.
  final Duration timestamp;

  /// Original lyrical text content.
  final String text;

  /// Optional translated text for multilingual display.
  final String? translation;

  /// Timestamp formatted as `mm:ss.cs` (e.g., `02:14.35`).
  String get formattedTimestamp {
    final totalSeconds = timestamp.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final centiseconds = (timestamp.inMilliseconds % 1000) ~/ 10;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${centiseconds.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'timestamp_ms': timestamp.inMilliseconds,
      'text': text,
      'translation': translation,
    };
  }

  factory LyricLine.fromMap(Map<String, dynamic> map) {
    return LyricLine(
      timestamp: Duration(milliseconds: map['timestamp_ms'] as int? ?? 0),
      text: map['text'] as String? ?? '',
      translation: map['translation'] as String?,
    );
  }

  @override
  List<Object?> get props => [timestamp, text, translation];
}
