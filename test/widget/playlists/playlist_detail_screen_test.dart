import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/playback_queue.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/player/presentation/providers/player_providers.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/services/m3u_service.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/screens/playlist_detail_screen.dart';
import 'package:nexa_player/shared/models/playlist.dart';
import 'package:nexa_player/shared/models/track.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../unit/player/player_notifier_test.dart';

class MockPlaylistsRepository extends Mock implements IPlaylistsRepository {}
class MockM3uService extends Mock implements IM3uService {}

void main() {
  late MockAudioEngine engine;
  late PlaybackQueueImpl queue;
  late SleepTimerServiceImpl sleepTimer;
  late MockPlaylistsRepository mockPlaylistsRepo;
  late MockM3uService mockM3uService;

  final testPlaylist = Playlist(
    id: 'pl-synth-1',
    name: 'Synthwave Dreams',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    trackCount: 2,
  );

  const testTracks = [
    Track(
      id: 'trk-1',
      title: 'Resonance',
      artist: 'HOME',
      album: 'Odyssey',
      duration: Duration(seconds: 212),
      filePath: '/music/resonance.mp3',
    ),
    Track(
      id: 'trk-2',
      title: 'Sunset',
      artist: 'The Midnight',
      album: 'Endless Summer',
      duration: Duration(seconds: 326),
      filePath: '/music/sunset.mp3',
    ),
  ];

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    engine = MockAudioEngine();
    queue = PlaybackQueueImpl();
    sleepTimer = SleepTimerServiceImpl();
    mockPlaylistsRepo = MockPlaylistsRepository();
    mockM3uService = MockM3uService();

    registerFallbackValue(testPlaylist);
    registerFallbackValue(testTracks);

    if (getIt.isRegistered<IPlaybackQueue>()) {
      getIt.unregister<IPlaybackQueue>();
    }
    if (getIt.isRegistered<IAudioEngine>()) {
      getIt.unregister<IAudioEngine>();
    }
    if (getIt.isRegistered<ISleepTimerService>()) {
      getIt.unregister<ISleepTimerService>();
    }

    await configureDependencies(
      audioEngine: engine,
      playbackQueue: queue,
      sleepTimerService: sleepTimer,
      seedDemoData: false,
    );
  });

  tearDown(() {
    engine.dispose();
    queue.dispose();
  });

  Widget buildSubject({Playlist? playlist}) {
    return ProviderScope(
      overrides: [
        playbackQueueProvider.overrideWithValue(queue),
        audioEngineProvider.overrideWithValue(engine),
        sleepTimerServiceProvider.overrideWithValue(sleepTimer),
        playlistsRepositoryProvider.overrideWithValue(mockPlaylistsRepo),
        m3uServiceProvider.overrideWithValue(mockM3uService),
        playlistTracksProvider((playlist ?? testPlaylist).id).overrideWith((ref) => Future.value(testTracks)),
      ],
      child: MaterialApp(
        home: PlaylistDetailScreen(playlist: playlist ?? testPlaylist),
      ),
    );
  }

  testWidgets('renders playlist header, track count, duration, and track tiles', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Synthwave Dreams'), findsNWidgets(2));
    expect(find.text('2 tracks • 9 mins'), findsOneWidget);
    expect(find.text('Play All'), findsOneWidget);
    expect(find.text('Shuffle'), findsOneWidget);
    expect(find.text('Resonance'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
  });

  testWidgets('Play All button initiates queue playback with first track', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Play All'));
    await tester.pumpAndSettle();

    expect(queue.state.currentTrack?.title, equals('Resonance'));
  });

  testWidgets('Shuffle button initiates queue playback in shuffle mode', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Shuffle'));
    await tester.pumpAndSettle();

    expect(queue.state.currentTrack?.title, equals('Resonance'));
  });

  testWidgets('Export M3U copies exported content to clipboard and shows SnackBar', (tester) async {
    when(() => mockM3uService.exportToM3u(any(), any()))
        .thenReturn('#EXTM3U\n#EXTINF:212,HOME - Resonance\n/music/resonance.mp3');

    // Setup clipboard mock
    final clipboardData = <Map<String, dynamic>>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall methodCall) async {
        if (methodCall.method == 'Clipboard.setData') {
          clipboardData.add(Map<String, dynamic>.from(methodCall.arguments as Map));
          return null;
        }
        return null;
      },
    );

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Tap Export M3U icon button in AppBar
    await tester.tap(find.byIcon(Icons.file_upload_outlined));
    await tester.pumpAndSettle();

    verify(() => mockM3uService.exportToM3u(testPlaylist, testTracks)).called(1);
    expect(find.textContaining('M3U playlist exported for "Synthwave Dreams"'), findsOneWidget);
    expect(clipboardData.isNotEmpty, isTrue);
    expect(clipboardData.last['text'], contains('#EXTM3U'));
  });

  testWidgets('Delete playlist shows confirmation dialog and executes deletion', (tester) async {
    when(() => mockPlaylistsRepo.deletePlaylist('pl-synth-1'))
        .thenAnswer((_) async => const Result.success(null));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Tap delete icon in AppBar
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to delete "Synthwave Dreams"? Audio tracks in your library will not be deleted.'), findsOneWidget);

    // Confirm Delete
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();

    verify(() => mockPlaylistsRepo.deletePlaylist('pl-synth-1')).called(1);
  });
}
