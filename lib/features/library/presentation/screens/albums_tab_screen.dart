import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../shared/models/album.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';

/// Albums tab screen presenting an responsive album grid.
class AlbumsTabScreen extends StatelessWidget {
  const AlbumsTabScreen({super.key});

  static const List<Album> _sampleAlbums = [
    Album(
      id: 'alb-1',
      title: 'Random Access Memories',
      artist: 'Daft Punk',
      year: 2013,
      trackCount: 13,
    ),
    Album(
      id: 'alb-2',
      title: 'Starboy',
      artist: 'The Weeknd',
      year: 2016,
      trackCount: 18,
    ),
    Album(
      id: 'alb-3',
      title: 'Currents',
      artist: 'Tame Impala',
      year: 2015,
      trackCount: 13,
    ),
    Album(
      id: 'alb-4',
      title: 'After Hours',
      artist: 'The Weeknd',
      year: 2020,
      trackCount: 14,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 900
        ? 4
        : screenWidth > 600
            ? 3
            : 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Albums',
        automaticallyImplyLeading: false,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 0.72,
        ),
        itemCount: _sampleAlbums.length,
        itemBuilder: (context, index) {
          final album = _sampleAlbums[index];
          return AlbumCard.fromAlbum(
            album: album,
            onTap: () {},
          );
        },
      ),
    );
  }
}
