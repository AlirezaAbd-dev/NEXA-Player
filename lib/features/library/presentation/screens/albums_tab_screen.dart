import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/features/library/domain/repositories/albums_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/album_detail_screen.dart';
import 'package:nexa_player/features/library/presentation/widgets/library_segmented_pill_bar.dart';
import 'package:nexa_player/shared/widgets/cards/album_card.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';

/// Albums tab screen displaying album grid with pinch-to-zoom density control.
class AlbumsTabScreen extends ConsumerStatefulWidget {
  const AlbumsTabScreen({super.key});

  @override
  ConsumerState<AlbumsTabScreen> createState() => _AlbumsTabScreenState();
}

class _AlbumsTabScreenState extends ConsumerState<AlbumsTabScreen> {
  int? _customColumns;
  bool _isScaling = false;
  AlbumSortBy _sortBy = AlbumSortBy.title;
  bool _ascending = true;

  int _resolveColumnCount(double screenWidth) {
    if (_customColumns != null) return _customColumns!;
    if (screenWidth >= 900) return 4;
    if (screenWidth >= 600) return 3;
    return 2;
  }

  double _resolveAspectRatio(int columns) {
    switch (columns) {
      case 1:
        return 1.15;
      case 2:
        return 0.67;
      case 3:
        return 0.64;
      case 4:
      default:
        return 0.60;
    }
  }

  PopupMenuItem<AlbumSortBy> _buildSortMenuItem(AlbumSortBy value, String label) {
    return PopupMenuItem<AlbumSortBy>(
      value: value,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (_sortBy == value)
            Icon(
              _ascending
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 16,
            ),
        ],
      ),
    );
  }

  void _cycleDensity(int current) {
    setState(() {
      _customColumns = current >= 4 ? 1 : current + 1;
    });
  }

  void _onScaleUpdate(ScaleUpdateDetails details, int currentColumns) {
    if (_isScaling) return;
    if (details.scale > 1.35) {
      _isScaling = true;
      setState(() {
        _customColumns = (currentColumns - 1).clamp(1, 4);
      });
    } else if (details.scale < 0.70) {
      _isScaling = true;
      setState(() {
        _customColumns = (currentColumns + 1).clamp(1, 4);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final queryParams = (_sortBy == AlbumSortBy.title && _ascending)
        ? null
        : AlbumQueryParams(sortBy: _sortBy, ascending: _ascending);
    final albumsAsync = ref.watch(albumsListProvider(queryParams));

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _resolveColumnCount(constraints.maxWidth);
        final aspectRatio = _resolveAspectRatio(columns);

        return Scaffold(
          backgroundColor: Colors.transparent,
          extendBodyBehindAppBar: true,
          appBar: GlassAppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.tabAlbums, style: AppTypography.titleLarge),
                albumsAsync.maybeWhen(
                  data: (albums) => Text(
                    context.l10n.albumsCountMeta(albums.length),
                    style: AppTypography.labelSmall.copyWith(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      fontSize: 10.5,
                    ),
                  ),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              PopupMenuButton<AlbumSortBy>(
                key: const ValueKey('albums_sort_btn'),
                icon: const Icon(Icons.sort_rounded),
                tooltip: 'Sort albums',
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
                  _buildSortMenuItem(AlbumSortBy.title, context.l10n.sortTitle),
                  _buildSortMenuItem(AlbumSortBy.artist, context.l10n.sortArtist),
                  _buildSortMenuItem(AlbumSortBy.year, context.l10n.sortYear),
                ],
              ),
              IconButton(
                icon: Icon(
                  columns == 1
                      ? Icons.view_agenda_rounded
                      : columns == 2
                          ? Icons.grid_view_rounded
                          : columns == 3
                              ? Icons.view_module_rounded
                              : Icons.apps_rounded,
                ),
                tooltip: 'Grid density ($columns columns)',
                onPressed: () => _cycleDensity(columns),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'Search library',
                onPressed: () => context.push(AppRoutes.search),
              ),
            ],
            bottom: const LibrarySegmentedPillBar(
              selectedTab: LibrarySubTab.albums,
            ),
          ),
          body: GestureDetector(
            onScaleUpdate: (details) => _onScaleUpdate(details, columns),
            onScaleEnd: (_) => _isScaling = false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 148.0, 16.0, 0.0),
              child: albumsAsync.when(
                data: (albums) {
                  if (albums.isEmpty) {
                    return const Center(
                      child: Text(
                        'No albums found. Scan your media in Settings!',
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }

                  return GridView.builder(
                    key: Phase2Keys.albumsGrid,
                    padding:
                        nexaScrollPadding(context, horizontal: 4.0, top: 12.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: AppSpacing.md,
                      mainAxisSpacing: AppSpacing.md,
                      childAspectRatio: aspectRatio,
                    ),
                    itemCount: albums.length,
                    itemBuilder: (context, index) {
                      final album = albums[index];
                      return AlbumCard.fromAlbum(
                        key: Phase2Keys.albumCard(album.id),
                        album: album,
                        heroTag: 'album_art_${album.id}',
                        mode: AlbumCardMode.grid,
                        onTap: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AlbumDetailScreen(album: album),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading albums: $error',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
