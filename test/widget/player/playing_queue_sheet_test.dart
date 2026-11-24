import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/domain/services/playback_queue.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/features/player/presentation/widgets/playing_queue_sheet.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/track_tile.dart';

class _QueueTestNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _QueueTestNotifier(super.state, this.queue);

  final IPlaybackQueue queue;
  final List<int> skippedIndices = [];

  @override
  Future<void> skipToIndex(int index) async {
    skippedIndices.add(index);
    final t = queue.skipToIndex(index);
    if (t != null) {
      state = state.copyWith(currentTrack: t);
    }
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
  final sampleTracks = List.generate(
    18,
    (i) => Track(
      id: 'trk-q-$i',
      title: 'Queue Song ${i + 1}',
      artist: 'Artist ${i + 1}',
      album: 'Rock Folder',
      duration: const Duration(minutes: 3, seconds: 10),
    ),
  );

  Widget buildNowPlaying({
    required IPlaybackQueue queue,
    required _QueueTestNotifier notifier,
    Size size = const Size(412, 915),
    double textScale = 1.0,
  }) {
    return ProviderScope(
      key: UniqueKey(),
      overrides: [
        playbackQueueProvider.overrideWithValue(queue),
        playbackQueueStateStreamProvider.overrideWith(
          (ref) => queue.queueStream,
        ),
        playerNotifierProvider.overrideWith((ref) => notifier),
      ],
      child: MaterialApp(
        theme: AppTheme.buildTheme(
          preset: ThemePreset.obsidian,
          mode: ThemeMode.dark,
        ),
        home: MediaQuery(
          data: MediaQueryData(
            size: size,
            textScaler: TextScaler.linear(textScale),
          ),
          child: const NowPlayingScreen(),
        ),
      ),
    );
  }

  group('PlayingQueueSheet Interactive Tests', () {
    testWidgets(
      'drag UP on NowPlayingScreen opens PlayingQueueSheet & drag DOWN closes sheet without dismissing NowPlaying',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final queue = PlaybackQueueImpl()
          ..setQueue(
            sampleTracks,
            initialIndex: 9,
            queueContext: const QueueContext.folder(
              '/music/Rock',
              title: 'Rock Folder',
            ),
          );
        final notifier = _QueueTestNotifier(
          PlaybackState(
            currentTrack: sampleTracks[9],
            status: PlaybackStatus.paused,
            duration: const Duration(minutes: 3),
          ),
          queue,
        );

        await tester.pumpWidget(buildNowPlaying(queue: queue, notifier: notifier));
        await tester.pumpAndSettle();

        // Drag UP on bottom dock / lower area opens PlayingQueueSheet
        await tester.drag(
          find.byKey(const ValueKey('now_playing_drag_up_dock')),
          const Offset(0, -120),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlayingQueueSheet), findsOneWidget);
        expect(find.textContaining('Playing From: Rock Folder'), findsOneWidget);
        // Active track (#10) auto-centered with equalizer glyph
        expect(
          find.descendant(
            of: find.byType(PlayingQueueSheet),
            matching: find.text('Queue Song 10'),
          ),
          findsOneWidget,
        );
        expect(find.byType(AnimatedEqualizerGlyph), findsOneWidget);

        // Drag DOWN on sheet closes PlayingQueueSheet without dismissing NowPlayingScreen
        await tester.drag(
          find.byKey(const ValueKey('playing_queue_grabber')),
          const Offset(0, 500),
        );
        await tester.pumpAndSettle();

        expect(find.byType(PlayingQueueSheet), findsNothing);
        expect(find.byType(NowPlayingScreen), findsOneWidget);
      },
    );

    testWidgets(
      'tapping Queue button opens sheet showing previous, active, "Up Next" badge, tap-to-jump, reorder, & swipe-to-remove with Undo',
      (tester) async {
        for (final spec in [
          (size: const Size(360, 780), scale: 1.0),
          (size: const Size(412, 915), scale: 1.3),
        ]) {
          await tester.binding.setSurfaceSize(spec.size);

          final queue = PlaybackQueueImpl()
            ..setQueue(
              sampleTracks.take(6).toList(),
              initialIndex: 2,
              queueContext: const QueueContext.folder('/music/Rock', title: 'Rock'),
            );
          // Insert a "Play Next" item right after active index 2
          queue.addNext(
            const Track(
              id: 'trk-play-next',
              title: 'Injected Next Track',
              artist: 'Guest',
              duration: Duration(minutes: 2),
            ),
          );

          final notifier = _QueueTestNotifier(
            PlaybackState(
              currentTrack: sampleTracks[2],
              status: PlaybackStatus.paused,
              duration: const Duration(minutes: 3),
            ),
            queue,
          );

          await tester.pumpWidget(
            buildNowPlaying(
              queue: queue,
              notifier: notifier,
              size: spec.size,
              textScale: spec.scale,
            ),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('Queue'));
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
          expect(find.byType(PlayingQueueSheet), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(PlayingQueueSheet),
              matching: find.text('Queue Song 1'),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(PlayingQueueSheet),
              matching: find.text('Queue Song 3'),
            ),
            findsOneWidget,
          );
          expect(find.text('Injected Next Track'), findsOneWidget);
          expect(find.text('Up Next'), findsOneWidget);

          // Tap previous song -> skips playback to index 0
          await tester.tap(
            find.descendant(
              of: find.byType(PlayingQueueSheet),
              matching: find.text('Queue Song 1'),
            ),
          );
          await tester.pumpAndSettle();
          expect(notifier.skippedIndices, contains(0));

          // Reorder index 4 cleanly without interrupting active track
          final countBefore = queue.state.length;
          queue.reorder(4, 1);
          await tester.pumpAndSettle();
          expect(queue.state.length, countBefore);

          // Swipe left on non-playing item removes it and shows Undo
          await tester.drag(
            find.byKey(const ValueKey('queue_tile_trk-play-next_4')),
            const Offset(-350, 0),
          );
          await tester.pumpAndSettle();
          expect(queue.state.length, countBefore - 1);
          expect(find.text('Undo'), findsOneWidget);

          await tester.tap(find.text('Undo'));
          await tester.pumpAndSettle();
          expect(queue.state.length, countBefore);

          // Close sheet before next viewport iteration
          await tester.tap(find.byKey(const ValueKey('playing_queue_close_button')));
          await tester.pumpAndSettle();
        }
        await tester.binding.setSurfaceSize(null);
      },
    );
  });
}
