import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../core/theme/theme_preset.dart';
import '../../../../core/theme/theme_state.dart';
import '../widgets/theme_preset_card.dart';
import 'custom_theme_editor_screen.dart';

/// Semantic Keys matching test/e2e/e2e_test_helpers.dart E2EKeys.
abstract final class _Keys {
  static const Key themePickerGrid = ValueKey('theme_picker_grid');
  static const Key themeCardMidnight = ValueKey('theme_card_midnight_black');
  static const Key themeCardDeepSpace = ValueKey('theme_card_deep_space');
  static const Key themeCardSakura = ValueKey('theme_card_sakura');
  static const Key themeCardOceanBlue = ValueKey('theme_card_ocean_blue');
  static const Key themeCardForestGreen = ValueKey('theme_card_forest_green');
  static const Key themeCardLava = ValueKey('theme_card_lava');
  static const Key themeCardDaylight = ValueKey('theme_card_daylight');
  static const Key themeCardNeonPurple = ValueKey('theme_card_neon_purple');
  static const Key themeCardCustom = ValueKey('theme_card_custom');

  static const Key themeModeDark = ValueKey('theme_mode_dark');
  static const Key themeModeLight = ValueKey('theme_mode_light');
  static const Key themeModeSystem = ValueKey('theme_mode_system');
}

/// Screen allowing the user to select from 8 presets, toggle brightness, or launch custom HSL editor.
class ThemePickerScreen extends ConsumerWidget {
  const ThemePickerScreen({super.key});

  static const String routePath = '/settings/theme';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Theme & Appearance'),
      ),
      body: _buildContent(context, ref, themeState),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    ThemeState themeState,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildModeSelector(context, ref, themeState),
        const SizedBox(height: 24),
        _buildPresetSection(context, ref, themeState),
      ],
    );
  }

  Widget _buildModeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeState themeState,
  ) {
    final activeMode = themeState.themeMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brightness Mode',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildModeButton(
                key: _Keys.themeModeDark,
                label: 'Dark',
                icon: Icons.dark_mode,
                isSelected: activeMode == ThemeMode.dark,
                primaryColor: primaryColor,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeButton(
                key: _Keys.themeModeLight,
                label: 'Light',
                icon: Icons.light_mode,
                isSelected: activeMode == ThemeMode.light,
                primaryColor: primaryColor,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildModeButton(
                key: _Keys.themeModeSystem,
                label: 'System',
                icon: Icons.brightness_auto,
                isSelected: activeMode == ThemeMode.system,
                primaryColor: primaryColor,
                onTap: () => ref
                    .read(themeControllerProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required Key key,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      key: key,
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        backgroundColor: isSelected ? primaryColor : null,
        foregroundColor: isSelected ? Colors.white : null,
      ),
    );
  }

  Widget _buildPresetSection(
    BuildContext context,
    WidgetRef ref,
    ThemeState themeState,
  ) {
    final activePreset = themeState.preset;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preset Palettes',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width > AppConstants.tabletBreakpoint
                ? 4
                : (width > AppConstants.phoneBreakpoint ? 3 : 2);

            return GridView(
              key: _Keys.themePickerGrid,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              children: [
                // 1. Midnight Black
                ThemePresetCard(
                  key: _Keys.themeCardMidnight,
                  title: 'Midnight Black',
                  primaryColor: const Color(0xFF00E5FF),
                  surfaceColor: const Color(0xFF121212),
                  backgroundColor: const Color(0xFF000000),
                  isSelected: activePreset == ThemePreset.midnightBlack,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.midnightBlack),
                ),
                // 2. Deep Space
                ThemePresetCard(
                  key: _Keys.themeCardDeepSpace,
                  title: 'Deep Space',
                  primaryColor: const Color(0xFF6366F1),
                  surfaceColor: const Color(0xFF131B2E),
                  backgroundColor: const Color(0xFF0B0F19),
                  isSelected: activePreset == ThemePreset.deepSpace,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.deepSpace),
                ),
                // 3. Sakura
                ThemePresetCard(
                  key: _Keys.themeCardSakura,
                  title: 'Sakura',
                  primaryColor: const Color(0xFFE91E63),
                  surfaceColor: const Color(0xFF2D121C),
                  backgroundColor: const Color(0xFF1F0B12),
                  isSelected: activePreset == ThemePreset.sakura,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.sakura),
                ),
                // 4. Ocean Blue
                ThemePresetCard(
                  key: _Keys.themeCardOceanBlue,
                  title: 'Ocean Blue',
                  primaryColor: const Color(0xFF00B4D8),
                  surfaceColor: const Color(0xFF1E3E62),
                  backgroundColor: const Color(0xFF0B192C),
                  isSelected: activePreset == ThemePreset.oceanBlue,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.oceanBlue),
                ),
                // 5. Forest Green
                ThemePresetCard(
                  key: _Keys.themeCardForestGreen,
                  title: 'Forest Green',
                  primaryColor: const Color(0xFF00E676),
                  surfaceColor: const Color(0xFF14291A),
                  backgroundColor: const Color(0xFF0B170E),
                  isSelected: activePreset == ThemePreset.forestGreen,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.forestGreen),
                ),
                // 6. Lava
                ThemePresetCard(
                  key: _Keys.themeCardLava,
                  title: 'Lava',
                  primaryColor: const Color(0xFFFF3D00),
                  surfaceColor: const Color(0xFF29100C),
                  backgroundColor: const Color(0xFF150806),
                  isSelected: activePreset == ThemePreset.lava,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.lava),
                ),
                // 7. Daylight
                ThemePresetCard(
                  key: _Keys.themeCardDaylight,
                  title: 'Daylight',
                  primaryColor: const Color(0xFF2563EB),
                  surfaceColor: const Color(0xFFFFFFFF),
                  backgroundColor: const Color(0xFFF8FAFC),
                  isSelected: activePreset == ThemePreset.daylight,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.daylight),
                ),
                // 8. Neon Purple
                ThemePresetCard(
                  key: _Keys.themeCardNeonPurple,
                  title: 'Neon Purple',
                  primaryColor: const Color(0xFFD946EF),
                  surfaceColor: const Color(0xFF1D1133),
                  backgroundColor: const Color(0xFF0F071A),
                  isSelected: activePreset == ThemePreset.neonPurple,
                  onTap: () => ref
                      .read(themeControllerProvider.notifier)
                      .setPreset(ThemePreset.neonPurple),
                ),
                // 9. Custom Theme Card
                ThemePresetCard(
                  key: _Keys.themeCardCustom,
                  title: 'Custom HSL',
                  subtitle: 'Personalize palette',
                  primaryColor: themeState.customTheme?.primaryColor ??
                      const Color(0xFF00E5FF),
                  surfaceColor: themeState.customTheme?.surfaceColor ??
                      const Color(0xFF1E293B),
                  backgroundColor:
                      themeState.customTheme?.scaffoldBackgroundColor ??
                          const Color(0xFF0F172A),
                  isSelected: activePreset == ThemePreset.custom,
                  trailingIcon: const Icon(Icons.tune, size: 18),
                  onTap: () {
                    ref
                        .read(themeControllerProvider.notifier)
                        .setPreset(ThemePreset.custom);
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const CustomThemeEditorScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
