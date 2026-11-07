import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a user or smart playlist.
class Playlist extends Equatable {
  const Playlist({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.trackCount = 0,
    this.artworkUri,
    this.duration,
    this.isSmart = false,
    this.smartCriteria,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int trackCount;
  final String? artworkUri;
  final Duration? duration;
  final bool isSmart;
  final String? smartCriteria;

  /// Formatted track count badge label (e.g., `1 Track`, `15 Tracks`).
  String get trackCountLabel =>
      trackCount == 1 ? '1 Track' : '$trackCount Tracks';

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt.millisecondsSinceEpoch,
      'track_count': trackCount,
      'artwork_uri': artworkUri,
      'duration_ms': duration?.inMilliseconds ?? 0,
      'is_smart': isSmart ? 1 : 0,
      'smart_criteria': smartCriteria,
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory Playlist.fromMap(Map<String, dynamic> map) {
    final createdRaw = map['created_at'] ?? map['createdAt'];
    final updatedRaw = map['updated_at'] ?? map['updatedAt'];

    return Playlist(
      id: map['id'] as String,
      name: map['name'] as String,
      createdAt: createdRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(createdRaw)
          : (createdRaw is DateTime ? createdRaw : DateTime.now()),
      updatedAt: updatedRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(updatedRaw)
          : (updatedRaw is DateTime ? updatedRaw : DateTime.now()),
      trackCount: (map['track_count'] ?? map['trackCount'] ?? 0) as int,
      artworkUri: map['artwork_uri'] as String? ?? map['artworkUri'] as String?,
      duration: (map['duration_ms'] ?? map['durationMs']) != null
          ? Duration(milliseconds: (map['duration_ms'] ?? map['durationMs']) as int)
          : (map['duration'] is Duration ? map['duration'] as Duration : null),
      isSmart: (map['is_smart'] == 1 || map['isSmart'] == true),
      smartCriteria: map['smart_criteria'] as String? ?? map['smartCriteria'] as String?,
    );
  }

  Playlist copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trackCount,
    String? artworkUri,
    Duration? duration,
    bool? isSmart,
    String? smartCriteria,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trackCount: trackCount ?? this.trackCount,
      artworkUri: artworkUri ?? this.artworkUri,
      duration: duration ?? this.duration,
      isSmart: isSmart ?? this.isSmart,
      smartCriteria: smartCriteria ?? this.smartCriteria,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        createdAt,
        updatedAt,
        trackCount,
        artworkUri,
        duration,
        isSmart,
        smartCriteria,
      ];
}
