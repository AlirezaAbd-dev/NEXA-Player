import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/navigation_helpers.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/services/artwork/artwork_providers.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/m3u_import_dialog.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import 'package:nexa_player/shared/widgets/glass/glass_fab.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';
import 'package:nexa_player/shared/widgets/inputs/nexa_sort_menu_button.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

enum _PlaylistSortBy { name, trackCount, updatedAt }

/// Playlists tab screen managing user playlists and smart auto-generated playlists.
class PlaylistsTabScreen extends ConsumerStatefulWidget {
  const PlaylistsTabScreen({super.key});

  @override
  ConsumerState<PlaylistsTabScreen> createState() => _PlaylistsTabScreenState();
}

class _PlaylistsTabScreenState extends ConsumerState<PlaylistsTabScreen> {
  _PlaylistSortBy _sortBy = _PlaylistSortBy.name;
  bool _ascending = true;

  List<Playlist> _sortPlaylists(List<Playlist> input) {
    final copy = List<Playlist>.from(input);
    copy.sort((a, b) {
      final cmp = switch (_sortBy) {
        _PlaylistSortBy.name =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _PlaylistSortBy.trackCount => a.trackCount.compareTo(b.trackCount),
        _PlaylistSortBy.updatedAt => a.updatedAt.compareTo(b.updatedAt),
      };
      return _ascending ? cmp : -cmp;
    });
    return copy;
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        key: Phase2Keys.createPlaylistDialog,
        title: 'Create Playlist',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassTextField(
              key: Phase2Keys.playlistNameInput,
              controller: controller,
              hintText: 'Playlist Name',
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            key: Phase2Keys.playlistConfirmCreate,
            label: 'Create',
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref
                    .read(playlistsListNotifierProvider.notifier)
                    .createPlaylist(name);
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Playlist playlist) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Delete Playlist',
        message:
            'Are you sure you want to delete "${playlist.name}"? This action cannot be undone.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            key: Phase2Keys.confirmDeletePlaylistButton,
            label: 'Delete',
            onPressed: () {
              ref
                  .read(playlistsListNotifierProvider.notifier)
                  .deletePlaylist(playlist.id);
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsListNotifierProvider);
    final smartPlaylists = ref.watch(smartPlaylistsProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.tabPlaylists, style: AppTypography.titleLarge),
            playlistsAsync.maybeWhen(
              data: (playlists) => Text(
                context.l10n.playlistsCountMeta(playlists.length),
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
          NexaSortMenuButton<_PlaylistSortBy>(
            key: const ValueKey('playlists_sort_btn'),
            selected: _sortBy,
            ascending: _ascending,
            tooltip: context.l10n.sortPlaylistsTooltip,
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
            options: [
              NexaSortOption(value: _PlaylistSortBy.name, label: context.l10n.sortName),
              NexaSortOption(
                value: _PlaylistSortBy.trackCount,
                label: context.l10n.sortTrackCount,
              ),
              NexaSortOption(
                value: _PlaylistSortBy.updatedAt,
                label: context.l10n.sortRecentlyUpdated,
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: context.l10n.searchLibraryTooltip,
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: context.l10n.importM3u,
            onPressed: () => M3uImportDialog.show(context),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.paddingOf(context).bottom + AppSpacing.md),
        child: GlassFAB(
          key: Phase2Keys.createPlaylistFab,
          icon: const Icon(Icons.add_rounded),
          label: Text(context.l10n.newPlaylist),
          onPressed: () => _showCreateDialog(context, ref),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          16.0,
          nexaBodyTopPadding(context, hasSubTabBar: false),
          16.0,
          0.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smart Playlists Section
            Text(
              'SMART PLAYLISTS',
              style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: smartPlaylists.length,
                itemBuilder: (ctx, i) {
                  final sp = smartPlaylists[i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: NexaSurface(
                      level: NexaSurfaceLevel.l2,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () {
                          final simulatedPlaylist = Playlist(
                            id: 'smart_${sp.type.name}',
                            name: sp.title,
                            isSmart: true,
                            smartCriteria: sp.type.name,
                            createdAt: DateTime.now(),
                            updatedAt: DateTime.now(),
                            trackCount: 0,
                          );
                          pushDetailScreen<void>(
                            context,
                            route: AppRoutes.playlistDetail,
                            extra: simulatedPlaylist,
                            fallbackBuilder: (_) =>
                                PlaylistDetailScreen(playlist: simulatedPlaylist),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 158,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(sp.icon, color: accent, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Builder(
                                  builder: (context) {
                                    final count = ref
                                        .watch(smartPlaylistTracksProvider(sp.type))
                                        .valueOrNull
                                        ?.length;
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sp.title,
                                          style: TextStyle(
                                            color: onSurface,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (count != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            '$count tracks',
                                            style: TextStyle(
                                              color: onSurfaceVariant,
                                              fontSize: 10.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // User Playlists Header
            Text(
              'MY PLAYLISTS',
              style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
                color: onSurfaceVariant.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),

            // User Playlists List
            Expanded(
              child: playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return const Center(
                      child: Text(
                        'No playlists yet. Tap "+ New Playlist" to create one!',
                        style: AppTypography.bodyMedium,
                      ),
                    );
                  }

                  final sortedPlaylists = _sortPlaylists(playlists);

                  return ListView.builder(
                    key: Phase2Keys.playlistsList,
                    padding:
                        nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
                    itemCount: sortedPlaylists.length,
                    itemBuilder: (context, index) {
                      final playlist = sortedPlaylists[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: NexaSurface(
                          key: Phase2Keys.playlistItem(playlist.id),
                          level: NexaSurfaceLevel.l1,
                          borderRadius: BorderRadius.circular(16.0),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16.0),
                            onTap: () => pushDetailScreen<void>(
                              context,
                              route: AppRoutes.playlistDetail,
                              extra: playlist,
                              fallbackBuilder: (_) =>
                                  PlaylistDetailScreen(playlist: playlist),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Row(
                                children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        color: surfaceTokens.level2,
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Builder(
                                        builder: (context) {
                                          final collage = ref
                                                  .watch(playlistCollageArtworkProvider(playlist.id))
                                                  .valueOrNull ??
                                              const <String>[];
                                          return Stack(
                                            children: [
                                              // 2x2 Real Artwork Collage quadrants
                                              Column(
                                                children: [
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: _collageCell(
                                                            collage.isNotEmpty ? collage[0] : null,
                                                            accent.withOpacity(0.20),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: _collageCell(
                                                            collage.length > 1
                                                                ? collage[1]
                                                                : (collage.isNotEmpty ? collage[0] : null),
                                                            theme.colorScheme.surface.withOpacity(0.5),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Row(
                                                      children: [
                                                        Expanded(
                                                          child: _collageCell(
                                                            collage.length > 2
                                                                ? collage[2]
                                                                : (collage.isNotEmpty ? collage[0] : null),
                                                            theme.colorScheme.surface.withOpacity(0.3),
                                                          ),
                                                        ),
                                                        Expanded(
                                                          child: _collageCell(
                                                            collage.length > 3
                                                                ? collage[3]
                                                                : (collage.length > 1 ? collage[1] : null),
                                                            accent.withOpacity(0.35),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (collage.isEmpty)
                                                Center(
                                                  child: Icon(
                                                    Icons.queue_music_rounded,
                                                    color: accent,
                                                    size: 22,
                                                  ),
                                                ),
                                              // Subtle 2px energy accent ribbon at bottom
                                              Positioned(
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                height: 2.5,
                                                child: Container(color: accent),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          playlist.name,
                                          style: AppTypography.titleMedium.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          playlist.trackCountLabel,
                                          style: (surfaceTokens.telemetryTextStyle ?? AppTypography.bodySmall).copyWith(
                                            fontSize: 12.0,
                                            color: onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    key: Phase2Keys.playlistDeleteButton(playlist.id),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () =>
                                        _showDeleteDialog(context, ref, playlist),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading playlists: $error',
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

  Widget _collageCell(String? artworkPath, Color fallbackColor) {
    if (artworkPath == null || artworkPath.isEmpty) {
      return Container(color: fallbackColor);
    }
    return NexaArtworkImage(
      artworkUri: artworkPath,
      cacheWidth: 120,
      fit: BoxFit.cover,
      fallbackBuilder: (_) => Container(color: fallbackColor),
    );
  }
}
