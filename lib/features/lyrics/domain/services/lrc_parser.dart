import 'package:nexa_player/features/lyrics/domain/models/lyric_line.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';

/// High-performance parser and serializer for standard LRC (LyRiCs) files.
class LrcParser {
  const LrcParser();

  static final RegExp _tagRegex = RegExp(r'^\[([a-zA-Z]+):(.*)\]$');
  static final RegExp _timeTagRegex = RegExp(r'\[(\d{1,3}):(\d{2})(?:\.(\d{1,3}))?\]');

  /// Parses an LRC formatted string into a structured [Lyrics] entity.
  Lyrics parse(
    String content, {
    required String trackId,
    LyricsSource source = LyricsSource.lrcFile,
  }) {
    final lines = content.split(RegExp(r'\r?\n'));
    final parsedLines = <LyricLine>[];
    final plainLines = <String>[];
    int parsedOffsetMs = 0;

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // 1. Check for metadata header tags like [offset:+500] or [ar:Artist]
      final metaMatch = _tagRegex.firstMatch(line);
      if (metaMatch != null) {
        final key = metaMatch.group(1)?.toLowerCase();
        final value = metaMatch.group(2)?.trim() ?? '';
        if (key == 'offset') {
          parsedOffsetMs = int.tryParse(value) ?? 0;
        }
        continue;
      }

      // 2. Extract all timestamp tags on this line (supports multiple e.g. [00:12.00][00:24.00])
      final timeMatches = _timeTagRegex.allMatches(line).toList();
      if (timeMatches.isNotEmpty) {
        // Text is whatever comes after the last time tag
        final lastMatch = timeMatches.last;
        final text = line.substring(lastMatch.end).trim();

        for (final match in timeMatches) {
          final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
          final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
          final fractionRaw = match.group(3) ?? '0';

          int milliseconds = 0;
          if (fractionRaw.length == 1) {
            milliseconds = (int.tryParse(fractionRaw) ?? 0) * 100;
          } else if (fractionRaw.length == 2) {
            // Centiseconds
            milliseconds = (int.tryParse(fractionRaw) ?? 0) * 10;
          } else if (fractionRaw.length >= 3) {
            // Milliseconds
            milliseconds = int.tryParse(fractionRaw.substring(0, 3)) ?? 0;
          }

          final duration = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );

          parsedLines.add(LyricLine(timestamp: duration, text: text));
        }

        if (text.isNotEmpty) {
          plainLines.add(text);
        }
      } else {
        // Plain unsynced lyric line
        plainLines.add(line);
      }
    }

    // Sort synced lines chronologically
    parsedLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final isSynced = parsedLines.isNotEmpty;

    return Lyrics(
      trackId: trackId,
      lines: parsedLines,
      plainLyrics: plainLines.join('\n'),
      rawLrc: content,
      isSynced: isSynced,
      source: source,
      offsetMs: parsedOffsetMs,
    );
  }

  /// Parses unsynchronized plain text lyrics into a [Lyrics] entity.
  Lyrics parsePlainText(
    String plainText, {
    required String trackId,
    LyricsSource source = LyricsSource.lrclib,
  }) {
    final rawLines = plainText.split(RegExp(r'\r?\n'));
    final plainLines = <String>[];

    for (final raw in rawLines) {
      final line = raw.trim();
      if (line.isNotEmpty) {
        plainLines.add(line);
      }
    }

    return Lyrics(
      trackId: trackId,
      lines: const [],
      plainLyrics: plainLines.join('\n'),
      rawLrc: null,
      isSynced: false,
      source: source,
    );
  }

  /// Serializes a list of [LyricLine]s and metadata into standard LRC string format.
  String toLrc(
    List<LyricLine> lines, {
    String? title,
    String? artist,
    String? album,
    int offsetMs = 0,
  }) {
    final buffer = StringBuffer();

    if (title != null && title.isNotEmpty) buffer.writeln('[ti:$title]');
    if (artist != null && artist.isNotEmpty) buffer.writeln('[ar:$artist]');
    if (album != null && album.isNotEmpty) buffer.writeln('[al:$album]');
    if (offsetMs != 0) buffer.writeln('[offset:$offsetMs]');

    for (final line in lines) {
      buffer.writeln('[${line.formattedTimestamp}] ${line.text}');
    }

    return buffer.toString();
  }
}
