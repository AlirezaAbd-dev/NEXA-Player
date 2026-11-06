import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/theme_preset.dart';
import '../../../../shared/widgets/cards/album_card.dart';
import '../../../../shared/widgets/cards/artist_card.dart';
import '../../../../shared/widgets/cards/genre_card.dart';
import '../../../../shared/widgets/cards/track_tile.dart';
import '../../../../shared/widgets/feedback/app_bottom_sheet.dart';
import '../../../../shared/widgets/feedback/app_dialog.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/glass/glass_button.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../../../../shared/widgets/glass/glass_chip.dart';
import '../../../../shared/widgets/glass/glass_fab.dart';
import '../../../../shared/widgets/glass/glass_text_field.dart';

/// Semantic keys matching test/e2e/e2e_test_helpers.dart E2EKeys.
abstract final class _ShowcaseKeys {
  static const Key root = ValueKey('design_system_showcase_screen');

  // Theme Modes
  static const Key themeModeDark = ValueKey('theme_mode_dark');
  static const Key themeModeLight = ValueKey('theme_mode_light');
  static const Key themeModeSystem = ValueKey('theme_mode_system');

  // Preset Cards
  static const Key themeCardMidnight = ValueKey('theme_card_midnight_black');
  static const Key themeCardDeepSpace = ValueKey('theme_card_deep_space');
  static const Key themeCardSakura = ValueKey('theme_card_sakura');
  static const Key themeCardOceanBlue = ValueKey('theme_card_ocean_blue');
  static const Key themeCardForestGreen = ValueKey('theme_card_forest_green');
  static const Key themeCardLava = ValueKey('theme_card_lava');
  static const Key themeCardDaylight = ValueKey('theme_card_daylight');
  static const Key themeCardNeonPurple = ValueKey('theme_card_neon_purple');

  // Feedback Triggers
  static const Key snackbarInfoBtn = ValueKey('show_snackbar_info');
  static const Key snackbarSuccessBtn = ValueKey('show_snackbar_success');
  static const Key snackbarWarningBtn = ValueKey('show_snackbar_warning');
  static const Key snackbarErrorBtn = ValueKey('show_snackbar_error');
  static const Key dialogBtn = ValueKey('show_dialog_btn');
  static const Key bottomSheetBtn = ValueKey('show_bottom_sheet_btn');

  // Components
  static const Key glassCard = ValueKey('glass_card');
  static const Key trackTile = ValueKey('track_tile');
  static const Key albumCard = ValueKey('album_card');
  static const Key artistCard = ValueKey('artist_card');
}

/// Comprehensive Design System Showcase Screen for NEXA Player.
///
/// Features:
/// - Accessible via route `/design-system`
/// - Visualizes every design system token (Spacing, Typography, Glass, Colors)
/// - Interactive Theme Switcher preview (8 presets + 3 brightness modes)
/// - Interactive Base Glass Controls (GlassCard, GlassButton, GlassTextField, GlassChip, GlassFAB)
/// - Domain Music Cards (TrackTile, AlbumCard, ArtistCard, GenreCard)
/// - Interactive Feedback Overlays (AppSnackbar, AppDialog, AppBottomSheet)
/// - Fully responsive across Phone Portrait (<600dp), Tablet (600–840dp), and Desktop (>840dp)
/// - Zero render overflow guarantee across all viewports
class DesignSystemShowcaseScreen extends ConsumerWidget {
  const DesignSystemShowcaseScreen({super.key});

