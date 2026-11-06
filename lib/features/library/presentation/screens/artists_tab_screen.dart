import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/models/artist.dart';
import '../../../../shared/widgets/cards/artist_card.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';

/// Artists tab screen presenting artist cards.
class ArtistsTabScreen extends StatelessWidget {
  const ArtistsTabScreen({super.key});

  static const List<Artist> _sampleArtists = [
    Artist(
      id: 'art-1',
      name: 'Daft Punk',
      trackCount: 42,
      albumCount: 4,
    ),
    Artist(
      id: 'art-2',
      name: 'The Weeknd',
      trackCount: 68,
      albumCount: 5,
    ),
    Artist(
      id: 'art-3',
      name: 'Tame Impala',
      trackCount: 38,
      albumCount: 4,
    ),
    Artist(
      id: 'art-4',
      name: 'M83',
      trackCount: 29,
      albumCount: 3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Artists',
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        itemCount: _sampleArtists.length,
        itemBuilder: (context, index) {
          final artist = _sampleArtists[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ArtistCard.fromArtist(
              artist: artist,
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
