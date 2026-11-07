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

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'track_count': trackCount,
      'gradient_colors': gradientColors
          ?.map((c) => c.value.toRadixString(16).padLeft(8, '0'))
          .join(','),
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory Genre.fromMap(Map<String, dynamic> map) {
    final colorsRaw = map['gradient_colors'] ?? map['gradientColors'];
    List<Color>? colors;

    if (colorsRaw is String && colorsRaw.isNotEmpty) {
      colors = colorsRaw.split(',').map((hex) {
        final val = int.tryParse(hex.trim(), radix: 16);
        return val != null ? Color(val) : const Color(0xFF00E5FF);
      }).toList();
    } else if (colorsRaw is List<Color>) {
      colors = colorsRaw;
    }

    return Genre(
      id: map['id'] as String,
      name: map['name'] as String,
      trackCount: (map['track_count'] ?? map['trackCount'] ?? 0) as int,
      gradientColors: colors,
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
