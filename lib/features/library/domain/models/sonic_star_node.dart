import 'package:equatable/equatable.dart';

/// Immutable model representing a track as a star on the 2D Sonic Constellation celestial map.
class SonicStarNode extends Equatable {
  final String trackId;
  final String title;
  final String artist;
  final double bpm; // 60.0 to 180.0
  final double energy; // 0.0 (ambient/chill) to 1.0 (intense/driving)
  final double valence; // 0.0 (melancholic/dark) to 1.0 (bright/euphoric)
  final double x; // Normalized coordinate in [-1.0, 1.0]
  final double y; // Normalized coordinate in [-1.0, 1.0]
  final int colorValue;

  const SonicStarNode({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.bpm,
    required this.energy,
    required this.valence,
    required this.x,
    required this.y,
    this.colorValue = 0xFF00E5FF,
  });

  /// Derives 2D celestial coordinates from acoustic tempo and energy.
  factory SonicStarNode.fromTrackMetrics({
    required String trackId,
    required String title,
    required String artist,
    required double bpm,
    required double energy,
    required double valence,
  }) {
    // Map BPM (60 - 180) to X in [-1.0, 1.0]
    final normX = (((bpm - 60.0) / 120.0) * 2.0 - 1.0).clamp(-1.0, 1.0);
    // Map Energy (0.0 - 1.0) to Y in [-1.0, 1.0]
    final normY = (energy * 2.0 - 1.0).clamp(-1.0, 1.0);

    // Color: cool blue/cyan for chill valence, warm amber/magenta for high valence
    final int color = valence > 0.6
        ? 0xFFFF6090 // Energetic pink/coral
        : valence > 0.35
            ? 0xFF00E5FF // Cyan / electric blue
            : 0xFF7C4DFF; // Deep indigo / contemplative

    return SonicStarNode(
      trackId: trackId,
      title: title,
      artist: artist,
      bpm: bpm,
      energy: energy,
      valence: valence,
      x: (normX * 1000).round() / 1000.0,
      y: (normY * 1000).round() / 1000.0,
      colorValue: color,
    );
  }

  Map<String, dynamic> toJson() => {
        'trackId': trackId,
        'title': title,
        'artist': artist,
        'bpm': bpm,
        'energy': energy,
        'valence': valence,
        'x': x,
        'y': y,
        'colorValue': colorValue,
      };

  factory SonicStarNode.fromJson(Map<String, dynamic> json) => SonicStarNode(
        trackId: json['trackId'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String,
        bpm: (json['bpm'] as num).toDouble(),
        energy: (json['energy'] as num).toDouble(),
        valence: (json['valence'] as num).toDouble(),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF00E5FF,
      );

  @override
  List<Object?> get props => [trackId, title, artist, bpm, energy, valence, x, y, colorValue];
}
