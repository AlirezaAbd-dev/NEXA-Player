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
import '../../../player/presentation/providers/player_providers.dart';
import '../../../scanner/presentation/providers/scanner_providers.dart';
import '../../../../shared/models/track.dart';
import '../../../../shared/widgets/branding/nexa_animated_logo.dart';
import '../../../../shared/widgets/glass/app_ambient_background.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../domain/repositories/folders_repository.dart';
import '../providers/library_providers.dart';
import '../widgets/library_segmented_pill_bar.dart';

/// Folders tab screen displaying local storage folder-tree hierarchy
/// with borderless L1 cards, breadcrumbs, and playable audio tracks.
class FoldersTabScreen extends ConsumerWidget {
  const FoldersTabScreen({
    super.key,
    this.initialPath,
  });

  final String? initialPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersTreeProvider(const []));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: true,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Folders', style: AppTypography.titleLarge),
            foldersAsync.maybeWhen(
              data: (folders) => Text(
                '${folders.length} STORAGE FOLDERS INDEXED',
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

                return ListView.builder(
                  key: Phase2Keys.foldersTreeView,
                  padding:
                      nexaScrollPadding(context, horizontal: 0.0, top: 0.0),
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    final isInitiallyExpanded = initialPath == null ||
                        folder.path.contains(initialPath!);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _FolderItem(
                        folder: folder,
                        initiallyExpanded: isInitiallyExpanded,
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
    );
  }
}

class _FolderItem extends ConsumerWidget {
  const _FolderItem({
    required this.folder,
    this.initiallyExpanded = true,
  });

  final FolderNode folder;
  final bool initiallyExpanded;

  String _extractExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex + 1).toUpperCase();
    }
    return 'AUDIO';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final breadcrumb = StoragePathFormatter.formatBreadcrumb(folder.path);

    return NexaSurface(
      key: Phase2Keys.folderNode(folder.path),
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(16.0),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: initiallyExpanded,
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: surfaceTokens.level2,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: const Icon(Icons.folder_rounded, color: Colors.amber, size: 22.0),
          ),
          title: Text(
            folder.name,
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(
              breadcrumb,
              style: AppTypography.bodySmall.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.65),
                fontSize: 11.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: surfaceTokens.level2,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              '${folder.files.length} items',
              style: surfaceTokens.telemetryTextStyle.copyWith(
                color: primary,
                fontWeight: FontWeight.w600,
                fontSize: 10.5,
              ),
            ),
          ),
          children: [
            ...folder.files.map((file) {
              final ext = _extractExtension(file.name);
              return ListTile(
                key: Phase2Keys.fileNode(file.path),
                leading: const Icon(Icons.music_note_rounded, size: 20),
                title: Text(
                  file.name,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
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
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final tracksRepo = ref.read(tracksRepositoryProvider);
                  final folderTracks = <Track>[];
                  int tappedIndex = 0;

                  for (var i = 0; i < folder.files.length; i++) {
                    final f = folder.files[i];
                    if (f.path == file.path) {
                      tappedIndex = folderTracks.length;
                    }
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
                    await ref
                        .read(playerNotifierProvider.notifier)
                        .playQueue(folderTracks, initialIndex: tappedIndex);
                  }
                },
              );
            }),
            ...folder.subFolders.map((sub) => Padding(
                  padding: const EdgeInsets.only(left: 12.0, top: 4.0, bottom: 4.0),
                  child: _FolderItem(folder: sub),
                )),
          ],
        ),
      ),
    );
  }
}
