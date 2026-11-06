import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/models/genre.dart';
import '../../../../shared/widgets/cards/genre_card.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_fab.dart';

/// Playlists tab screen.
class PlaylistsTabScreen extends StatelessWidget {
  const PlaylistsTabScreen({super.key});

  static const List<Genre> _samplePlaylists = [
    Genre(id: 'pl-1', name: 'Synthwave Night Drive', trackCount: 34),
    Genre(id: 'pl-2', name: 'Late Night Focus', trackCount: 52),
    Genre(id: 'pl-3', name: 'Electronic Workout', trackCount: 28),
    Genre(id: 'pl-4', name: 'Audiophile Mastertracks', trackCount: 16),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Playlists',
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90.0),
        child: GlassFAB(
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Playlist'),
          onPressed: () {},
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          Text(
            'Smart Playlists',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._samplePlaylists.map(
            (pl) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: GenreCard.fromGenre(
                genre: pl,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
