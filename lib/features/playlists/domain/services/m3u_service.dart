import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import '../models/m3u_entry.dart';

/// Contract for exporting and importing standard M3U/M3U8 playlists.
abstract interface class IM3uService {
  /// Converts a [playlist] and its [tracks] into an M3U8 string format.
  String exportToM3u(
    Playlist playlist,
    List<Track> tracks, {
    bool extended = true,
  });

  /// Parses raw M3U / M3U8 file [content] into a list of [M3uEntry] models.
  List<M3uEntry> parseM3u(String content);

  /// Imports an M3U file content, creating a new playlist and matching tracks from the library.
  Future<Result<Playlist, Failure>> importM3u(
    String playlistName,
    String content,
  );
}
