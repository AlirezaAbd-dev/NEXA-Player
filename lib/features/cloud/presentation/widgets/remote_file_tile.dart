import 'package:flutter/material.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../domain/models/remote_media_item.dart';

/// List item displaying either a remote folder or an audio streamable track.
class RemoteFileTile extends StatelessWidget {
  const RemoteFileTile({
    super.key,
    required this.item,
    required this.onTap,
    this.onDownloadTap,
    this.isDownloading = false,
    this.downloadProgress = 0.0,
  });

  final RemoteMediaItem item;
  final VoidCallback onTap;
  final VoidCallback? onDownloadTap;
  final bool isDownloading;
  final double downloadProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (item.isDirectory) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: ListTile(
          key: ValueKey('remote_folder_${item.id}'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
            side: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
          tileColor: Colors.white.withOpacity(0.02),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.15),
            ),
            child: Icon(
              Icons.folder_rounded,
              color: colorScheme.primary,
              size: 20,
            ),
          ),
          title: Text(
            item.name,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          subtitle: Text(
            'Remote Folder',
            style: AppTypography.bodySmall.copyWith(
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          onTap: onTap,
        ),
      );
    }

    final ext = item.fileExtension.toUpperCase();
    final badgeColor = _resolveFormatColor(ext);
    final sizeFormatted = _formatBytes(item.sizeBytes ?? 0);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: ListTile(
        key: ValueKey('remote_track_${item.id}'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GlassTokens.radiusSm),
          side: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
        tileColor: Colors.white.withOpacity(0.02),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.05),
          ),
          child: const Icon(
            Icons.music_note_rounded,
            color: Colors.white70,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                item.title ?? item.name,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: badgeColor.withOpacity(0.4), width: 0.5),
              ),
              child: Text(
                ext.isNotEmpty ? ext : 'AUDIO',
                style: AppTypography.labelSmall.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Text(
              item.artist ?? 'Network Stream',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            if (sizeFormatted.isNotEmpty) ...[
              Text(
                ' • $sizeFormatted',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
            ],
            if (item.isCached) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF00E676)),
              const SizedBox(width: 2),
              Text(
                'Cached',
                style: AppTypography.labelSmall.copyWith(
                  color: const Color(0xFF00E676),
                  fontSize: 10,
                ),
              ),
            ],
          ],
        ),
        trailing: isDownloading
            ? SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  value: downloadProgress > 0 ? downloadProgress : null,
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            : IconButton(
                icon: Icon(
                  item.isCached ? Icons.download_done_rounded : Icons.cloud_download_outlined,
                  color: item.isCached ? const Color(0xFF00E676) : Colors.white60,
                  size: 20,
                ),
                onPressed: onDownloadTap,
                tooltip: item.isCached ? 'Available Offline' : 'Cache for Offline Play',
              ),
        onTap: onTap,
      ),
    );
  }

  Color _resolveFormatColor(String ext) {
    switch (ext) {
      case 'DSD':
      case 'DSF':
      case 'DFF':
        return const Color(0xFFFFD700); // Gold
      case 'FLAC':
      case 'ALAC':
        return const Color(0xFF00E676); // Emerald
      case 'WAV':
      case 'AIFF':
        return const Color(0xFF00E5FF); // Cyan
      case 'M4A':
      case 'AAC':
        return const Color(0xFFFF9100); // Amber
      default:
        return const Color(0xFFB0BEC5); // Neutral Slate
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
