import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Contract for sharing audio tracks, files, or branded track cards.
abstract interface class IShareService {
  /// Shares an individual track via standard system intent or branded share card.
  Future<Result<void, Failure>> shareTrack(Track track);

  /// Shares a playlist as an M3U export or text manifest.
  Future<Result<void, Failure>> sharePlaylist(Playlist playlist, List<Track> tracks);
}
