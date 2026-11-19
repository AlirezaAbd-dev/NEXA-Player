import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/equalizer/domain/services/equalizer_service.dart';
import 'package:nexa_player/features/lyrics/data/services/lrclib_api_client.dart';
import 'package:nexa_player/features/lyrics/domain/services/lyrics_service.dart';
import 'package:nexa_player/features/player/data/services/nexa_audio_handler.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/playback_queue.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
import 'package:nexa_player/features/playlists/domain/services/m3u_service.dart';
import 'package:nexa_player/features/playlists/domain/services/ringtone_service.dart';
import 'package:nexa_player/features/playlists/domain/services/share_service.dart';
import 'package:nexa_player/features/playlists/domain/services/tag_editor_service.dart';
import 'package:nexa_player/features/search/domain/repositories/search_repository.dart';
import 'package:nexa_player/shared/services/database/app_database.dart';
import 'package:nexa_player/shared/services/logging/logging_service.dart';
import 'package:nexa_player/shared/services/storage/storage_service.dart';
import 'package:talker_flutter/talker_flutter.dart';

/// Exposes the [Talker] instance to Riverpod.
final talkerProvider = Provider<Talker>((ref) {
  return getIt<Talker>();
});

/// Exposes the [ILoggingService] interface to Riverpod.
final loggingServiceProvider = Provider<ILoggingService>((ref) {
  return getIt<ILoggingService>();
});

/// Exposes the [IStorageService] interface to Riverpod.
final storageServiceProvider = Provider<IStorageService>((ref) {
  return getIt<IStorageService>();
});

/// Exposes the [IAppDatabase] interface to Riverpod.
final appDatabaseProvider = Provider<IAppDatabase>((ref) {
  return getIt<IAppDatabase>();
});

/// Exposes the [IAudioEngine] interface to Riverpod.
final audioEngineProvider = Provider<IAudioEngine>((ref) {
  return getIt<IAudioEngine>();
});

/// Exposes the [IPlaybackQueue] interface to Riverpod.
final playbackQueueProvider = Provider<IPlaybackQueue>((ref) {
  return getIt<IPlaybackQueue>();
});

/// Exposes the [ISleepTimerService] interface to Riverpod.
final sleepTimerServiceProvider = Provider<ISleepTimerService>((ref) {
  return getIt<ISleepTimerService>();
});

/// Exposes the [NexaAudioHandler] background service to Riverpod.
final nexaAudioHandlerProvider = Provider<NexaAudioHandler>((ref) {
  return getIt<NexaAudioHandler>();
});

/// Exposes the [IEqualizerService] interface to Riverpod.
final equalizerServiceProvider = Provider<IEqualizerService>((ref) {
  return getIt<IEqualizerService>();
});

/// Exposes the [IM3uService] interface to Riverpod.
final m3uServiceProvider = Provider<IM3uService>((ref) {
  return getIt<IM3uService>();
});

/// Exposes the [ITagEditorService] interface to Riverpod.
final tagEditorServiceProvider = Provider<ITagEditorService>((ref) {
  return getIt<ITagEditorService>();
});

/// Exposes the [IRingtoneService] interface to Riverpod.
final ringtoneServiceProvider = Provider<IRingtoneService>((ref) {
  return getIt<IRingtoneService>();
});

/// Exposes the [IShareService] interface to Riverpod.
final shareServiceProvider = Provider<IShareService>((ref) {
  return getIt<IShareService>();
});

/// Exposes the [ILrclibApiClient] interface to Riverpod.
final lrclibApiClientProvider = Provider<ILrclibApiClient>((ref) {
  return getIt<ILrclibApiClient>();
});

/// Exposes the [ILyricsService] interface to Riverpod.
final lyricsServiceProvider = Provider<ILyricsService>((ref) {
  return getIt<ILyricsService>();
});

/// Exposes the [ISearchRepository] interface to Riverpod.
final searchRepositoryProvider = Provider<ISearchRepository>((ref) {
  return getIt<ISearchRepository>();
});



