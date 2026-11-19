import 'package:flutter/material.dart';

/// Supported types of dynamically computed smart playlists.
enum SmartPlaylistType {
  recentlyAdded('Recently Added', 'Tracks added to your library in the last 30 days', Icons.schedule_rounded),
  topRated('Top Rated', 'Tracks with high star ratings and favorites', Icons.star_rounded),
  favorites('My Favorites', 'All favorited tracks across your library', Icons.favorite_rounded),
  mostPlayed('Most Played', 'Your most frequently listened tracks', Icons.local_fire_department_rounded);

  const SmartPlaylistType(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

/// Represents a dynamically queried smart playlist configuration.
class SmartPlaylist {
  const SmartPlaylist({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
  });

  final SmartPlaylistType type;
  final String title;
  final String description;
  final IconData icon;

  factory SmartPlaylist.fromType(SmartPlaylistType type) {
    return SmartPlaylist(
      type: type,
      title: type.title,
      description: type.description,
      icon: type.icon,
    );
  }
}
