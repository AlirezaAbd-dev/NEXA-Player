import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a music artist.
class Artist extends Equatable {
  const Artist({
    required this.id,
    required this.name,
    this.artworkUri,
    this.trackCount = 0,
    this.albumCount = 0,
  });

  final String id;
  final String name;
  final String? artworkUri;
  final int trackCount;
  final int albumCount;

  /// Subtitle formatted as `24 Tracks • 2 Albums`.
  String get tracksAndAlbumsLabel {
    final tLabel = trackCount == 1 ? '1 Track' : '$trackCount Tracks';
    final aLabel = albumCount == 1 ? '1 Album' : '$albumCount Albums';
    return '$tLabel • $aLabel';
  }

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'artwork_uri': artworkUri,
      'track_count': trackCount,
      'album_count': albumCount,
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String,
      name: map['name'] as String,
      artworkUri: map['artwork_uri'] as String? ?? map['artworkUri'] as String?,
      trackCount: (map['track_count'] ?? map['trackCount'] ?? 0) as int,
      albumCount: (map['album_count'] ?? map['albumCount'] ?? 0) as int,
    );
  }

  Artist copyWith({
    String? id,
    String? name,
    String? artworkUri,
    int? trackCount,
    int? albumCount,
  }) {
    return Artist(
      id: id ?? this.id,
      name: name ?? this.name,
      artworkUri: artworkUri ?? this.artworkUri,
      trackCount: trackCount ?? this.trackCount,
      albumCount: albumCount ?? this.albumCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        artworkUri,
        trackCount,
        albumCount,
      ];
}
