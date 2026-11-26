import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../../app/routes.dart';
import '../../../../core/constants/phase2_keys.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/services/storage_permission_orchestrator.dart';
import '../../../../core/services/storage_permission_service.dart';
import '../../../../core/utils/contrast_validator.dart';
import '../../../../core/utils/storage_path_formatter.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/branding/nexa_animated_logo.dart';
import '../../../../shared/widgets/cards/nexa_artwork_image.dart';
import '../../../../shared/widgets/cards/track_actions_helper.dart';
import '../../../../shared/widgets/cards/track_tile.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/inputs/nexa_sort_menu_button.dart';
import '../../../../shared/widgets/lists/active_track_auto_scroller.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../../../shared/widgets/typography/bidi_text.dart';
import '../../../player/domain/entities/playback_state.dart';
import '../../../player/domain/entities/queue_context.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';
import '../../domain/repositories/folders_repository.dart';
import '../../domain/repositories/tracks_repository.dart';
import '../providers/library_providers.dart';
import '../widgets/library_segmented_pill_bar.dart';

/// Folders tab screen displaying a clean drill-down storage hierarchy:
/// - Root view shows ONLY audio-containing folders (zero auto-expanding tiles).
/// - Entering a folder displays ONLY its direct subfolders and direct audio tracks.
/// - Tapping any track loads the folder's ordered tracks as the active queue.
class FoldersTabScreen extends ConsumerStatefulWidget {
  const FoldersTabScreen({
    super.key,
    this.initialPath,
  });

  final String? initialPath;

  @override
  ConsumerState<FoldersTabScreen> createState() => _FoldersTabScreenState();
}

enum _FolderSortBy {
  name,
  songCount,
  title,
  artist,
  album,
  duration,
  dateAdded,
}

class _FoldersTabScreenState extends ConsumerState<FoldersTabScreen> {
  final List<String> _navigationStack = [];
  _FolderSortBy _sortBy = _FolderSortBy.title;
  bool _ascending = true;

  List<FolderNode> _sortFolders(List<FolderNode> input) {
    final copy = List<FolderNode>.from(input);
    copy.sort((a, b) {
      final cmp = switch (_sortBy) {
        _FolderSortBy.songCount =>
          a.recursiveTrackCount.compareTo(b.recursiveTrackCount),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return _ascending ? cmp : -cmp;
    });
    return copy;
  }

  List<FileNode> _sortFiles(List<FileNode> input) {
    final copy = List<FileNode>.from(input);
    copy.sort((a, b) {
      final cmp = switch (_sortBy) {
        _FolderSortBy.name =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        _FolderSortBy.title || _FolderSortBy.songCount =>
          a.displayTitle.toLowerCase().compareTo(b.displayTitle.toLowerCase()),
        _FolderSortBy.artist =>
          a.displayArtist.toLowerCase().compareTo(b.displayArtist.toLowerCase()),
        _FolderSortBy.album => (a.track?.album ?? '')
            .toLowerCase()
            .compareTo((b.track?.album ?? '').toLowerCase()),
        _FolderSortBy.duration => (a.track?.duration ?? Duration.zero)
            .compareTo(b.track?.duration ?? Duration.zero),
        _FolderSortBy.dateAdded =>
          (a.track?.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                b.track?.dateAdded ?? DateTime.fromMillisecondsSinceEpoch(0),
              ),
      };
      return _ascending ? cmp : -cmp;
    });
    return copy;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialPath != null && widget.initialPath!.isNotEmpty) {
      _navigationStack.add(widget.initialPath!);
    }
  }

  String? get _currentPath =>
      _navigationStack.isNotEmpty ? _navigationStack.last : null;

  FolderNode? _resolveCurrentNode(List<FolderNode> roots) {
    final targetPath = _currentPath;
    if (targetPath == null) return null;
    for (final root in roots) {
      final found = root.findByPath(targetPath);
      if (found != null) return found;
    }
    return null;
  }

  void _enterFolder(FolderNode folder) {
    HapticFeedback.selectionClick();
    setState(() {
      _navigationStack.add(folder.path);
    });
  }

