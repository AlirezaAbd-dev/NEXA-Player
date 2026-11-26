import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/songs_tab_screen.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';
import 'package:nexa_player/shared/models/track.dart';

class _FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _FakePlayerNotifier(Track activeTrack)
      : super(PlaybackState(currentTrack: activeTrack));

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'SongsTabScreen Jump-to-Playing chip sits ~12dp above MiniPlayer inset, not in middle of screen',
    (tester) async {
      const screenSize = Size(390, 844);
      const bottomShellInset = 146.0;
      final tracks = List<Track>.generate(
        40,
        (i) => Track(
          id: 't-$i',
          title: 'Song $i',
          artist: 'Artist $i',
          duration: const Duration(minutes: 3),
        ),
      );

      await tester.binding.setSurfaceSize(screenSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tracksListProvider.overrideWith((ref, params) => Future.value(tracks)),
            playerNotifierProvider.overrideWith(
              (ref) => _FakePlayerNotifier(tracks.first),
            ),
            currentTrackProvider.overrideWith((ref) => tracks.first),
            isPlayingProvider.overrideWith((ref) => false),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: MediaQuery(
              data: MediaQueryData(
                size: screenSize,
                padding: EdgeInsets.only(bottom: bottomShellInset),
              ),
              child: SongsTabScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll far down (>10 items away from track 0) so the Jump-to-Playing chip appears
      await tester.drag(find.byKey(Phase2Keys.allSongsList), const Offset(0, -1800));
      await tester.pumpAndSettle();

      final chipFinder = find.byKey(const ValueKey('jump_to_playing_chip'));
      expect(chipFinder, findsOneWidget);

      final chipBottom = tester.getBottomLeft(chipFinder).dy;
      final expectedBottom = screenSize.height - bottomShellInset - 12.0;
      expect(chipBottom, closeTo(expectedBottom, 2.0));
    },
  );
}
