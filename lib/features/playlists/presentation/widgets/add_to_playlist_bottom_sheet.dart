import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/core/services/library/library_sync_bus.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/playlists/domain/models/smart_playlist.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

/// Borderless tonal `L3` bottom sheet allowing users to add a [track] to one
/// or more existing playlists (showing duplicate-check marks and 2x2 covers) or
/// create a new playlist inline in one tap.
class AddToPlaylistBottomSheet extends ConsumerStatefulWidget {
  const AddToPlaylistBottomSheet({
    super.key,
    required this.track,
  });

  final Track track;

  static Future<void> show(BuildContext context, {required Track track}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistBottomSheet(track: track),
    );
  }

  @override
  ConsumerState<AddToPlaylistBottomSheet> createState() =>
      _AddToPlaylistBottomSheetState();
}

class _AddToPlaylistBottomSheetState
    extends ConsumerState<AddToPlaylistBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  bool _isCreating = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _notifySyncBus() {
    if (getIt.isRegistered<LibrarySyncBus>()) {
      getIt<LibrarySyncBus>().notifyChanged();
    }
  }

  Future<void> _handleCreateAndAdd() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(playlistsRepositoryProvider);
      final createResult = await repo.createPlaylist(name);
      if (createResult.isSuccess && mounted) {
        final newPlaylist = createResult.valueOrNull!;
        await repo.addTrackToPlaylist(newPlaylist.id, widget.track.id);
        ref.invalidate(playlistsListNotifierProvider);
        ref.invalidate(playlistTracksProvider(newPlaylist.id));
        _notifySyncBus();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${widget.track.title}" to "$name"'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _handleSelectPlaylist(
    Playlist playlist, {
    required bool alreadyContains,
  }) async {
    if (_isSubmitting) return;
    if (alreadyContains) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${widget.track.title}" is already in "${playlist.name}"'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(playlistsRepositoryProvider);
      final res = await repo.addTrackToPlaylist(playlist.id, widget.track.id);
      if (res.isSuccess && mounted) {
        ref.invalidate(playlistsListNotifierProvider);
        ref.invalidate(playlistTracksProvider(playlist.id));
        _notifySyncBus();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Added "${widget.track.title}" to "${playlist.name}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _buildPlaylistThumbnail(
    Playlist playlist,
    List<Track> tracks,
    NexaSurfaceTokens surfaceTokens,
    ColorScheme colorScheme,
  ) {
    final collage = tracks.take(4).toList();
    if (collage.isEmpty) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.queue_music_rounded,
          size: 22,
          color: colorScheme.primary,
        ),
      );
    }

    Widget cell(int index) {
      final t = index < collage.length ? collage[index] : collage.first;
      return NexaArtworkImage(
        track: t,
        artworkUri: t.artworkUri,
        fit: BoxFit.cover,
        cacheWidth: 96,
        fallbackBuilder: (_) => Container(
          color: surfaceTokens.level1,
          child: Icon(
            Icons.music_note_rounded,
            size: 10,
            color: colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: cell(0)),
                  Expanded(child: cell(1)),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: cell(2)),
                  Expanded(child: cell(3)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(playlistsListNotifierProvider);
    final favTracks = ref
            .watch(smartPlaylistTracksProvider(SmartPlaylistType.favorites))
            .valueOrNull ??
        const <Track>[];
    final isFavorite = favTracks.any((t) => t.id == widget.track.id) ||
        widget.track.isFavorite;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final accent = colorScheme.primary;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return NexaSurface(
      tier: NexaSurfaceTier.l3,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add to Playlist',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        BidiText(
                          widget.track.title,
                          style: AppTypography.bodySmall.copyWith(
                            color: accent,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isCreating = !_isCreating;
                      });
                    },
                    icon: Icon(
                      _isCreating ? Icons.close_rounded : Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text(_isCreating ? 'Cancel' : 'New Playlist'),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      backgroundColor: accent.withOpacity(0.12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_isCreating) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        autofocus: true,
                        onSubmitted: (_) => _handleCreateAndAdd(),
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Playlist name...',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                          ),
                          filled: true,
                          fillColor: surfaceTokens.level2,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isSubmitting ? null : _handleCreateAndAdd,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Quick toggle for Dynamic "My Favorites" Smart Playlist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: NexaSurface(
                level: isFavorite ? NexaSurfaceLevel.l2 : NexaSurfaceLevel.l1,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: const ValueKey('add_to_favorites_toggle'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    await ref
                        .read(playerNotifierProvider.notifier)
                        .toggleFavorite(widget.track);
                    ref.invalidate(
                      smartPlaylistTracksProvider(SmartPlaylistType.favorites),
                    );
                    if (mounted) {
                      navigator.pop();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: Colors.redAccent.shade200,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.favorites,
                                style: AppTypography.titleSmall.copyWith(
                                  color: colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.tracksCount(favTracks.length),
                                style: AppTypography.bodySmall.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isFavorite
                              ? Icons.check_circle_rounded
                              : Icons.add_circle_outline_rounded,
                          color: isFavorite
                              ? Colors.redAccent.shade200
                              : colorScheme.onSurfaceVariant,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: playlistsAsync.when(
                data: (playlists) {
                  if (playlists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.playlist_add_rounded,
                              size: 48,
                              color:
                                  colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No playlists yet',
                              style: AppTypography.bodyMedium.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: playlists.length,
                    itemBuilder: (ctx, i) {
                      final pl = playlists[i];
                      final tracksAsync =
                          ref.watch(playlistTracksProvider(pl.id));
                      final plTracks = tracksAsync.valueOrNull ?? const [];
                      final alreadyContains = plTracks.any(
                        (t) => t.id == widget.track.id,
                      );

                      final liveCount = tracksAsync.hasValue
                          ? plTracks.length
                          : pl.trackCount;
                      final countLabel = liveCount == 1
                          ? '1 track'
                          : '$liveCount tracks';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NexaSurface(
                          level: alreadyContains
                              ? NexaSurfaceLevel.l2
                              : NexaSurfaceLevel.l1,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            key: ValueKey('add_to_playlist_item_${pl.id}'),
                            onTap: () => _handleSelectPlaylist(
                              pl,
                              alreadyContains: alreadyContains,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  _buildPlaylistThumbnail(
                                    pl,
                                    plTracks,
                                    surfaceTokens,
                                    colorScheme,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        BidiText(
                                          pl.name,
                                          style: AppTypography.titleSmall
                                              .copyWith(
                                            color: colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          alreadyContains
                                              ? '$countLabel • Added'
                                              : countLabel,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                            color: alreadyContains
                                                ? accent
                                                : colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    alreadyContains
                                        ? Icons.check_circle_rounded
                                        : Icons.add_circle_outline_rounded,
                                    color: alreadyContains
                                        ? accent
                                        : colorScheme.onSurfaceVariant,
                                    size: 22,
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
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Error loading playlists: $err',
                      style: AppTypography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
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
