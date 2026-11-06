import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/routes.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_card.dart';

/// Semantic Keys matching E2EKeys.
abstract final class _SettingsKeys {
  static const Key themeSettingsTile = ValueKey('theme_settings_tile');
}

/// Central settings hub for NEXA Player.
class SettingsHubScreen extends ConsumerWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'Settings',
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          // 1. Theme & Appearance (Hero Tile)
          GlassCard(
            key: _SettingsKeys.themeSettingsTile,
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
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
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
                        'Theme & Appearance',
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
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Design System Showcase Tile
          GlassCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
            onTap: () => context.push(AppRoutes.designSystem),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.purpleAccent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Design System Showcase',
                        style: AppTypography.titleLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Live glassmorphism interactive widget lab',
                        style: AppTypography.bodySmall.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Audio & Playback Engine Tile
          _buildCategoryCard(
            context,
            icon: Icons.equalizer_rounded,
            iconColor: Colors.tealAccent,
            title: 'Equalizer & DSP Engine',
            subtitle: '12-Band Parametric EQ, Z-Bass, Reverb, Compressor',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.sm),

          // 4. Audio Playback Settings
          _buildCategoryCard(
            context,
            icon: Icons.volume_up_rounded,
            iconColor: Colors.amberAccent,
            title: 'Audio Settings',
            subtitle: 'Gapless playback, Crossfade, Output buffer',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.sm),

          // 5. Media Scanner Settings
          _buildCategoryCard(
            context,
            icon: Icons.folder_special_rounded,
            iconColor: Colors.lightGreenAccent,
            title: 'Scanner Settings',
            subtitle: 'Included folders, skip rules, tag encoding',
            onTap: () {},
          ),
          const SizedBox(height: AppSpacing.sm),

          // 6. Album Art Settings
          _buildCategoryCard(
            context,
            icon: Icons.image_rounded,
            iconColor: Colors.pinkAccent,
            title: 'Album Art & Lyrics',
            subtitle: 'Embedded priority, download quality, sync LRC',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
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
                Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
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
