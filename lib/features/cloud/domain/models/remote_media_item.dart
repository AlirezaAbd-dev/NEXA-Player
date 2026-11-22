import 'package:equatable/equatable.dart';
import '../../../../shared/models/track.dart';

/// Represents a remote folder or audio asset hosted on a network server.
class RemoteMediaItem extends Equatable {
  const RemoteMediaItem({
    required this.id,
    required this.serverId,
    required this.name,
    required this.remotePath,
    this.isDirectory = false,
    this.sizeBytes,
    this.mimeType,
    this.lastModified,
    this.title,
    this.artist,
    this.album,
    this.duration,
    this.isCached = false,
    this.cachedLocalPath,
  });

  final String id;
  final String serverId;
  final String name;
  final String remotePath;
  final bool isDirectory;
  final int? sizeBytes;
  final String? mimeType;
  final DateTime? lastModified;
  final String? title;
  final String? artist;
  final String? album;
  final Duration? duration;
  final bool isCached;
  final String? cachedLocalPath;

  /// Returns audio file extension (e.g. `flac`, `mp3`, `dsd`).
  String get fileExtension {
    if (isDirectory) return '';
    final dotIdx = name.lastIndexOf('.');
    if (dotIdx == -1 || dotIdx == name.length - 1) return '';
    return name.substring(dotIdx + 1).toLowerCase();
  }

  /// Converts this remote media item into an executable playback [Track].
  Track toTrack({required String streamUrl}) {
    return Track(
      id: id,
      title: title ?? (name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name),
      artist: artist ?? 'Network Stream',
      album: album ?? 'Remote Server',
      duration: duration ?? const Duration(minutes: 3, seconds: 30),
      filePath: isCached && cachedLocalPath != null ? cachedLocalPath : streamUrl,
      fileSize: sizeBytes,
      dateModified: lastModified,
    );
  }

  RemoteMediaItem copyWith({
    String? id,
    String? serverId,
    String? name,
    String? remotePath,
    bool? isDirectory,
    int? sizeBytes,
    String? mimeType,
    DateTime? lastModified,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    bool? isCached,
    String? cachedLocalPath,
  }) {
    return RemoteMediaItem(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      remotePath: remotePath ?? this.remotePath,
      isDirectory: isDirectory ?? this.isDirectory,
      sizeBytes: sizeBytes ?? this.sizeBytes,
      mimeType: mimeType ?? this.mimeType,
      lastModified: lastModified ?? this.lastModified,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      isCached: isCached ?? this.isCached,
      cachedLocalPath: cachedLocalPath ?? this.cachedLocalPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serverId,
        name,
        remotePath,
        isDirectory,
        sizeBytes,
        mimeType,
        lastModified,
        title,
        artist,
        album,
        duration,
        isCached,
        cachedLocalPath,
      ];
}
