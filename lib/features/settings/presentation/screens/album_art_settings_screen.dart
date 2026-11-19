import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Album artwork rendering, online downloading, and disk cache management screen.
class AlbumArtSettingsScreen extends ConsumerWidget {
  const AlbumArtSettingsScreen({super.key});

  void _confirmClearCache(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Clear Covers Cache?',
        content: const Text(
          'This will remove all downloaded album covers from local cache. Embedded file tags will remain untouched.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Clear Cache',
            accentColor: Colors.redAccent,
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Album covers cache cleared successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final art = ref.watch(albumArtSettingsProvider);
    final notifier = ref.read(albumArtSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Album Art Settings',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          // Online Retrieval
          SettingsGroupCard(
            title: 'Online Artwork Fetching',
            children: [
              SettingsSwitchTile(
                title: 'Download Missing Covers',
                subtitle: 'Automatically fetch high-res covers for unjacketed albums',
                icon: Icons.cloud_download_rounded,
                iconColor: Colors.pinkAccent,
                value: art.downloadMissingCovers,
                onChanged: (val) =>
                    notifier.update(art.copyWith(downloadMissingCovers: val)),
              ),
              SettingsSwitchTile(
                title: 'Only via Wi-Fi',
                subtitle: 'Save mobile cellular data by downloading on unmetered Wi-Fi',
                icon: Icons.wifi_rounded,
                iconColor: Colors.blueAccent,
                value: art.onlyViaWifi,
                onChanged: (val) =>
                    notifier.update(art.copyWith(onlyViaWifi: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Cover Download Quality',
                subtitle: 'Target image resolution and compression',
                icon: Icons.photo_size_select_actual_rounded,
                iconColor: Colors.purpleAccent,
                selectedValue: art.downloadQuality,
                options: const {
                  'low': 'Compact (300×300 px)',
                  'medium': 'Balanced (600×600 px)',
                  'high': 'High Definition (1200×1200 px)',
                  'original': 'Uncompressed Original Source',
                },
                onSelected: (val) =>
                    notifier.update(art.copyWith(downloadQuality: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Max Download File Size',
                subtitle: 'Cap maximum download memory per cover',
                icon: Icons.data_usage_rounded,
                iconColor: Colors.amberAccent,
                selectedValue: art.maxDownloadSize,
                options: const {
                  '500_kb': '500 KB limit',
                  '1_mb': '1 MB limit',
                  '2_mb': '2 MB limit',
                  'unlimited': 'Unlimited',
                },
                onSelected: (val) =>
                    notifier.update(art.copyWith(maxDownloadSize: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Priority & Rendering
          SettingsGroupCard(
            title: 'Visual Rendering & Priority',
            children: [
              SettingsSelectorTile<String>(
                title: 'Artwork Source Priority',
                subtitle: 'Which image source to prioritize when both are present',
                icon: Icons.layers_rounded,
                iconColor: Colors.tealAccent,
                selectedValue: art.embeddedArtPriority,
                options: const {
                  'prefer_embedded': 'Prefer Embedded ID3 Tag Art',
                  'prefer_downloaded': 'Prefer High-Res Downloaded Art',
                },
                onSelected: (val) =>
                    notifier.update(art.copyWith(embeddedArtPriority: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Blurred Art Background',
                subtitle: 'Backdrop blur intensity in Now Playing screen',
                icon: Icons.blur_on_rounded,
                iconColor: Colors.cyanAccent,
                selectedValue: art.blurBackground,
                options: const {
                  'none': 'Disabled (Clean AMOLED Black)',
                  'low': 'Subtle (10px Gaussian)',
                  'medium': 'Balanced (24px Glass)',
                  'high': 'Deep Diffusion (40px Atmosphere)',
                },
                onSelected: (val) =>
                    notifier.update(art.copyWith(blurBackground: val)),
              ),
              SettingsSwitchTile(
                title: 'Auto-Crop to Square',
                subtitle: 'Force 1:1 aspect ratio center-crop for non-square art',
                icon: Icons.crop_square_rounded,
                iconColor: Colors.orangeAccent,
                value: art.autoCropSquare,
                onChanged: (val) =>
                    notifier.update(art.copyWith(autoCropSquare: val)),
              ),
              SettingsSwitchTile(
                title: 'Animated Covers (GIF / APNG)',
                subtitle: 'Render animated album artwork where available',
                icon: Icons.animation_rounded,
                iconColor: Colors.indigoAccent,
                value: art.animatedCovers,
                onChanged: (val) =>
                    notifier.update(art.copyWith(animatedCovers: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Storage & Cache
          SettingsGroupCard(
            title: 'Disk Storage & Cache',
            children: [
              SettingsSwitchTile(
                title: 'Save Without File Extension',
                subtitle: 'Prevent gallery scanners from displaying cached album jackets',
                icon: Icons.hide_image_outlined,
                iconColor: Colors.grey,
                value: art.saveWithoutExtension,
                onChanged: (val) =>
                    notifier.update(art.copyWith(saveWithoutExtension: val)),
              ),
              SettingsActionTile(
                title: 'Covers Storage Location',
                subtitle: art.savedFolder,
                icon: Icons.folder_open_rounded,
                iconColor: Colors.lightGreenAccent,
                onTap: () {},
              ),
              SettingsActionTile(
                title: 'Clear Covers Cache',
                subtitle: 'Purge all cached covers from disk to free up storage space',
                icon: Icons.delete_sweep_rounded,
                iconColor: Colors.redAccent,
                isDestructive: true,
                onTap: () => _confirmClearCache(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
