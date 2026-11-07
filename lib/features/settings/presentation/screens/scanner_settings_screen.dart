import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
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

  Future<void> _startRescan(List<ScanDirectory> dirs) async {
    final activePaths = dirs.where((d) => d.isEnabled).map((d) => d.path).toList();
    final config = ScannerConfig(
      skipShortAudio: _skipShortFiles,
      minDurationSeconds: _minDuration.round(),
      skipNoMedia: true,
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

    return Scaffold(
      key: Phase2Keys.scannerSettingsScreen,
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Media Scanner',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 40.0),
        children: [
          // Section 1: Scan Actions & Status
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scanner Status',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    GlassButton(
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
                Text(
                  switch (scannerState.status) {
                    ScannerStatus.idle => 'Idle. Ready to scan.',
                    ScannerStatus.scanning =>
                      'Scanning: ${scannerState.filesScanned} of ${scannerState.filesFound} files...',
                    ScannerStatus.completed =>
                      'Scan complete! ${scannerState.filesScanned} files indexed.',
                    ScannerStatus.error =>
                      'Scan failed: ${scannerState.errorMessage}',
                  },
                  key: Phase2Keys.scannerStatusText,
                  style: AppTypography.bodySmall,
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
                  'Skip Heuristics',
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
                    children: [
                      const Text('Minimum Duration:'),
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 3: Music Folders
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Music Folders',
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.bold),
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
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.folder_rounded),
                          title: Text(
                            dir.path,
                            style: AppTypography.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: IconButton(
                            key: Phase2Keys.removeFolderButton(dir.path),
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                              color: Colors.redAccent,
                            ),
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
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error: $e'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
