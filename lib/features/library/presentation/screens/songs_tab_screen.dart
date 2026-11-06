import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/cards/track_tile.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_text_field.dart';

/// Songs tab screen displaying searchable song library.
class SongsTabScreen extends StatefulWidget {
  const SongsTabScreen({super.key});

  @override
  State<SongsTabScreen> createState() => _SongsTabScreenState();
}

class _SongsTabScreenState extends State<SongsTabScreen> {
  final _searchController = TextEditingController();

  static const List<Track> _sampleTracks = [
    Track(
      id: 'trk-1',
      title: 'Starboy',
      artist: 'The Weeknd • Daft Punk',
      album: 'Starboy',
      duration: Duration(minutes: 3, seconds: 50),
      trackNumber: 1,
      year: 2016,
    ),
    Track(
      id: 'trk-2',
      title: 'Get Lucky',
      artist: 'Daft Punk • Pharrell Williams',
      album: 'Random Access Memories',
      duration: Duration(minutes: 4, seconds: 8),
      trackNumber: 2,
      year: 2013,
    ),
    Track(
      id: 'trk-3',
      title: 'Midnight City',
      artist: 'M83',
      album: 'Hurry Up, We\'re Dreaming',
      duration: Duration(minutes: 4, seconds: 3),
      trackNumber: 3,
      year: 2011,
    ),
    Track(
      id: 'trk-4',
      title: 'The Less I Know The Better',
      artist: 'Tame Impala',
      album: 'Currents',
      duration: Duration(minutes: 3, seconds: 36),
      trackNumber: 4,
      year: 2015,
    ),
    Track(
      id: 'trk-5',
      title: 'Blinding Lights',
      artist: 'The Weeknd',
      album: 'After Hours',
      duration: Duration(minutes: 3, seconds: 20),
      trackNumber: 5,
      year: 2020,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Songs',
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded),
            onPressed: null,
            tooltip: 'Sort order',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          GlassTextField(
            controller: _searchController,
            hintText: 'Search songs, artists, albums...',
            prefixIcon: Icons.search_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'All Songs (${_sampleTracks.length})',
            style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._sampleTracks.map(
            (track) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TrackTile.fromTrack(
                track: track,
                onTap: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }
}
