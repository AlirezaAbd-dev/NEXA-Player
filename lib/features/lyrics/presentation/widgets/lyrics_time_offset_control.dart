import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/features/lyrics/presentation/providers/lyrics_providers.dart';

/// Floating glassmorphism toolbar for adjusting real-time lyrics synchronization offset.
class LyricsTimeOffsetControl extends ConsumerWidget {
  const LyricsTimeOffsetControl({
    super.key,
    required this.onClose,
  });

  final VoidCallback onClose;

  String _formatOffset(int offsetMs) {
    if (offsetMs == 0) return '0 ms';
    final sign = offsetMs > 0 ? '+' : '';
    return '$sign$offsetMs ms (${(offsetMs / 1000).toStringAsFixed(2)}s)';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offsetMs = ref.watch(lyricsOffsetNotifierProvider);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF121722).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: accent),
                  const SizedBox(width: 8),
                  Text(
                    'Sync Offset: ${_formatOffset(offsetMs)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.white70),
                onPressed: onClose,
                tooltip: 'Close Offset Controls',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _OffsetButton(
                label: '-0.5s',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(lyricsOffsetNotifierProvider.notifier).adjust(-500);
                },
              ),
              _OffsetButton(
                label: '-0.1s',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(lyricsOffsetNotifierProvider.notifier).adjust(-100);
                },
              ),
              _OffsetButton(
                label: 'Reset',
                isReset: true,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(lyricsOffsetNotifierProvider.notifier).setOffset(0);
                },
              ),
              _OffsetButton(
                label: '+0.1s',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(lyricsOffsetNotifierProvider.notifier).adjust(100);
                },
              ),
              _OffsetButton(
                label: '+0.5s',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(lyricsOffsetNotifierProvider.notifier).adjust(500);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton.icon(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                await ref
                    .read(lyricsOffsetNotifierProvider.notifier)
                    .saveOffsetForCurrentTrack();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Lyrics offset (${_formatOffset(offsetMs)}) saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                onClose();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save Offset', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OffsetButton extends StatelessWidget {
  const _OffsetButton({
    required this.label,
    required this.onPressed,
    this.isReset = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isReset;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isReset
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.14),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isReset ? Colors.white70 : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
