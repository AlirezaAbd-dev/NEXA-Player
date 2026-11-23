import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/nexa_surface_tokens.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';

/// Folders tab screen displaying the local storage folder-tree hierarchy
/// with borderless L1 cards and tabular metadata badges.
class FoldersTabScreen extends ConsumerWidget {
  const FoldersTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foldersAsync = ref.watch(foldersTreeProvider(const []));

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Folders',
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAmbientBackground(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
            child: foldersAsync.when(
              data: (folders) {
                if (folders.isEmpty) {
                  return const Center(
                    child: Text(
                      'No folders indexed. Add scan folders in Settings!',
                      style: AppTypography.bodyMedium,
                    ),
                  );
                }

                return ListView.builder(
                  key: Phase2Keys.foldersTreeView,
                  padding: EdgeInsets.zero,
                  itemCount: folders.length,
                  itemBuilder: (context, index) {
                    final folder = folders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _FolderItem(folder: folder),
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

class _FolderItem extends StatelessWidget {
  const _FolderItem({required this.folder});

  final FolderNode folder;

  String _extractExtension(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1 && dotIndex < name.length - 1) {
      return name.substring(dotIndex + 1).toUpperCase();
    }
    return 'AUDIO';
  }

  @override
  Widget build(BuildContext context) {
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return NexaSurface(
      key: Phase2Keys.folderNode(folder.path),
      level: NexaSurfaceLevel.l1,
      borderRadius: BorderRadius.circular(16.0),
      child: Theme(
        // Remove default expansion tile dividers
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const Border(),
          collapsedShape: const Border(),
          initiallyExpanded: true,
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
          subtitle: Text(
            folder.path,
            style: AppTypography.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: surfaceTokens.level2,
              borderRadius: BorderRadius.circular(6.0),
            ),
            child: Text(
              '${folder.files.length} items',
              style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
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
                    style: (surfaceTokens.telemetryTextStyle ?? AppTypography.labelSmall).copyWith(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.0,
                    ),
                  ),
                ),
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
