import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/shared/models/models.dart';

void main() {
  group('Domain Models Unit Tests', () {
    test('Track creates and formats duration and subtitles accurately', () {
      const track = Track(
        id: 't1',
        title: 'Midnight Stargazer',
        artist: 'NEXA Sound',
        album: 'Cosmic Drift',
        duration: Duration(minutes: 3, seconds: 45),
        trackNumber: 1,
        year: 2026,
      );

      expect(track.id, equals('t1'));
      expect(track.title, equals('Midnight Stargazer'));
      expect(track.formattedDuration, equals('3:45'));
      expect(track.artistAndAlbum, equals('NEXA Sound • Cosmic Drift'));

      final cloned = track.copyWith(isFavorite: true);
      expect(cloned.isFavorite, isTrue);
      expect(cloned == track, isFalse);
    });

    test('Album formats subtitle and track count label properly', () {
      const album = Album(
        id: 'a1',
        title: 'Cosmic Drift',
        artist: 'NEXA Sound',
        year: 2026,
        trackCount: 10,
      );

      expect(album.artistAndYear, equals('NEXA Sound • 2026'));
      expect(album.trackCountLabel, equals('10 Tracks'));

      const singleTrackAlbum = Album(
        id: 'a2',
        title: 'Single Ep',
        artist: 'NEXA Sound',
        trackCount: 1,
      );
      expect(singleTrackAlbum.artistAndYear, equals('NEXA Sound'));
      expect(singleTrackAlbum.trackCountLabel, equals('1 Track'));
    });

    test('Artist formats tracks and albums labels properly', () {
      const artist = Artist(
        id: 'ar1',
        name: 'NEXA Sound',
        trackCount: 24,
        albumCount: 2,
      );

      expect(artist.tracksAndAlbumsLabel, equals('24 Tracks • 2 Albums'));

      const singleArtist = Artist(
        id: 'ar2',
        name: 'Solo',
        trackCount: 1,
        albumCount: 1,
      );
      expect(singleArtist.tracksAndAlbumsLabel, equals('1 Track • 1 Album'));
    });

    test('Genre resolves deterministic gradient and labels properly', () {
      const genre = Genre(
        id: 'g1',
        name: 'Synthwave',
        trackCount: 142,
      );

      expect(genre.trackCountLabel, equals('142 Tracks'));
      final grad = genre.resolvedGradient;
      expect(grad.colors.length, greaterThanOrEqualTo(2));

      const customGenre = Genre(
        id: 'g2',
        name: 'Custom',
        gradientColors: [Colors.red, Colors.blue],
      );
      expect(customGenre.resolvedGradient.colors, equals([Colors.red, Colors.blue]));
    });
  });
}
