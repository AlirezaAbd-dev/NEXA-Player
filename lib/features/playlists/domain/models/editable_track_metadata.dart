import 'package:flutter/foundation.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Mutable representation of track metadata used for in-app tag editing.
@immutable
class EditableTrackMetadata {
  const EditableTrackMetadata({
    required this.title,
    required this.artist,
    required this.album,
    this.genre,
    this.year,
    this.trackNumber,
  });

  final String title;
  final String artist;
  final String album;
  final String? genre;
  final int? year;
  final int? trackNumber;

  factory EditableTrackMetadata.fromTrack(Track track) {
    return EditableTrackMetadata(
      title: track.title,
      artist: track.artist,
      album: track.album,
      genre: track.genre,
      year: track.year,
      trackNumber: track.trackNumber,
    );
  }

  EditableTrackMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    int? trackNumber,
  }) {
    return EditableTrackMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditableTrackMetadata &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist &&
          album == other.album &&
          genre == other.genre &&
          year == other.year &&
          trackNumber == other.trackNumber;

  @override
  int get hashCode => Object.hash(title, artist, album, genre, year, trackNumber);

  @override
  String toString() =>
      'EditableTrackMetadata(title: $title, artist: $artist, album: $album)';
}
