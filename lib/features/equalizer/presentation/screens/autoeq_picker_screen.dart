import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/glass_app_bar.dart';
import '../../../../shared/widgets/glass/glass_text_field.dart';
import '../../../../shared/widgets/surfaces/nexa_surface.dart';
import '../../data/datasources/autoeq_database.dart';
import '../../domain/models/headphone_autoeq_profile.dart';
import '../providers/equalizer_providers.dart';

/// Semantic Keys for AutoEqPickerScreen testing.
abstract final class AutoEqPickerKeys {
  static const Key searchInput = ValueKey('autoeq_search_input');
  static const Key resetFlatButton = ValueKey('autoeq_reset_flat');
}

/// Borderless studio picker screen for AutoEQ calibrated headphone compensation profiles.
class AutoEqPickerScreen extends ConsumerStatefulWidget {
  const AutoEqPickerScreen({super.key});

  @override
  ConsumerState<AutoEqPickerScreen> createState() => _AutoEqPickerScreenState();
}

class _AutoEqPickerScreenState extends ConsumerState<AutoEqPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyProfile(HeadphoneAutoEqProfile profile) {
    ref.read(selectedAutoEqProfileProvider.notifier).state = profile;
    final eqNotifier = ref.read(equalizerNotifierProvider.notifier);

    // Apply 10 calibrated frequency band gains
    for (int i = 0; i < profile.bandOffsets.length; i++) {
      eqNotifier.setBandGain(i, profile.bandOffsets[i]);
    }
    eqNotifier.setPreamp(profile.preampDb);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied AutoEQ target for ${profile.displayName}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetToFlat() {
    ref.read(selectedAutoEqProfileProvider.notifier).state = null;
    ref.read(equalizerNotifierProvider.notifier).resetToFlat();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Equalizer reset to Flat'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(autoEqDatabaseProvider);
    final activeProfile = ref.watch(selectedAutoEqProfileProvider);
    final results = db.search(_searchQuery);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primary = colorScheme.primary;
    final surfaceTokens = theme.extension<NexaSurfaceTokens>();

    final telemetryStyle = surfaceTokens?.telemetryTextStyle ??
        const TextStyle(
          fontFamily: 'monospace',
          fontFeatures: [FontFeature.tabularFigures()],
        );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Headphone AutoEQ',
        actions: [
          TextButton.icon(
            key: AutoEqPickerKeys.resetFlatButton,
            icon: const Icon(Icons.restart_alt_rounded, size: 16),
            label: const Text('Flat'),
            style: TextButton.styleFrom(foregroundColor: primary),
            onPressed: _resetToFlat,
          ),
        ],
      ),
      body: ListView(
        padding: nexaScrollPadding(context, horizontal: 16.0, top: 100.0),
        children: [
          // Search input
          GlassTextField(
            key: AutoEqPickerKeys.searchInput,
            controller: _searchController,
            hintText: 'Search Sennheiser, Sony, Apple, Beyerdynamic...',
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            onChanged: (val) {
              setState(() => _searchQuery = val);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Header count
          Text(
            '${results.length} CALIBRATION PROFILES',
            style: AppTypography.labelSmall.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Results list
          if (results.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Text(
                  'No profiles found for "$_searchQuery"',
                  style: AppTypography.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.5),
                  ),
                ),
              ),
            )
          else
            ...results.map((profile) {
              final isSelected = activeProfile?.id == profile.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: NexaSurface(
                  tier: isSelected ? NexaSurfaceTier.l2 : NexaSurfaceTier.l1,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  borderRadius: BorderRadius.circular(GlassTokens.radiusCard),
                  onTap: () => _applyProfile(profile),
                  child: Row(
                    children: [
                      // Icon by form factor
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withOpacity(0.24)
                              : colorScheme.onSurface.withOpacity(0.06),
                          borderRadius:
                              BorderRadius.circular(GlassTokens.radiusSmall),
                        ),
                        child: Icon(
                          profile.formFactor == 'in_ear'
                              ? Icons.headphones_rounded
                              : Icons.headset_rounded,
                          color: isSelected ? primary : colorScheme.onSurface.withOpacity(0.7),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Metadata
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    profile.displayName,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? primary : null,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? primary.withOpacity(0.18)
                                        : colorScheme.onSurface.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(
                                      GlassTokens.radiusSmall,
                                    ),
                                  ),
                                  child: Text(
                                    profile.targetCurve.toUpperCase(),
                                    style: telemetryStyle.copyWith(
                                      fontSize: 9,
                                      color: isSelected
                                          ? primary
                                          : colorScheme.onSurface.withOpacity(0.6),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Preamp ${profile.preampDb.toStringAsFixed(1)} dB • 10-Band Harman Target',
                              style: AppTypography.bodySmall.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.55),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (isSelected) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.check_circle_rounded,
                          color: primary,
                          size: 22,
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
