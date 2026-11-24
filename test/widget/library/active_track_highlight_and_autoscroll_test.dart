import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/songs_tab_screen.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';
import 'package:nexa_player/shared/widgets/lists/active_track_auto_scroller.dart';

class _TestPlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _TestPlayerNotifier(super.state);

  void setActiveTrack(Track track, {bool isPlaying = true}) {
    state = state.copyWith(
      currentTrack: track,
      status: isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
    );
  }

  @override
  Future<void> playQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    PlaybackMode? mode,
    NexaRepeatMode? repeatMode,
    QueueContext? queueContext,
  }) async {}

  @override
  Future<void> playTrack(
    Track track, {
    List<Track>? queue,
    int? initialIndex,
    QueueContext? queueContext,
  }) async {}

  @override
  void refreshTrack(Track updatedTrack) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final tracks = List.generate(
    40,
    (i) => Track(
      id: 'trk-$i',
      title: 'Track ${i + 1}',
      artist: 'Artist ${i + 1}',
      album: 'Album',
      duration: const Duration(minutes: 3),
      filePath: '/music/track_${i + 1}.mp3',
    ),
  );

  group('ActiveTrackAutoScroller unit checks', () {
    test('manual scroll suppresses auto-follow during 3s cooldown', () {
      var now = DateTime(2026, 1, 1, 12, 0, 0);
      final scroller = ActiveTrackAutoScroller(
        itemExtent: 72.0,
        manualCooldown: const Duration(seconds: 3),
        clock: () => now,
      );

      expect(scroller.isSuppressedByUser, isFalse);
      scroller.registerManualScroll();
      expect(scroller.isSuppressedByUser, isTrue);

      now = now.add(const Duration(seconds: 2));
      expect(scroller.isSuppressedByUser, isTrue);

      now = now.add(const Duration(seconds: 2));
      expect(scroller.isSuppressedByUser, isFalse);
    });

    test('computes centered clamped target offset above mini-player occlusion',
        () {
      final scroller = ActiveTrackAutoScroller(itemExtent: 72.0);
      final offset = scroller.computeTargetOffset(
        itemIndex: 25,
        currentPixels: 0.0,
        viewportDimension: 600.0,
        maxScrollExtent: 2400.0,
      );
      expect(offset, isNotNull);
      expect(offset!, greaterThan(1000.0));
      expect(offset, lessThanOrEqualTo(2400.0));
    });
  });

  group('ActiveTrackAutoScrollScope & Highlight Widget Tests', () {
    testWidgets(
      'highlights track #15 with L2 pill + EQ glyph, auto-scrolls on advance #15 -> #16 -> #25, and respects manual drag cooldown',
      (tester) async {
        final activeTrack = ValueNotifier<String>('trk-14');
        var fakeClock = DateTime(2026, 1, 1, 12, 0, 0);
        final scrollController = ScrollController();
        addTearDown(() {
          activeTrack.dispose();
          scrollController.dispose();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.buildTheme(
              preset: ThemePreset.obsidian,
              mode: ThemeMode.dark,
            ),
            home: Scaffold(
              body: SizedBox(
                height: 460,
                child: ValueListenableBuilder<String>(
                  valueListenable: activeTrack,
                  builder: (context, currentId, _) {
                    return ActiveTrackAutoScrollScope(
                      controller: scrollController,
                      trackIds: tracks.map((t) => t.id).toList(),
                      activeTrackId: currentId,
                      clock: () => fakeClock,
                      builder: (ctx, controller) => ListView.builder(
                        controller: controller,
                        itemExtent: 72.0,
                        itemCount: tracks.length,
                        itemBuilder: (_, index) {
                          final t = tracks[index];
                          return TrackTile.fromTrack(
                            key: Phase2Keys.trackTile(t.id),
                            track: t,
                            isPlaying: t.id == currentId,
                            isPlaybackActive: false,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Jump initially to near track #15 (index 14) and confirm highlight
        scrollController.jumpTo(12 * 72.0);
        await tester.pump();

        expect(find.byType(AnimatedEqualizerGlyph), findsOneWidget);
        expect(find.text('Track 15'), findsOneWidget);

        // Advance #15 (trk-14) -> #16 (trk-15) -> #25 (trk-24)
        activeTrack.value = 'trk-15';
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));

        activeTrack.value = 'trk-24';
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));

        // Track 25 should now be scrolled into view
        expect(find.text('Track 25'), findsOneWidget);
        final track25Rect = tester.getRect(find.byKey(Phase2Keys.trackTile('trk-24')));
        expect(track25Rect.top, greaterThanOrEqualTo(0.0));
        expect(track25Rect.bottom, lessThanOrEqualTo(460.0));

        // Now perform a manual user drag scroll upward -> cooldown suppresses auto-scroll!
        await tester.drag(find.byType(ListView), const Offset(0, 500));
        await tester.pump();
        final offsetAfterManualDrag = scrollController.offset;

        // Track advances while within 3s manual cooldown -> list must NOT fight user
        activeTrack.value = 'trk-35';
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(scrollController.offset, closeTo(offsetAfterManualDrag, 5.0));

        // Advance clock past 3s cooldown and trigger next track -> resumes auto-follow
        fakeClock = fakeClock.add(const Duration(seconds: 4));
        activeTrack.value = 'trk-36';
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));
        expect(find.text('Track 37'), findsOneWidget);
      },
    );

    testWidgets(
      'SongsTabScreen highlights active playing track consistently and wires ActiveTrackAutoScrollScope',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final fakeNotifier = _TestPlayerNotifier(
          PlaybackState(
            currentTrack: tracks[14],
            status: PlaybackStatus.paused,
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playerNotifierProvider.overrideWith((ref) => fakeNotifier),
              tracksListProvider(const TrackQueryParams(searchQuery: ''))
                  .overrideWith(
                (ref) async => tracks,
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.buildTheme(
                preset: ThemePreset.obsidian,
                mode: ThemeMode.dark,
              ),
              home: const SongsTabScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActiveTrackAutoScrollScope), findsOneWidget);

        // Advance active track to #25 (trk-24)
        fakeNotifier.setActiveTrack(tracks[24], isPlaying: false);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));

        expect(find.text('Track 25'), findsOneWidget);
        expect(find.byType(AnimatedEqualizerGlyph), findsOneWidget);
      },
    );
  });
}
