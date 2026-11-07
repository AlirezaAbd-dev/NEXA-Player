import 'package:equatable/equatable.dart';
import '../../../core/extensions/duration_x.dart';

/// Immutable domain entity representing a playable audio track.
class Track extends Equatable {
  const Track({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    required this.duration,
    this.artworkUri,
    this.filePath,
    this.trackNumber,
    this.discNumber,
    this.year,
    this.genre,
    this.isFavorite = false,
    this.playCount = 0,
    this.bitrate,
    this.fileSize,
    this.dateAdded,
    this.dateModified,
    this.albumId,
    this.artistId,
    this.genreId,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? artworkUri;
  final String? filePath;
  final int? trackNumber;
  final int? discNumber;
  final int? year;
  final String? genre;
  final bool isFavorite;
  final int playCount;
  final int? bitrate;
  final int? fileSize;
  final DateTime? dateAdded;
  final DateTime? dateModified;
  final String? albumId;
  final String? artistId;
  final String? genreId;

  /// Formatted duration string (e.g. `03:45` or `3:45`).
  String get formattedDuration => duration.toMinutesSeconds(padMinutes: false);

  /// Combined artist and album subtitle string.
  String get artistAndAlbum =>
      album.isNotEmpty ? '$artist • $album' : artist;

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'duration_ms': duration.inMilliseconds,
      'artwork_uri': artworkUri,
      'file_path': filePath,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'year': year,
      'genre': genre,
      'is_favorite': isFavorite ? 1 : 0,
      'play_count': playCount,
      'bitrate': bitrate,
      'file_size': fileSize,
      'date_added': (dateAdded ?? DateTime.now()).millisecondsSinceEpoch,
      'date_modified': dateModified?.millisecondsSinceEpoch ??
          (dateAdded ?? DateTime.now()).millisecondsSinceEpoch,
      'album_id': albumId,
      'artist_id': artistId,
      'genre_id': genreId,
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory Track.fromMap(Map<String, dynamic> map) {
    final dateAddedRaw = map['date_added'] ?? map['dateAdded'];
    final dateModRaw = map['date_modified'] ?? map['dateModified'];
    final durRaw = map['duration_ms'] ?? map['durationMs'] ?? map['duration'];

    Duration dur;
    if (durRaw is int) {
      dur = Duration(milliseconds: durRaw);
    } else if (durRaw is Duration) {
      dur = durRaw;
    } else {
      dur = Duration.zero;
    }

    return Track(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String,
      album: (map['album'] as String?) ?? '',
      duration: dur,
      artworkUri: map['artwork_uri'] as String? ?? map['artworkUri'] as String?,
      filePath: map['file_path'] as String? ?? map['filePath'] as String?,
      trackNumber: map['track_number'] as int? ?? map['trackNumber'] as int?,
      discNumber: map['disc_number'] as int? ?? map['discNumber'] as int?,
      year: map['year'] as int?,
      genre: map['genre'] as String?,
      isFavorite: map['is_favorite'] == 1 || map['isFavorite'] == true,
      playCount: (map['play_count'] ?? map['playCount'] ?? 0) as int,
      bitrate: map['bitrate'] as int?,
      fileSize: map['file_size'] as int? ?? map['fileSize'] as int?,
      dateAdded: dateAddedRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(dateAddedRaw)
          : (dateAddedRaw is DateTime ? dateAddedRaw : null),
      dateModified: dateModRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(dateModRaw)
          : (dateModRaw is DateTime ? dateModRaw : null),
      albumId: map['album_id'] as String? ?? map['albumId'] as String?,
      artistId: map['artist_id'] as String? ?? map['artistId'] as String?,
      genreId: map['genre_id'] as String? ?? map['genreId'] as String?,
    );
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? artworkUri,
    String? filePath,
    int? trackNumber,
    int? discNumber,
    int? year,
    String? genre,
    bool? isFavorite,
    int? playCount,
    int? bitrate,
    int? fileSize,
    DateTime? dateAdded,
    DateTime? dateModified,
    String? albumId,
    String? artistId,
    String? genreId,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      artworkUri: artworkUri ?? this.artworkUri,
      filePath: filePath ?? this.filePath,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      isFavorite: isFavorite ?? this.isFavorite,
      playCount: playCount ?? this.playCount,
      bitrate: bitrate ?? this.bitrate,
      fileSize: fileSize ?? this.fileSize,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      albumId: albumId ?? this.albumId,
      artistId: artistId ?? this.artistId,
      genreId: genreId ?? this.genreId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        artist,
        album,
        duration,
        artworkUri,
        filePath,
        trackNumber,
        discNumber,
        year,
        genre,
        isFavorite,
        playCount,
        bitrate,
        fileSize,
        dateAdded,
        dateModified,
        albumId,
        artistId,
        genreId,
      ];
}
