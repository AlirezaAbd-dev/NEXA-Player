import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/models/ringtone_trim_range.dart';
import 'package:nexa_player/features/playlists/domain/services/ringtone_service.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/screens/ringtone_trimmer_screen.dart';
import 'package:nexa_player/shared/models/track.dart';

class MockRingtoneService extends Mock implements IRingtoneService {}

void main() {
  late MockRingtoneService mockRingtoneService;

  const testTrack = Track(
    id: 'track-trim-99',
    title: 'Cyberpunk Odyssey',
    artist: 'Synth Master',
    duration: Duration(seconds: 120),
    filePath: '/storage/music/cyberpunk.mp3',
  );

  setUp(() {
    mockRingtoneService = MockRingtoneService();
    registerFallbackValue(testTrack);
    registerFallbackValue(const RingtoneTrimRange(startMs: 0, endMs: 30000));
    registerFallbackValue(RingtoneTarget.ringtone);
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        ringtoneServiceProvider.overrideWithValue(mockRingtoneService),
      ],
      child: const MaterialApp(
        home: RingtoneTrimmerScreen(track: testTrack),
      ),
    );
  }

  testWidgets('renders track title, time readouts, and destination targets', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.text('Ringtone Trimmer'), findsOneWidget);
    expect(find.textContaining('Cyberpunk Odyssey'), findsOneWidget);
    expect(find.textContaining('Synth Master'), findsOneWidget);
    expect(find.text('Phone Ringtone'), findsOneWidget);
    expect(find.text('Notification Sound'), findsOneWidget);
    expect(find.text('Alarm Clock'), findsOneWidget);
    expect(find.text('Custom Audio File'), findsOneWidget);
    expect(find.text('Set as Phone Ringtone'), findsOneWidget);
  });

  testWidgets('toggles audition preview state when play button is pressed', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.pause_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause_rounded));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });

  testWidgets('changes target to Alarm Clock and triggers export', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockRingtoneService.trimAudio(
      track: any(named: 'track'),
      range: any(named: 'range'),
      target: RingtoneTarget.alarm,
    )).thenAnswer((_) async => const Result.success('/storage/ringtones/alarm.mp3'));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    // Select Alarm Clock
    await tester.tap(find.text('Alarm Clock'));
    await tester.pumpAndSettle();

    expect(find.text('Set as Alarm Clock'), findsOneWidget);

    // Tap Export button
    await tester.tap(find.text('Set as Alarm Clock'));
    await tester.pumpAndSettle();

    verify(() => mockRingtoneService.trimAudio(
      track: any(named: 'track'),
      range: any(named: 'range'),
      target: RingtoneTarget.alarm,
    )).called(1);

    expect(find.textContaining('Alarm Clock exported successfully!'), findsOneWidget);
  });
}
