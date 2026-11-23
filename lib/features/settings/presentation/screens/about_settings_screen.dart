import 'package:flutter/material.dart';
import 'package:nexa_player/core/design_system/app_spacing.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/core/design_system/glass_tokens.dart';
import 'package:nexa_player/shared/widgets/branding/nexa_animated_logo.dart';
import 'package:nexa_player/shared/widgets/feedback/app_dialog.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';
import 'package:nexa_player/shared/widgets/glass/glass_card.dart';
import '../widgets/settings_tiles.dart';

/// About screen showcasing app version, changelog, audiophile tech stack, and open source licenses.
class AboutSettingsScreen extends StatelessWidget {
  const AboutSettingsScreen({super.key});

  void _showChangelog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppDialog(
        title: 'Release Changelog',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version 1.0.0 — "Obsidian Edition"',
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              '• 10-Band Parametric Equalizer with Z-Bass and psychoacoustic harmonics.\n'
              '• Synchronized LRCLIB lyrics with karaoke line glow.\n'
              '• Direct Volume Control (DVC) 32-bit floating point audio engine.\n'
              '• Gapless audio playback and customizable crossfade transitions.\n'
              '• Neo-Modern Obsidian AMOLED glassmorphism design system.\n'
              '• Comprehensive settings hub with instant keyword search and JSON backup.',
              style: TextStyle(
                color: Colors.white70,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(
        titleText: 'About NEXA',
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 100.0, 16.0, 130.0),
        children: [
          // Branding Hero Card
          GlassCard(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.lg,
            ),
            borderRadius: BorderRadius.circular(GlassTokens.radiusMedium),
            child: Column(
              children: [
                const NexaAnimatedLogo(
                  size: 72,
                  mode: NexaLogoAnimationMode.playing,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'NEXA PLAYER',
                  style: AppTypography.headlineMedium.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'The Definitive Audiophile Music Experience',
                  style: AppTypography.bodySmall.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(GlassTokens.radiusSmall),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'v1.0.0 (Obsidian AMOLED Build 104)',
                    style: AppTypography.labelSmall.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Details & Links
          SettingsGroupCard(
            title: 'Information & Legal',
            children: [
              SettingsActionTile(
                title: 'Release Changelog',
                subtitle: 'View changes and new features in this release',
                icon: Icons.history_edu_rounded,
                iconColor: Colors.cyanAccent,
                onTap: () => _showChangelog(context),
              ),
              SettingsActionTile(
                title: 'Open Source Licenses',
                subtitle: 'Software libraries powering NEXA Player',
                icon: Icons.gavel_rounded,
                iconColor: Colors.amberAccent,
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: 'NEXA Player',
                    applicationVersion: '1.0.0 (Obsidian)',
                  );
                },
              ),
              SettingsActionTile(
                title: 'Audio Engine Specifications',
                subtitle: '32-bit Float, Pure Dart DSP, ReplayGain 2.0, LRCLIB API',
                icon: Icons.memory_rounded,
                iconColor: Colors.purpleAccent,
                onTap: () {},
              ),
              SettingsActionTile(
                title: 'Project Repository & GitHub',
                subtitle: 'github.com/nexa-player/nexa-audio',
                icon: Icons.code_rounded,
                iconColor: Colors.lightGreenAccent,
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
