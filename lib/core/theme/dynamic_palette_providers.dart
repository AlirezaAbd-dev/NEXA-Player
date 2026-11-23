import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/di/injection.dart';
import '../../core/di/service_providers.dart';
import '../../features/player/presentation/providers/player_providers.dart';
import '../../shared/services/storage/storage_service.dart';
import 'dynamic_palette_service.dart';

/// Exposes the [DynamicPaletteService] singleton.
final dynamicPaletteServiceProvider = Provider<DynamicPaletteService>((ref) {
  return const DynamicPaletteService();
});

/// Notifier managing whether dynamic album art color adaptation is enabled.
class DynamicThemeNotifier extends StateNotifier<bool> {
  DynamicThemeNotifier(this._ref) : super(true) {
    _load();
  }

  final Ref _ref;

  void _load() {
    if (!getIt.isRegistered<IStorageService>()) {
      state = true;
      return;
    }
    final storage = _ref.read(storageServiceProvider);
    final res = storage.getBool(StorageKeys.dynamicAlbumArtTheme);
    final value = res.valueOrNull;
    state = value ?? true;
  }

  Future<void> toggle() async {
    state = !state;
    if (getIt.isRegistered<IStorageService>()) {
      final storage = _ref.read(storageServiceProvider);
      await storage.setBool(StorageKeys.dynamicAlbumArtTheme, state);
    }
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    if (getIt.isRegistered<IStorageService>()) {
      final storage = _ref.read(storageServiceProvider);
      await storage.setBool(StorageKeys.dynamicAlbumArtTheme, enabled);
    }
  }
}

/// Provider for dynamic album art theme state toggle.
final dynamicThemeEnabledProvider =
    StateNotifierProvider<DynamicThemeNotifier, bool>((ref) {
  return DynamicThemeNotifier(ref);
});

/// Computes the [ExtractedPalette] asynchronously when the track changes.
final activeDynamicPaletteFutureProvider =
    FutureProvider.autoDispose<ExtractedPalette>((ref) async {
  final isEnabled = ref.watch(dynamicThemeEnabledProvider);
  if (!isEnabled) {
    return ExtractedPalette.fallback;
  }

  final playerState = ref.watch(playerNotifierProvider);
  final track = playerState.currentTrack;

  final service = ref.watch(dynamicPaletteServiceProvider);
  if (track == null) {
    return ExtractedPalette.fallback;
  }

  return service.extractPalette(
    trackId: track.id,
    albumArtPath: track.artworkUri,
    seedText: '${track.title} ${track.artist} ${track.album}',
  );
});

/// Actively surfaces the synchronous [ExtractedPalette] with zero-flicker fallback.
final activeDynamicPaletteProvider = Provider<ExtractedPalette>((ref) {
  final asyncVal = ref.watch(activeDynamicPaletteFutureProvider);
  return asyncVal.valueOrNull ?? ExtractedPalette.fallback;
});
