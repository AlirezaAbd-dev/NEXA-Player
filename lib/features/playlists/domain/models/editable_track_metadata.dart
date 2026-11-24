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
    this.comment,
    this.artworkUri,
    this.artworkBytes,
    this.clearArtwork = false,
  });

  final String title;
  final String artist;
  final String album;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final String? comment;
  final String? artworkUri;
  final Uint8List? artworkBytes;
  final bool clearArtwork;

  factory EditableTrackMetadata.fromTrack(Track track) {
    return EditableTrackMetadata(
      title: track.title,
      artist: track.artist,
      album: track.album,
      genre: track.genre,
      year: track.year,
      trackNumber: track.trackNumber,
      comment: track.comment,
      artworkUri: track.artworkUri,
    );
  }

  EditableTrackMetadata copyWith({
    String? title,
    String? artist,
    String? album,
    String? genre,
    int? year,
    int? trackNumber,
    String? comment,
    String? artworkUri,
    Uint8List? artworkBytes,
    bool? clearArtwork,
  }) {
    return EditableTrackMetadata(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      comment: comment ?? this.comment,
      artworkUri: artworkUri ?? this.artworkUri,
      artworkBytes: artworkBytes ?? this.artworkBytes,
      clearArtwork: clearArtwork ?? this.clearArtwork,
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
          trackNumber == other.trackNumber &&
          comment == other.comment &&
          artworkUri == other.artworkUri &&
          clearArtwork == other.clearArtwork &&
          listEquals(artworkBytes, other.artworkBytes);

  @override
  int get hashCode => Object.hash(
        title,
        artist,
        album,
        genre,
        year,
        trackNumber,
        comment,
        artworkUri,
        clearArtwork,
        artworkBytes == null ? null : Object.hashAll(artworkBytes!),
      );

  @override
  String toString() =>
      'EditableTrackMetadata(title: $title, artist: $artist, album: $album)';
}
