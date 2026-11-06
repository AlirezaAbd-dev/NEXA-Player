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
