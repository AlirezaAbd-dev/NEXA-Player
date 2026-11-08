import 'package:get_it/get_it.dart';
import 'package:nexa_player/features/equalizer/data/services/pure_dart_equalizer_service.dart';
import 'package:nexa_player/features/equalizer/domain/services/equalizer_service.dart';
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
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/playlists/data/repositories/sqlite_playlists_repository.dart';
import 'package:nexa_player/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:nexa_player/features/scanner/data/media_scanner_service_impl.dart';
import 'package:nexa_player/features/scanner/data/pure_dart_audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/data/repositories/sqlite_scan_directories_repository.dart';
import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/features/scanner/domain/repositories/scan_directories_repository.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
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
  bool seedDemoData = true,
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

  // 6. IAudioMetadataReader
  if (!getIt.isRegistered<IAudioMetadataReader>()) {
    getIt.registerSingleton<IAudioMetadataReader>(
      metadataReader ?? const PureDartAudioMetadataReader(),
    );
  }

  // 7. IMediaScannerService
  if (!getIt.isRegistered<IMediaScannerService>()) {
    getIt.registerSingleton<IMediaScannerService>(
      scannerService ??
          MediaScannerServiceImpl(
            database: db,
            metadataReader: getIt<IAudioMetadataReader>(),
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
      tracksRepository ?? SqliteTracksRepository(db),
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
    getIt.registerSingleton<NexaAudioHandler>(
      NexaAudioHandler(
        engine: getIt<IAudioEngine>(),
        queue: getIt<IPlaybackQueue>(),
      ),
    );
  }

  // 10. Equalizer & DSP Service
  if (!getIt.isRegistered<IEqualizerService>()) {
    final eq = equalizerService ??
        PureDartEqualizerService(
          storageService: getIt.isRegistered<IStorageService>()
              ? getIt<IStorageService>()
              : null,
        );
    await eq.initialize();
    getIt.registerSingleton<IEqualizerService>(eq);
  }

  // 11. Seed demo library if database is freshly opened and empty
  if (seedDemoData && !db.isClosed) {
    _seedDemoData(db);
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
