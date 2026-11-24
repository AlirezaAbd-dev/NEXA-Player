import 'package:nexa_player/shared/models/track.dart';

/// Parsed representation of a smart search query with format, duration,
/// and playback state tokens separated from search terms.
class ParsedQuery {
  const ParsedQuery({
    required this.rawQuery,
    this.textTerm = '',
    this.formats = const {},
    this.minDuration,
    this.maxDuration,
    this.onlyFavorites = false,
    this.unplayedOnly = false,
    this.playedOnly = false,
  });

  /// The raw unparsed query text.
  final String rawQuery;

  /// Remaining search terms with tokens stripped out.
  final String textTerm;

  /// Audio formats extracted from query (e.g. {'flac', 'mp3'}).
  final Set<String> formats;

  /// Minimum duration threshold (e.g. from `>5m`).
  final Duration? minDuration;

  /// Maximum duration threshold (e.g. from `<3m`).
  final Duration? maxDuration;

  /// Whether to filter exclusively for favorited tracks.
  final bool onlyFavorites;

  /// Whether to filter exclusively for unplayed tracks.
  final bool unplayedOnly;

  /// Whether to filter exclusively for played tracks.
  final bool playedOnly;

  /// True if any smart filter token was identified in the query.
  bool get hasFilters =>
      formats.isNotEmpty ||
      minDuration != null ||
      maxDuration != null ||
      onlyFavorites ||
      unplayedOnly ||
      playedOnly;

  /// Evaluates whether a [Track] satisfies all parsed criteria.
  bool matchesTrack(Track track) {
    // 1. Text term matching
    if (textTerm.isNotEmpty) {
      final term = textTerm.toLowerCase();
      final titleMatch = track.title.toLowerCase().contains(term);
      final artistMatch = track.artist.toLowerCase().contains(term);
      final albumMatch = track.album.toLowerCase().contains(term);
      if (!titleMatch && !artistMatch && !albumMatch) {
        return false;
      }
    }

    // 2. Format filter
    if (formats.isNotEmpty) {
      final filePath = track.filePath?.toLowerCase() ?? '';
      final matchesFormat = formats.any((fmt) {
        final cleanFmt = fmt.startsWith('.') ? fmt : '.$fmt';
        return filePath.endsWith(cleanFmt) || filePath.contains(cleanFmt);
      });
      if (!matchesFormat) return false;
    }

    // 3. Min Duration filter
    if (minDuration != null && track.duration < minDuration!) {
      return false;
    }

    // 4. Max Duration filter
    if (maxDuration != null && track.duration > maxDuration!) {
      return false;
    }

    // 5. Favorites filter
    if (onlyFavorites && !track.isFavorite) {
      return false;
    }

    // 6. Play count filters
    if (unplayedOnly && track.playCount > 0) {
      return false;
    }
    if (playedOnly && track.playCount == 0) {
      return false;
    }

    return true;
  }

  /// Filters a list of tracks returning only those satisfying criteria.
  List<Track> filterTracks(List<Track> tracks) {
    if (!hasFilters && textTerm.isEmpty) return tracks;
    return tracks.where(matchesTrack).toList();
  }
}

/// Pure Dart parser for tokenizing search queries with format flags (`flac`, `mp3`),
/// duration bounds (`>5m`, `<3m`), favorite flags, and playback state.
class QueryTokenParser {
  const QueryTokenParser._();

  static const Set<String> supportedFormats = {
    'flac',
    'mp3',
    'opus',
    'wav',
    'aac',
    'm4a',
    'ogg',
  };

  /// Parses [raw] input string into a structured [ParsedQuery].
  static ParsedQuery parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const ParsedQuery(rawQuery: '');
    }

    final tokens = trimmed.split(RegExp(r'\s+'));
    final remainingText = <String>[];
    final formats = <String>{};
    Duration? minDuration;
    Duration? maxDuration;
    bool onlyFavorites = false;
    bool unplayedOnly = false;
    bool playedOnly = false;

    for (final token in tokens) {
      final lower = token.toLowerCase();

      // Format token check (e.g. "flac", ".flac")
      final fmtCandidate = lower.startsWith('.') ? lower.substring(1) : lower;
      if (supportedFormats.contains(fmtCandidate)) {
        formats.add(fmtCandidate);
        continue;
      }

      // Duration comparison check (e.g. ">5m", ">=5m", "<3m", "<=30s")
      final durationRegex = RegExp(r'^([><]=?)(\d+)([smh])$');
      final match = durationRegex.firstMatch(lower);
      if (match != null) {
        final operator = match.group(1)!;
        final value = int.tryParse(match.group(2)!) ?? 0;
        final unit = match.group(3)!;

        Duration dur;
        switch (unit) {
          case 's':
            dur = Duration(seconds: value);
            break;
          case 'h':
            dur = Duration(hours: value);
            break;
          case 'm':
          default:
            dur = Duration(minutes: value);
            break;
        }

        if (operator.startsWith('>')) {
          minDuration = dur;
        } else if (operator.startsWith('<')) {
          maxDuration = dur;
        }
        continue;
      }

      // Favorite token check
      if (lower == 'favorite' || lower == 'favorites' || lower == 'fav') {
        onlyFavorites = true;
        continue;
      }

      // Play state tokens
      if (lower == 'unplayed') {
        unplayedOnly = true;
        continue;
      }
      if (lower == 'played') {
        playedOnly = true;
        continue;
      }

      remainingText.add(token);
    }

    return ParsedQuery(
      rawQuery: raw,
      textTerm: remainingText.join(' '),
      formats: formats,
      minDuration: minDuration,
      maxDuration: maxDuration,
      onlyFavorites: onlyFavorites,
      unplayedOnly: unplayedOnly,
      playedOnly: playedOnly,
    );
  }

  /// Toggles [token] presence in [currentQuery], appending or removing as needed.
  static String toggleToken(String currentQuery, String token) {
    final tokens = currentQuery
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final lowerToken = token.toLowerCase();
    final index = tokens.indexWhere((t) => t.toLowerCase() == lowerToken);

    if (index != -1) {
      tokens.removeAt(index);
    } else {
      tokens.add(token);
    }

    return tokens.join(' ');
  }
}
