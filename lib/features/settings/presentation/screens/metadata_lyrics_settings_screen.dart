import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_tiles.dart';

/// Lyrics synchronization, translation, and tag persistence settings screen.
class MetadataLyricsSettingsScreen extends ConsumerWidget {
  const MetadataLyricsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metadata = ref.watch(metadataLyricsSettingsProvider);
    final notifier = ref.read(metadataLyricsSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Lyrics & Metadata',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          // Synchronized Lyrics
          SettingsGroupCard(
            title: 'Synchronized Lyrics (LRC)',
            children: [
              SettingsSwitchTile(
                title: 'Auto-Fetch Synchronized Lyrics',
                subtitle: 'Automatically query online providers for matching time-synced lyrics',
                icon: Icons.lyrics_rounded,
                iconColor: Colors.cyanAccent,
                value: metadata.autoFetchLyrics,
                onChanged: (val) =>
                    notifier.update(metadata.copyWith(autoFetchLyrics: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Preferred Lyrics Source',
                subtitle: 'Primary provider for karaoke and plain lyrics retrieval',
                icon: Icons.cloud_done_rounded,
                iconColor: Colors.tealAccent,
                selectedValue: metadata.preferredLyricsSource,
                options: const {
                  'lrclib': 'LRCLIB (Synchronized Database)',
                  'embedded': 'Embedded USLT / SYLT Tag',
                  'genius': 'Genius API (Web Lyrics)',
                  'offline': 'Companion Local .lrc Files Only',
                },
                onSelected: (val) => notifier.update(
                  metadata.copyWith(preferredLyricsSource: val),
                ),
              ),
              SettingsSliderTile(
                title: 'Lyrics Text Size',
                subtitle: 'Scale karaoke line typography in lyrics viewer',
                icon: Icons.format_size_rounded,
                iconColor: Colors.blueAccent,
                value: metadata.lyricsFontSize,
                min: 14,
                max: 34,
                divisions: 10,
                valueLabel: '${metadata.lyricsFontSize.round()} pt',
                onChanged: (val) =>
                    notifier.update(metadata.copyWith(lyricsFontSize: val)),
              ),
              SettingsSelectorTile<String>(
                title: 'Active Line Glow Color',
                subtitle: 'Color accent for currently sung lyric line',
                icon: Icons.color_lens_rounded,
                iconColor: Colors.pinkAccent,
                selectedValue: metadata.lyricsHighlightColorHex,
                options: const {
                  '0xFF00E5FF': 'Neon Cyan',
                  '0xFFD946EF': 'Electric Orchid',
                  '0xFFFFD600': 'Cyberpunk Gold',
                  '0xFFFF4081': 'Hot Rose Pink',
                  '0xFF00E676': 'Emerald Neon',
                },
                onSelected: (val) => notifier.update(
                  metadata.copyWith(lyricsHighlightColorHex: val),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Translation & Localization
          SettingsGroupCard(
            title: 'Metadata Translation',
            children: [
              SettingsSwitchTile(
                title: 'Translate Song Metadata',
                subtitle: 'Automatically translate non-Latin song titles and artist names',
                icon: Icons.translate_rounded,
                iconColor: Colors.purpleAccent,
                value: metadata.translateMetadata,
                onChanged: (val) =>
                    notifier.update(metadata.copyWith(translateMetadata: val)),
              ),
              if (metadata.translateMetadata)
                SettingsSelectorTile<String>(
                  title: 'Translation Provider',
                  subtitle: 'Machine translation cloud or offline neural model',
                  icon: Icons.smart_toy_rounded,
                  iconColor: Colors.purpleAccent,
                  selectedValue: metadata.translationProvider,
                  options: const {
                    'google': 'Google Neural Translate',
                    'deepl': 'DeepL Pro API',
                    'local': 'On-Device Lightweight Model',
                  },
                  onSelected: (val) => notifier.update(
                    metadata.copyWith(translationProvider: val),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // File Writeback
          SettingsGroupCard(
            title: 'File Writeback & Storage',
            children: [
              SettingsSwitchTile(
                title: 'Write Tags Directly to File',
                subtitle: 'Save metadata edits into physical MP3/FLAC ID3 tags',
                icon: Icons.edit_note_rounded,
                iconColor: Colors.amberAccent,
                value: metadata.writeTagsToFile,
                onChanged: (val) =>
                    notifier.update(metadata.copyWith(writeTagsToFile: val)),
              ),
              SettingsSwitchTile(
                title: 'Embed Artwork into Audio File',
                subtitle: 'Save downloaded cover jackets directly into media containers',
                icon: Icons.save_rounded,
                iconColor: Colors.lightGreenAccent,
                value: metadata.writeArtToFile,
                onChanged: (val) =>
                    notifier.update(metadata.copyWith(writeArtToFile: val)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
