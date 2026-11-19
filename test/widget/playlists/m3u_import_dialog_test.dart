import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/playlists/domain/services/m3u_service.dart';
import 'package:nexa_player/features/playlists/presentation/providers/playlists_providers.dart';
import 'package:nexa_player/features/playlists/presentation/widgets/m3u_import_dialog.dart';
import 'package:nexa_player/shared/models/playlist.dart';

class MockM3uService extends Mock implements IM3uService {}

void main() {
  late MockM3uService mockM3uService;

  final testPlaylist = Playlist(
    id: 'pl-imported-1',
    name: 'Lo-Fi Study',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    trackCount: 4,
  );

  setUp(() {
    mockM3uService = MockM3uService();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        m3uServiceProvider.overrideWithValue(mockM3uService),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => M3uImportDialog.show(context),
                child: const Text('Open Import Dialog'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders dialog title, input fields, and action buttons', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Import Dialog'));
    await tester.pumpAndSettle();

    expect(find.text('Import M3U Playlist'), findsOneWidget);
    expect(find.text('PLAYLIST NAME'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Import'), findsOneWidget);
  });

  testWidgets('shows validation error when content is empty', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Import Dialog'));
    await tester.pumpAndSettle();

    // Click Import without content
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(find.text('Please paste M3U playlist content'), findsOneWidget);
    verifyNever(() => mockM3uService.importM3u(any(), any()));
  });

  testWidgets('imports M3U playlist successfully and shows SnackBar', (tester) async {
    when(() => mockM3uService.importM3u('Lo-Fi Study', any()))
        .thenAnswer((_) async => Result.success(testPlaylist));

    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Import Dialog'));
    await tester.pumpAndSettle();

    // Change name
    final nameFinder = find.widgetWithText(TextField, 'Imported Playlist');
    await tester.enterText(nameFinder, 'Lo-Fi Study');
    await tester.pumpAndSettle();

    // Enter M3U content into the multi-line text field
    final contentFinder = find.byWidgetPredicate(
      (w) => w is TextField && w.maxLines == 6,
    );
    await tester.enterText(contentFinder, '#EXTM3U\n/music/lofi.mp3');
    await tester.pumpAndSettle();

    // Tap Import
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    verify(() => mockM3uService.importM3u('Lo-Fi Study', '#EXTM3U\n/music/lofi.mp3')).called(1);
    expect(find.text('Imported playlist "Lo-Fi Study" successfully'), findsOneWidget);
  });
}
