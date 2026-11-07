import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexa_player/core/di/injection.dart';
import 'package:nexa_player/features/scanner/domain/audio_metadata_reader.dart';
import 'package:nexa_player/features/scanner/domain/media_scanner_service.dart';
import 'package:nexa_player/features/scanner/domain/repositories/scan_directories_repository.dart';
import 'package:nexa_player/shared/models/scan_directory.dart';

/// Provider exposing [IAudioMetadataReader].
final audioMetadataReaderProvider = Provider<IAudioMetadataReader>((ref) {
  return getIt<IAudioMetadataReader>();
});

/// Provider exposing [IMediaScannerService].
final mediaScannerServiceProvider = Provider<IMediaScannerService>((ref) {
  return getIt<IMediaScannerService>();
});

/// Provider exposing [IScanDirectoriesRepository].
final scanDirectoriesRepositoryProvider =
    Provider<IScanDirectoriesRepository>((ref) {
  return getIt<IScanDirectoriesRepository>();
});

/// State notifier managing live media scanner states.
class ScannerStateNotifier extends StateNotifier<ScannerState> {
  ScannerStateNotifier(this._scannerService) : super(const ScannerState()) {
    _subscription = _scannerService.stateStream.listen((state) {
      this.state = state;
    });
  }

  final IMediaScannerService _scannerService;
  StreamSubscription<ScannerState>? _subscription;

  Future<void> startScan(List<String> directories, {ScannerConfig? config}) async {
    await _scannerService.scanDirectories(directories, config: config);
  }

  void stopScan() {
    _scannerService.stopScan();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider exposing the reactive [ScannerStateNotifier].
final scannerStateNotifierProvider =
    StateNotifierProvider<ScannerStateNotifier, ScannerState>((ref) {
  final service = ref.watch(mediaScannerServiceProvider);
  return ScannerStateNotifier(service);
});

/// State notifier managing the list of configured scan directories.
class ScanDirectoriesNotifier
    extends AsyncNotifier<List<ScanDirectory>> {
  @override
  FutureOr<List<ScanDirectory>> build() async {
    final repo = ref.watch(scanDirectoriesRepositoryProvider);
    final res = await repo.getDirectories();
    return res.valueOrNull ?? [];
  }

  Future<void> addDirectory(String path) async {
    final repo = ref.read(scanDirectoriesRepositoryProvider);
    final res = await repo.addDirectory(path);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }

  Future<void> removeDirectory(String path) async {
    final repo = ref.read(scanDirectoriesRepositoryProvider);
    final res = await repo.removeDirectory(path);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    final repo = ref.read(scanDirectoriesRepositoryProvider);
    final res = await repo.toggleActive(id, isActive);
    if (res.isSuccess) {
      ref.invalidateSelf();
    }
  }
}

/// Provider exposing the list of scan directories.
final scanDirectoriesProvider =
    AsyncNotifierProvider<ScanDirectoriesNotifier, List<ScanDirectory>>(
  ScanDirectoriesNotifier.new,
);
