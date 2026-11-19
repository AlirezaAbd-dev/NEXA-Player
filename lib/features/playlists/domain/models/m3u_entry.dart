import 'package:flutter/foundation.dart';

/// Single parsed entry in an M3U or M3U8 extended playlist.
@immutable
class M3uEntry {
  const M3uEntry({
    required this.filePath,
    this.title,
    this.artist,
    this.durationSeconds = -1,
  });

  /// Absolute or relative file path to the audio track.
  final String filePath;

  /// Optional track title parsed from #EXTINF.
  final String? title;

  /// Optional artist name parsed from #EXTINF.
  final String? artist;

  /// Duration in seconds (-1 if unspecified or streaming).
  final int durationSeconds;

  /// Formatted display representation: "Artist - Title" or file basename.
  String get displayName {
    if (artist != null && artist!.isNotEmpty && title != null && title!.isNotEmpty) {
      return '$artist - $title';
    }
    if (title != null && title!.isNotEmpty) {
      return title!;
    }
    final segments = filePath.split(RegExp(r'[/\\]'));
    return segments.isNotEmpty ? segments.last : filePath;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is M3uEntry &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          title == other.title &&
          artist == other.artist &&
          durationSeconds == other.durationSeconds;

  @override
  int get hashCode => Object.hash(filePath, title, artist, durationSeconds);

  @override
  String toString() => 'M3uEntry(path: $filePath, title: $title, artist: $artist)';
}
