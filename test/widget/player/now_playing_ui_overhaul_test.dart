import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/features/player/presentation/widgets/gearshift_waveform_scrubber.dart';
import 'package:nexa_player/shared/models/track.dart';

class _TestOverhaulNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _TestOverhaulNotifier(super.state);

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
  Future<void> skipNext() async {}

  @override
  Future<void> skipPrevious() async {}

  @override
  Future<void> skipToIndex(int index) async {}

  @override
  void refreshTrack(Track updatedTrack) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const sampleTrack = Track(
    id: 'trk-overhaul-1',
    title: 'شادمهر عقیلی - پر پرواز',
    artist: 'Shadmehr Aghili',
    album: 'Par-e Parvaz',
    duration: Duration(minutes: 4, seconds: 15),
    bitrate: 320000,
    codec: 'MP3',
    sampleRate: 44100,
    channels: 2,
    isFavorite: true,
  );

  Widget buildSubject({
    required ThemeData theme,
    double textScale = 1.0,
  }) {
    return ProviderScope(
      overrides: [
        playerNotifierProvider.overrideWith(
          (ref) => _TestOverhaulNotifier(
            const PlaybackState(
              currentTrack: sampleTrack,
              status: PlaybackStatus.paused,
              position: Duration(minutes: 1, seconds: 5),
              duration: Duration(minutes: 4, seconds: 15),
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            textScaler: TextScaler.linear(textScale),
          ),
          child: const NowPlayingScreen(),
        ),
      ),
    );
  }

  group('NowPlayingScreen Sculptural UI Overhaul Tests', () {
    for (final spec in [
      (name: 'compact 360x780 @ 1.0x', size: const Size(360, 780), scale: 1.0),
      (name: 'Huawei Y9s 412x915 @ 1.0x', size: const Size(412, 915), scale: 1.0),
      (name: 'compact 360x780 @ 1.3x text scale', size: const Size(360, 780), scale: 1.3),
    ]) {
      testWidgets('zero RenderFlex overflow on ${spec.name}', (tester) async {
        await tester.binding.setSurfaceSize(spec.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        final errors = <FlutterErrorDetails>[];
        final prevHandler = FlutterError.onError;
        FlutterError.onError = (details) => errors.add(details);
        addTearDown(() => FlutterError.onError = prevHandler);

        await tester.pumpWidget(
          buildSubject(
            theme: AppTheme.buildTheme(
              preset: ThemePreset.obsidian,
              mode: ThemeMode.dark,
            ),
            textScale: spec.scale,
          ),
        );
        await tester.pumpAndSettle();

        expect(errors, isEmpty);
        expect(tester.takeException(), isNull);
        expect(find.byType(GearshiftWaveformScrubber), findsOneWidget);
        expect(find.byKey(const Key('now_playing_repeat_button')), findsOneWidget);

        // Zero idle HUD clutter
        expect(find.byKey(const ValueKey('gearshift_active_hud')), findsNothing);
        // Zero rating widgets
        expect(find.byIcon(Icons.star_rounded), findsNothing);
        expect(find.byIcon(Icons.star_border_rounded), findsNothing);
      });
    }

    testWidgets(
      'diagonal drag on artwork rejects pull-down dismiss when horizontal dominates',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(412, 915));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              playerNotifierProvider.overrideWith(
                (ref) => _TestOverhaulNotifier(
                  const PlaybackState(
                    currentTrack: sampleTrack,
                    status: PlaybackStatus.paused,
                    position: Duration(seconds: 30),
                    duration: Duration(minutes: 4),
                  ),
                ),
              ),
            ],
            child: MaterialApp(
              theme: AppTheme.buildTheme(
                preset: ThemePreset.daylight,
                mode: ThemeMode.light,
              ),
              home: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NowPlayingScreen(),
                        ),
                      );
                    },
                    child: const Text('Open NowPlaying'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open NowPlaying'));
        await tester.pumpAndSettle();
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        // Diagonal drag (mostly horizontal +180, slight downward +45) must NOT dismiss!
        final artworkFinder =
            find.byKey(const ValueKey('now_playing_pull_down_artwork'));
        await tester.drag(artworkFinder, const Offset(180, 45));
        await tester.pumpAndSettle();
        expect(find.byType(NowPlayingScreen), findsOneWidget);

        // Strong downward vertical drag (>150dp) dismisses cleanly
        await tester.drag(
          find.byKey(const ValueKey('now_playing_pull_down_header')),
          const Offset(0, 260),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NowPlayingScreen), findsNothing);
      },
    );
  });
}
