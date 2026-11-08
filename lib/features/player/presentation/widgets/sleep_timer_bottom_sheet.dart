import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/design_system/app_typography.dart';
import '../providers/player_providers.dart';

/// Modal bottom sheet for configuring sleep countdown timer with smooth audio fade out.
class SleepTimerBottomSheet extends ConsumerWidget {
  const SleepTimerBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const SleepTimerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final primary = colorScheme.primary;

    final timerService = ref.watch(sleepTimerServiceProvider);
    final remainingAsync = ref.watch(sleepTimerRemainingProvider);
    final remaining = remainingAsync.valueOrNull ?? timerService.remainingTime;
    final isActive = timerService.isActive;

    final options = [
      {'label': '15 Minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 Minutes', 'duration': const Duration(minutes: 30)},
      {'label': '45 Minutes', 'duration': const Duration(minutes: 45)},
      {'label': '60 Minutes', 'duration': const Duration(minutes: 60)},
    ];

    String formatRemaining(Duration dur) {
      final minutes = dur.inMinutes;
      final seconds = dur.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141923) : theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
        border: Border.all(
          color: isDark ? const Color(0x20FFFFFF) : const Color(0x10000000),
          width: 1.0,
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bedtime_rounded, color: primary, size: 24.0),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Sleep Timer',
                      style: AppTypography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (isActive && remaining != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      formatRemaining(remaining),
                      style: AppTypography.labelMedium.copyWith(
                        color: primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16.0),

            ...options.map((opt) {
              final dur = opt['duration'] as Duration;
              final label = opt['label'] as String;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  tileColor: isDark ? const Color(0xFF1A202C) : const Color(0xFFF1F5F9),
                  leading: const Icon(Icons.timer_outlined),
                  title: Text(label, style: AppTypography.bodyMedium),
                  onTap: () {
                    ref.read(playerNotifierProvider.notifier).startSleepTimer(dur);
                    Navigator.of(context).pop();
                  },
                ),
              );
            }),

            if (isActive) ...[
              const SizedBox(height: 8.0),
              OutlinedButton.icon(
                icon: const Icon(Icons.stop_circle_outlined, color: Colors.redAccent),
                label: const Text('Cancel Active Timer', style: TextStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                onPressed: () {
                  ref.read(playerNotifierProvider.notifier).cancelSleepTimer();
                  Navigator.of(context).pop();
                },
              ),
            ],
            const SizedBox(height: 8.0),
          ],
        ),
      ),
    ),
  );
  }
}
