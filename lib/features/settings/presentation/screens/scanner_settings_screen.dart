import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/core/services/storage_permission_orchestrator.dart';
import 'package:nexa_player/core/services/storage_permission_service.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/features/scanner/presentation/providers/scanner_providers.dart';
import 'package:nexa_player/shared/models/scan_directory.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';

/// Scanner settings screen managing scan directories, skip heuristics, and manual rescan.
class ScannerSettingsScreen extends ConsumerStatefulWidget {
  const ScannerSettingsScreen({super.key});

  @override
  ConsumerState<ScannerSettingsScreen> createState() =>
      _ScannerSettingsScreenState();
}

class _ScannerSettingsScreenState extends ConsumerState<ScannerSettingsScreen> {
  bool _skipShortFiles = true;
  double _minDuration = 5.0;
  bool _skipNoMedia = true;
  bool _skipMp4 = true;
  bool _scanOnLaunch = true;
  final String _tagEncoding = 'Auto (UTF-8 / ID3v2)';

  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Add Music Folder',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlassTextField(
              key: Phase2Keys.addFolderPathInput,
              controller: controller,
              hintText: '/storage/emulated/0/Music',
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
            key: Phase2Keys.addFolderConfirmButton,
            label: 'Add',
            onPressed: () {
              final path = controller.text.trim();
              if (path.isNotEmpty) {
                ref.read(scanDirectoriesProvider.notifier).addDirectory(path);
              }
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  void _confirmDropDatabase(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Drop & Wipe Database?',
        content: const Text(
          'This will purge all indexed tracks, albums, artists, and playlists from the database cache. Physical audio files on your storage will remain untouched.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Wipe Database',
            accentColor: Colors.redAccent,
            onPressed: () {
              final db = ref.read(appDatabaseProvider);
              db.execute('DELETE FROM tracks;');
              db.execute('DELETE FROM albums;');
              db.execute('DELETE FROM artists;');
              db.execute('DELETE FROM genres;');

              ref.invalidate(tracksListProvider);
              ref.invalidate(albumsListProvider);
              ref.invalidate(artistsListProvider);
              ref.invalidate(genresListProvider);
              ref.invalidate(foldersTreeProvider);

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Database reset. Tap "Scan Now" to re-index.'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _startRescan(List<ScanDirectory> dirs) async {
    final hasPerm = await StoragePermissionOrchestrator.ensureStoragePermission(context);
    if (!hasPerm) {
      ref.read(scannerStateNotifierProvider.notifier).setPermissionDenied();
      return;
    }

    var activePaths =
        dirs.where((d) => d.isEnabled).map((d) => d.path).toList();

    if (activePaths.isEmpty) {
      final discovered = StoragePermissionService.discoverStandardMusicDirectories();
      if (discovered.isNotEmpty) {
        for (final p in discovered) {
          await ref.read(scanDirectoriesProvider.notifier).addDirectory(p);
        }
        activePaths = discovered;
      } else {
        activePaths = const ['/storage/emulated/0/Music', '/storage/emulated/0/Download'];
      }
    }

    final config = ScannerConfig(
      skipShortAudio: _skipShortFiles,
      minDurationSeconds: _minDuration.round(),
      skipNoMedia: _skipNoMedia,
      skipSmallFiles: true,
    );

    await ref.read(scannerStateNotifierProvider.notifier).startScan(
          activePaths,
          config: config,
        );

    // Refresh library lists
    ref.invalidate(tracksListProvider);
    ref.invalidate(albumsListProvider);
    ref.invalidate(artistsListProvider);
    ref.invalidate(genresListProvider);
    ref.invalidate(foldersTreeProvider);
  }

  @override
  Widget build(BuildContext context) {
    final directoriesAsync = ref.watch(scanDirectoriesProvider);
    final scannerState = ref.watch(scannerStateNotifierProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      key: Phase2Keys.scannerSettingsScreen,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Media Scanner',
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Section 1: Scan Actions & Status
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Scanner Status',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    GlassButton(
                      size: GlassButtonSize.small,
                      key: Phase2Keys.rescanButton,
                      label: scannerState.status == ScannerStatus.scanning
                          ? 'Scanning...'
                          : 'Scan Now',
                      onPressed: scannerState.status == ScannerStatus.scanning
                          ? null
                          : () {
                              final dirs = directoriesAsync.valueOrNull ?? [];
                              _startRescan(dirs);
                            },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: switch (scannerState.status) {
                          ScannerStatus.scanning => colorScheme.primary,
                          ScannerStatus.completed => Colors.greenAccent,
                          ScannerStatus.error ||
                          ScannerStatus.permissionDenied =>
                            Colors.redAccent,
                          ScannerStatus.idle => Colors.greenAccent,
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        switch (scannerState.status) {
                          ScannerStatus.idle =>
                            'Scanner ready · Tap Scan Now to index library',
                          ScannerStatus.scanning =>
                            'Scanning: ${scannerState.filesScanned} of ${scannerState.filesFound} files...',
                          ScannerStatus.completed =>
                            'Scan complete! ${scannerState.filesScanned} files indexed.',
                          ScannerStatus.error =>
                            'Scan failed: ${scannerState.errorMessage}',
                          ScannerStatus.permissionDenied =>
                            'Storage permission required. Tap here to open App Settings.',
                        },
                        key: Phase2Keys.scannerStatusText,
                        style: AppTypography.bodySmall.copyWith(
                          fontWeight: FontWeight.w500,
                          color: scannerState.status ==
                                  ScannerStatus.permissionDenied
                              ? Colors.redAccent
                              : null,
                        ),
                      ),
                    ),
                    if (scannerState.status == ScannerStatus.permissionDenied) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => openAppSettings(),
                        child: const Text('Settings'),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(
                  key: Phase2Keys.scannerProgressBar,
                  value: scannerState.progress,
                  backgroundColor: Colors.white10,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Heuristics & Skip Rules
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Skip Heuristics & Filtering',
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  key: Phase2Keys.skipShortFilesSwitch,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Skip Short Audio Files'),
                  subtitle: Text(
                    'Exclude ringtones and voice clips shorter than ${_minDuration.round()}s',
                    style: AppTypography.bodySmall,
                  ),
                  value: _skipShortFiles,
                  onChanged: (val) {
                    setState(() {
                      _skipShortFiles = val;
                    });
                  },
                ),
                if (_skipShortFiles) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Minimum Duration:',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text('${_minDuration.round()}s'),
                    ],
                  ),
                  Slider(
                    key: Phase2Keys.minDurationSlider,
                    min: 1,
                    max: 60,
                    divisions: 59,
                    value: _minDuration,
                    onChanged: (val) {
                      setState(() {
                        _minDuration = val;
                      });
                    },
                  ),
                ],
                const Divider(color: Colors.white12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Skip .nomedia Directories'),
                  subtitle: const Text(
                    'Respect Android hidden directory marker flags',
                    style: AppTypography.bodySmall,
                  ),
                  value: _skipNoMedia,
                  onChanged: (val) {
                    setState(() {
                      _skipNoMedia = val;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Skip Video/MP4 Audio Containers'),
                  subtitle: const Text(
                    'Filter out video files from audio library scan',
                    style: AppTypography.bodySmall,
                  ),
                  value: _skipMp4,
                  onChanged: (val) {
                    setState(() {
                      _skipMp4 = val;
                    });
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Automatic Scan on App Launch'),
                  subtitle: const Text(
                    'Detect newly downloaded media on startup',
                    style: AppTypography.bodySmall,
                  ),
                  value: _scanOnLaunch,
                  onChanged: (val) {
                    setState(() {
                      _scanOnLaunch = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 3: Metadata & Formats
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tag Encoding & Formats',
                  style: AppTypography.titleMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Tag Encoding',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(GlassTokens.radiusSmall),
                      ),
                      child: Text(
                        _tagEncoding,
                        style: AppTypography.labelSmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Recognized Extensions: .mp3, .flac, .m4a, .wav, .aac, .ogg, .opus',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 4: Music Folders
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Music Folders',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      key: Phase2Keys.addFolderButton,
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      tooltip: 'Add Folder',
                      onPressed: () => _showAddFolderDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                directoriesAsync.when(
                  data: (dirs) {
                    if (dirs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No folders configured. Tap "+" to add a folder.',
                          style: AppTypography.bodySmall,
                        ),
                      );
                    }

                    return ListView.builder(
                      key: Phase2Keys.scannerFolderList,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: dirs.length,
                      itemBuilder: (context, index) {
                        final dir = dirs[index];
                        final segments = dir.path.split('/').where((s) => s.isNotEmpty).toList();
                        final friendlyName = segments.isNotEmpty ? segments.last : dir.path;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                            ),
                            child: Icon(
                              Icons.folder_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            friendlyName,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            dir.path,
                            style: AppTypography.bodySmall.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            key: Phase2Keys.removeFolderButton(dir.path),
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Remove Folder',
                            onPressed: () {
                              ref
                                  .read(scanDirectoriesProvider.notifier)
                                  .removeDirectory(dir.path);
                            },
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 5: Database Maintenance (Dangerous)
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Database Maintenance',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Purge and reconstruct the local SQLite music database index.',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                GlassButton(
                  label: 'Drop & Reconstruct Database',
                  accentColor: Colors.redAccent,
                  onPressed: () => _confirmDropDatabase(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
