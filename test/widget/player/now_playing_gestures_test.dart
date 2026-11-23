import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/now_playing_screen.dart';
import 'package:nexa_player/features/player/presentation/widgets/gearshift_waveform_scrubber.dart';
import 'package:nexa_player/features/player/presentation/widgets/hero_artwork_card.dart';
import 'package:nexa_player/shared/models/track.dart';

void main() {
  const sampleTrack = Track(
    id: 'trk-now-playing',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: Duration(minutes: 3, seconds: 50),
    filePath: '/music/starboy.mp3',
    bitrate: 320000,
    isFavorite: true,
  );

  Widget createSubject({
    Track track = sampleTrack,
    bool isPlaying = true,
  }) {
    return ProviderScope(
      overrides: [
        playerNotifierProvider.overrideWith(
          (ref) => _FakePlayerNotifier(
            PlaybackState(
              currentTrack: track,
              status: isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
              position: const Duration(minutes: 1, seconds: 30),
              duration: const Duration(minutes: 3, seconds: 50),
              volume: 0.8,
              speed: 1.0,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark(),
        home: const NowPlayingScreen(),
      ),
    );
  }

  group('NowPlayingScreen Precision Gestures & Studio Telemetry Tests', () {
    testWidgets('renders hero artwork, gearshift scrubber, and compact bottom utility dock', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      expect(find.text('Starboy'), findsWidgets);
      expect(find.byType(HeroArtworkCard), findsOneWidget);
      expect(find.byType(GearshiftWaveformScrubber), findsOneWidget);

      // Verify thumb zone primary controls
      expect(find.byTooltip('Play'), findsNothing);
      expect(find.byTooltip('Pause'), findsOneWidget);
      expect(find.byTooltip('Next'), findsOneWidget);
      expect(find.byTooltip('Previous'), findsOneWidget);

      // Verify compact bottom utility dock
      expect(find.text('320 KBPS • STEREO'), findsOneWidget);
      expect(find.byTooltip('Queue'), findsOneWidget);
      expect(find.byTooltip('Sleep Timer'), findsOneWidget);
      expect(find.byTooltip('Equalizer & DSP'), findsOneWidget);
      expect(find.byTooltip('Lyrics'), findsOneWidget);
    });

    testWidgets('long press on artwork flips card to reveal 3D Signal Chain telemetry', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump();

      // Long press hero artwork
      final artwork = find.byType(HeroArtworkCard);
      await tester.longPress(artwork);
      await tester.pumpAndSettle();

      // Verify 3D Signal Chain header and flow
      expect(find.text('3D SIGNAL CHAIN'), findsOneWidget);
      expect(find.text('SOURCE'), findsOneWidget);
      expect(find.text('DSP'), findsOneWidget);
      expect(find.text('DVC'), findsOneWidget);
      expect(find.text('OUTPUT'), findsOneWidget);
      expect(find.text('Tap anywhere to flip back'), findsOneWidget);
    });

    testWidgets('GearshiftWaveformScrubber precision shifts down on vertical drag', (tester) async {
      Duration? soughtPos;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: GearshiftWaveformScrubber(
                  position: const Duration(seconds: 60),
                  duration: const Duration(seconds: 200),
                  isPlaying: false,
                  onSeek: (pos) => soughtPos = pos,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(GearshiftWaveformScrubber), findsOneWidget);

      // Horizontal drag
      final scrubberFinder = find.byType(GearshiftWaveformScrubber);
      final gesture = await tester.startGesture(tester.getCenter(scrubberFinder));
      await gesture.moveBy(const Offset(30, 0));
      await tester.pump();

      expect(soughtPos, isNotNull);

      // Drag downward to shift to fine/ultra-fine gear
      await gesture.moveBy(const Offset(10, 45));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

class _FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _FakePlayerNotifier(super.state);

  @override
  Future<void> playTrack(Track track, {List<Track>? queue, int? initialIndex}) async {}

  @override
  Future<void> togglePlayPause() async {
    state = state.copyWith(
      status: state.isPlaying ? PlaybackStatus.paused : PlaybackStatus.playing,
    );
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {
    state = state.copyWith(position: position);
  }

  @override
  Future<void> skipNext() async {}

  @override
  Future<void> skipToIndex(int index) async {}

  @override
  Future<void> skipPrevious() async {}

  @override
  void addNext(Track track) {}

  @override
  void addTrack(Track track) {}

  @override
  void setPlaybackMode(PlaybackMode mode) {}

  @override
  void toggleShuffle() {}

  @override
  void cycleRepeatMode() {}

  @override
  Future<void> setVolume(double volume) async {
    state = state.copyWith(volume: volume);
  }

  @override
  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
  }

  @override
  Future<void> toggleFavorite([Track? targetTrack]) async {}

  @override
  void startSleepTimer(Duration duration) {}

  @override
  void cancelSleepTimer() {}
}
