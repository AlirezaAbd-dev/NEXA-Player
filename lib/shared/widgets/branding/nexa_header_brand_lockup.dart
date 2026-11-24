import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/routes.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../features/player/presentation/providers/player_providers.dart';
import 'nexa_animated_logo.dart';

/// Compact borderless brand lockup displayed in the primary mobile Library header.
///
/// Surfaces [NexaAnimatedLogo] alongside `"NEXA"` and the section title while
/// maintaining a >= 48dp touch target, zero vertical bloat, and battery-safe
/// playback-coupled shimmer (paused when audio is paused or Reduced Motion is on).
class NexaHeaderBrandLockup extends ConsumerWidget {
  const NexaHeaderBrandLockup({
    super.key,
    required this.sectionTitle,
  });

  final String sectionTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playerState = ref.watch(playerNotifierProvider);
    final isPlaying = playerState.isPlaying;
    final hasActiveTrack = playerState.currentTrack != null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          label: hasActiveTrack ? 'Open Now Playing' : 'About NEXA Player',
          child: InkWell(
            key: const ValueKey('nexa_header_brand_lockup'),
            borderRadius: BorderRadius.circular(14.0),
            onTap: () {
              HapticFeedback.selectionClick();
              final router = GoRouter.maybeOf(context);
              if (router == null) return;
              router.push(
                hasActiveTrack ? AppRoutes.player : AppRoutes.aboutSettings,
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48.0, minWidth: 48.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NexaAnimatedLogo(
                      size: 28.0,
                      mode: NexaLogoAnimationMode.playing,
                      isPlaying: isPlaying,
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      'NEXA',
                      style: AppTypography.labelSmall.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6.0),
        Flexible(
          child: Text(
            sectionTitle,
            style: AppTypography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
