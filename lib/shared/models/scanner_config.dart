import 'package:equatable/equatable.dart';

/// Immutable domain configuration governing media scanner heuristics and skip filters.
class ScannerConfig extends Equatable {
  const ScannerConfig({
    this.skipNoMedia = true,
    this.skipShortAudio = true,
    this.minDurationSeconds = 10,
    this.skipSmallFiles = true,
    this.minSizeBytes = 51200, // 50 KB
    this.extensionsWhitelist = defaultExtensions,
  });

  /// Standard audio container and codec extensions recognized by NEXA Player.
  static const List<String> defaultExtensions = [
    'mp3',
    'flac',
    'm4a',
    'wav',
    'ogg',
    'aac',
    'opus',
  ];

  final bool skipNoMedia;
  final bool skipShortAudio;
  final int minDurationSeconds;
  final bool skipSmallFiles;
  final int minSizeBytes;
  final List<String> extensionsWhitelist;

  /// Default production configuration factory.
  static const defaultConfig = ScannerConfig();

  /// Verifies whether an extension (with or without leading dot) is whitelisted.
  bool isExtensionSupported(String extension) {
    final clean = extension.startsWith('.')
        ? extension.substring(1).toLowerCase()
        : extension.toLowerCase();
    return extensionsWhitelist.any((ext) => ext.toLowerCase() == clean);
  }

  /// Serializes configuration to a persistable map.
  Map<String, dynamic> toMap() {
    return {
      'skip_no_media': skipNoMedia ? 1 : 0,
      'skip_short_audio': skipShortAudio ? 1 : 0,
      'min_duration_seconds': minDurationSeconds,
      'skip_small_files': skipSmallFiles ? 1 : 0,
      'min_size_bytes': minSizeBytes,
      'extensions_whitelist': extensionsWhitelist.join(','),
    };
  }

  /// Deserializes configuration from a persisted map.
  factory ScannerConfig.fromMap(Map<String, dynamic> map) {
    final extensionsRaw = map['extensions_whitelist'] ?? map['extensionsWhitelist'];
    List<String> parsedExtensions = defaultExtensions;

    if (extensionsRaw is String && extensionsRaw.isNotEmpty) {
      parsedExtensions = extensionsRaw
          .split(',')
          .map((e) => e.trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (extensionsRaw is List) {
      parsedExtensions = extensionsRaw.map((e) => e.toString().toLowerCase()).toList();
    }

    final skipNoMediaRaw = map['skip_no_media'] ?? map['skipNoMedia'];
    final skipShortAudioRaw = map['skip_short_audio'] ?? map['skipShortAudio'];
    final skipSmallFilesRaw = map['skip_small_files'] ?? map['skipSmallFiles'];

    return ScannerConfig(
      skipNoMedia: skipNoMediaRaw == null ? true : (skipNoMediaRaw == 1 || skipNoMediaRaw == true),
      skipShortAudio: skipShortAudioRaw == null ? true : (skipShortAudioRaw == 1 || skipShortAudioRaw == true),
      minDurationSeconds: (map['min_duration_seconds'] ?? map['minDurationSeconds'] ?? 10) as int,
      skipSmallFiles: skipSmallFilesRaw == null ? true : (skipSmallFilesRaw == 1 || skipSmallFilesRaw == true),
      minSizeBytes: (map['min_size_bytes'] ?? map['minSizeBytes'] ?? 51200) as int,
      extensionsWhitelist: parsedExtensions,
    );
  }

  ScannerConfig copyWith({
    bool? skipNoMedia,
    bool? skipShortAudio,
    int? minDurationSeconds,
    bool? skipSmallFiles,
    int? minSizeBytes,
    List<String>? extensionsWhitelist,
  }) {
    return ScannerConfig(
      skipNoMedia: skipNoMedia ?? this.skipNoMedia,
      skipShortAudio: skipShortAudio ?? this.skipShortAudio,
      minDurationSeconds: minDurationSeconds ?? this.minDurationSeconds,
      skipSmallFiles: skipSmallFiles ?? this.skipSmallFiles,
      minSizeBytes: minSizeBytes ?? this.minSizeBytes,
      extensionsWhitelist: extensionsWhitelist ?? this.extensionsWhitelist,
    );
  }

  @override
  List<Object?> get props => [
        skipNoMedia,
        skipShortAudio,
        minDurationSeconds,
        skipSmallFiles,
        minSizeBytes,
        extensionsWhitelist,
      ];
}
