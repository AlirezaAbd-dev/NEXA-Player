import 'package:equatable/equatable.dart';

/// Execution lifecycle states of the media scanner.
enum ScannerStatus { idle, scanning, completed, error }

/// Immutable snapshot representing live progress and diagnostics of an active scan.
class ScannerState extends Equatable {
  const ScannerState({
    this.status = ScannerStatus.idle,
    this.progress = 0.0,
    this.filesScanned = 0,
    this.filesFound = 0,
    this.currentFile,
    this.errorMessage,
  });

  final ScannerStatus status;
  final double progress; // 0.0 to 1.0
  final int filesScanned;
  final int filesFound;
  final String? currentFile;
  final String? errorMessage;

  ScannerState copyWith({
    ScannerStatus? status,
    double? progress,
    int? filesScanned,
    int? filesFound,
    String? currentFile,
    String? errorMessage,
  }) {
    return ScannerState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filesScanned: filesScanned ?? this.filesScanned,
      filesFound: filesFound ?? this.filesFound,
      currentFile: currentFile ?? this.currentFile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        progress,
        filesScanned,
        filesFound,
        currentFile,
        errorMessage,
      ];
}

/// Immutable summary returned upon scan completion.
class ScanResult extends Equatable {
  const ScanResult({
    required this.scannedFilesCount,
    required this.insertedTracksCount,
    required this.skippedFilesCount,
    required this.duration,
    this.errors = const [],
  });

  final int scannedFilesCount;
  final int insertedTracksCount;
  final int skippedFilesCount;
  final Duration duration;
  final List<String> errors;

  @override
  List<Object?> get props => [
        scannedFilesCount,
        insertedTracksCount,
        skippedFilesCount,
        duration,
        errors,
      ];
}
