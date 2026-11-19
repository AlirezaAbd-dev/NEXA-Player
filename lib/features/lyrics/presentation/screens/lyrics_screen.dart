import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/design_system/app_typography.dart';
import 'package:nexa_player/features/lyrics/presentation/providers/lyrics_providers.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/lyrics_editor_modal.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/lyrics_time_offset_control.dart';
import 'package:nexa_player/features/lyrics/presentation/widgets/synced_lyrics_view.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/widgets/glass/app_ambient_background.dart';
import 'package:nexa_player/shared/widgets/glass/glass_app_bar.dart';

/// Full-screen immersive karaoke-style lyrics viewer.
class LyricsScreen extends ConsumerStatefulWidget {
  const LyricsScreen({super.key});

  @override
  ConsumerState<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends ConsumerState<LyricsScreen> {
  bool _showOffsetControls = false;

  void _toggleOffsetControls() {
    HapticFeedback.selectionClick();
    setState(() {
      _showOffsetControls = !_showOffsetControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentTrack = ref.watch(currentTrackProvider);
    final lyricsAsync = ref.watch(currentTrackLyricsProvider);
    final activeIndex = ref.watch(activeLyricIndexProvider);
    final autoScroll = ref.watch(lyricsAutoScrollEnabledProvider);

    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    if (currentTrack == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF090C13),
        appBar: GlassAppBar(titleText: 'Lyrics'),
        body: Center(
          child: Text(
            'No track is currently playing.',
            style: AppTypography.bodyMedium,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        titleText: 'Lyrics',
        actions: [
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: _showOffsetControls ? accent : Colors.white70,
              size: 22,
            ),
            tooltip: 'Sync Offset',
            onPressed: _toggleOffsetControls,
          ),
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, size: 24, color: Colors.white70),
            tooltip: 'Edit Lyrics',
            onPressed: () {
              final lyrics = lyricsAsync.valueOrNull;
              LyricsEditorModal.show(
                context,
                track: currentTrack,
                currentLyrics: lyrics,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22, color: Colors.white70),
            tooltip: 'Re-fetch Online',
            onPressed: () {
              HapticFeedback.lightImpact();
              ref.invalidate(trackLyricsProvider(currentTrack));
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const AppAmbientBackground(),
          // Dark vignette layer to ensure high lyric contrast
          Container(color: Colors.black.withOpacity(0.55)),

          // Main Lyrics Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Track & Source Header Pill
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentTrack.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              currentTrack.artist,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white60,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      lyricsAsync.when(
                        data: (lyrics) {
                          if (lyrics == null) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: accent.withOpacity(0.3)),
                            ),
                            child: Text(
                              lyrics.source.displayName,
                              style: TextStyle(
                                color: accent,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Lyrics Viewer or Empty/Loading State
                Expanded(
                  child: lyricsAsync.when(
                    data: (lyrics) {
                      if (lyrics == null || (lyrics.lines.isEmpty && (lyrics.plainLyrics == null || lyrics.plainLyrics!.isEmpty))) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lyrics_outlined,
                                size: 56,
                                color: Colors.white.withOpacity(0.25),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No lyrics found for "${currentTrack.title}"',
                                style: AppTypography.bodyLarge.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () {
                                  LyricsEditorModal.show(
                                    context,
                                    track: currentTrack,
                                    currentLyrics: lyrics,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Add or Search Lyrics'),
                              ),
                            ],
                          ),
                        );
                      }

                      return SyncedLyricsView(
                        lyrics: lyrics,
                        activeIndex: activeIndex,
                        autoScrollEnabled: autoScroll,
                        onSeekToTimestamp: (timestamp) {
                          ref.read(playerNotifierProvider.notifier).seek(timestamp);
                        },
                      );
                    },
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (err, _) => Center(
                      child: Text(
                        'Failed to load lyrics: $err',
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating Time Offset Control
          if (_showOffsetControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24,
              child: LyricsTimeOffsetControl(
                onClose: () => setState(() => _showOffsetControls = false),
              ),
            ),
        ],
      ),
    );
  }
}
