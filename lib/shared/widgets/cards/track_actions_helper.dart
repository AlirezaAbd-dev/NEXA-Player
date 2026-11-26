import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexa_player/app/routes.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/l10n/locale_controller.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/playlists/domain/services/share_service.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/track_tag_editor_modal.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';

/// Shared helper executing universal [TrackTileMenuAction] actions across
/// Songs, Folders, Albums, Artists, Search, Playlists, and Now Playing.
abstract final class TrackActionsHelper {
  static Future<void> handleAction(
    BuildContext context,
    WidgetRef ref, {
    required Track track,
    required TrackTileMenuAction action,
    String? activePlaylistId,
  }) async {
    switch (action) {
      case TrackTileMenuAction.playNext:
        ref.read(playerNotifierProvider.notifier).addNext(track);
        _showSnack(context, context.l10n.playingNextSnack(track.title));
        break;
      case TrackTileMenuAction.addToQueue:
        ref.read(playerNotifierProvider.notifier).addTrack(track);
        _showSnack(context, context.l10n.addedToQueueSnack(track.title));
        break;
      case TrackTileMenuAction.addToPlaylist:
        await AddToPlaylistBottomSheet.show(context, track: track);
        break;
      case TrackTileMenuAction.editTags:
        final updated = await TrackTagEditorModal.show(context, track: track);
        if (updated != null && activePlaylistId != null) {
          ref.invalidate(playlistTracksProvider(activePlaylistId));
        }
        break;
      case TrackTileMenuAction.goToAlbum:
        if (context.mounted) {
          context.go(AppRoutes.albums);
        }
        break;
      case TrackTileMenuAction.goToArtist:
        if (context.mounted) {
          context.go(AppRoutes.artists);
        }
        break;
      case TrackTileMenuAction.share:
        if (getIt.isRegistered<IShareService>()) {
          await getIt<IShareService>().shareTrack(track);
        }
        break;
      case TrackTileMenuAction.trimRingtone:
        if (context.mounted) {
          context.push(AppRoutes.ringtoneTrimmer, extra: track);
        }
        break;
      case TrackTileMenuAction.details:
        await TrackTagEditorModal.show(context, track: track);
        break;
    }
  }

  static void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
