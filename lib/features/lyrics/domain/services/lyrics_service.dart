import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Service contract governing discovery, parsing, online fetching,
/// local caching, and manual editing of track lyrics.
abstract interface class ILyricsService {
  /// Resolves lyrics for [track] across cache, local `.lrc` files, and online providers.
  Future<Result<Lyrics?, Failure>> getLyricsForTrack(
    Track track, {
    bool forceRefresh = false,
  });

  /// Saves or updates custom/edited [lyrics] for [track].
  Future<Result<void, Failure>> saveLyrics(
    Track track,
    Lyrics lyrics, {
    bool saveToLrcFile = false,
  });

  /// Updates the synchronization time offset (in milliseconds) for [trackId].
  Future<Result<void, Failure>> updateOffset(
    String trackId,
    int offsetMs,
  );

  /// Clears cached lyrics for [trackId].
  Future<Result<void, Failure>> deleteLyrics(String trackId);

  /// Directly attempts to query online lyrics providers (e.g. LRCLIB) for [track].
  Future<Result<Lyrics?, Failure>> fetchOnlineLyrics(Track track);
}
