import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/l10n/locale_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/inputs/nexa_search_bar.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../providers/settings_providers.dart';
import '../widgets/audio_status_strip.dart';

/// Semantic Keys matching E2EKeys and widget tests.
abstract final class _SettingsKeys {
  static const Key themeSettingsTile = ValueKey('theme_settings_tile');
  static const Key searchSettingsInput = ValueKey('search_settings_input');
}

/// Central settings hub for NEXA Player organized into a 3-tier audiophile hierarchy
/// with instant telemetry status strip and fuzzy search.
class SettingsHubScreen extends ConsumerStatefulWidget {
  const SettingsHubScreen({super.key});

  @override
  ConsumerState<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends ConsumerState<SettingsHubScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final localePref = ref.watch(localeControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final searchQuery = ref.watch(settingsSearchQueryProvider);
    final searchResults = ref.watch(settingsSearchResultsProvider);
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: l10n.tabSettings,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Instant Settings Search Bar
          NexaSearchBar(
            key: _SettingsKeys.searchSettingsInput,
            controller: _searchController,
            hintText: l10n.searchSettingsHint,
            onChanged: (val) {
              ref.read(settingsSearchQueryProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // If searching: display search results
          if (searchQuery.trim().isNotEmpty) ...[
            if (searchResults.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'No settings found for "$searchQuery"',
                        style: AppTypography.bodyMedium.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4.0, bottom: 8.0),
                child: Text(
                  'MATCHING SETTINGS (${searchResults.length})',
                  style: AppTypography.labelSmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...searchResults.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: NexaSurface(
                      tier: NexaSurfaceTier.l1,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      borderRadius:
                          BorderRadius.circular(GlassTokens.radiusCard),
                      onTap: () {
                        _searchController.clear();
                        ref.read(settingsSearchQueryProvider.notifier).state =
                            '';
                        context.push(item.route);
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(
                                          GlassTokens.radiusSmall,
                                        ),
                                      ),
                                      child: Text(
                                        item.category.toUpperCase(),
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          fontSize: 10,
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style:
                                            AppTypography.titleMedium.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.subtitle,
                                  style: AppTypography.bodySmall.copyWith(
                                    color:
                                        colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: colorScheme.onSurface.withOpacity(0.35),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ] else ...[
            // Hardware Audio Status Strip (L2 borderless telemetry)
            const AudioStatusStrip(),
            const SizedBox(height: AppSpacing.lg),

            // ==========================================
            // TIER 1: DAILY ESSENTIALS
            // ==========================================
            _buildSectionHeader(context, l10n.dailyEssentials),
            const SizedBox(height: AppSpacing.xs),

            // Theme & Appearance (Hero Card)
            NexaSurface(
              key: _SettingsKeys.themeSettingsTile,
              tier: NexaSurfaceTier.l1,
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
              onTap: () => context.push(AppRoutes.themePicker),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.18),
                      borderRadius:
                          BorderRadius.circular(GlassTokens.radiusSmall),
                    ),
                    child: Icon(
                      Icons.palette_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.themeAndAppearance,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Preset: ${themeState.preset.displayName} • ${themeState.themeMode.name.toUpperCase()}',
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Language Picker Card (System Default / English / فارسی)
            NexaSurface(
              key: const ValueKey('language_settings_tile'),
              tier: NexaSurfaceTier.l1,
              padding: const EdgeInsets.all(AppSpacing.md),
              borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
              onTap: () => _showLanguagePicker(context, localePref),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.18),
                      borderRadius:
                          BorderRadius.circular(GlassTokens.radiusSmall),
                    ),
                    child: Icon(
                      Icons.language_rounded,
                      color: colorScheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.language,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          switch (localePref) {
                            AppLocalePreference.system => l10n.languageSubtitleSystem,
                            AppLocalePreference.en => l10n.languageSubtitleEnglish,
                            AppLocalePreference.fa => l10n.languageSubtitlePersian,
                          },
                          style: AppTypography.bodySmall.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurface.withOpacity(0.45),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Playback & Controls
            _buildCategoryCard(
              context,
              icon: Icons.gamepad_rounded,
              iconColor: Colors.blueAccent,
              title: 'Playback & Controls',
              subtitle: 'Telephony resume, Focus ducking, Gestures, Car mode',
              onTap: () => context.push(AppRoutes.controlSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Homescreen Widgets & Bedside Standby
            _buildCategoryCard(
              context,
              icon: Icons.widgets_rounded,
              iconColor: Colors.deepOrangeAccent,
              title: 'Homescreen Widgets & Standby',
              subtitle: '4×1, 4×2 Hero Vinyl, 2×2, 4×3 Karaoke & OLED Bedside',
              badge: 'INTERACTIVE',
              onTap: () => context.push(AppRoutes.widgets),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ==========================================
            // TIER 2: ACOUSTIC ENGINE
            // ==========================================
            _buildSectionHeader(context, 'ACOUSTIC ENGINE'),
            const SizedBox(height: AppSpacing.xs),

            // Audio Settings
            _buildCategoryCard(
              context,
              icon: Icons.volume_up_rounded,
              iconColor: Colors.amberAccent,
              title: 'Audio Settings',
              subtitle: 'Bit-perfect Hi-Res, Gapless, DVC, Sample rate',
              badge: '14 OPTIONS',
              onTap: () => context.push(AppRoutes.audioSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Equalizer & DSP Engine
            _buildCategoryCard(
              context,
              icon: Icons.equalizer_rounded,
              iconColor: Colors.tealAccent,
              title: 'Equalizer & DSP Engine',
              subtitle: '10-Band Parametric EQ, Z-Bass, Reverb, Presets',
              badge: 'STUDIO DSP',
              onTap: () => context.push(AppRoutes.equalizer),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Visualizer & Spectrum Engine
            _buildCategoryCard(
              context,
              icon: Icons.graphic_eq_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Visualizer & Spectrum',
              subtitle: 'FFT Bars, Circle, Wave, Spectrogram, VU Meter',
              badge: 'REAL-TIME FFT',
              onTap: () => context.push(AppRoutes.visualizerSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Auto & Wearable Ecosystem
            _buildCategoryCard(
              context,
              icon: Icons.directions_car_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Auto & Wearables',
              subtitle: 'Android Auto, Car Mode HUD, Galaxy/Pixel Watch companion',
              badge: 'AUTOMOTIVE',
              onTap: () => context.push(AppRoutes.autoSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Cloud & Network Streaming
            _buildCategoryCard(
              context,
              icon: Icons.cloud_sync_rounded,
              iconColor: const Color(0xFF00E5FF),
              title: 'Cloud & Network Streaming',
              subtitle: 'UPnP/DLNA Casting, WebDAV/NAS sync, Lossless Web Radio',
              badge: 'DLNA / NAS',
              onTap: () => context.push(AppRoutes.cloud),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ==========================================
            // TIER 3: SYSTEM & STORAGE
            // ==========================================
            _buildSectionHeader(context, 'SYSTEM & STORAGE'),
            const SizedBox(height: AppSpacing.xs),

            // Scanner Settings
            _buildCategoryCard(
              context,
              icon: Icons.folder_special_rounded,
              iconColor: Colors.lightGreenAccent,
              title: 'Scanner Settings',
              subtitle: 'Included folders, skip rules, tag encoding, database',
              onTap: () => context.push(AppRoutes.scannerSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Album Art Settings
            _buildCategoryCard(
              context,
              icon: Icons.image_rounded,
              iconColor: Colors.pinkAccent,
              title: 'Album Art',
              subtitle: 'Online cover download, quality, priority, cache wipe',
              onTap: () => context.push(AppRoutes.albumArtSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Lyrics & Metadata Settings
            _buildCategoryCard(
              context,
              icon: Icons.lyrics_rounded,
              iconColor: Colors.cyanAccent,
              title: 'Lyrics & Metadata',
              subtitle: 'LRCLIB auto-fetch, karaoke font size, tag writeback',
              onTap: () => context.push(AppRoutes.metadataSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Power Saving Settings
            _buildCategoryCard(
              context,
              icon: Icons.battery_charging_full_rounded,
              iconColor: Colors.greenAccent,
              title: 'Power Saving',
              subtitle: 'Battery saving threshold, animations reduction, wake locks',
              onTap: () => context.push(AppRoutes.powerSavingSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Notifications & Widgets
            _buildCategoryCard(
              context,
              icon: Icons.notifications_active_rounded,
              iconColor: Colors.indigoAccent,
              title: 'Notifications & Widgets',
              subtitle: 'Media notification layout, Android Auto, Wear OS',
              onTap: () => context.push(AppRoutes.notificationSettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Privacy & Storage Backup
            _buildCategoryCard(
              context,
              icon: Icons.shield_rounded,
              iconColor: Colors.orangeAccent,
              title: 'Privacy & Storage',
              subtitle: 'JSON settings export/import, search history purge',
              onTap: () => context.push(AppRoutes.privacySettings),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Design System Showcase Tile
            _buildCategoryCard(
              context,
              icon: Icons.auto_awesome_rounded,
              iconColor: Colors.purpleAccent,
              title: 'Design System Showcase',
              subtitle: 'Live tactile interactive widget lab',
              onTap: () => context.push(AppRoutes.designSystem),
            ),
            const SizedBox(height: AppSpacing.sm),

            // About NEXA Player Tile
            _buildCategoryCard(
              context,
              icon: Icons.info_outline_rounded,
              iconColor: Colors.lightBlueAccent,
              title: 'About NEXA',
              subtitle: 'v1.0.0 Obsidian, changelog, legal licenses, credits',
              onTap: () => context.push(AppRoutes.aboutSettings),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showLanguagePicker(
    BuildContext context,
    AppLocalePreference current,
  ) async {
    final l10n = context.l10n;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<AppLocalePreference>(
              value: AppLocalePreference.system,
              groupValue: current,
              title: Text(l10n.languageSystemDefault),
              onChanged: (val) {
                if (val != null) {
                  ref.read(localeControllerProvider.notifier).setLocalePreference(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
            RadioListTile<AppLocalePreference>(
              value: AppLocalePreference.en,
              groupValue: current,
              title: Text(l10n.languageEnglish),
              onChanged: (val) {
                if (val != null) {
                  ref.read(localeControllerProvider.notifier).setLocalePreference(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
            RadioListTile<AppLocalePreference>(
              value: AppLocalePreference.fa,
              groupValue: current,
              title: Text(l10n.languagePersian),
              onChanged: (val) {
                if (val != null) {
                  ref.read(localeControllerProvider.notifier).setLocalePreference(val);
                  Navigator.of(ctx).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0, top: 4.0),
      child: Text(
        title,
        style: AppTypography.labelSmall.copyWith(
          color: colorScheme.primary.withOpacity(0.85),
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NexaSurface(
      tier: NexaSurfaceTier.l1,
      padding: const EdgeInsets.all(AppSpacing.md),
      borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.18),
              borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(GlassTokens.radiusSmall),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 9,
                            color: iconColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
        ],
      ),
    );
  }
}
