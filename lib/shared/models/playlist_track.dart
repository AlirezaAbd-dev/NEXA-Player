import 'package:equatable/equatable.dart';

/// Immutable domain entity representing an ordered track entry inside a playlist.
class PlaylistTrack extends Equatable {
  const PlaylistTrack({
    required this.id,
    required this.playlistId,
    required this.trackId,
    required this.position,
    required this.addedAt,
  });

  final String id;
  final String playlistId;
  final String trackId;
  final int position;
  final DateTime addedAt;

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playlist_id': playlistId,
      'track_id': trackId,
      'position': position,
      'added_at': addedAt.millisecondsSinceEpoch,
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory PlaylistTrack.fromMap(Map<String, dynamic> map) {
    final addedRaw = map['added_at'] ?? map['addedAt'];
    final playlistId = (map['playlist_id'] ?? map['playlistId']) as String;
    final trackId = (map['track_id'] ?? map['trackId']) as String;
    final position = (map['position']) as int;
    final id = (map['id'] as String?) ?? '${playlistId}_${trackId}_$position';

    return PlaylistTrack(
      id: id,
      playlistId: playlistId,
      trackId: trackId,
      position: position,
      addedAt: addedRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(addedRaw)
          : (addedRaw is DateTime ? addedRaw : DateTime.now()),
    );
  }

  PlaylistTrack copyWith({
    String? id,
    String? playlistId,
    String? trackId,
    int? position,
    DateTime? addedAt,
  }) {
    return PlaylistTrack(
      id: id ?? this.id,
      playlistId: playlistId ?? this.playlistId,
      trackId: trackId ?? this.trackId,
      position: position ?? this.position,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        playlistId,
        trackId,
        position,
        addedAt,
      ];
}
