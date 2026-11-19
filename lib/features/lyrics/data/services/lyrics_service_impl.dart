import 'dart:convert';
import 'dart:io';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/lyrics/data/services/lrclib_api_client.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyrics_source.dart';
import 'package:nexa_player/features/lyrics/domain/services/lrc_parser.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';

/// Concrete implementation of [ILyricsService] combining local cache,
/// companion `.lrc` files, and the LRCLIB online API.
class LyricsServiceImpl implements ILyricsService {
  LyricsServiceImpl({
    required IStorageService storageService,
    required ILrclibApiClient lrclibClient,
    LrcParser? parser,
  })  : _storage = storageService,
        _lrclib = lrclibClient,
        _parser = parser ?? const LrcParser();

  final IStorageService _storage;
  final ILrclibApiClient _lrclib;
  final LrcParser _parser;

  static const String _storagePrefix = 'nexa_lyrics_';

  String _cacheKey(String trackId) => '$_storagePrefix$trackId';

  @override
  Future<Result<Lyrics?, Failure>> getLyricsForTrack(
    Track track, {
    bool forceRefresh = false,
  }) async {
    try {
      // 1. Check local persistent cache
      if (!forceRefresh) {
        final cachedResult = _storage.getString(_cacheKey(track.id));
        if (cachedResult.isSuccess && cachedResult.valueOrNull != null) {
          try {
            final json = jsonDecode(cachedResult.valueOrNull!) as Map<String, dynamic>;
            final lyrics = Lyrics.fromMap(json);
            return Result.success(lyrics);
          } catch (_) {
            // Invalid cache, continue to fallbacks
          }
        }

        // 2. Check local filesystem companion .lrc file
        final localLrc = await _readLocalLrcFile(track);
        if (localLrc != null) {
          await _saveToCache(track.id, localLrc);
          return Result.success(localLrc);
        }
      }

      // 3. Query online LRCLIB service
      return await fetchOnlineLyrics(track);
    } catch (e, st) {
      return Result.failure(
        UnexpectedFailure('Failed to resolve lyrics for track ${track.id}: $e', e, st),
      );
    }
  }

  @override
  Future<Result<Lyrics?, Failure>> fetchOnlineLyrics(Track track) async {
    try {
      final onlineResult = await _lrclib.fetchLyrics(
        trackName: track.title,
        artistName: track.artist,
        albumName: track.album,
        durationSeconds: track.duration.inSeconds,
      );

      if (onlineResult.isFailure) {
        return Result.failure(onlineResult.failureOrNull!);
      }

      final payload = onlineResult.valueOrNull;
      if (payload == null) {
        return const Result.success(null);
      }

      Lyrics? parsedLyrics;
      if (payload.syncedLyrics != null && payload.syncedLyrics!.trim().isNotEmpty) {
        parsedLyrics = _parser.parse(
          payload.syncedLyrics!,
          trackId: track.id,
          source: LyricsSource.lrclib,
        );
      } else if (payload.plainLyrics != null && payload.plainLyrics!.trim().isNotEmpty) {
        parsedLyrics = _parser.parsePlainText(
          payload.plainLyrics!,
          trackId: track.id,
          source: LyricsSource.lrclib,
        );
      }

      if (parsedLyrics != null) {
        await _saveToCache(track.id, parsedLyrics);
      }

      return Result.success(parsedLyrics);
    } catch (e, st) {
      return Result.failure(
        UnexpectedFailure('Failed to fetch online lyrics: $e', e, st),
      );
    }
  }

  @override
  Future<Result<void, Failure>> saveLyrics(
    Track track,
    Lyrics lyrics, {
    bool saveToLrcFile = false,
  }) async {
    try {
      await _saveToCache(track.id, lyrics);

      if (saveToLrcFile && track.filePath != null) {
        final filePath = track.filePath!;
        final dotIndex = filePath.lastIndexOf('.');
        final lrcPath = dotIndex != -1
            ? '${filePath.substring(0, dotIndex)}.lrc'
            : '$filePath.lrc';

        final file = File(lrcPath);
        final content = lyrics.rawLrc ??
            _parser.toLrc(
              lyrics.lines,
              title: track.title,
              artist: track.artist,
              album: track.album,
              offsetMs: lyrics.offsetMs,
            );
        await file.writeAsString(content);
      }

      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        UnexpectedFailure('Failed to save lyrics: $e', e, st),
      );
    }
  }

  @override
  Future<Result<void, Failure>> updateOffset(String trackId, int offsetMs) async {
    try {
      final cachedResult = _storage.getString(_cacheKey(trackId));
      if (cachedResult.isSuccess && cachedResult.valueOrNull != null) {
        final json = jsonDecode(cachedResult.valueOrNull!) as Map<String, dynamic>;
        final currentLyrics = Lyrics.fromMap(json);
        final updated = currentLyrics.copyWith(offsetMs: offsetMs);
        await _saveToCache(trackId, updated);
      }
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        UnexpectedFailure('Failed to update lyrics offset: $e', e, st),
      );
    }
  }

  @override
  Future<Result<void, Failure>> deleteLyrics(String trackId) async {
    try {
      await _storage.remove(_cacheKey(trackId));
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        UnexpectedFailure('Failed to delete lyrics: $e', e, st),
      );
    }
  }

  Future<void> _saveToCache(String trackId, Lyrics lyrics) async {
    final jsonStr = jsonEncode(lyrics.toMap());
    await _storage.setString(_cacheKey(trackId), jsonStr);
  }

  Future<Lyrics?> _readLocalLrcFile(Track track) async {
    final filePath = track.filePath;
    if (filePath == null) return null;

    final dotIndex = filePath.lastIndexOf('.');
    final lrcPath = dotIndex != -1
        ? '${filePath.substring(0, dotIndex)}.lrc'
        : '$filePath.lrc';

    final file = File(lrcPath);
    if (file.existsSync()) {
      final content = await file.readAsString();
      if (content.trim().isNotEmpty) {
        return _parser.parse(
          content,
          trackId: track.id,
          source: LyricsSource.lrcFile,
        );
      }
    }
    return null;
  }
}
