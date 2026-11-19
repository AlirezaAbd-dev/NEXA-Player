import 'package:flutter/foundation.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/services/share_service.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Concrete implementation of [IShareService] coordinating track and playlist sharing.
class ShareServiceImpl implements IShareService {
  const ShareServiceImpl({this.onShareTrack, this.onSharePlaylist});

  final Future<void> Function(Track track)? onShareTrack;
  final Future<void> Function(Playlist playlist, List<Track> tracks)? onSharePlaylist;

  @override
  Future<Result<void, Failure>> shareTrack(Track track) async {
    try {
      if (onShareTrack != null) {
        await onShareTrack!(track);
      } else {
        debugPrint('Sharing track: "${track.title}" by ${track.artist} (${track.filePath})');
      }
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(UnexpectedFailure('Failed to share track: $e', e, st));
    }
  }

  @override
  Future<Result<void, Failure>> sharePlaylist(
    Playlist playlist,
    List<Track> tracks,
  ) async {
    try {
      if (onSharePlaylist != null) {
        await onSharePlaylist!(playlist, tracks);
      } else {
        debugPrint('Sharing playlist: "${playlist.name}" with ${tracks.length} tracks');
      }
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(UnexpectedFailure('Failed to share playlist: $e', e, st));
    }
  }
}
