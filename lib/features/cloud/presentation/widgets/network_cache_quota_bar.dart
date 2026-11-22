import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/glass_tokens.dart';
import '../../../../shared/widgets/glass/glass_card.dart';
import '../providers/cloud_settings_providers.dart';
import '../providers/network_servers_providers.dart';

/// Interactive gauge displaying offline streaming cache usage and quota controls.
class NetworkCacheQuotaBar extends ConsumerWidget {
  const NetworkCacheQuotaBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(cloudSettingsProvider);
    final cacheBytesAsync = ref.watch(networkCacheSizeBytesProvider);
    final cacheBytes = cacheBytesAsync.valueOrNull ?? 0;

    final usedMb = cacheBytes / (1024 * 1024);
    final maxMb = settings.maxCacheMb;
    final fraction = (usedMb / maxMb).clamp(0.0, 1.0);

    return GlassCard(
      borderRadius: BorderRadius.circular(GlassTokens.radiusMd),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.storage_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Streaming Disk Cache',
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                '${usedMb.toStringAsFixed(1)} MB / $maxMb MB',
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Progress gauge
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              key: const ValueKey('cache_quota_progress_bar'),
              value: fraction,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(
                fraction > 0.85 ? Colors.amberAccent : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Quota choices & Clear Cache button
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [512, 1024, 2048].map((mb) {
                    final isSelected = settings.maxCacheMb == mb;
                    return InkWell(
                      key: ValueKey('cache_quota_chip_$mb'),
                      onTap: () {
                        ref.read(cloudSettingsProvider.notifier).setMaxCacheMb(mb);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withOpacity(0.2)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Text(
                          mb >= 1024 ? '${mb ~/ 1024} GB' : '$mb MB',
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? colorScheme.primary : Colors.white70,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              TextButton.icon(
                key: const ValueKey('clear_cloud_cache_button'),
                onPressed: () async {
                  final manager = ref.read(networkCacheManagerProvider);
                  await manager.clearAllCache();
                  ref.invalidate(networkCacheSizeBytesProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Streaming cache cleared successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                label: Text(
                  'Purge Cache',
                  style: AppTypography.labelSmall.copyWith(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
