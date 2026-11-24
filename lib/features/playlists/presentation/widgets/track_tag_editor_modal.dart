import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/core/utils/tag_encoding_decoder.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/playlists/data/services/tag_editor_service_impl.dart';
import 'package:nexa_player/features/playlists/domain/models/editable_track_metadata.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';
import 'package:nexa_player/shared/widgets/surfaces/nexa_surface.dart';
import 'package:nexa_player/shared/widgets/typography/bidi_text.dart';

/// Signature for picking replacement cover image bytes cleanly in UI or tests.
typedef CoverImagePickerCallback = Future<Uint8List?> Function();

/// Convenience alias for [TrackTagEditorModal].
typedef TrackTagEditorScreen = TrackTagEditorModal;

/// Borderless tonal Track Tag & Cover Art Editor modal supporting full UTF-8 /
/// Persian fields (`Title`, `Artist`, `Album`, `Genre`, `Year`, `Track #`,
/// `Comment`) plus custom cover art picking & reset.
class TrackTagEditorModal extends ConsumerStatefulWidget {
  const TrackTagEditorModal({
    super.key,
    required this.track,
    this.pickCoverImage,
    this.artworkService,
  });

  final Track track;
  final CoverImagePickerCallback? pickCoverImage;
  final IArtworkResolutionService? artworkService;

  static Future<Track?> show(
    BuildContext context, {
    required Track track,
    CoverImagePickerCallback? pickCoverImage,
    IArtworkResolutionService? artworkService,
  }) {
    return showModalBottomSheet<Track>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TrackTagEditorModal(
        track: track,
        pickCoverImage: pickCoverImage,
        artworkService: artworkService,
      ),
    );
  }

  @override
  ConsumerState<TrackTagEditorModal> createState() =>
      _TrackTagEditorModalState();
}

class _TrackTagEditorModalState extends ConsumerState<TrackTagEditorModal> {
  static const MethodChannel _mediaStoreChannel =
      MethodChannel('com.nexa.player/media_store');

  late final TextEditingController _titleController;
  late final TextEditingController _artistController;
  late final TextEditingController _albumController;
  late final TextEditingController _genreController;
  late final TextEditingController _yearController;
  late final TextEditingController _trackNumController;
  late final TextEditingController _commentController;

