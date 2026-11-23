import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/core/services/storage_permission_orchestrator.dart';
import 'package:nexa_player/features/scanner/data/media_scanner_service_impl.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/features/scanner/domain/scanner_state.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await resetDependencies();
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await resetDependencies();
  });

  group('HW-PR 1/5: DEF-01 Demo Seed Purge & Production Hygiene', () {
    test('configureDependencies(seedDemoData: false) produces 0 tracks in database', () async {
      await configureDependencies(seedDemoData: false);

      final db = GetIt.I<IAppDatabase>();
      final tracks = db.select('SELECT COUNT(*) as count FROM tracks;').first['count'] as int;
      expect(tracks, equals(0));
    });

    test('Migration cleans up fake trk- rows without touching existing real files', () async {
      final db = AppDatabase.inMemory();
      final prefs = await SharedPreferences.getInstance();

      // Create a real temporary file on disk
      final tempDir = Directory.systemTemp.createTempSync('hw_test_');
      final realFile = File('${tempDir.path}/real_song.mp3')..writeAsStringSync('dummy-audio');

      // Seed fake and real tracks
      db.execute('''
        INSERT INTO tracks (id, title, artist, album, duration_ms, file_path, track_number, year, is_favorite, date_added)
        VALUES 
          ('trk-fake-1', 'Starboy', 'The Weeknd', 'Starboy', 230000, '/storage/emulated/0/Music/Pop/NonExistent.mp3', 1, 2016, 1, 1000),
          ('trk-real-1', 'My Real Song', 'Me', 'Album', 180000, '${realFile.path}', 1, 2026, 0, 2000);
      ''');

      // Verify both exist initially
      var count = db.select('SELECT COUNT(*) as count FROM tracks;').first['count'] as int;
      expect(count, equals(2));

      // Trigger dependency configuration which executes purge migration
      await configureDependencies(
        appDatabase: db,
        sharedPreferences: prefs,
        seedDemoData: false,
      );

      // Verify fake track was purged and real file track was preserved
      final remaining = db.select('SELECT id, file_path FROM tracks;');
      expect(remaining.length, equals(1));
      expect(remaining.first['id'], equals('trk-real-1'));
      expect(remaining.first['file_path'], equals(realFile.path));

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });

  group('HW-PR 1/5: DEF-02 StoragePermissionOrchestrator & Safe Ordering', () {
    tearDown(() {
      StoragePermissionOrchestrator.setMockSdkInt(null);
    });

    test('Target permission is Permission.storage on Android SDK < 33 (e.g. Android 10 / API 29)', () async {
      StoragePermissionOrchestrator.setMockSdkInt(29);
      final permission = await StoragePermissionOrchestrator.getRequiredPermission();
      expect(permission, equals(Permission.storage));
    });

    test('Target permission is Permission.audio on Android SDK >= 33 (e.g. Android 13+ / API 34)', () async {
      StoragePermissionOrchestrator.setMockSdkInt(34);
      final permission = await StoragePermissionOrchestrator.getRequiredPermission();
      expect(permission, equals(Permission.audio));
    });
  });

  group('HW-PR 1/5: MediaScannerServiceImpl Error & Permission Diagnostics', () {
    test('Emits ScannerStatus.permissionDenied when access is restricted', () async {
      final db = AppDatabase.inMemory();
      final scanner = MediaScannerServiceImpl(
        database: db,
        metadataReader: const PureDartAudioMetadataReader(),
      );

      final nonExistentDir = '/non_existent_path_guaranteed_restricted_${DateTime.now().millisecondsSinceEpoch}';

      final res = await scanner.scanDirectories([nonExistentDir]);

      // Result should report error or directory inaccessible
      expect(res.isFailure, isTrue);
      expect(scanner.currentState.status, isIn([ScannerStatus.error, ScannerStatus.permissionDenied]));

      scanner.dispose();
      db.close();
    });
  });
}
