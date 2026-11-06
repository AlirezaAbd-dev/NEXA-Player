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

  /// Formatted duration string (e.g. `03:45` or `3:45`).
  String get formattedDuration => duration.toMinutesSeconds(padMinutes: false);

  /// Combined artist and album subtitle string.
  String get artistAndAlbum =>
      album.isNotEmpty ? '$artist • $album' : artist;

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
      ];
}