  Uint8List? _pendingCoverBytes;
  bool _resetCover = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.track.title);
    _artistController = TextEditingController(text: widget.track.artist);
    _albumController = TextEditingController(text: widget.track.album);
    _genreController = TextEditingController(text: widget.track.genre ?? '');
    _yearController = TextEditingController(
      text: widget.track.year != null ? widget.track.year.toString() : '',
    );
    _trackNumController = TextEditingController(
      text: widget.track.trackNumber != null
          ? widget.track.trackNumber.toString()
          : '',
    );
    _commentController =
        TextEditingController(text: widget.track.comment ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _albumController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    _trackNumController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  IArtworkResolutionService? get _effectiveArtworkService {
    if (widget.artworkService != null) return widget.artworkService;
    if (getIt.isRegistered<IArtworkResolutionService>()) {
      return getIt<IArtworkResolutionService>();
    }
    return null;
  }

  Future<void> _handlePickCoverImage() async {
    Uint8List? bytes;
    if (widget.pickCoverImage != null) {
      bytes = await widget.pickCoverImage!();
    } else {
      try {
        bytes = await _mediaStoreChannel
            .invokeMethod<Uint8List>('pickCoverImageBytes');
      } catch (_) {
        bytes = null;
      }
    }

    if (!mounted || bytes == null || bytes.isEmpty) return;
    setState(() {
      _pendingCoverBytes = bytes;
      _resetCover = false;
      _errorMessage = null;
    });
  }

  void _handleResetCover() {
    HapticFeedback.selectionClick();
    setState(() {
      _pendingCoverBytes = null;
      _resetCover = true;
    });
  }

  void _evictArtworkCaches(String? oldPath, String? newPath) {
    final cache = PaintingBinding.instance.imageCache;
    for (final path in {oldPath, newPath}) {
      if (path == null || path.isEmpty) continue;
      if (!path.startsWith('http://') && !path.startsWith('https://')) {
        final clean = path.startsWith('file://') ? path.substring(7) : path;
        cache.evict(FileImage(File(clean)));
      }
    }
  }

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    final artist = _artistController.text.trim();
    final album = _albumController.text.trim();

    if (title.isEmpty) {
      setState(() => _errorMessage = 'Title cannot be empty');
      return;
    }
    if (artist.isEmpty) {
      setState(() => _errorMessage = 'Artist cannot be empty');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final artworkService = _effectiveArtworkService;
    String? resolvedOverridePath;
    if (_pendingCoverBytes != null && artworkService != null) {
      resolvedOverridePath = await artworkService.saveCustomOverride(
        widget.track.id,
        _pendingCoverBytes!,
      );
      _evictArtworkCaches(widget.track.artworkUri, resolvedOverridePath);
    } else if (_resetCover && artworkService != null) {
      await artworkService.clearCustomOverride(widget.track.id);
      _evictArtworkCaches(widget.track.artworkUri, null);
    }

    final metadata = EditableTrackMetadata(
      title: title,
      artist: artist,
      album: album.isEmpty ? 'Unknown Album' : album,
      genre: _genreController.text.trim().isNotEmpty
          ? _genreController.text.trim()
          : null,
      year: int.tryParse(_yearController.text.trim()),
      trackNumber: int.tryParse(_trackNumController.text.trim()),
      comment: _commentController.text.trim().isNotEmpty
          ? _commentController.text.trim()
          : null,
      artworkUri: _resetCover ? null : resolvedOverridePath,
      artworkBytes: _pendingCoverBytes,
      clearArtwork: _resetCover,
    );

    final service = ref.read(tagEditorServiceProvider);
    final res = await service.updateTrackMetadata(widget.track.id, metadata);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res.isSuccess) {
      final savedTrack = res.valueOrNull!;
      // Synchronize active playback state, MiniPlayer, Notification & library tabs
      try {
        if (getIt.isRegistered<IArtworkResolutionService>()) {
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
      } catch (_) {}
      try {
        ref.read(playerNotifierProvider.notifier).refreshTrack(savedTrack);
      } catch (_) {}
      try {
        ref.invalidate(tracksListProvider);
        ref.invalidate(albumsListProvider);
        ref.invalidate(artistsListProvider);
        ref.invalidate(playlistsListNotifierProvider);
      } catch (_) {}

      final warning = service is TagEditorServiceImpl
          ? service.lastFileWriteWarning
          : null;
      final snackText = warning == null
          ? 'Track tags updated successfully'
          : 'Track tags updated successfully ($warning)';

      Navigator.of(context).pop(savedTrack);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(snackText),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res.failureOrNull?.message ?? 'Failed to update tags';
      });
    }
  }

  Widget _buildField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required NexaSurfaceTokens surfaceTokens,
    required ColorScheme colorScheme,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    final textDirection = TagEncodingDecoder.detectBidiDirection(controller.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textDirection: textDirection,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyMedium.copyWith(
              color: colorScheme.onSurface,
              fontFamilyFallback: AppTypography.persianFontFallback,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant.withOpacity(0.55),
              ),
              filled: true,
              fillColor: surfaceTokens.level2,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverHeader(
    BuildContext context,
    NexaSurfaceTokens surfaceTokens,
    ColorScheme colorScheme,
  ) {
    Widget coverPreview;
    if (_pendingCoverBytes != null) {
      coverPreview = Image.memory(
        _pendingCoverBytes!,
        width: 140,
        height: 140,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _coverFallback(surfaceTokens, colorScheme),
      );
    } else if (_resetCover) {
      coverPreview = _coverFallback(surfaceTokens, colorScheme);
    } else {
      coverPreview = NexaArtworkImage(
        track: widget.track,
        artworkUri: widget.track.artworkUri,
        artworkService: widget.artworkService,
        width: 140,
        height: 140,
        cacheWidth: 420,
        fallbackBuilder: (_) => _coverFallback(surfaceTokens, colorScheme),
      );
    }

    return Center(
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              width: 140,
              height: 140,
              child: coverPreview,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              FilledButton.tonalIcon(
                key: const ValueKey('tag_editor_pick_cover'),
                onPressed: _isSaving ? null : _handlePickCoverImage,
                icon: const Icon(Icons.photo_library_rounded, size: 18),
                label: const Text('Pick Image'),
              ),
              OutlinedButton.icon(
                key: const ValueKey('tag_editor_reset_cover'),
                onPressed: _isSaving ? null : _handleResetCover,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset Cover'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _coverFallback(
    NexaSurfaceTokens surfaceTokens,
    ColorScheme colorScheme,
  ) {
    return Container(
      width: 140,
      height: 140,
      color: surfaceTokens.level2,
      child: Icon(
        Icons.album_rounded,
        size: 56,
        color: colorScheme.primary.withOpacity(0.65),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surfaceTokens = NexaSurfaceTokens.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return NexaSurface(
      tier: NexaSurfaceTier.l3,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: bottomInset + 16,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Track Tags',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      BidiText(
                        widget.track.filePath ?? 'Library metadata',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: AppTypography.bodySmall.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildCoverHeader(context, surfaceTokens, colorScheme),
                    const SizedBox(height: AppSpacing.lg),
                    _buildField(
                      context: context,
                      label: 'TITLE',
                      controller: _titleController,
                      surfaceTokens: surfaceTokens,
                      colorScheme: colorScheme,
                    ),
                    _buildField(
                      context: context,
                      label: 'ARTIST / SINGER',
                      controller: _artistController,
                      surfaceTokens: surfaceTokens,
                      colorScheme: colorScheme,
                    ),
                    _buildField(
                      context: context,
                      label: 'ALBUM',
                      controller: _albumController,
                      surfaceTokens: surfaceTokens,
                      colorScheme: colorScheme,
                    ),
                    _buildField(
                      context: context,
                      label: 'GENRE',
                      controller: _genreController,
                      surfaceTokens: surfaceTokens,
                      colorScheme: colorScheme,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            context: context,
                            label: 'YEAR / DATE',
                            controller: _yearController,
                            surfaceTokens: surfaceTokens,
                            colorScheme: colorScheme,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            context: context,
                            label: 'TRACK #',
                            controller: _trackNumController,
                            surfaceTokens: surfaceTokens,
                            colorScheme: colorScheme,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    _buildField(
                      context: context,
                      label: 'COMMENT',
                      controller: _commentController,
                      surfaceTokens: surfaceTokens,
                      colorScheme: colorScheme,
                      maxLines: 3,
                      hintText: 'Add notes or comment...',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
