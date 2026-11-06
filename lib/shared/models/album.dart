import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a music album.
class Album extends Equatable {
  const Album({
    required this.id,
    required this.title,
    required this.artist,
    this.artworkUri,
    this.year,
    this.trackCount = 0,
    this.duration,
  });

  final String id;
  final String title;
  final String artist;
  final String? artworkUri;
  final int? year;
  final int trackCount;
  final Duration? duration;

  /// Subtitle formatted as `Artist • Year` or simply `Artist`.
  String get artistAndYear =>
      year != null ? '$artist • $year' : artist;

  /// Human-readable track count badge label.
  String get trackCountLabel =>
      trackCount == 1 ? '1 Track' : '$trackCount Tracks';

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? artworkUri,
    int? year,
    int? trackCount,
    Duration? duration,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkUri: artworkUri ?? this.artworkUri,
      year: year ?? this.year,
      trackCount: trackCount ?? this.trackCount,
      duration: duration ?? this.duration,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        artworkUri,
        year,
        trackCount,
        duration,
      ];
}
