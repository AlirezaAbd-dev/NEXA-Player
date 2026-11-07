import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';

/// Folders tab screen displaying the local storage folder-tree hierarchy.
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

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      key: Phase2Keys.folderNode(folder.path),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: const Icon(Icons.folder_rounded, color: Colors.amber),
        title: Text(
          folder.name,
          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          folder.path,
          style: AppTypography.bodySmall,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          ...folder.files.map((file) => ListTile(
                key: Phase2Keys.fileNode(file.path),
                leading: const Icon(Icons.music_note_rounded, size: 20),
                title: Text(
                  file.name,
                  style: AppTypography.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              )),
          ...folder.subFolders.map((sub) => _FolderItem(folder: sub)),
        ],
      ),
    );
  }
}
