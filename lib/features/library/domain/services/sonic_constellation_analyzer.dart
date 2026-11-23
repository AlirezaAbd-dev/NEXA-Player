import 'dart:ui';
import '../models/sonic_star_node.dart';

/// Pure Dart geometric analyzer and lasso filter for the 2D Sonic Constellation.
class SonicConstellationAnalyzer {
  const SonicConstellationAnalyzer();

  /// Ray-casting algorithm to test if [point] is enclosed inside [polygon].
  bool isPointInPolygon(Offset point, List<Offset> polygon) {
    if (polygon.length < 3) return false;

    bool inside = false;
    int j = polygon.length - 1;

    for (int i = 0; i < polygon.length; i++) {
      final pi = polygon[i];
      final pj = polygon[j];

      if ((pi.dy > point.dy) != (pj.dy > point.dy) &&
          point.dx < (pj.dx - pi.dx) * (point.dy - pi.dy) / (pj.dy - pi.dy) + pi.dx) {
        inside = !inside;
      }
      j = i;
    }

    return inside;
  }

  /// Filters star nodes that fall inside a normalized lasso polygon where
  /// coordinates are normalized to [-1.0, 1.0].
  List<SonicStarNode> filterStarsInLasso(
    List<SonicStarNode> stars,
    List<Offset> normalizedPolygon,
  ) {
    if (normalizedPolygon.length < 3) return [];

    return stars.where((star) {
      final starPoint = Offset(star.x, star.y);
      return isPointInPolygon(starPoint, normalizedPolygon);
    }).toList();
  }

  /// Generates sample acoustic star nodes for testing and library exploration.
  List<SonicStarNode> generateSampleConstellation() {
    return [
      SonicStarNode.fromTrackMetrics(
        trackId: 'star_1',
        title: 'Starboy',
        artist: 'The Weeknd',
        bpm: 186.0, // High tempo
        energy: 0.85, // High energy
        valence: 0.55,
      ),
      SonicStarNode.fromTrackMetrics(
        trackId: 'star_2',
        title: 'Get Lucky',
        artist: 'Daft Punk',
        bpm: 116.0, // Mid tempo
        energy: 0.78, // High groove
        valence: 0.85, // High euphoria
      ),
      SonicStarNode.fromTrackMetrics(
        trackId: 'star_3',
        title: 'Midnight City',
        artist: 'M83',
        bpm: 105.0,
        energy: 0.70,
        valence: 0.45,
      ),
      SonicStarNode.fromTrackMetrics(
        trackId: 'star_4',
        title: 'Weightless',
        artist: 'Marconi Union',
        bpm: 65.0, // Ambient chill
        energy: 0.12, // Very low energy
        valence: 0.25, // Deep calm
      ),
      SonicStarNode.fromTrackMetrics(
        trackId: 'star_5',
        title: 'Giorgio by Moroder',
        artist: 'Daft Punk',
        bpm: 113.0,
        energy: 0.65,
        valence: 0.70,
      ),
      SonicStarNode.fromTrackMetrics(
        trackId: 'star_6',
        title: 'Clair de Lune',
        artist: 'Claude Debussy',
        bpm: 60.0,
        energy: 0.18,
        valence: 0.35,
      ),
    ];
  }
}
