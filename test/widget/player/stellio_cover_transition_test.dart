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
import 'package:nexa_player/features/player/presentation/widgets/hero_artwork_card.dart';
import 'package:nexa_player/shared/models/track.dart';

class _CarouselTestPlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _CarouselTestPlayerNotifier(super.state, this.queue);

  final IPlaybackQueue queue;
  final List<int> skipToIndexCalls = [];

  @override
  Future<void> skipToIndex(int index) async {
    skipToIndexCalls.add(index);
    final selected = queue.skipToIndex(index);
    if (selected != null) {
      state = state.copyWith(currentTrack: selected);
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
  final sampleQueue = List.generate(
    5,
    (i) => Track(
      id: 'trk-flow-$i',
      title: 'Flow Track ${i + 1}',
      artist: 'Artist ${i + 1}',
      album: 'Album ${i + 1}',
      duration: const Duration(minutes: 3, seconds: 20),
      bitrate: 320000,
    ),
  );

  Widget buildSubject({
    required _CarouselTestPlayerNotifier notifier,
    required IPlaybackQueue queue,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
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
            disableAnimations: disableAnimations,
            size: const Size(412, 915),
          ),
          child: const NowPlayingScreen(),
        ),
      ),
    );
  }

  group('Stellio Cover Transition & Metadata Parallax Tests', () {
    testWidgets(
      'fractional cover drag drives synchronized metadata parallax mid-drag and commits skipToIndex once on settle',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final queue = PlaybackQueueImpl()..setQueue(sampleQueue, initialIndex: 0);
        final notifier = _CarouselTestPlayerNotifier(
          PlaybackState(
            currentTrack: sampleQueue.first,
            status: PlaybackStatus.paused,
            duration: const Duration(minutes: 3),
          ),
          queue,
        );

        await tester.pumpWidget(buildSubject(notifier: notifier, queue: queue));
        await tester.pumpAndSettle();

        expect(find.text('Flow Track 1'), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);
        final pageView = tester.widget<PageView>(find.byType(PageView));
        expect(pageView.physics, isA<StellioPageScrollPhysics>());

        // Hold & drag left past touch slop so fractional scroll offset drives metadata parallax
        final center = tester.getCenter(find.byType(HeroArtworkCard));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(-30, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-90, 0));
        await tester.pump();
        await tester.pump();

        expect(
          find.byKey(const ValueKey('now_playing_metadata_parallax')),
          findsOneWidget,
        );
        expect(find.text('Flow Track 1'), findsOneWidget);
        expect(find.text('Flow Track 2'), findsOneWidget);

        // Complete fling to page 1 and settle
        await gesture.moveBy(const Offset(-140, 0));
        await gesture.up();
        await tester.pumpAndSettle();

        expect(notifier.skipToIndexCalls, equals([1]));
        expect(find.text('Flow Track 2'), findsOneWidget);
      },
    );

    testWidgets(
      'disableAnimations uses flat crossfade without 3D rotateY tilt or ±24dp horizontal parallax offset',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final queue = PlaybackQueueImpl()..setQueue(sampleQueue, initialIndex: 0);
        final notifier = _CarouselTestPlayerNotifier(
          PlaybackState(
            currentTrack: sampleQueue.first,
            status: PlaybackStatus.paused,
            duration: const Duration(minutes: 3),
          ),
          queue,
        );

        await tester.pumpWidget(
          buildSubject(
            notifier: notifier,
            queue: queue,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();

        final center = tester.getCenter(find.byType(HeroArtworkCard));
        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(-30, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-90, 0));
        await tester.pump();
        await tester.pump();

        // Under reduced motion, metadata crossfades in-place (Offset.zero)
        final parallaxFinder = find.byKey(
          const ValueKey('now_playing_metadata_parallax'),
        );
        expect(parallaxFinder, findsOneWidget);
        final transforms = tester.widgetList<Transform>(
          find.descendant(of: parallaxFinder, matching: find.byType(Transform)),
        );
        for (final t in transforms) {
          expect(t.transform.getTranslation().x, closeTo(0.0, 0.001));
        }

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );
  });
}
