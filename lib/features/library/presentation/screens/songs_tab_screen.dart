import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/duration_x.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';

/// Songs tab screen displaying searchable and sortable track library.
class SongsTabScreen extends ConsumerStatefulWidget {
  const SongsTabScreen({super.key});

  @override
  ConsumerState<SongsTabScreen> createState() => _SongsTabScreenState();
}

class _SongsTabScreenState extends ConsumerState<SongsTabScreen> {
  final _searchController = TextEditingController();
  TrackSortBy _sortBy = TrackSortBy.title;
  bool _ascending = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text;
      if (text != _searchQuery) {
        setState(() {
          _searchQuery = text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavorite(Track track) async {
    final repo = ref.read(tracksRepositoryProvider);
    final res = await repo.toggleFavorite(track.id);
    if (res.isSuccess) {
      ref.invalidate(tracksListProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryParams = TrackQueryParams(
      sortBy: _sortBy,
      ascending: _ascending,
      searchQuery: _searchQuery,
    );

    final tracksAsync = ref.watch(tracksListProvider(queryParams));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Songs',
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<TrackSortBy>(
            key: Phase2Keys.sortButton,
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort songs',
            onSelected: (sortBy) {
              setState(() {
                if (_sortBy == sortBy) {
                  _ascending = !_ascending;
                } else {
                  _sortBy = sortBy;
                  _ascending = true;
                }
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                key: Phase2Keys.sortMenuTitle,
                value: TrackSortBy.title,
                child: Text('Title'),
              ),
              const PopupMenuItem(
                key: Phase2Keys.sortMenuArtist,
                value: TrackSortBy.artist,
                child: Text('Artist'),
              ),
              const PopupMenuItem(
                key: Phase2Keys.sortMenuDuration,
                value: TrackSortBy.duration,
                child: Text('Duration'),
              ),
              const PopupMenuItem(
                key: Phase2Keys.sortMenuDateAdded,
                value: TrackSortBy.dateAdded,
                child: Text('Date Added'),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GlassTextField(
              key: Phase2Keys.searchField,
              controller: _searchController,
              hintText: 'Search songs, artists, albums...',
              prefixIcon: Icons.search_rounded,
              borderRadius: BorderRadius.circular(24.0),
            ),
            const SizedBox(height: AppSpacing.md),
            tracksAsync.when(
              data: (tracks) => Text(
                'All Songs (${tracks.length})',
                key: Phase2Keys.songCountHeader,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              loading: () => Text(
                'Loading songs...',
                key: Phase2Keys.songCountHeader,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              error: (_, __) => Text(
                'All Songs (0)',
                key: Phase2Keys.songCountHeader,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: tracksAsync.when(
                data: (tracks) {
                  if (tracks.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No songs found. Scan your device in Settings!'
                            : 'No matching tracks.',
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    key: Phase2Keys.allSongsList,
                    padding: EdgeInsets.zero,
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: TrackTile.fromTrack(
                          key: Phase2Keys.trackTile(track.id),
                          track: track,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Phase2Keys.trackFavoriteToggle(track.id),
                                icon: Icon(
                                  track.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: track.isFavorite
                                      ? Colors.redAccent.shade200
                                      : null,
                                ),
                                onPressed: () => _toggleFavorite(track),
                              ),
                              if (track.duration.inMilliseconds > 0) ...[
                                Text(
                                  track.duration
                                      .toMinutesSeconds(padMinutes: false),
                                  style: AppTypography.bodySmall,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading tracks: $error',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
