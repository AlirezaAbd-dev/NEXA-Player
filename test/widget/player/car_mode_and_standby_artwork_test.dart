import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/auto/domain/models/auto_settings.dart';
import 'package:nexa_player/features/auto/presentation/providers/auto_providers.dart';
import 'package:nexa_player/features/auto/presentation/screens/car_mode_screen.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/standby_mode_screen.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/widgets/cards/nexa_artwork_image.dart';

class _FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _FakePlayerNotifier(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeAutoSettingsNotifier extends StateNotifier<AutoSettings>
    implements AutoSettingsNotifier {
  _FakeAutoSettingsNotifier() : super(const AutoSettings());

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const sampleTrack = Track(
    id: 'art-1',
    title: 'Cover Art Song',
    artist: 'NEXA Artist',
    album: 'Cover Album',
    duration: Duration(minutes: 3, seconds: 30),
    artworkUri: 'content://media/external/audio/albumart/77',
  );

  testWidgets('CarModeScreen queue drawer renders NexaArtworkImage for tracks',
      (tester) async {
    final queue = PlaybackQueueImpl();
    addTearDown(queue.dispose);
    queue.setQueue(const [sampleTrack], initialIndex: 0);

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          autoSettingsProvider.overrideWith((ref) => _FakeAutoSettingsNotifier()),
          playbackQueueProvider.overrideWithValue(queue),
          playerNotifierProvider.overrideWith(
            (ref) => _FakePlayerNotifier(
              const PlaybackState(
                currentTrack: sampleTrack,
                status: PlaybackStatus.paused,
                duration: Duration(minutes: 3, seconds: 30),
              ),
            ),
          ),
          isPlayingProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: CarModeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Open Up Next Queue drawer
    await tester.tap(find.byIcon(Icons.queue_music_rounded));
    await tester.pumpAndSettle();

    expect(find.text('UP NEXT QUEUE'), findsOneWidget);
    final artworks = tester
        .widgetList<NexaArtworkImage>(find.byType(NexaArtworkImage))
        .toList();
    expect(
      artworks.any((w) => w.artworkUri == sampleTrack.artworkUri),
      isTrue,
    );
  });

  testWidgets('StandbyModeScreen turntable renders NexaArtworkImage for current track',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerNotifierProvider.overrideWith(
            (ref) => _FakePlayerNotifier(
              const PlaybackState(
                currentTrack: sampleTrack,
                status: PlaybackStatus.paused,
                duration: Duration(minutes: 3, seconds: 30),
              ),
            ),
          ),
          isPlayingProvider.overrideWith((ref) => false),
        ],
        child: const MaterialApp(home: StandbyModeScreen()),
      ),
    );
    await tester.pump();

    final artworks = tester
        .widgetList<NexaArtworkImage>(find.byType(NexaArtworkImage))
        .toList();
    expect(artworks, isNotEmpty);
    expect(artworks.first.artworkUri, sampleTrack.artworkUri);
  });
}
