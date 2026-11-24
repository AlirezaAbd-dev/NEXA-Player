import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../core/constants/phase2_keys.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/services/storage_permission_orchestrator.dart';
import '../../../../core/services/storage_permission_service.dart';
import '../../../../core/utils/storage_path_formatter.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/branding/nexa_animated_logo.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../../player/domain/entities/playback_state.dart';
import '../../../player/presentation/providers/player_providers.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';
import '../../domain/repositories/folders_repository.dart';
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

class _FoldersTabScreenState extends ConsumerState<FoldersTabScreen> {
  final List<String> _navigationStack = [];

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
    int initialIndex = 0,
    bool shuffle = false,
  }) async {
    if (folder.files.isEmpty) return;
    HapticFeedback.lightImpact();

    final tracksRepo = ref.read(tracksRepositoryProvider);
    final folderTracks = <Track>[];

    for (final f in folder.files) {
      Track? resolved;
      if (f.trackId != null) {
        final res = await tracksRepo.getTrackById(f.trackId!);
        resolved = res.valueOrNull;
      }
      folderTracks.add(
        resolved ??
            Track(
              id: f.trackId ?? f.path,
              title: p.basenameWithoutExtension(f.name),
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

    return PopScope(
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
                activeNode?.name ?? 'Folders',
                style: AppTypography.titleLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              foldersAsync.maybeWhen(
                data: (folders) => Text(
                  activeNode != null
                      ? _formatFolderCounts(activeNode).toUpperCase()
                      : '${folders.length} STORAGE FOLDERS INDEXED',
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
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const AppAmbientBackground(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 148.0, 16.0, 0.0),
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

                  // Root View: Folders ONLY (no auto-expanding tiles or loose songs)
                  return ListView.builder(
                    key: Phase2Keys.foldersTreeView,
                    padding:
                        nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
                    itemCount: folders.length,
                    itemBuilder: (context, index) {
                      final folder = folders[index];
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
                    Text(
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
    final subCount = folder.subFolders.length;
    final fileCount = folder.files.length;
    final totalItems = subCount + fileCount;

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
                label: const Text('Play All'),
                onPressed: () => _playFolderFiles(folder, initialIndex: 0),
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
          child: ListView.builder(
            key: const ValueKey('folder_contents_list'),
            padding: nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
            itemCount: totalItems,
            itemBuilder: (context, index) {
              // Direct subfolders first
              if (index < subCount) {
                final sub = folder.subFolders[index];
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
              final file = folder.files[fileIndex];
              final ext = _extractExtension(file.name);
              final isActive = activeTrack != null &&
                  ((file.trackId != null && activeTrack.id == file.trackId) ||
                      activeTrack.filePath == file.path);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: NexaSurface(
                  level: isActive ? NexaSurfaceLevel.l2 : NexaSurfaceLevel.l1,
                  borderRadius: BorderRadius.circular(14.0),
                  child: ListTile(
                    key: Phase2Keys.fileNode(file.path),
                    leading: Icon(
                      isActive
                          ? Icons.equalizer_rounded
                          : Icons.music_note_rounded,
                      size: 20,
                      color: isActive ? primary : null,
                    ),
                    title: Text(
                      file.name,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isActive ? primary : null,
                        fontWeight: isActive ? FontWeight.bold : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
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
                    onTap: () => _playFolderFiles(
                      folder,
                      initialIndex: fileIndex,
                    ),
                  ),
                ),
              );
            },
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
