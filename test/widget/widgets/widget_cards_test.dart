import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/di/service_providers.dart';
import 'package:nexa_player/features/lyrics/domain/models/lyric_line.dart';
import 'package:nexa_player/features/player/domain/entities/playback_state.dart';
import 'package:nexa_player/features/player/presentation/providers/player_notifier.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/widgets/presentation/screens/widget_showcase_screen.dart';
import 'package:nexa_player/features/widgets/presentation/widgets/compact_widget_card.dart';
import 'package:nexa_player/features/widgets/presentation/widgets/hero_vinyl_widget_card.dart';
import 'package:nexa_player/features/widgets/presentation/widgets/karaoke_widget_card.dart';
import 'package:nexa_player/features/widgets/presentation/widgets/square_widget_card.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakePlayerNotifier extends StateNotifier<PlaybackState>
    implements PlayerNotifier {
  FakePlayerNotifier([Track? initialTrack])
      : super(PlaybackState(
          currentTrack: initialTrack ??
              const Track(
                id: 'track_1',
                title: 'Neon Nights',
                artist: 'Synthetica',
                album: 'Retro Future',
                duration: Duration(minutes: 3, seconds: 30),
              ),
          status: PlaybackStatus.playing,
          position: const Duration(minutes: 1, seconds: 15),
          duration: const Duration(minutes: 3, seconds: 30),
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack = Track(
    id: 'track_1',
    title: 'Neon Nights',
    artist: 'Synthetica',
    album: 'Retro Future',
    duration: Duration(minutes: 3, seconds: 30),
  );

  late IStorageService storage;
  late FakePlayerNotifier fakePlayer;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    storage = SharedPreferencesStorageService(prefs);
    if (!getIt.isRegistered<IStorageService>()) {
      getIt.registerSingleton<IStorageService>(storage);
    }
    fakePlayer = FakePlayerNotifier(testTrack);
  });

  tearDown(() async {
    if (getIt.isRegistered<IStorageService>()) {
      await getIt.unregister<IStorageService>();
    }
  });

  group('CompactWidgetCard', () {
    testWidgets('renders track title, artist, and handles play/pause tap',
        (tester) async {
      bool playPauseCalled = false;
      bool nextCalled = false;
      bool prevCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CompactWidgetCard(
                track: testTrack,
                isPlaying: false,
                position: const Duration(seconds: 45),
                duration: const Duration(minutes: 3, seconds: 30),
                accentColor: const Color(0xFF00E5FF),
                onPlayPause: () => playPauseCalled = true,
                onNext: () => nextCalled = true,
                onPrevious: () => prevCalled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Neon Nights'), findsOneWidget);
      expect(find.text('Synthetica'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      expect(playPauseCalled, isTrue);

      await tester.tap(find.byIcon(Icons.skip_next_rounded));
      expect(nextCalled, isTrue);

      await tester.tap(find.byIcon(Icons.skip_previous_rounded));
      expect(prevCalled, isTrue);
    });
  });

  group('HeroVinylWidgetCard', () {
    testWidgets('renders sleeve, spinning vinyl, and toggles favorite',
        (tester) async {
      bool favToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HeroVinylWidgetCard(
                track: testTrack,
                isPlaying: true,
                position: const Duration(minutes: 1, seconds: 15),
                duration: const Duration(minutes: 3, seconds: 30),
                accentColor: const Color(0xFFD946EF),
                isFavorite: false,
                onFavoriteToggle: () => favToggled = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Neon Nights'), findsOneWidget);
      expect(find.text('Synthetica'), findsOneWidget);
      expect(find.text('Retro Future'), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      expect(favToggled, isTrue);
    });
  });

  group('SquareWidgetCard', () {
    testWidgets('renders 2x2 tile layout and circular progress', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SquareWidgetCard(
                track: testTrack,
                isPlaying: false,
                position: Duration(seconds: 30),
                duration: Duration(minutes: 3),
                accentColor: Color(0xFF00E5FF),
              ),
            ),
          ),
        ),
      );

      expect(find.text('NEXA'), findsOneWidget);
      expect(find.text('Neon Nights'), findsOneWidget);
      expect(find.text('Synthetica'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('KaraokeWidgetCard', () {
    testWidgets('renders synced lyrics with active glowing line',
        (tester) async {
      const lyrics = [
        LyricLine(timestamp: Duration.zero, text: 'First verse starts here'),
        LyricLine(timestamp: Duration(seconds: 10), text: 'Glowing chorus line'),
        LyricLine(timestamp: Duration(seconds: 20), text: 'Outro coming soon'),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: KaraokeWidgetCard(
                track: testTrack,
                isPlaying: true,
                position: Duration(seconds: 12),
                duration: Duration(minutes: 3),
                lyricLines: lyrics,
                accentColor: Color(0xFF00E676),
              ),
            ),
          ),
        ),
      );

      expect(find.text('First verse starts here'), findsOneWidget);
      expect(find.text('Glowing chorus line'), findsOneWidget);
      expect(find.text('Outro coming soon'), findsOneWidget);
    });
  });

  group('WidgetShowcaseScreen', () {
    testWidgets('renders showcase screen, tabs, and customizer controls',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(storage),
            playerNotifierProvider.overrideWith((ref) => fakePlayer),
          ],
          child: const MaterialApp(
            home: WidgetShowcaseScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Homescreen Widgets'), findsOneWidget);
      expect(find.text('LIVE HOMESCREEN PREVIEW'), findsOneWidget);
      expect(find.text('4×1 Compact'), findsOneWidget);
      expect(find.text('4×2 Hero Vinyl'), findsOneWidget);
      expect(find.text('2×2 Square'), findsOneWidget);
      expect(find.text('4×3 Karaoke'), findsOneWidget);

      // Verify customizer sliders and switches exist
      expect(find.text('Background Opacity'), findsOneWidget);
      expect(find.text('Corner Curvature'), findsOneWidget);
      expect(find.text('Ambient Neon Glow'), findsOneWidget);
      expect(find.text('Peeking Vinyl Disc'), findsOneWidget);
      expect(find.text('Monet Dynamic Colors'), findsOneWidget);

      // Switch form factor to 4x1 Compact
      await tester.tap(find.text('4×1 Compact'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CompactWidgetCard), findsOneWidget);
    });
  });
}
