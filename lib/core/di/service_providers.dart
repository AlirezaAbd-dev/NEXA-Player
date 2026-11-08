import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/equalizer/domain/services/equalizer_service.dart';
import 'package:nexa_player/features/player/data/services/nexa_audio_handler.dart';
import 'package:nexa_player/features/player/domain/services/audio_engine.dart';
import 'package:nexa_player/features/player/domain/services/playback_queue.dart';
import 'package:nexa_player/features/player/domain/services/sleep_timer_service.dart';
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


