import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'package:nexa_player/core/services/artwork/artwork_resolution_service.dart';
import 'package:nexa_player/core/services/audio/audio_telemetry_service.dart';
import 'package:nexa_player/core/services/library/library_sync_bus.dart';
import 'package:nexa_player/features/equalizer/data/services/native_equalizer_bridge.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/equalizer/domain/services/equalizer_service.dart';
import 'package:nexa_player/features/lyrics/data/services/lrclib_api_client.dart';
import 'package:nexa_player/features/lyrics/data/services/lyrics_service_impl.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_albums_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_artists_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_folders_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_genres_repository.dart';
import 'package:nexa_player/features/library/data/repositories/sqlite_tracks_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/albums_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/artists_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/folders_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/genres_repository.dart';
import 'package:nexa_player/features/library/domain/repositories/tracks_repository.dart';
import 'package:nexa_player/features/player/data/services/just_audio_engine.dart';
import 'package:nexa_player/features/player/data/services/nexa_audio_handler.dart';
import 'package:nexa_player/features/player/data/services/playback_queue_impl.dart';
import 'package:nexa_player/features/player/data/services/sleep_timer_service_impl.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/playback_queue.dart';
import 'package:nexa_player/features/player/domain/services/queue_list_navigator.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_playlists_repository.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_smart_playlists_repository.dart';
import 'package:nexa_player/features/playlists/data/services/m3u_service_impl.dart';
import 'package:nexa_player/features/playlists/data/services/ringtone_service_impl.dart';
import 'package:nexa_player/features/playlists/data/services/share_service_impl.dart';
import 'package:nexa_player/features/playlists/data/services/tag_editor_service_impl.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/services/m3u_service.dart';
import 'package:nexa_player/features/playlists/domain/services/ringtone_service.dart';
import 'package:nexa_player/features/playlists/domain/services/share_service.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/features/scanner/data/media_scanner_service_impl.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/data/repositories/sqlite_scan_directories_repository.dart';
import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/features/scanner/domain/repositories/scan_directories_repository.dart';
import 'package:nexa_player/features/search/data/repositories/sqlite_search_repository.dart';
import 'package:nexa_player/features/search/domain/repositories/search_repository.dart';
import 'package:nexa_player/features/settings/data/services/settings_service_impl.dart';
import 'package:nexa_player/features/settings/domain/services/settings_service.dart';
import 'package:nexa_player/features/visualizer/domain/services/waveform_pre_processor.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/database/database_schema.dart';
import 'package:nexa_player/shared/services/logging/logging_service.dart';
import 'package:nexa_player/shared/services/logging/talker_logging_service.dart';
import 'package:nexa_player/shared/services/storage/shared_preferences_storage_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Configures core application dependencies in [getIt].
///
/// Accepts optional overrides for hermetic testing.
Future<void> configureDependencies({
  SharedPreferences? sharedPreferences,
  Talker? talker,
  IAppDatabase? appDatabase,
  IAudioMetadataReader? metadataReader,
  IMediaScannerService? scannerService,
  ITracksRepository? tracksRepository,
  IAlbumsRepository? albumsRepository,
  IArtistsRepository? artistsRepository,
  IGenresRepository? genresRepository,
  IFoldersRepository? foldersRepository,
  IPlaylistsRepository? playlistsRepository,
  IScanDirectoriesRepository? scanDirectoriesRepository,
  IAudioEngine? audioEngine,
  IPlaybackQueue? playbackQueue,
  ISleepTimerService? sleepTimerService,
  IEqualizerService? equalizerService,
  IM3uService? m3uService,
  ITagEditorService? tagEditorService,
  IRingtoneService? ringtoneService,
  IShareService? shareService,
  ILrclibApiClient? lrclibApiClient,
  ILyricsService? lyricsService,
  IWaveformPreProcessor? waveformPreProcessor,
  ISearchRepository? searchRepository,
  ISettingsService? settingsService,
  bool seedDemoData = false,
  bool initAudioService = false,
}) async {
  // 1. SharedPreferences instance
  final prefs = sharedPreferences ?? await SharedPreferences.getInstance();
  if (!getIt.isRegistered<SharedPreferences>()) {
    getIt.registerSingleton<SharedPreferences>(prefs);
  }

  // 2. Talker instance
  final talkerInstance = talker ?? Talker();
  if (!getIt.isRegistered<Talker>()) {
    getIt.registerSingleton<Talker>(talkerInstance);
  }

  // 3. ILoggingService
  if (!getIt.isRegistered<ILoggingService>()) {
    getIt.registerSingleton<ILoggingService>(
      TalkerLoggingService(talker: getIt<Talker>()),
    );
  }

  // 4. IStorageService
  if (!getIt.isRegistered<IStorageService>()) {
    getIt.registerSingleton<IStorageService>(
      SharedPreferencesStorageService(getIt<SharedPreferences>()),
    );
  }

  // 5. IAppDatabase
  if (!getIt.isRegistered<IAppDatabase>()) {
    if (appDatabase != null) {
      if (!getIt.isRegistered<IAppDatabase>()) {
        getIt.registerSingleton<IAppDatabase>(appDatabase);
      }
    } else {
      try {
        final db = await AppDatabase.open();
        if (!getIt.isRegistered<IAppDatabase>()) {
          getIt.registerSingleton<IAppDatabase>(db);
        } else {
          db.close();
        }
      } catch (_) {
        if (!getIt.isRegistered<IAppDatabase>()) {
          final db = AppDatabase.inMemory();
          if (!getIt.isRegistered<IAppDatabase>()) {
            getIt.registerSingleton<IAppDatabase>(db);
          } else {
            db.close();
          }
        }
      }
    }
  }

  final db = getIt<IAppDatabase>();

  // 6. IAudioMetadataReader & ArtworkResolutionService
  if (!getIt.isRegistered<IAudioMetadataReader>()) {
    getIt.registerSingleton<IAudioMetadataReader>(
      metadataReader ?? const PureDartAudioMetadataReader(),
    );
  }

  if (!getIt.isRegistered<IArtworkResolutionService>()) {
    getIt.registerSingleton<IArtworkResolutionService>(
      ArtworkResolutionService(
        metadataReader: getIt<IAudioMetadataReader>(),
        onTrackArtworkResolved: (track, resolvedPath) async {
          db.execute(
            'UPDATE ${DatabaseSchema.tableTracks} SET ${DatabaseSchema.colArtworkUri} = ? '
            'WHERE ${DatabaseSchema.colId} = ? AND (${DatabaseSchema.colArtworkUri} IS NULL OR ${DatabaseSchema.colArtworkUri} = ?);',
            [resolvedPath, track.id, ''],
          );
          if (track.albumId != null && track.albumId!.isNotEmpty) {
            db.execute(
              'UPDATE ${DatabaseSchema.tableAlbums} SET ${DatabaseSchema.colArtworkUri} = ? '
              'WHERE ${DatabaseSchema.colId} = ? AND (${DatabaseSchema.colArtworkUri} IS NULL OR ${DatabaseSchema.colArtworkUri} = ?);',
              [resolvedPath, track.albumId, ''],
            );
          } else if (track.album.isNotEmpty) {
            db.execute(
              'UPDATE ${DatabaseSchema.tableAlbums} SET ${DatabaseSchema.colArtworkUri} = ? '
              'WHERE ${DatabaseSchema.colTitle} = ? AND (${DatabaseSchema.colArtworkUri} IS NULL OR ${DatabaseSchema.colArtworkUri} = ?);',
              [resolvedPath, track.album, ''],
            );
          }
        },
        onAlbumArtworkResolved: (album, resolvedPath) async {
          db.execute(
            'UPDATE ${DatabaseSchema.tableAlbums} SET ${DatabaseSchema.colArtworkUri} = ? '
            'WHERE ${DatabaseSchema.colId} = ? AND (${DatabaseSchema.colArtworkUri} IS NULL OR ${DatabaseSchema.colArtworkUri} = ?);',
            [resolvedPath, album.id, ''],
          );
        },
      ),
    );
  }

  // 6b. AudioTelemetryService (backfills API 29 missing 0 KBPS tracks cleanly off UI thread)
  if (!getIt.isRegistered<IAudioTelemetryService>()) {
    final telemetry = AudioTelemetryService(database: db);
    getIt.registerSingleton<IAudioTelemetryService>(telemetry);
    unawaited(telemetry.backfillMissingTelemetry(batchLimit: 60));
  }

  if (!getIt.isRegistered<LibrarySyncBus>()) {
    getIt.registerSingleton<LibrarySyncBus>(LibrarySyncBus());
  }
  final syncBus = getIt<LibrarySyncBus>();

  // 7. IMediaScannerService
  if (!getIt.isRegistered<IMediaScannerService>()) {
    getIt.registerSingleton<IMediaScannerService>(
      scannerService ??
          MediaScannerServiceImpl(
            database: db,
            metadataReader: getIt<IAudioMetadataReader>(),
            artworkService: getIt<IArtworkResolutionService>(),
            syncBus: syncBus,
          ),
    );
  }

  // 8. Repositories
  if (!getIt.isRegistered<IScanDirectoriesRepository>()) {
    getIt.registerSingleton<IScanDirectoriesRepository>(
      scanDirectoriesRepository ?? SqliteScanDirectoriesRepository(db),
    );
  }

  if (!getIt.isRegistered<ITracksRepository>()) {
    getIt.registerSingleton<ITracksRepository>(
      tracksRepository ?? SqliteTracksRepository(db, syncBus: syncBus),
    );
  }

  if (!getIt.isRegistered<IAlbumsRepository>()) {
    getIt.registerSingleton<IAlbumsRepository>(
      albumsRepository ?? SqliteAlbumsRepository(db),
    );
  }

  if (!getIt.isRegistered<IArtistsRepository>()) {
    getIt.registerSingleton<IArtistsRepository>(
      artistsRepository ?? SqliteArtistsRepository(db),
    );
  }

  if (!getIt.isRegistered<IGenresRepository>()) {
    getIt.registerSingleton<IGenresRepository>(
      genresRepository ?? SqliteGenresRepository(db),
    );
  }

  if (!getIt.isRegistered<IFoldersRepository>()) {
    getIt.registerSingleton<IFoldersRepository>(
      foldersRepository ?? SqliteFoldersRepository(db),
    );
  }

  if (!getIt.isRegistered<IPlaylistsRepository>()) {
    getIt.registerSingleton<IPlaylistsRepository>(
      playlistsRepository ?? SqlitePlaylistsRepository(db),
    );
  }

  if (!getIt.isRegistered<ISmartPlaylistsRepository>()) {
    getIt.registerSingleton<ISmartPlaylistsRepository>(
      SqliteSmartPlaylistsRepository(db),
    );
  }

  if (!getIt.isRegistered<ISearchRepository>()) {
    getIt.registerSingleton<ISearchRepository>(
      searchRepository ??
          SqliteSearchRepository(
            database: db,
            storage: getIt<IStorageService>(),
          ),
    );
  }

  // 9. Audio Engine & Playback Services
  if (!getIt.isRegistered<IAudioEngine>()) {
    getIt.registerSingleton<IAudioEngine>(
      audioEngine ?? JustAudioEngine(),
    );
  }

  if (!getIt.isRegistered<IPlaybackQueue>()) {
    getIt.registerSingleton<IPlaybackQueue>(
      playbackQueue ?? PlaybackQueueImpl(),
    );
  }

  if (!getIt.isRegistered<IQueueListNavigator>()) {
    getIt.registerSingleton<IQueueListNavigator>(
      LibraryQueueListNavigator(
        foldersRepository: getIt<IFoldersRepository>(),
        tracksRepository: getIt<ITracksRepository>(),
        albumsRepository: getIt<IAlbumsRepository>(),
        artistsRepository: getIt<IArtistsRepository>(),
        playlistsRepository: getIt<IPlaylistsRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<ISleepTimerService>()) {
    getIt.registerSingleton<ISleepTimerService>(
      sleepTimerService ??
          SleepTimerServiceImpl(
            onVolumeFade: (multiplier) {
              if (getIt.isRegistered<IAudioEngine>()) {
                getIt<IAudioEngine>().setVolume(multiplier);
              }
            },
          ),
    );
  }

  if (!getIt.isRegistered<NexaAudioHandler>()) {
    final handler = NexaAudioHandler(
      engine: getIt<IAudioEngine>(),
      queue: getIt<IPlaybackQueue>(),
      tracksRepository: getIt<ITracksRepository>(),
      playlistsRepository: getIt<IPlaylistsRepository>(),
      searchRepository: getIt<ISearchRepository>(),
      artworkResolver: getIt<IArtworkResolutionService>(),
      storageService: getIt<IStorageService>(),
    );
    if (initAudioService &&
        (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      try {
        final initializedHandler = await AudioService.init<NexaAudioHandler>(
          builder: () => handler,
          config: nexaAudioServiceConfig,
        );
        getIt.registerSingleton<NexaAudioHandler>(initializedHandler);
      } catch (e, st) {
        getIt<ILoggingService>().error(
          'AudioService.init failed; falling back to local handler',
          e,
          st,
        );
        getIt.registerSingleton<NexaAudioHandler>(handler);
      }
    } else {
      getIt.registerSingleton<NexaAudioHandler>(handler);
    }
  }

  // 10. Equalizer & DSP Service
  if (!getIt.isRegistered<IEqualizerService>()) {
    final audioEngine =
        getIt.isRegistered<IAudioEngine>() ? getIt<IAudioEngine>() : null;
    final dspBridge = (Platform.isAndroid &&
            audioEngine is IAudioSessionProvider)
        ? AndroidEqualizerDspBridge(
            audioSessionProvider: audioEngine as IAudioSessionProvider,
          )
        : null;
    final eq = equalizerService ??
        PureDartEqualizerService(
          storageService: getIt.isRegistered<IStorageService>()
              ? getIt<IStorageService>()
              : null,
          dspBridge: dspBridge,
        );
    await eq.initialize();
    getIt.registerSingleton<IEqualizerService>(eq);
  }

  // 11. Playlist & Track Operations Services
  if (!getIt.isRegistered<IM3uService>()) {
    getIt.registerSingleton<IM3uService>(
      m3uService ??
          M3uServiceImpl(
            playlistsRepository: getIt<IPlaylistsRepository>(),
            tracksRepository: getIt<ITracksRepository>(),
          ),
    );
  }

  if (!getIt.isRegistered<ITagEditorService>()) {
    getIt.registerSingleton<ITagEditorService>(
      tagEditorService ??
          TagEditorServiceImpl(
            getIt<IAppDatabase>(),
            syncBus: syncBus,
          ),
    );
  }

  if (!getIt.isRegistered<IRingtoneService>()) {
    getIt.registerSingleton<IRingtoneService>(
      ringtoneService ?? RingtoneServiceImpl(),
    );
  }

  if (!getIt.isRegistered<IShareService>()) {
    getIt.registerSingleton<IShareService>(
      shareService ?? const ShareServiceImpl(),
    );
  }

  // 12. Lyrics Services
  if (!getIt.isRegistered<ILrclibApiClient>()) {
    getIt.registerSingleton<ILrclibApiClient>(
      lrclibApiClient ?? LrclibApiClient(),
    );
  }

  if (!getIt.isRegistered<ILyricsService>()) {
    getIt.registerSingleton<ILyricsService>(
      lyricsService ??
          LyricsServiceImpl(
            storageService: getIt<IStorageService>(),
            lrclibClient: getIt<ILrclibApiClient>(),
          ),
    );
  }

  // 13. Visualizer Waveform Pre-processor
  if (!getIt.isRegistered<IWaveformPreProcessor>()) {
    getIt.registerSingleton<IWaveformPreProcessor>(
      waveformPreProcessor ??
          WaveformPreProcessorImpl(
            getIt<IStorageService>(),
            database: db,
          ),
    );
  }

  // 14. Settings Service
  if (!getIt.isRegistered<ISettingsService>()) {
    getIt.registerSingleton<ISettingsService>(
      settingsService ?? SettingsServiceImpl(getIt<IStorageService>()),
    );
  }

  // 15. Seed demo library if database is freshly opened and empty (or purge fake demo data if disabled)
  if (!db.isClosed) {
    if (seedDemoData) {
      _seedDemoData(db);
    } else {
      _purgeMockDataIfPresent(db, getIt<SharedPreferences>());
    }
  }
}

void _purgeMockDataIfPresent(IAppDatabase db, SharedPreferences prefs) {
  try {
    const key = 'demo_purged_v1';
    if (prefs.getBool(key) == true) return;

    db.transaction(() {
      final rows = db.select(
        "SELECT id, file_path FROM tracks WHERE id LIKE 'trk-%' OR file_path LIKE '/storage/emulated/0/Music/Pop/%'",
      );
      final tracksToDelete = <String>[];
      for (final row in rows) {
        final path = row['file_path'] as String?;
        final id = row['id'] as String;
        if (path == null || !File(path).existsSync()) {
          tracksToDelete.add(id);
        }
      }

      if (tracksToDelete.isNotEmpty) {
        final inClause = tracksToDelete.map((id) => "'$id'").join(',');
        db.execute('DELETE FROM playlist_tracks WHERE track_id IN ($inClause);');
        db.execute('DELETE FROM tracks WHERE id IN ($inClause);');
      }

      // Sweep orphaned demo albums
      db.execute('''
        DELETE FROM albums WHERE id IN ('alb-ram', 'alb-starboy', 'alb-currents', 'alb-hurry-up', 'alb-after-hours')
        AND title NOT IN (SELECT DISTINCT album FROM tracks WHERE album IS NOT NULL);
      ''');

      // Sweep orphaned demo artists
      db.execute('''
        DELETE FROM artists WHERE id IN ('art-daft-punk', 'art-the-weeknd', 'art-tame-impala', 'art-m83')
        AND name NOT IN (SELECT DISTINCT artist FROM tracks WHERE artist IS NOT NULL);
      ''');
    });

    prefs.setBool(key, true);
  } catch (_) {
    // Gracefully ignore if tables are not initialized
  }
}

void _seedDemoData(IAppDatabase db) {
  try {
    final albumCount = (db.select('SELECT COUNT(*) as count FROM albums').first['count'] as int?) ?? 0;
    if (albumCount > 0) return;

    db.transaction(() {
      db.execute('''
        INSERT INTO artists (id, name, track_count, album_count)
        VALUES ('art-daft-punk', 'Daft Punk', 24, 4),
               ('art-the-weeknd', 'The Weeknd', 32, 5),
               ('art-tame-impala', 'Tame Impala', 18, 3),
               ('art-m83', 'M83', 15, 2)
        ON CONFLICT(name) DO NOTHING;
      ''');

      db.execute('''
        INSERT INTO albums (id, title, artist, year, track_count)
        VALUES ('alb-ram', 'Random Access Memories', 'Daft Punk', 2013, 13),
               ('alb-starboy', 'Starboy', 'The Weeknd', 2016, 18),
               ('alb-currents', 'Currents', 'Tame Impala', 2015, 13),
               ('alb-hurry-up', 'Hurry Up, We''re Dreaming', 'M83', 2011, 22),
               ('alb-after-hours', 'After Hours', 'The Weeknd', 2020, 14)
        ON CONFLICT(title, artist) DO NOTHING;
      ''');

      db.execute('''
        INSERT INTO tracks (id, title, artist, album, duration_ms, file_path, track_number, year, is_favorite, date_added)
        VALUES ('trk-1', 'Starboy', 'The Weeknd • Daft Punk', 'Starboy', 230000, '/storage/emulated/0/Music/Pop/Starboy.mp3', 1, 2016, 1, 1000),
               ('trk-2', 'Get Lucky', 'Daft Punk • Pharrell Williams', 'Random Access Memories', 248000, '/storage/emulated/0/Music/Electronic/Get Lucky.mp3', 2, 2013, 1, 2000),
               ('trk-3', 'Midnight City', 'M83', 'Hurry Up, We''re Dreaming', 243000, '/storage/emulated/0/Music/Synthwave/Midnight City.mp3', 3, 2011, 0, 3000),
               ('trk-4', 'The Less I Know The Better', 'Tame Impala', 'Currents', 216000, '/storage/emulated/0/Music/Indie/The Less I Know.mp3', 4, 2015, 0, 4000),
               ('trk-5', 'Blinding Lights', 'The Weeknd', 'After Hours', 200000, '/storage/emulated/0/Music/Pop/Blinding Lights.mp3', 5, 2020, 1, 5000),
               ('trk-6', 'Instant Crush', 'Daft Punk • Julian Casablancas', 'Random Access Memories', 337000, '/storage/emulated/0/Music/Electronic/Instant Crush.mp3', 5, 2013, 1, 6000),
               ('trk-7', 'Lose Yourself to Dance', 'Daft Punk • Pharrell Williams', 'Random Access Memories', 353000, '/storage/emulated/0/Music/Electronic/Lose Yourself.mp3', 6, 2013, 0, 7000),
               ('trk-8', 'Save Your Tears', 'The Weeknd', 'After Hours', 215000, '/storage/emulated/0/Music/Pop/Save Your Tears.mp3', 11, 2020, 1, 8000)
        ON CONFLICT(file_path) DO NOTHING;
      ''');

      db.execute('''
        INSERT INTO playlists (id, name, created_at, updated_at, track_count)
        VALUES ('pl-smart', 'Smart Playlists', 1000, 1000, 3),
               ('pl-favorites', 'Favorites', 2000, 2000, 4)
        ON CONFLICT(id) DO NOTHING;
      ''');

      db.execute('''
        INSERT INTO playlist_tracks (playlist_id, track_id, position, added_at)
        VALUES ('pl-smart', 'trk-1', 1, 1000),
               ('pl-smart', 'trk-2', 2, 2000),
               ('pl-smart', 'trk-5', 3, 3000),
               ('pl-favorites', 'trk-1', 1, 1000),
               ('pl-favorites', 'trk-2', 2, 2000),
               ('pl-favorites', 'trk-5', 3, 3000),
               ('pl-favorites', 'trk-6', 4, 4000)
        ON CONFLICT(playlist_id, track_id, position) DO NOTHING;
      ''');

      db.execute('''
        INSERT INTO scan_directories (id, path, is_active, last_scanned, file_count)
        VALUES ('sd-1', '/storage/emulated/0/Music', 1, 1715000000000, 240),
               ('sd-2', '/storage/emulated/0/Download', 1, 1715000000000, 45),
               ('sd-3', '/storage/emulated/0/Podcasts', 0, 0, 0)
        ON CONFLICT(path) DO NOTHING;
      ''');
    });
  } catch (_) {
    // Gracefully ignore if tables are not initialized
  }
}

/// Clears all registrations in [getIt]. Used for test isolation.
Future<void> resetDependencies() async {
  if (getIt.isRegistered<IAppDatabase>()) {
    final db = getIt<IAppDatabase>();
    if (!db.isClosed) {
      db.close();
    }
  }
  await getIt.reset();
}
