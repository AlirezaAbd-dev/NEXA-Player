import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/player/presentation/screens/lockscreen_player_screen.dart';
import 'package:nexa_player/l10n/generated/app_localizations.dart';
import 'package:nexa_player/shared/models/track.dart';

class _FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  _FakePlayerNotifier(super.initialState);

  bool playCalled = false;
  bool pauseCalled = false;
  bool nextCalled = false;
  bool prevCalled = false;
  bool favoriteToggled = false;

  @override
  Future<void> play() async {
    playCalled = true;
    state = state.copyWith(status: PlaybackStatus.playing);
  }

  @override
  Future<void> pause() async {
    pauseCalled = true;
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  @override
  Future<void> skipNext() async {
    nextCalled = true;
  }

  @override
  Future<void> skipPrevious() async {
    prevCalled = true;
  }

  @override
  Future<void> toggleFavorite([Track? track]) async {
    favoriteToggled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets(
    'LockscreenPlayerScreen renders metadata, transport controls, and dismisses cleanly',
    (tester) async {
      const track = Track(
        id: 'ls-1',
        title: 'Lockscreen Symphony',
        artist: 'NEXA Artist',
        album: 'Midnight',
        duration: Duration(minutes: 4, seconds: 20),
      );
      final fakeNotifier = _FakePlayerNotifier(
        const PlaybackState(
          currentTrack: track,
          status: PlaybackStatus.playing,
          position: Duration(minutes: 1, seconds: 10),
          duration: Duration(minutes: 4, seconds: 20),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerNotifierProvider.overrideWith((ref) => fakeNotifier),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    key: const ValueKey('open_ls_btn'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const LockscreenPlayerScreen(),
                        ),
                      );
                    },
                    child: const Text('Open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('open_ls_btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('lockscreen_player_root')), findsOneWidget);
      expect(find.byKey(const ValueKey('lockscreen_clock')), findsOneWidget);
      expect(find.text('Lockscreen Symphony'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('lockscreen_play_pause_btn')));
      await tester.pump();
      expect(fakeNotifier.pauseCalled, isTrue);

      await tester.tap(find.byKey(const ValueKey('lockscreen_next_btn')));
      await tester.pump();
      expect(fakeNotifier.nextCalled, isTrue);

      await tester.tap(find.byKey(const ValueKey('lockscreen_prev_btn')));
      await tester.pump();
      expect(fakeNotifier.prevCalled, isTrue);

      await tester.tap(find.byKey(const ValueKey('lockscreen_favorite_btn')));
      await tester.pump();
      expect(fakeNotifier.favoriteToggled, isTrue);

      // Dismiss via Unlock & Close button
      await tester.tap(find.byKey(const ValueKey('lockscreen_dismiss_btn')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('lockscreen_player_root')), findsNothing);
    },
  );
}
