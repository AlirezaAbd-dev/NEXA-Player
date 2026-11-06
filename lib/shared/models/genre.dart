import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Immutable domain entity representing a music genre.
class Genre extends Equatable {
  const Genre({
    required this.id,
    required this.name,
    this.trackCount = 0,
    this.gradientColors,
  });

  final String id;
  final String name;
  final int trackCount;
  final List<Color>? gradientColors;

  /// Human-readable track count badge label.
  String get trackCountLabel =>
      trackCount == 1 ? '1 Track' : '$trackCount Tracks';

  /// Deterministic vibrant gradient derived from genre name or custom colors.
  LinearGradient get resolvedGradient {
    if (gradientColors != null && gradientColors!.length >= 2) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors!,
      );
    }

    // Curated high-contrast aesthetic gradients
    const palettes = <List<Color>>[
      [Color(0xFF00E5FF), Color(0xFF651FFF)], // Cyan to Electric Purple
      [Color(0xFFFF3D00), Color(0xFFFF9100)], // Lava Red to Orange
      [Color(0xFF00E676), Color(0xFF00B0FF)], // Emerald to Sky Blue
      [Color(0xFFE040FB), Color(0xFF7C4DFF)], // Magenta to Violet
      [Color(0xFF2979FF), Color(0xFF00E5FF)], // Royal Blue to Cyan
      [Color(0xFFFF1744), Color(0xFFF50057)], // Ruby to Hot Pink
      [Color(0xFFFFAB00), Color(0xFFFF3D00)], // Amber to Sunset
      [Color(0xFF651FFF), Color(0xFF00B0FF)], // Deep Purple to Azure
    ];

    final index = (name.hashCode.abs()) % palettes.length;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: palettes[index],
    );
  }

  Genre copyWith({
    String? id,
    String? name,
    int? trackCount,
    List<Color>? gradientColors,
  }) {
    return Genre(
      id: id ?? this.id,
      name: name ?? this.name,
      trackCount: trackCount ?? this.trackCount,
      gradientColors: gradientColors ?? this.gradientColors,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        trackCount,
        gradientColors,
      ];
}