  void _navigateUp() {
    if (_navigationStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _navigationStack.removeLast();
    });
  }

  void _navigateToRoot() {
    if (_navigationStack.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _navigationStack.clear();
    });
  }

  void _navigateToStackIndex(int index) {
    if (index < 0 || index >= _navigationStack.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _navigationStack.removeRange(index + 1, _navigationStack.length);
    });
  }

  String _extractExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex + 1).toUpperCase();
    }
    return 'AUDIO';
  }

  String _formatFolderCounts(FolderNode folder) {
    final songsCount = folder.recursiveTrackCount;
    final subsCount = folder.subFolderCount;
    final songWord = songsCount == 1 ? 'song' : 'songs';
    if (subsCount > 0) {
      final folderWord = subsCount == 1 ? 'folder' : 'folders';
      return '$songsCount $songWord · $subsCount $folderWord';
    }
    return '$songsCount $songWord';
  }

  Future<void> _playFolderFiles(
    FolderNode folder, {
    List<FileNode>? files,
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    final targetFiles = files ?? folder.files;
    if (targetFiles.isEmpty) return;
    HapticFeedback.lightImpact();

    final tracksRepo = ref.read(tracksRepositoryProvider);
    final folderTracks = <Track>[];

    for (final f in targetFiles) {
      Track? resolved = f.track;
      if (resolved == null && f.trackId != null) {
        final res = await tracksRepo.getTrackById(f.trackId!);
        resolved = res.valueOrNull;
      }
      folderTracks.add(
        resolved ??
            Track(
              id: f.trackId ?? f.path,
              title: f.displayTitle,
              artist: folder.name,
              album: folder.name,
              duration: Duration.zero,
              filePath: f.path,
              fileSize: f.fileSize,
            ),
      );
    }

    if (folderTracks.isNotEmpty) {
      await ref.read(playerNotifierProvider.notifier).playQueue(
            folderTracks,
            initialIndex: initialIndex.clamp(0, folderTracks.length - 1),
            mode: shuffle ? PlaybackMode.shuffle : null,
            queueContext: QueueContext.folder(folder.path, title: folder.name),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersAsync = ref.watch(foldersTreeProvider(const []));
    Track? activeTrack;
    try {
      activeTrack = ref.watch(currentTrackProvider);
    } catch (_) {
      activeTrack = null;
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = NexaSurfaceTokens.of(context);

    final activeNode = foldersAsync.maybeWhen(
      data: (roots) => _resolveCurrentNode(roots),
      orElse: () => null,
    );

    final scaffold = PopScope(
      canPop: _navigationStack.isEmpty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _navigationStack.isNotEmpty) {
          _navigateUp();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: GlassAppBar(
          automaticallyImplyLeading: activeNode == null,
          leading: activeNode != null
              ? IconButton(
                  key: const ValueKey('folder_navigate_up_btn'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  tooltip: 'Up one folder',
                  onPressed: _navigateUp,
                )
              : null,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                activeNode?.name ?? context.l10n.tabFolders,
                style: AppTypography.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              foldersAsync.maybeWhen(
                data: (folders) => Text(
                  activeNode != null
                      ? _formatFolderCounts(activeNode).toUpperCase()
                      : context.l10n.foldersCountMeta(folders.length),
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.primary.withOpacity(0.85),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    fontSize: 10.5,
                  ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          bottom: const LibrarySegmentedPillBar(
            selectedTab: LibrarySubTab.folders,
          ),
          actions: [
            NexaSortMenuButton<_FolderSortBy>(
              key: const ValueKey('folders_sort_btn'),
              selected: _sortBy,
              ascending: _ascending,
              tooltip: context.l10n.sortFoldersTooltip,
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
                NexaSortOption(
                  value: _FolderSortBy.title,
                  label: context.l10n.sortTitle,
                ),
                NexaSortOption(
                  value: _FolderSortBy.artist,
                  label: context.l10n.sortArtist,
                ),
                NexaSortOption(
                  value: _FolderSortBy.album,
                  label: context.l10n.sortAlbum,
                ),
                NexaSortOption(
                  value: _FolderSortBy.duration,
                  label: context.l10n.sortDuration,
                ),
                NexaSortOption(
                  value: _FolderSortBy.dateAdded,
                  label: context.l10n.sortDateAdded,
                ),
                NexaSortOption(
                  value: _FolderSortBy.name,
                  label: context.l10n.sortName,
                ),
                NexaSortOption(
                  value: _FolderSortBy.songCount,
                  label: context.l10n.sortSongCount,
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: context.l10n.searchLibraryTooltip,
              onPressed: () => context.push(AppRoutes.search),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppAmbientBackground(),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16.0,
                nexaBodyTopPadding(context, hasSubTabBar: true),
                16.0,
                0.0,
              ),
              child: foldersAsync.when(
                data: (folders) {
                  if (folders.isEmpty) {
                    return _buildEmptyState(context, colorScheme);
                  }

                  final currentFolder = _resolveCurrentNode(folders);
                  if (currentFolder != null) {
                    return _buildFolderContentsView(
                      context,
                      currentFolder,
                      activeTrack,
                      surfaceTokens,
                      colorScheme,
                    );
                  }

                  final sortedRoots = _sortFolders(folders);

                  // Root View: Folders ONLY (no auto-expanding tiles or loose songs)
                  return ListView.builder(
                    key: Phase2Keys.foldersTreeView,
                    padding:
                        nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
                    itemCount: sortedRoots.length,
                    itemBuilder: (context, index) {
                      final folder = sortedRoots[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildFolderCard(
                          context,
                          folder: folder,
                          surfaceTokens: surfaceTokens,
                          colorScheme: colorScheme,
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(
                    'Error loading folders: $error',
                    style: AppTypography.bodyMedium,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (Router.maybeOf(context) == null) {
      return scaffold;
    }

    return BackButtonListener(
      onBackButtonPressed: () async {
        if (_navigationStack.isNotEmpty) {
          _navigateUp();
          return true;
        }
        return false;
      },
      child: scaffold,
    );
  }

  Widget _buildFolderCard(
    BuildContext context, {
    required FolderNode folder,
    required NexaSurfaceTokens surfaceTokens,
    required ColorScheme colorScheme,
  }) {
    final primary = colorScheme.primary;
    final breadcrumb = StoragePathFormatter.formatBreadcrumb(folder.path);

    return NexaSurface(
      key: Phase2Keys.folderNode(folder.path),
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onTap: () => _enterFolder(folder),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2.0,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: surfaceTokens.level2,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Icon(
                  Icons.folder_rounded,
                  color: Colors.amber,
                  size: 24.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BidiText(
                      folder.name,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      breadcrumb,
                      style: AppTypography.bodySmall.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.65),
                        fontSize: 11.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: surfaceTokens.level2,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _formatFolderCounts(folder),
                  style: surfaceTokens.telemetryTextStyle.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 10.5,
                  ),
                ),
              ),
              const SizedBox(width: 4.0),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withOpacity(0.45),
                size: 20.0,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderContentsView(
    BuildContext context,
    FolderNode folder,
    Track? activeTrack,
    NexaSurfaceTokens surfaceTokens,
    ColorScheme colorScheme,
  ) {
    final primary = colorScheme.primary;
    final sortedSubFolders = _sortFolders(folder.subFolders);
    final sortedFiles = _sortFiles(folder.files);
    final subCount = sortedSubFolders.length;
    final fileCount = sortedFiles.length;
    final totalItems = subCount + fileCount;

    final activeFileKey = activeTrack == null
        ? null
        : (sortedFiles.any((f) => f.trackId == activeTrack.id)
            ? activeTrack.id
            : activeTrack.filePath);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ActionChip(
                key: const ValueKey('folder_breadcrumb_root'),
                avatar: Icon(Icons.home_rounded, size: 16, color: primary),
                label: const Text('Folders'),
                onPressed: _navigateToRoot,
              ),
              for (int i = 0; i < _navigationStack.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
                ActionChip(
                  label: Text(
                    p.posix.basename(_navigationStack[i].replaceAll(r'\', '/')),
                    style: TextStyle(
                      fontWeight: i == _navigationStack.length - 1
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onPressed: i == _navigationStack.length - 1
                      ? null
                      : () => _navigateToStackIndex(i),
                ),
              ],
            ],
          ),
        ),

        // Play All & Shuffle pills when folder has direct songs
        if (folder.files.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              FilledButton.icon(
                key: const ValueKey('folder_play_all_btn'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.0),
                  ),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18.0),
                label: Text(context.l10n.playAll),
                onPressed: () => _playFolderFiles(
                  folder,
                  files: sortedFiles,
                  initialIndex: 0,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              NexaSurface(
                level: NexaSurfaceLevel.l2,
                borderRadius: BorderRadius.circular(18.0),
                child: IconButton(
                  key: const ValueKey('folder_shuffle_btn'),
                  icon: const Icon(Icons.shuffle_rounded, size: 18.0),
                  tooltip: 'Shuffle folder',
                  onPressed: () => _playFolderFiles(
                    folder,
                    files: sortedFiles,
                    initialIndex: 0,
                    shuffle: true,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.sm),

        Expanded(
          child: ActiveTrackAutoScrollScope(
            trackIds:
                sortedFiles.map((f) => f.trackId ?? f.path).toList(growable: false),
            activeTrackId: activeFileKey,
            indexOffset: subCount,
            builder: (context, scrollController) => ListView.builder(
              key: const ValueKey('folder_contents_list'),
              controller: scrollController,
              padding: nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
              itemCount: totalItems,
              itemBuilder: (context, index) {
                // Direct subfolders first
                if (index < subCount) {
                  final sub = sortedSubFolders[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _buildFolderCard(
                      context,
                      folder: sub,
                      surfaceTokens: surfaceTokens,
                      colorScheme: colorScheme,
                    ),
                  );
                }

                // Direct files in this folder
                final fileIndex = index - subCount;
                final file = sortedFiles[fileIndex];
                final ext = _extractExtension(file.name);
                final resolvedTrack = file.track ??
                    Track(
                      id: file.trackId ?? file.path,
                      title: file.displayTitle,
                      artist: folder.name,
                      album: folder.name,
                      duration: Duration.zero,
                      filePath: file.path,
                      fileSize: file.fileSize,
                    );
                final isActive = activeTrack != null &&
                    ((file.trackId != null && activeTrack.id == file.trackId) ||
                        activeTrack.filePath == file.path);
                final activeCardColor = Color.alphaBlend(
                  primary.withOpacity(0.10),
                  surfaceTokens.l2,
                );
                final activeTitleColor = ContrastValidator.ensureContrast(
                  primary,
                  activeCardColor,
                );

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive ? activeCardColor : surfaceTokens.l1,
                      borderRadius: BorderRadius.circular(14.0),
                    ),
                    child: ListTile(
                      key: Phase2Keys.fileNode(file.path),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(10.0),
                        child: SizedBox(
                          width: 40.0,
                          height: 40.0,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              NexaArtworkImage(
                                track: resolvedTrack,
                                width: 40.0,
                                height: 40.0,
                                cacheWidth: 160,
                                fallbackBuilder: (_) => Container(
                                  color: isActive
                                      ? primary.withOpacity(0.18)
                                      : surfaceTokens.level2,
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    size: 20,
                                    color: isActive ? primary : null,
                                  ),
                                ),
                              ),
                              if (isActive)
                                Container(
                                  color: Colors.black.withOpacity(0.45),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.equalizer_rounded,
                                    color: primary,
                                    size: 20.0,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      title: BidiText(
                        file.displayTitle,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isActive ? activeTitleColor : null,
                          fontWeight: isActive ? FontWeight.bold : null,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: file.displayArtist.isNotEmpty
                          ? BidiText(
                              file.displayArtist,
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11.0,
                                color: colorScheme.onSurface.withOpacity(0.62),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceTokens.level2,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              ext,
                              style: surfaceTokens.telemetryTextStyle.copyWith(
                                color: primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10.0,
                              ),
                            ),
                          ),
                          if (file.trackId != null)
                            PopupMenuButton<TrackTileMenuAction>(
                              icon: const Icon(Icons.more_vert_rounded, size: 18),
                              padding: EdgeInsets.zero,
                              tooltip: 'Track actions',
                              onSelected: (action) async {
                                Track? track = file.track;
                                if (track == null) {
                                  final repo = getIt.isRegistered<ITracksRepository>()
                                      ? getIt<ITracksRepository>()
                                      : null;
                                  track = repo != null
                                      ? (await repo.getTrackById(file.trackId!))
                                          .valueOrNull
                                      : null;
                                }
                                track ??= resolvedTrack;
                                if (!context.mounted) return;
                                await TrackActionsHelper.handleAction(
                                  context,
                                  ref,
                                  track: track,
                                  action: action,
                                );
                              },
                              itemBuilder: (_) => const [
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
                              ],
                            ),
                        ],
                      ),
                      onTap: () => _playFolderFiles(
                        folder,
                        files: sortedFiles,
                        initialIndex: fileIndex,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
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
                  'No Audio Folders Found',
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Grant storage access to discover audio folders and albums on your internal storage and MicroSD card.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                GlassButton(
                  label: 'Grant Access & Scan Library',
                  icon: Icons.folder_copy_rounded,
                  onPressed: () async {
                    final hasPerm = await StoragePermissionOrchestrator
                        .ensureStoragePermission(context);
                    if (!hasPerm) return;

                    final dirs =
                        ref.read(scanDirectoriesProvider).valueOrNull ?? [];
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
                          '/storage/emulated/0/Download',
                        ];
                      }
                    }

                    await ref
                        .read(scannerStateNotifierProvider.notifier)
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
}
