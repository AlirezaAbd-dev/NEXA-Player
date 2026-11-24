import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/theme/app_theme.dart';
import 'package:nexa_player/core/theme/theme_preset.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/songs_tab_screen.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/domain/entities/queue_context.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/database/database_failure.dart';
import 'package:nexa_player/shared/widgets/branding/nexa_animated_logo.dart';
import 'package:nexa_player/shared/widgets/branding/nexa_header_brand_lockup.dart';

class _TestPlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _TestPlayerNotifier(super.state);

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

class _FakeTracksRepo implements ITracksRepository {
  @override
  Future<Result<List<Track>, DatabaseFailure>> getAllTracks({
    TrackSortBy sortBy = TrackSortBy.title,
    bool ascending = true,
    String? searchQuery,
  }) async {
    return const Result.success([
      Track(
        id: 'hdr-1',
        title: 'Midnight Echo',
        artist: 'NEXA Artist',
        album: 'Obsidian',
        duration: Duration(minutes: 3, seconds: 40),
      ),
    ]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildSongsScreen({
    required ThemeData theme,
    required Size viewport,
    required bool isPlaying,
    bool disableAnimations = false,
  }) {
    return ProviderScope(
      overrides: [
        tracksRepositoryProvider.overrideWithValue(_FakeTracksRepo()),
        playerNotifierProvider.overrideWith(
          (ref) => _TestPlayerNotifier(
            PlaybackState(
              currentTrack: const Track(
                id: 'hdr-1',
                title: 'Midnight Echo',
                artist: 'NEXA Artist',
                duration: Duration(minutes: 3, seconds: 40),
              ),
              status:
                  isPlaying ? PlaybackStatus.playing : PlaybackStatus.paused,
            ),
          ),
        ),
      ],
      child: MaterialApp(
        theme: theme,
        home: MediaQuery(
          data: MediaQueryData(
            size: viewport,
            disableAnimations: disableAnimations,
          ),
          child: const SongsTabScreen(),
        ),
      ),
    );
  }

  group('Task #17 Mobile Library Header NEXA Logo Presence Tests', () {
    for (final entry in {
      'Dark 360x780': (
        theme: AppTheme.buildTheme(
          preset: ThemePreset.midnightBlack,
          mode: ThemeMode.dark,
        ),
        size: const Size(360, 780),
      ),
      'Daylight 412x915': (
        theme: AppTheme.buildTheme(
          preset: ThemePreset.daylight,
          mode: ThemeMode.light,
        ),
        size: const Size(412, 915),
      ),
    }.entries) {
      testWidgets(
        '${entry.key}: renders NexaAnimatedLogo & NEXA brand lockup in Library header without overflow',
        (tester) async {
          tester.view.physicalSize = entry.value.size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            buildSongsScreen(
              theme: entry.value.theme,
              viewport: entry.value.size,
              isPlaying: true,
            ),
          );
          // Single pump since playing mode animates continuously
          await tester.pump(const Duration(milliseconds: 50));

          expect(find.byType(NexaAnimatedLogo), findsOneWidget);
          expect(find.text('NEXA'), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(NexaHeaderBrandLockup),
              matching: find.text('Songs'),
            ),
            findsOneWidget,
          );

          final lockupSize = tester.getSize(
            find.byKey(const ValueKey('nexa_header_brand_lockup')),
          );
          expect(lockupSize.width, greaterThanOrEqualTo(48.0));
          expect(lockupSize.height, greaterThanOrEqualTo(48.0));
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'pauses logo shimmer when isPlaying == false or disableAnimations == true',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          buildSongsScreen(
            theme: AppTheme.buildTheme(
              preset: ThemePreset.midnightBlack,
              mode: ThemeMode.dark,
            ),
            viewport: const Size(360, 780),
            isPlaying: false,
          ),
        );
        await tester.pumpAndSettle();

        final pausedLogo =
            tester.widget<NexaAnimatedLogo>(find.byType(NexaAnimatedLogo));
        expect(pausedLogo.isPlaying, isFalse);

        await tester.pumpWidget(
          buildSongsScreen(
            theme: AppTheme.buildTheme(
              preset: ThemePreset.midnightBlack,
              mode: ThemeMode.dark,
            ),
            viewport: const Size(360, 780),
            isPlaying: true,
            disableAnimations: true,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
