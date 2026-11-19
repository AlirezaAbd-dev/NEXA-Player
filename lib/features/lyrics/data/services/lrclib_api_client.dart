import 'dart:convert';
import 'dart:io';
import 'package:nexa_player/core/utils/result.dart';

/// Response payload from LRCLIB API.
class LrclibResponse {
  const LrclibResponse({
    required this.id,
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.durationSeconds,
    this.instrumental = false,
    this.plainLyrics,
    this.syncedLyrics,
  });

  final int id;
  final String trackName;
  final String artistName;
  final String? albumName;
  final int? durationSeconds;
  final bool instrumental;
  final String? plainLyrics;
  final String? syncedLyrics;

  factory LrclibResponse.fromJson(Map<String, dynamic> json) {
    return LrclibResponse(
      id: json['id'] as int? ?? 0,
      trackName: json['trackName'] as String? ?? json['name'] as String? ?? '',
      artistName: json['artistName'] as String? ?? '',
      albumName: json['albumName'] as String?,
      durationSeconds: (json['duration'] as num?)?.toInt(),
      instrumental: json['instrumental'] as bool? ?? false,
      plainLyrics: json['plainLyrics'] as String?,
      syncedLyrics: json['syncedLyrics'] as String?,
    );
  }
}

/// Abstract contract for querying LRCLIB online lyrics.
abstract interface class ILrclibApiClient {
  Future<Result<LrclibResponse?, Failure>> fetchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  });
}

/// Production implementation of [ILrclibApiClient] communicating with https://lrclib.net.
class LrclibApiClient implements ILrclibApiClient {
  LrclibApiClient({HttpClient? httpClient}) : _client = httpClient ?? HttpClient() {
    _client.connectionTimeout = const Duration(seconds: 10);
  }

  final HttpClient _client;
  static const String _host = 'lrclib.net';

  @override
  Future<Result<LrclibResponse?, Failure>> fetchLyrics({
    required String trackName,
    required String artistName,
    String? albumName,
    int? durationSeconds,
  }) async {
    try {
      final queryParams = <String, String>{
        'track_name': trackName,
        'artist_name': artistName,
      };
      if (albumName != null && albumName.isNotEmpty) {
        queryParams['album_name'] = albumName;
      }
      if (durationSeconds != null && durationSeconds > 0) {
        queryParams['duration'] = durationSeconds.toString();
      }

      final uri = Uri.https(_host, '/api/get', queryParams);
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'NEXA-Player/1.0.0 (https://github.com/AlirezaAbd-dev/NEXA-Player)');

      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        return Result.success(LrclibResponse.fromJson(json));
      } else if (response.statusCode == 404) {
        // Fallback to fuzzy search query
        return _searchFallback(trackName, artistName);
      } else {
        return Result.failure(
          NetworkFailure('LRCLIB responded with HTTP status ${response.statusCode}'),
        );
      }
    } catch (e, st) {
      return Result.failure(
        NetworkFailure('Failed to contact LRCLIB: $e', e, st),
      );
    }
  }

  Future<Result<LrclibResponse?, Failure>> _searchFallback(
    String trackName,
    String artistName,
  ) async {
    try {
      final query = '$artistName $trackName';
      final uri = Uri.https(_host, '/api/search', {'q': query});
      final request = await _client.getUrl(uri);
      request.headers.set('User-Agent', 'NEXA-Player/1.0.0');

      final response = await request.close();
      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final list = jsonDecode(body) as List<dynamic>;
        if (list.isNotEmpty) {
          final first = list.first as Map<String, dynamic>;
          return Result.success(LrclibResponse.fromJson(first));
        }
      }
      return const Result.success(null);
    } catch (e, st) {
      return Result.failure(
        NetworkFailure('LRCLIB fallback search failed: $e', e, st),
      );
    }
  }
}
