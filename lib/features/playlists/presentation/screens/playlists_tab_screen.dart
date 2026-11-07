import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';
import 'package:nexa_player/shared/widgets/glass/glass_fab.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';

/// Playlists tab screen managing user playlists.
class PlaylistsTabScreen extends ConsumerWidget {
  const PlaylistsTabScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsListNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Playlists',
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70.0),
        child: GlassFAB(
          key: Phase2Keys.createPlaylistFab,
          icon: const Icon(Icons.add_rounded),
          label: const Text('New Playlist'),
          onPressed: () => _showCreateDialog(context, ref),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
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

            return ListView.builder(
              key: Phase2Keys.playlistsList,
              padding: EdgeInsets.zero,
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final playlist = playlists[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: GlassCard(
                    key: Phase2Keys.playlistItem(playlist.id),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              PlaylistDetailScreen(playlist: playlist),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white.withOpacity(0.08),
                          ),
                          child: const Icon(
                            Icons.queue_music_rounded,
                            color: Colors.white70,
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
                                style: AppTypography.bodySmall,
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
    );
  }
}
