import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/constants/storage_keys.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_button.dart';
import 'package:nexa_player/shared/widgets/glass/glass_text_field.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Privacy, crash analytics, database wipe, and JSON export/import screen.
class PrivacyStorageSettingsScreen extends ConsumerWidget {
  const PrivacyStorageSettingsScreen({super.key});

  Future<void> _exportSettings(BuildContext context, WidgetRef ref) async {
    final service = ref.read(settingsServiceProvider);
    final jsonString = await service.exportSettingsJson();

    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Export Settings (JSON)',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your current configuration has been formatted into JSON. You can copy it to the clipboard as a backup.',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white12),
              ),
              child: SingleChildScrollView(
                child: Text(
                  jsonString,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          GlassButton(
            label: 'Copy to Clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonString));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings backup copied to clipboard!'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _importSettings(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Import Settings (JSON)',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Paste your JSON configuration below to restore settings:',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            GlassTextField(
              controller: controller,
              hintText: '{\n  "audio": { ... }\n}',
              maxLines: 8,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Restore',
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final service = ref.read(settingsServiceProvider);
              final result = await service.importSettingsJson(text);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();

              result.when(
                success: (_) {
                  ref.invalidate(audioSettingsProvider);
                  ref.invalidate(controlSettingsProvider);
                  ref.invalidate(albumArtSettingsProvider);
                  ref.invalidate(metadataLyricsSettingsProvider);
                  ref.invalidate(powerSavingSettingsProvider);
                  ref.invalidate(notificationSettingsProvider);
                  ref.invalidate(privacySettingsProvider);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Settings restored successfully!'),
                    ),
                  );
                },
                failure: (err) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Restore failed: ${err.message}'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _clearSearchHistory(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Clear Search History?',
        content: const Text(
          'This will remove all recent search queries. Your music library remains intact.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Clear History',
            accentColor: Colors.redAccent,
            onPressed: () async {
              final storage = ref.read(storageServiceProvider);
              await storage.remove(StorageKeys.recentSearches);
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Search history cleared'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _resetDefaults(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Reset All Settings?',
        content: const Text(
          'This will restore all audio, controls, theme, and playback options back to factory defaults. Your music library and playlists will NOT be deleted.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Reset Defaults',
            accentColor: Colors.redAccent,
            onPressed: () async {
              final service = ref.read(settingsServiceProvider);
              await service.resetAllSettingsToDefaults();
              if (!ctx.mounted) return;
              Navigator.of(ctx).pop();

              ref.invalidate(audioSettingsProvider);
              ref.invalidate(controlSettingsProvider);
              ref.invalidate(albumArtSettingsProvider);
              ref.invalidate(metadataLyricsSettingsProvider);
              ref.invalidate(powerSavingSettingsProvider);
              ref.invalidate(notificationSettingsProvider);
              ref.invalidate(privacySettingsProvider);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All settings reset to defaults'),
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
    final privacy = ref.watch(privacySettingsProvider);
    final notifier = ref.read(privacySettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Privacy & Storage',
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Privacy & Diagnostics
          SettingsGroupCard(
            title: 'Privacy & Diagnostics',
            children: [
              SettingsSwitchTile(
                title: 'Anonymous Crash Reporting',
                subtitle: 'Automatically send stack traces to developers to resolve bugs',
                icon: Icons.bug_report_rounded,
                iconColor: Colors.orangeAccent,
                value: privacy.crashReporting,
                onChanged: (val) =>
                    notifier.update(privacy.copyWith(crashReporting: val)),
              ),
              SettingsSwitchTile(
                title: 'Telemetry & Usage Diagnostics',
                subtitle: 'Send aggregated playback telemetry to improve audio stability',
                icon: Icons.analytics_rounded,
                iconColor: Colors.blueAccent,
                value: privacy.analytics,
                onChanged: (val) =>
                    notifier.update(privacy.copyWith(analytics: val)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Backup & Restore
          SettingsGroupCard(
            title: 'Backup & Restore',
            children: [
              SettingsActionTile(
                title: 'Export Settings (JSON)',
                subtitle: 'Create a portable JSON configuration backup',
                icon: Icons.upload_file_rounded,
                iconColor: Colors.tealAccent,
                onTap: () => _exportSettings(context, ref),
              ),
              SettingsActionTile(
                title: 'Import Settings (JSON)',
                subtitle: 'Restore your configuration from a previously exported JSON backup',
                icon: Icons.download_rounded,
                iconColor: Colors.cyanAccent,
                onTap: () => _importSettings(context, ref),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Cache & Reset
          SettingsGroupCard(
            title: 'History & Factory Reset',
            children: [
              SettingsActionTile(
                title: 'Clear Search History',
                subtitle: 'Remove all saved search suggestions and recent queries',
                icon: Icons.history_rounded,
                iconColor: Colors.amberAccent,
                onTap: () => _clearSearchHistory(context, ref),
              ),
              SettingsActionTile(
                title: 'Reset Settings to Factory Defaults',
                subtitle: 'Revert all audio, theme, and control preferences back to defaults',
                icon: Icons.restart_alt_rounded,
                iconColor: Colors.redAccent,
                isDestructive: true,
                onTap: () => _resetDefaults(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
