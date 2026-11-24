import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexa_player/core/constants/phase2_keys.dart';
import 'package:nexa_player/core/utils/storage_path_formatter.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/presentation/providers/library_providers.dart';
import 'package:nexa_player/features/library/presentation/screens/folders_tab_screen.dart';

void main() {
  group('HW-v1.1.1 PR 2/5 (DEF-06) — StoragePathFormatter Unit Tests', () {
    test('normalizes internal emulated storage paths into Internal breadcrumbs', () {
      expect(
        StoragePathFormatter.formatBreadcrumb('/storage/emulated/0/Music/Rock'),
        equals('Internal › Music › Rock'),
      );
      expect(
        StoragePathFormatter.formatBreadcrumb('/storage/emulated/0/Download'),
        equals('Internal › Download'),
      );
      expect(
        StoragePathFormatter.formatBreadcrumb('/storage/emulated/0'),
        equals('Internal'),
      );
    });

    test('normalizes legacy /sdcard symlink to Internal breadcrumbs', () {
      expect(
        StoragePathFormatter.formatBreadcrumb('/sdcard/Music/Pop'),
        equals('Internal › Music › Pop'),
      );
      expect(
        StoragePathFormatter.formatBreadcrumb('/sdcard'),
        equals('Internal'),
      );
    });

    test('normalizes removable MicroSD volume IDs into SD Card breadcrumbs', () {
      expect(
        StoragePathFormatter.formatBreadcrumb('/storage/9C33-6BBD/FLAC'),
        equals('SD Card › FLAC'),
      );
      expect(
        StoragePathFormatter.formatBreadcrumb('/storage/ABCD-1234/HiRes/Audio'),
        equals('SD Card › HiRes › Audio'),
      );
      expect(
        StoragePathFormatter.formatBreadcrumb('/storage/1234-5678'),
        equals('SD Card'),
      );
    });

    test('correctly breaks path into individual segments', () {
      final segments = StoragePathFormatter.toSegments('/storage/emulated/0/Music/Jazz/BeBop');
      expect(segments, equals(['Internal', 'Music', 'Jazz', 'BeBop']));

      final sdSegments = StoragePathFormatter.toSegments('/storage/9C33-6BBD/FLAC/Miles');
      expect(sdSegments, equals(['SD Card', 'FLAC', 'Miles']));
    });
  });

  group('HW-v1.1.1 PR 2/5 (DEF-06) — FoldersTabScreen Widget Tests', () {
    testWidgets('renders empty-state onboarding card when no folders are indexed', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foldersTreeProvider(const []).overrideWith((ref) => Future.value([])),
          ],
          child: const MaterialApp(
            home: FoldersTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No Audio Folders Found'), findsOneWidget);
      expect(find.text('Grant Access & Scan Library'), findsOneWidget);
      expect(find.byKey(Phase2Keys.tabFolders), findsOneWidget);
      expect(find.byKey(Phase2Keys.tabSongs), findsOneWidget);
    });

    testWidgets('renders indexed folder tree with normalized breadcrumbs and file items', (tester) async {
      final mockFolders = [
        const FolderNode(
          path: '/storage/emulated/0/Music/Rock',
          name: 'Rock',
          files: [
            FileNode(
              path: '/storage/emulated/0/Music/Rock/track1.flac',
              name: 'track1.flac',
              trackId: 'trk-1',
              fileSize: 25000000,
            ),
          ],
        ),
        const FolderNode(
          path: '/storage/9C33-6BBD/FLAC',
          name: 'FLAC',
          files: [
            FileNode(
              path: '/storage/9C33-6BBD/FLAC/audiophile.wav',
              name: 'audiophile.wav',
              trackId: 'trk-2',
              fileSize: 45000000,
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            foldersTreeProvider(const []).overrideWith((ref) => Future.value(mockFolders)),
          ],
          child: const MaterialApp(
            home: FoldersTabScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Phase2Keys.foldersTreeView), findsOneWidget);
      expect(find.text('Rock'), findsOneWidget);
      expect(find.text('Internal › Music › Rock'), findsOneWidget);
      expect(find.text('FLAC'), findsWidgets);
      expect(find.text('SD Card › FLAC'), findsOneWidget);
      // Root shows folders only (no auto-expanded songs until tapped)
      expect(find.text('track1.flac'), findsNothing);
      expect(find.text('audiophile.wav'), findsNothing);

      // Tapping Rock reveals its direct track
      await tester.tap(find.text('Rock'));
      await tester.pumpAndSettle();
      expect(find.text('track1.flac'), findsOneWidget);
      expect(find.text('audiophile.wav'), findsNothing);

      // Navigating back and tapping FLAC reveals audiophile.wav
      await tester.tap(find.byKey(const ValueKey('folder_navigate_up_btn')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('FLAC'));
      await tester.pumpAndSettle();
      expect(find.text('audiophile.wav'), findsOneWidget);
    });

    testWidgets('responsive layout renders without overflow at 360x780, 412x915, and 1280x800', (tester) async {
      final mockFolders = [
        const FolderNode(
          path: '/storage/emulated/0/Music/Rock',
          name: 'Rock',
          files: [
            FileNode(
              path: '/storage/emulated/0/Music/Rock/track1.flac',
              name: 'track1.flac',
              trackId: 'trk-1',
            ),
          ],
        ),
      ];

      final testSizes = [
        const Size(360, 780),
        const Size(412, 915),
        const Size(1280, 800),
      ];

      for (final size in testSizes) {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              foldersTreeProvider(const []).overrideWith((ref) => Future.value(mockFolders)),
            ],
            child: const MaterialApp(
              home: FoldersTabScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byKey(Phase2Keys.tabFolders), findsOneWidget);
      }
    });
  });
}
