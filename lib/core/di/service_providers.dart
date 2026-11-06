import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
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
