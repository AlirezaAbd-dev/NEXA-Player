import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/duration_x.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/core/services/storage_permission_orchestrator.dart';
import 'package:nexa_player/core/services/storage_permission_service.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/player/player.dart';
import 'package:nexa_player/features/scanner/presentation/providers/scanner_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/branding/nexa_animated_logo.dart';
import 'package:nexa_player/shared/widgets/cards/track_actions_helper.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import '../widgets/library_segmented_pill_bar.dart';
import '../widgets/swipeable_track_tile.dart';

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
    await ref.read(playerNotifierProvider.notifier).toggleFavorite(track);
    ref.invalidate(tracksListProvider);
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
        bottom: const LibrarySegmentedPillBar(
          selectedTab: LibrarySubTab.songs,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 148.0, 16.0, 130.0),
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
                    if (_searchQuery.isNotEmpty) {
                      return const Center(
                        child: Text(
                          'No matching tracks.',
                          style: AppTypography.bodyMedium,
                        ),
                      );
                    }

                    final theme = Theme.of(context);
                    final colorScheme = theme.colorScheme;

                    return Center(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          child: NexaSurface(
                            tier: NexaSurfaceTier.l2,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const NexaAnimatedLogo(
                                  size: 88,
                                  mode: NexaLogoAnimationMode.splash,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Your Music Library is Empty',
                                  style: AppTypography.titleLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  'Grant storage access to index local audio tracks from internal storage and your MicroSD card.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: colorScheme.onSurface.withOpacity(0.7),
                                    height: 1.4,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                GlassButton(
                                  label: 'Grant Access & Scan Library',
                                  icon: Icons.document_scanner_rounded,
                                  onPressed: () async {
                                    final hasPerm =
                                        await StoragePermissionOrchestrator
                                            .ensureStoragePermission(context);
                                    if (!hasPerm) return;

                                    final dirs = ref
                                            .read(scanDirectoriesProvider)
                                            .valueOrNull ??
                                        [];
                                    var paths = dirs
                                        .where((d) => d.isEnabled)
                                        .map((d) => d.path)
                                        .toList();
                                    if (paths.isEmpty) {
                                      paths = StoragePermissionService
                                          .discoverStandardMusicDirectories();
                                      if (paths.isEmpty) {
                                        paths = const [
                                          '/storage/emulated/0/Music',
                                          '/storage/emulated/0/Download'
                                        ];
                                      }
                                    }

                                    await ref
                                        .read(scannerStateNotifierProvider
                                            .notifier)
                                        .startScan(paths);
                                    ref.invalidate(tracksListProvider);
                                    ref.invalidate(albumsListProvider);
                                    ref.invalidate(artistsListProvider);
                                    ref.invalidate(genresListProvider);
                                    ref.invalidate(foldersTreeProvider);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final activePlayingTrack = ref.watch(currentTrackProvider);
                  final isEnginePlaying = ref.watch(isPlayingProvider);

                  return ListView.builder(
                    key: Phase2Keys.allSongsList,
                    padding:
                        nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
                    itemCount: tracks.length,
                    itemBuilder: (context, index) {
                      final track = tracks[index];
                      final isPlaying = isEnginePlaying && activePlayingTrack?.id == track.id;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: SwipeableTrackTile(
                          onPlayNext: () {
                            ref.read(playerNotifierProvider.notifier).addNext(track);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Playing next: ${track.title}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onAddToQueueEnd: () {
                            ref.read(playerNotifierProvider.notifier).addTrack(track);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Added to queue end: ${track.title}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          onSwipeLeft: () => _toggleFavorite(track),
                          child: TrackTile.fromTrack(
                            key: Phase2Keys.trackTile(track.id),
                            track: track,
                            isPlaying: isPlaying,
                            onTap: () {
                              ref.read(playerNotifierProvider.notifier).playTrack(
                                    track,
                                    queue: tracks,
                                    initialIndex: index,
                                    queueContext: const QueueContext.allSongs(),
                                  );
                            },
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
                                PopupMenuButton<TrackTileMenuAction>(
                                  icon: const Icon(
                                    Icons.more_vert_rounded,
                                    size: 20.0,
                                  ),
                                  tooltip: 'Track actions',
                                  padding: EdgeInsets.zero,
                                  onSelected: (action) {
                                    TrackActionsHelper.handleAction(
                                      context,
                                      ref,
                                      track: track,
                                      action: action,
                                    );
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.playNext,
                                      child: Row(
                                        children: [
                                          Icon(Icons.playlist_play_rounded),
                                          SizedBox(width: 8),
                                          Text('Play next'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.addToQueue,
                                      child: Row(
                                        children: [
                                          Icon(Icons.queue_music_rounded),
                                          SizedBox(width: 8),
                                          Text('Add to queue'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.addToPlaylist,
                                      child: Row(
                                        children: [
                                          Icon(Icons.playlist_add_rounded),
                                          SizedBox(width: 8),
                                          Text('Add to playlist'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.editTags,
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_note_rounded),
                                          SizedBox(width: 8),
                                          Text('Edit tags & cover'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.goToAlbum,
                                      child: Row(
                                        children: [
                                          Icon(Icons.album_rounded),
                                          SizedBox(width: 8),
                                          Text('Go to album'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.goToArtist,
                                      child: Row(
                                        children: [
                                          Icon(Icons.person_rounded),
                                          SizedBox(width: 8),
                                          Text('Go to artist'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.share,
                                      child: Row(
                                        children: [
                                          Icon(Icons.share_rounded),
                                          SizedBox(width: 8),
                                          Text('Share'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: TrackTileMenuAction.trimRingtone,
                                      child: Row(
                                        children: [
                                          Icon(Icons.content_cut_rounded),
                                          SizedBox(width: 8),
                                          Text('Trim ringtone'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
