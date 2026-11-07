import 'dart:io';
import 'dart:typed_data';

/// Immutable container holding raw audio metadata extracted from a file.
class ExtractedMetadata {
  const ExtractedMetadata({
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.genre,
    this.bitrate,
    this.artworkBytes,
  });

  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? genre;
  final int? bitrate;
  final Uint8List? artworkBytes;
}

/// Abstract contract for extracting audio tags and embedded artwork.
abstract interface class IAudioMetadataReader {
  /// Extracts metadata from the audio [file].
  Future<ExtractedMetadata> extract(File file);

  /// Extracts metadata from raw [bytes] with a [fallbackTitle].
  ExtractedMetadata extractBytes(Uint8List bytes, String fallbackTitle);
}