  static const String routePath = AppConstants.designSystemRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);

    return Scaffold(
      key: _ShowcaseKeys.root,
      appBar: AppBar(
        title: const Text('Design System Showcase'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: _buildBreakpointBadge(context),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isCompact = width < AppConstants.phoneBreakpoint;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? AppSpacing.md : AppSpacing.xl,
                  vertical: AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSectionHeader(
                      context,
                      '1. Theme Engine & Mode Switcher',
                      'Live Material 3 presets and triple-state brightness mode',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildThemeSection(context, ref, themeState),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionHeader(
                      context,
                      '2. Spacing Scale Tokens',
                      '8-step numerical scale with zero magic numbers',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildSpacingTokensSection(context),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionHeader(
                      context,
                      '3. Typography Hierarchy',
                      'Material 3 typography hierarchy styled for NEXA Player',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildTypographySection(context),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionHeader(
                      context,
                      '4. Glassmorphism Design Tokens',
                      'Backdrop blur, surface fill opacity, borders, and shadows',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildGlassTokensSection(context),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionHeader(
                      context,
                      '5. Base Glass Controls',
                      'Interactive buttons, chips, text inputs, cards, and FAB',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildGlassControlsSection(context),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionHeader(
                      context,
                      '6. Domain Music Cards',
                      'Reusable music list items, album grid cards, and artist avatars',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildDomainCardsSection(context, width),
                    const SizedBox(height: AppSpacing.xxl),

                    _buildSectionHeader(
                      context,
                      '7. Frosted Feedback Overlays',
                      'Floating frosted snackbar, modal dialog, and bottom sheet',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildFeedbackOverlaysSection(context),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBreakpointBadge(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final (String label, Color color) = width < AppConstants.phoneBreakpoint
        ? ('PHONE (<600dp)', Colors.orange)
        : (width <= AppConstants.tabletBreakpoint
            ? ('TABLET (600–840dp)', Colors.cyan)
            : ('DESKTOP (>840dp)', Colors.green));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(GlassTokens.radiusPill),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          subtitle,
          style: AppTypography.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    dynamic themeState,
  ) {
    final activePreset = themeState.preset as ThemePreset;
    final activeMode = themeState.themeMode as ThemeMode;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Brightness Mode:',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  alignment: WrapAlignment.end,
                  children: [
                    ChoiceChip(
                      key: _ShowcaseKeys.themeModeDark,
                      label: const Text('Dark'),
                      selected: activeMode == ThemeMode.dark,
                      onSelected: (_) => ref
                          .read(themeControllerProvider.notifier)
                          .setThemeMode(ThemeMode.dark),
                    ),
                    ChoiceChip(
                      key: _ShowcaseKeys.themeModeLight,
                      label: const Text('Light'),
                      selected: activeMode == ThemeMode.light,
                      onSelected: (_) => ref
                          .read(themeControllerProvider.notifier)
                          .setThemeMode(ThemeMode.light),
                    ),
                    ChoiceChip(
                      key: _ShowcaseKeys.themeModeSystem,
                      label: const Text('System'),
                      selected: activeMode == ThemeMode.system,
                      onSelected: (_) => ref
                          .read(themeControllerProvider.notifier)
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Preset Palettes:',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardMidnight,
                label: 'Midnight Black',
                preset: ThemePreset.midnightBlack,
                isSelected: activePreset == ThemePreset.midnightBlack,
                accentColor: const Color(0xFF00E5FF),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardDeepSpace,
                label: 'Deep Space',
                preset: ThemePreset.deepSpace,
                isSelected: activePreset == ThemePreset.deepSpace,
                accentColor: const Color(0xFF6366F1),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardSakura,
                label: 'Sakura',
                preset: ThemePreset.sakura,
                isSelected: activePreset == ThemePreset.sakura,
                accentColor: const Color(0xFFE91E63),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardOceanBlue,
                label: 'Ocean Blue',
                preset: ThemePreset.oceanBlue,
                isSelected: activePreset == ThemePreset.oceanBlue,
                accentColor: const Color(0xFF00B4D8),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardForestGreen,
                label: 'Forest Green',
                preset: ThemePreset.forestGreen,
                isSelected: activePreset == ThemePreset.forestGreen,
                accentColor: const Color(0xFF00E676),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardLava,
                label: 'Lava',
                preset: ThemePreset.lava,
                isSelected: activePreset == ThemePreset.lava,
                accentColor: const Color(0xFFFF3D00),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardDaylight,
                label: 'Daylight',
                preset: ThemePreset.daylight,
                isSelected: activePreset == ThemePreset.daylight,
                accentColor: const Color(0xFF2563EB),
              ),
              _presetChip(
                ref: ref,
                key: _ShowcaseKeys.themeCardNeonPurple,
                label: 'Neon Purple',
                preset: ThemePreset.neonPurple,
                isSelected: activePreset == ThemePreset.neonPurple,
                accentColor: const Color(0xFFD946EF),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _presetChip({
    required WidgetRef ref,
    required Key key,
    required String label,
    required ThemePreset preset,
    required bool isSelected,
    required Color accentColor,
  }) {
    return ChoiceChip(
      key: key,
      avatar: CircleAvatar(
        backgroundColor: accentColor,
        radius: 6,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: accentColor.withOpacity(0.25),
      onSelected: (_) =>
          ref.read(themeControllerProvider.notifier).setPreset(preset),
    );
  }

  Widget _buildSpacingTokensSection(BuildContext context) {
    const steps = [
      ('xxxs (2dp)', AppSpacing.xxxs),
      ('xxs (4dp)', AppSpacing.xxs),
      ('xs (8dp)', AppSpacing.xs),
      ('sm (12dp)', AppSpacing.sm),
      ('md (16dp)', AppSpacing.md),
      ('lg (24dp)', AppSpacing.lg),
      ('xl (32dp)', AppSpacing.xl),
      ('xxl (48dp)', AppSpacing.xxl),
      ('xxxl (64dp)', AppSpacing.xxxl),
    ];

    final primary = Theme.of(context).colorScheme.primary;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: steps.map((s) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                SizedBox(
                  width: 90,
                  child: Text(s.$1, style: AppTypography.bodySmall),
                ),
                Container(
                  width: s.$2 * 2.0,
                  height: 14,
                  decoration: BoxDecoration(
                    color: primary.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('${s.$2} dp', style: AppTypography.labelSmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTypographySection(BuildContext context) {
    final styles = [
      ('displayLarge (32pt w800)', AppTypography.displayLarge),
      ('displayMedium (26pt w700)', AppTypography.displayMedium),
      ('headlineMedium (20pt w700)', AppTypography.headlineMedium),
      ('titleLarge (17pt w600)', AppTypography.titleLarge),
      ('titleMedium (15pt w600)', AppTypography.titleMedium),
      ('bodyMedium (14pt w400)', AppTypography.bodyMedium),
      ('bodySmall (12pt w400)', AppTypography.bodySmall),
      ('labelMedium (12pt w600)', AppTypography.labelMedium),
      ('labelSmall (10pt w600)', AppTypography.labelSmall),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: styles.map((st) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  st.$1,
                  style: AppTypography.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text('The quick brown fox jumps over the lazy dog',
                    style: st.$2),
                const Divider(height: 12),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGlassTokensSection(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GlassCard(
                blur: GlassTokens.blurSubtle,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text('Blur Subtle (16dp)'),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassCard(
                key: _ShowcaseKeys.glassCard,
                blur: GlassTokens.blurStandard,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text('Blur Standard (20dp)'),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassCard(
                blur: GlassTokens.blurHeavy,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text('Blur Heavy (24dp)'),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: GlassCard(
                opacity: GlassTokens.opacitySubtle,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text('Opacity Subtle (0.10)'),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassCard(
                opacity: GlassTokens.opacityStandard,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text('Opacity Standard (0.15)'),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: GlassCard(
                opacity: GlassTokens.opacityElevated,
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(
                  child: Text('Opacity Elevated (0.20)'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassControlsSection(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Buttons (Filled, Outlined, Ghost):',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              GlassButton(
                label: 'Filled Button',
                variant: GlassButtonVariant.filled,
                icon: Icons.play_arrow_rounded,
                onPressed: () {},
              ),
              GlassButton(
                label: 'Outlined Button',
                variant: GlassButtonVariant.outlined,
                icon: Icons.favorite_border_rounded,
                onPressed: () {},
              ),
              GlassButton(
                label: 'Ghost Button',
                variant: GlassButtonVariant.ghost,
                onPressed: () {},
              ),
              const GlassButton(
                label: 'Disabled',
                variant: GlassButtonVariant.filled,
                onPressed: null,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Search Input Field:',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          const GlassTextField(
            hintText: 'Search tracks, albums, artists...',
            prefixIcon: Icons.search_rounded,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Filter Chips & FAB:',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    GlassChip(
                      label: 'All Tracks',
                      isSelected: true,
                      onSelected: (_) {},
                    ),
                    GlassChip(
                      label: 'Hi-Res Audio',
                      isSelected: false,
                      icon: Icons.graphic_eq_rounded,
                      onSelected: (_) {},
                    ),
                    GlassChip(
                      label: 'Favorites',
                      isSelected: false,
                      icon: Icons.star_rounded,
                      onSelected: (_) {},
                    ),
                  ],
                ),
              ),
              GlassFAB(
                icon: const Icon(Icons.shuffle_rounded),
                tooltip: 'Shuffle All',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDomainCardsSection(BuildContext context, double screenWidth) {
    return Column(
      children: [
        TrackTile(
          key: _ShowcaseKeys.trackTile,
          title: 'Midnight Stargazer',
          artist: 'NEXA Sound',
          album: 'Cosmic Drift',
          duration: const Duration(minutes: 3, seconds: 45),
          onTap: () {},
          onMorePressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = constraints.maxWidth;
            final isCompact = cardWidth < AppConstants.phoneBreakpoint;

            if (isCompact) {
              return Column(
                children: [
                  AlbumCard(
                    key: _ShowcaseKeys.albumCard,
                    title: 'Cosmic Drift',
                    artist: 'NEXA Sound',
                    year: 2026,
                    trackCount: 10,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ArtistCard(
                    key: _ShowcaseKeys.artistCard,
                    name: 'NEXA Sound',
                    trackCount: 24,
                    albumCount: 2,
                    onTap: () {},
                  ),
                  const SizedBox(height: AppSpacing.md),
                  GenreCard(
                    title: 'Synthwave',
                    trackCount: 142,
                    onTap: () {},
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AlbumCard(
                    key: _ShowcaseKeys.albumCard,
                    title: 'Cosmic Drift',
                    artist: 'NEXA Sound',
                    year: 2026,
                    trackCount: 10,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ArtistCard(
                    key: _ShowcaseKeys.artistCard,
                    name: 'NEXA Sound',
                    trackCount: 24,
                    albumCount: 2,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: GenreCard(
                    title: 'Synthwave',
                    trackCount: 142,
                    onTap: () {},
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFeedbackOverlaysSection(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Snackbars (Spring Entrance & Horizontal Dismiss):',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              GlassButton(
                key: _ShowcaseKeys.snackbarInfoBtn,
                label: 'Show Info',
                variant: GlassButtonVariant.outlined,
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Track added to playback queue',
                    variant: AppSnackbarVariant.info,
                    actionLabel: 'UNDO',
                    onAction: () {},
                  );
                },
              ),
              GlassButton(
                key: _ShowcaseKeys.snackbarSuccessBtn,
                label: 'Show Success',
                variant: GlassButtonVariant.outlined,
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Playlist saved successfully to storage',
                    variant: AppSnackbarVariant.success,
                  );
                },
              ),
              GlassButton(
                key: _ShowcaseKeys.snackbarWarningBtn,
                label: 'Show Warning',
                variant: GlassButtonVariant.outlined,
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Low disk space: unable to cache 3 album covers',
                    variant: AppSnackbarVariant.warning,
                  );
                },
              ),
              GlassButton(
                key: _ShowcaseKeys.snackbarErrorBtn,
                label: 'Show Error',
                variant: GlassButtonVariant.outlined,
                onPressed: () {
                  AppSnackbar.show(
                    context,
                    message: 'Playback failure: unsupported audio codec',
                    variant: AppSnackbarVariant.error,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Dialog & Bottom Sheet (Backdrop Blur & Spring Physics):',
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              GlassButton(
                key: _ShowcaseKeys.dialogBtn,
                label: 'Show Glass Dialog',
                icon: Icons.layers_rounded,
                variant: GlassButtonVariant.filled,
                onPressed: () {
                  AppDialog.show(
                    context: context,
                    title: 'Equalizer Preset',
                    message:
                        'Applying the "Bass Boost Extra" preset will reset current band gains. Do you want to proceed?',
                    primaryActionText: 'Apply',
                    secondaryActionText: 'Cancel',
                    icon: Icons.equalizer_rounded,
                  );
                },
              ),
              GlassButton(
                key: _ShowcaseKeys.bottomSheetBtn,
                label: 'Show Bottom Sheet',
                icon: Icons.vertical_align_top_rounded,
                variant: GlassButtonVariant.filled,
                onPressed: () {
                  AppBottomSheet.show(
                    context: context,
                    title: 'Track Options',
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.playlist_add_rounded),
                          title: const Text('Add to Playlist'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.share_rounded),
                          title: const Text('Share Song'),
                          onTap: () => Navigator.pop(context),
                        ),
                        ListTile(
                          leading: const Icon(Icons.info_outline_rounded),
                          title: const Text('View Audio Metadata'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
