import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/library/domain/models/sonic_star_node.dart';
import 'package:nexa_player/features/library/domain/services/sonic_constellation_analyzer.dart';

void main() {
  group('SonicStarNode Model & Mapping Tests', () {
    test('maps BPM and Energy accurately into normalized 2D celestial coordinates', () {
      // 120 BPM (midpoint) & 0.5 energy (midpoint) -> (0.0, 0.0) center
      final center = SonicStarNode.fromTrackMetrics(
        trackId: 't1',
        title: 'Mid',
        artist: 'Artist',
        bpm: 120.0,
        energy: 0.5,
        valence: 0.5,
      );
      expect(center.x, closeTo(0.0, 0.01));
      expect(center.y, closeTo(0.0, 0.01));

      // 60 BPM (minimum) & 0.0 energy -> (-1.0, -1.0)
      final bottomFarLeft = SonicStarNode.fromTrackMetrics(
        trackId: 't2',
        title: 'Chill',
        artist: 'Ambient',
        bpm: 60.0,
        energy: 0.0,
        valence: 0.2,
      );
      expect(bottomFarLeft.x, equals(-1.0));
      expect(bottomFarLeft.y, equals(-1.0));

      // 180 BPM (maximum) & 1.0 energy -> (1.0, 1.0)
      final topFarRight = SonicStarNode.fromTrackMetrics(
        trackId: 't3',
        title: 'Fast',
        artist: 'Banger',
        bpm: 180.0,
        energy: 1.0,
        valence: 0.9,
      );
      expect(topFarRight.x, equals(1.0));
      expect(topFarRight.y, equals(1.0));
    });

    test('serializes and deserializes cleanly through JSON', () {
      final node = SonicStarNode.fromTrackMetrics(
        trackId: 'test_node',
        title: 'Star Dust',
        artist: 'Cosmic Voyager',
        bpm: 128.0,
        energy: 0.82,
        valence: 0.75,
      );

      final json = node.toJson();
      final restored = SonicStarNode.fromJson(json);

      expect(restored, equals(node));
      expect(restored.trackId, equals('test_node'));
      expect(restored.bpm, equals(128.0));
    });
  });

  group('SonicConstellationAnalyzer Geometric Tests', () {
    const analyzer = SonicConstellationAnalyzer();

    test('isPointInPolygon correctly detects interior vs exterior points', () {
      // Square polygon with corners at (-0.5, -0.5), (0.5, -0.5), (0.5, 0.5), (-0.5, 0.5)
      const square = [
        Offset(-0.5, -0.5),
        Offset(0.5, -0.5),
        Offset(0.5, 0.5),
        Offset(-0.5, 0.5),
      ];

      // Point at origin (0, 0) is strictly inside
      expect(analyzer.isPointInPolygon(const Offset(0.0, 0.0), square), isTrue);

      // Points strictly outside
      expect(analyzer.isPointInPolygon(const Offset(0.9, 0.0), square), isFalse);
      expect(analyzer.isPointInPolygon(const Offset(-0.8, -0.8), square), isFalse);
      expect(analyzer.isPointInPolygon(const Offset(0.0, 1.2), square), isFalse);
    });

    test('filterStarsInLasso isolates stars within custom user freehand loop', () {
      final stars = [
        // Inside target box
        const SonicStarNode(
          trackId: 'in_1',
          title: 'Inner One',
          artist: 'A',
          bpm: 120,
          energy: 0.5,
          valence: 0.5,
          x: 0.1,
          y: 0.1,
        ),
        const SonicStarNode(
          trackId: 'in_2',
          title: 'Inner Two',
          artist: 'B',
          bpm: 130,
          energy: 0.6,
          valence: 0.5,
          x: -0.2,
          y: -0.2,
        ),
        // Outside target box
        const SonicStarNode(
          trackId: 'out_1',
          title: 'Outer One',
          artist: 'C',
          bpm: 60,
          energy: 0.1,
          valence: 0.2,
          x: 0.9,
          y: 0.9,
        ),
      ];

      const lasso = [
        Offset(-0.5, -0.5),
        Offset(0.5, -0.5),
        Offset(0.5, 0.5),
        Offset(-0.5, 0.5),
      ];

      final filtered = analyzer.filterStarsInLasso(stars, lasso);
      expect(filtered.length, equals(2));
      expect(filtered.map((s) => s.trackId), containsAll(['in_1', 'in_2']));
      expect(filtered.map((s) => s.trackId), isNot(contains('out_1')));
    });
  });
}
