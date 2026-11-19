import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/playlists/domain/models/m3u_entry.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/services/m3u_service.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';

/// Concrete implementation of [IM3uService] parsing and exporting standard M3U/M3U8 playlists.
class M3uServiceImpl implements IM3uService {
  M3uServiceImpl({
    required IPlaylistsRepository playlistsRepository,
    required ITracksRepository tracksRepository,
  })  : _playlistsRepo = playlistsRepository,
        _tracksRepo = tracksRepository;

  final IPlaylistsRepository _playlistsRepo;
  final ITracksRepository _tracksRepo;

  @override
  String exportToM3u(
    Playlist playlist,
    List<Track> tracks, {
    bool extended = true,
  }) {
    final buffer = StringBuffer();
    if (extended) {
      buffer.writeln('#EXTM3U');
      buffer.writeln('#PLAYLIST:${playlist.name}');
    }

    for (final track in tracks) {
      if (extended) {
        final sec = track.duration.inSeconds;
        buffer.writeln('#EXTINF:$sec,${track.artist} - ${track.title}');
      }
      buffer.writeln(track.filePath);
    }

    return buffer.toString();
  }

  @override
  List<M3uEntry> parseM3u(String content) {
    final entries = <M3uEntry>[];
    final lines = content.split(RegExp(r'\r?\n'));

    int? pendingDuration;
    String? pendingTitle;
    String? pendingArtist;

    for (var rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('#EXTINF:')) {
        // Example: #EXTINF:230,The Weeknd - Starboy or #EXTINF:180,Track Title
        final infoPart = line.substring(8);
        final commaIdx = infoPart.indexOf(',');
        if (commaIdx != -1) {
          final durationStr = infoPart.substring(0, commaIdx).trim();
          pendingDuration = int.tryParse(durationStr) ?? -1;

          final namePart = infoPart.substring(commaIdx + 1).trim();
          final dashIdx = namePart.indexOf(' - ');
          if (dashIdx != -1) {
            pendingArtist = namePart.substring(0, dashIdx).trim();
            pendingTitle = namePart.substring(dashIdx + 3).trim();
          } else {
            pendingTitle = namePart;
            pendingArtist = null;
          }
        }
        continue;
      }

      // Ignore other comments or metadata directives
      if (line.startsWith('#')) {
        continue;
      }

      // File path line
      entries.add(M3uEntry(
        filePath: line,
        title: pendingTitle,
        artist: pendingArtist,
        durationSeconds: pendingDuration ?? -1,
      ));

      // Reset pending state
      pendingDuration = null;
      pendingTitle = null;
      pendingArtist = null;
    }

    return entries;
  }

  @override
  Future<Result<Playlist, Failure>> importM3u(
    String playlistName,
    String content,
  ) async {
    try {
      final entries = parseM3u(content);
      if (entries.isEmpty) {
        return const Result.failure(
          UnexpectedFailure('M3U content contains no valid track entries'),
        );
      }

      // 1. Create playlist
      final createResult = await _playlistsRepo.createPlaylist(
        playlistName,
        description: 'Imported from M3U playlist (${entries.length} tracks)',
      );

      if (createResult.isFailure) {
        return Result.failure(createResult.failureOrNull!);
      }

      final playlist = createResult.valueOrNull!;

      // 2. Load all library tracks to match paths or titles
      final tracksResult = await _tracksRepo.getAllTracks();
      final allTracks = tracksResult.valueOrNull ?? [];

      final tracksByPath = {
        for (final t in allTracks)
          if (t.filePath != null) t.filePath!.toLowerCase(): t,
      };
      final tracksByTitleArtist = {
        for (final t in allTracks) '${t.artist.toLowerCase()}:::${t.title.toLowerCase()}': t
      };

      // 3. Match and link tracks
      for (final entry in entries) {
        Track? matchedTrack = tracksByPath[entry.filePath.toLowerCase()];

        if (matchedTrack == null && entry.artist != null && entry.title != null) {
          final key = '${entry.artist!.toLowerCase()}:::${entry.title!.toLowerCase()}';
          matchedTrack = tracksByTitleArtist[key];
        }

        if (matchedTrack != null) {
          await _playlistsRepo.addTrackToPlaylist(playlist.id, matchedTrack.id);
        }
      }

      // 4. Return refreshed playlist
      final refreshed = await _playlistsRepo.getPlaylistById(playlist.id);
      return Result.success(refreshed.valueOrNull ?? playlist);
    } catch (e, st) {
      return Result.failure(UnexpectedFailure('Failed to import M3U playlist: $e', e, st));
    }
  }
}
