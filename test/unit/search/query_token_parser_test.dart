import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/search/domain/query_token_parser.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  group('QueryTokenParser Unit Tests', () {
    test('parses empty query cleanly', () {
      final parsed = QueryTokenParser.parse('');
      expect(parsed.rawQuery, isEmpty);
      expect(parsed.textTerm, isEmpty);
      expect(parsed.hasFilters, isFalse);
    });

    test('extracts audio formats and separates search terms', () {
      final parsed = QueryTokenParser.parse('Daft Punk flac mp3');
      expect(parsed.textTerm, equals('Daft Punk'));
      expect(parsed.formats, containsAll(['flac', 'mp3']));
      expect(parsed.hasFilters, isTrue);
    });

    test('extracts duration comparison filters', () {
      final parsedMin = QueryTokenParser.parse('>5m');
      expect(parsedMin.minDuration, equals(const Duration(minutes: 5)));
      expect(parsedMin.maxDuration, isNull);

      final parsedMax = QueryTokenParser.parse('<3m');
      expect(parsedMax.maxDuration, equals(const Duration(minutes: 3)));

      final parsedSeconds = QueryTokenParser.parse('>30s');
      expect(parsedSeconds.minDuration, equals(const Duration(seconds: 30)));
    });

    test('extracts favorite and playback state tokens', () {
      final parsedFav = QueryTokenParser.parse('favorites Synthwave');
      expect(parsedFav.onlyFavorites, isTrue);
      expect(parsedFav.textTerm, equals('Synthwave'));

      final parsedUnplayed = QueryTokenParser.parse('unplayed');
      expect(parsedUnplayed.unplayedOnly, isTrue);

      final parsedPlayed = QueryTokenParser.parse('played');
      expect(parsedPlayed.playedOnly, isTrue);
    });

    test('filters candidate tracks accurately', () {
      const track1 = Track(
        id: '1',
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'RAM',
        duration: Duration(minutes: 4, seconds: 8),
        filePath: '/music/get_lucky.flac',
        isFavorite: true,
        playCount: 12,
      );

      const track2 = Track(
        id: '2',
        title: 'Instant Crush',
        artist: 'Daft Punk',
        album: 'RAM',
        duration: Duration(minutes: 5, seconds: 37),
        filePath: '/music/instant_crush.mp3',
        isFavorite: false,
        playCount: 0,
      );

      // Filter by format flac
      final flacQuery = QueryTokenParser.parse('flac');
      expect(flacQuery.filterTracks([track1, track2]), equals([track1]));

      // Filter by duration >5m
      final durQuery = QueryTokenParser.parse('>5m');
      expect(durQuery.filterTracks([track1, track2]), equals([track2]));

      // Filter by unplayed
      final unplayedQuery = QueryTokenParser.parse('unplayed');
      expect(unplayedQuery.filterTracks([track1, track2]), equals([track2]));

      // Filter by favorite
      final favQuery = QueryTokenParser.parse('favorites');
      expect(favQuery.filterTracks([track1, track2]), equals([track1]));

      // Combined query
      final comboQuery = QueryTokenParser.parse('Daft Punk >4m unplayed');
      expect(comboQuery.filterTracks([track1, track2]), equals([track2]));
    });

    test('toggleToken appends or removes tokens correctly', () {
      var query = 'synthwave';
      query = QueryTokenParser.toggleToken(query, 'flac');
      expect(query, equals('synthwave flac'));

      query = QueryTokenParser.toggleToken(query, 'flac');
      expect(query, equals('synthwave'));
    });
  });
}
