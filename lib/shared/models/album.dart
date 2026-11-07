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
    this.dateAdded,
    this.artistId,
  });

  final String id;
  final String title;
  final String artist;
  final String? artworkUri;
  final int? year;
  final int trackCount;
  final Duration? duration;
  final DateTime? dateAdded;
  final String? artistId;

  /// Subtitle formatted as `Artist • Year` or simply `Artist`.
  String get artistAndYear =>
      year != null ? '$artist • $year' : artist;

  /// Human-readable track count badge label.
  String get trackCountLabel =>
      trackCount == 1 ? '1 Track' : '$trackCount Tracks';

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artwork_uri': artworkUri,
      'year': year,
      'track_count': trackCount,
      'duration_ms': duration?.inMilliseconds ?? 0,
      'date_added': dateAdded?.millisecondsSinceEpoch,
      'artist_id': artistId,
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory Album.fromMap(Map<String, dynamic> map) {
    final dateAddedRaw = map['date_added'] ?? map['dateAdded'];
    final durRaw = map['duration_ms'] ?? map['durationMs'] ?? map['duration'];

    Duration? dur;
    if (durRaw is int) {
      dur = Duration(milliseconds: durRaw);
    } else if (durRaw is Duration) {
      dur = durRaw;
    }

    return Album(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      artworkUri: map['artwork_uri'] as String? ?? map['artworkUri'] as String?,
      year: map['year'] as int?,
      trackCount: (map['track_count'] ?? map['trackCount'] ?? 0) as int,
      duration: dur,
      dateAdded: dateAddedRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(dateAddedRaw)
          : (dateAddedRaw is DateTime ? dateAddedRaw : null),
      artistId: map['artist_id'] as String? ?? map['artistId'] as String?,
    );
  }

  Album copyWith({
    String? id,
    String? title,
    String? artist,
    String? artworkUri,
    int? year,
    int? trackCount,
    Duration? duration,
    DateTime? dateAdded,
    String? artistId,
  }) {
    return Album(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artworkUri: artworkUri ?? this.artworkUri,
      year: year ?? this.year,
      trackCount: trackCount ?? this.trackCount,
      duration: duration ?? this.duration,
      dateAdded: dateAdded ?? this.dateAdded,
      artistId: artistId ?? this.artistId,
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
        dateAdded,
        artistId,
      ];
}
