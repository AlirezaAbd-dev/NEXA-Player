import 'package:equatable/equatable.dart';

/// Immutable domain entity representing a local folder targeted for media scanning.
class ScanDirectory extends Equatable {
  const ScanDirectory({
    required this.id,
    required this.path,
    this.isEnabled = true,
    this.lastScannedAt,
    this.trackCount = 0,
  });

  final String id;
  final String path;
  final bool isEnabled;
  final DateTime? lastScannedAt;
  final int trackCount;

  /// Human-readable label for track count badge.
  String get trackCountLabel =>
      trackCount == 1 ? '1 Track' : '$trackCount Tracks';

  /// Serializes entity to an SQLite-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'is_active': isEnabled ? 1 : 0,
      'last_scanned': lastScannedAt?.millisecondsSinceEpoch,
      'file_count': trackCount,
    };
  }

  /// Deserializes entity from an SQLite query row or JSON map.
  factory ScanDirectory.fromMap(Map<String, dynamic> map) {
    final scannedRaw = map['last_scanned'] ?? map['last_scanned_at'] ?? map['lastScannedAt'];
    final enabledRaw = map['is_active'] ?? map['enabled'] ?? map['is_enabled'] ?? map['isEnabled'];

    return ScanDirectory(
      id: map['id'] as String,
      path: map['path'] as String,
      isEnabled: enabledRaw == null ? true : (enabledRaw == 1 || enabledRaw == true),
      lastScannedAt: scannedRaw is int
          ? DateTime.fromMillisecondsSinceEpoch(scannedRaw)
          : (scannedRaw is DateTime ? scannedRaw : null),
      trackCount: (map['file_count'] ?? map['track_count'] ?? map['trackCount'] ?? 0) as int,
    );
  }

  ScanDirectory copyWith({
    String? id,
    String? path,
    bool? isEnabled,
    DateTime? lastScannedAt,
    int? trackCount,
  }) {
    return ScanDirectory(
      id: id ?? this.id,
      path: path ?? this.path,
      isEnabled: isEnabled ?? this.isEnabled,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      trackCount: trackCount ?? this.trackCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        path,
        isEnabled,
        lastScannedAt,
        trackCount,
      ];
}
