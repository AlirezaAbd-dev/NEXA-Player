import 'package:equatable/equatable.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyric_line.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';

export 'lyric_line.dart';
export 'lyrics_source.dart';

/// Immutable domain entity representing a track's lyrics.
class Lyrics extends Equatable {
  const Lyrics({
    this.trackId = '',
    this.lines = const [],
    this.plainLyrics,
    this.rawLrc,
    this.isSynced = false,
    this.source = LyricsSource.none,
    this.offsetMs = 0,
  });

  /// Associated track identifier.
  final String trackId;

  /// Ordered list of lyric lines with start timestamps.
  final List<LyricLine> lines;

  /// Raw unsynchronized plaintext lyrics.
  final String? plainLyrics;

  /// Raw LRC file string (including metadata and timestamp tags).
  final String? rawLrc;

  /// Whether the lyrics contain valid timecodes for synchronized karaoke scrolling.
  final bool isSynced;

  /// Origin of this lyrical data.
  final LyricsSource source;

  /// User-customized time synchronization offset in milliseconds (+/- ms).
  final int offsetMs;

  /// Resolves the index of the active lyric line for the given audio [currentPosition].
  ///
  /// Returns -1 if no lines exist or if playback has not yet reached the first lyric line.
  int findActiveLineIndex(Duration currentPosition) {
    if (lines.isEmpty) return -1;

    final effectiveMs = currentPosition.inMilliseconds - offsetMs;
    if (effectiveMs < lines.first.timestamp.inMilliseconds) {
      return -1;
    }

    // Binary or reverse search for highest timestamp <= effectiveMs
    for (int i = lines.length - 1; i >= 0; i--) {
      if (lines[i].timestamp.inMilliseconds <= effectiveMs) {
        return i;
      }
    }

    return -1;
  }

  Lyrics copyWith({
    String? trackId,
    List<LyricLine>? lines,
    String? plainLyrics,
    String? rawLrc,
    bool? isSynced,
    LyricsSource? source,
    int? offsetMs,
  }) {
    return Lyrics(
      trackId: trackId ?? this.trackId,
      lines: lines ?? this.lines,
      plainLyrics: plainLyrics ?? this.plainLyrics,
      rawLrc: rawLrc ?? this.rawLrc,
      isSynced: isSynced ?? this.isSynced,
      source: source ?? this.source,
      offsetMs: offsetMs ?? this.offsetMs,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'track_id': trackId,
      'lines': lines.map((l) => l.toMap()).toList(),
      'plain_lyrics': plainLyrics,
      'raw_lrc': rawLrc,
      'is_synced': isSynced,
      'source': source.name,
      'offset_ms': offsetMs,
    };
  }

  factory Lyrics.fromMap(Map<String, dynamic> map) {
    final rawLines = map['lines'] as List<dynamic>? ?? [];
    return Lyrics(
      trackId: map['track_id'] as String? ?? '',
      lines: rawLines
          .map((e) => LyricLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList(),
      plainLyrics: map['plain_lyrics'] as String?,
      rawLrc: map['raw_lrc'] as String?,
      isSynced: map['is_synced'] as bool? ?? false,
      source: LyricsSource.values.firstWhere(
        (s) => s.name == map['source'],
        orElse: () => LyricsSource.none,
      ),
      offsetMs: map['offset_ms'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        trackId,
        lines,
        plainLyrics,
        rawLrc,
        isSynced,
        source,
        offsetMs,
      ];
}
