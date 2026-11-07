import 'package:nexa_player/core/utils/result.dart';
import 'package:nexa_player/features/scanner/domain/scanner_state.dart';
import 'package:nexa_player/shared/models/scanner_config.dart';

export 'package:nexa_player/features/scanner/domain/scanner_state.dart';
export 'package:nexa_player/shared/models/scanner_config.dart';

/// Abstract service contract for discovering and indexing audio media files.
abstract interface class IMediaScannerService {
  /// Stream emitting real-time state changes during scanning.
  Stream<ScannerState> get stateStream;

  /// Current instantaneous state of the scanner.
  ScannerState get currentState;

  /// Recursively scans the provided [directoryPaths] for audio files,
  /// extracts metadata, and upserts them into the local database.
  Future<Result<ScanResult, ScannerFailure>> scanDirectories(
    List<String> directoryPaths, {
    ScannerConfig? config,
  });

  /// Requests cancellation of an in-progress scan operation.
  void stopScan();
}
