/// Immutable model representing album artwork rendering, fetching, and storage settings.
class AlbumArtSettings {
  const AlbumArtSettings({
    this.downloadMissingCovers = true,
    this.onlyViaWifi = true,
    this.saveWithoutExtension = false,
    this.savedFolder = '/storage/emulated/0/Music/AlbumArt',
    this.downloadQuality = 'high', // low, medium, high, original
    this.maxDownloadSize = '1_mb', // 500_kb, 1_mb, 2_mb, unlimited
    this.embeddedArtPriority = 'prefer_embedded', // prefer_embedded, prefer_downloaded
    this.blurBackground = 'medium', // none, low, medium, high
    this.autoCropSquare = true,
    this.animatedCovers = false,
  });

  final bool downloadMissingCovers;
  final bool onlyViaWifi;
  final bool saveWithoutExtension;
  final String savedFolder;
  final String downloadQuality;
  final String maxDownloadSize;
  final String embeddedArtPriority;
  final String blurBackground;
  final bool autoCropSquare;
  final bool animatedCovers;

  AlbumArtSettings copyWith({
    bool? downloadMissingCovers,
    bool? onlyViaWifi,
    bool? saveWithoutExtension,
    String? savedFolder,
    String? downloadQuality,
    String? maxDownloadSize,
    String? embeddedArtPriority,
    String? blurBackground,
    bool? autoCropSquare,
    bool? animatedCovers,
  }) {
    return AlbumArtSettings(
      downloadMissingCovers:
          downloadMissingCovers ?? this.downloadMissingCovers,
      onlyViaWifi: onlyViaWifi ?? this.onlyViaWifi,
      saveWithoutExtension: saveWithoutExtension ?? this.saveWithoutExtension,
      savedFolder: savedFolder ?? this.savedFolder,
      downloadQuality: downloadQuality ?? this.downloadQuality,
      maxDownloadSize: maxDownloadSize ?? this.maxDownloadSize,
      embeddedArtPriority: embeddedArtPriority ?? this.embeddedArtPriority,
      blurBackground: blurBackground ?? this.blurBackground,
      autoCropSquare: autoCropSquare ?? this.autoCropSquare,
      animatedCovers: animatedCovers ?? this.animatedCovers,
    );
  }

  Map<String, dynamic> toJson() => {
        'downloadMissingCovers': downloadMissingCovers,
        'onlyViaWifi': onlyViaWifi,
        'saveWithoutExtension': saveWithoutExtension,
        'savedFolder': savedFolder,
        'downloadQuality': downloadQuality,
        'maxDownloadSize': maxDownloadSize,
        'embeddedArtPriority': embeddedArtPriority,
        'blurBackground': blurBackground,
        'autoCropSquare': autoCropSquare,
        'animatedCovers': animatedCovers,
      };

  factory AlbumArtSettings.fromJson(Map<String, dynamic> json) =>
      AlbumArtSettings(
        downloadMissingCovers: json['downloadMissingCovers'] as bool? ?? true,
        onlyViaWifi: json['onlyViaWifi'] as bool? ?? true,
        saveWithoutExtension:
            json['saveWithoutExtension'] as bool? ?? false,
        savedFolder: json['savedFolder'] as String? ??
            '/storage/emulated/0/Music/AlbumArt',
        downloadQuality: json['downloadQuality'] as String? ?? 'high',
        maxDownloadSize: json['maxDownloadSize'] as String? ?? '1_mb',
        embeddedArtPriority:
            json['embeddedArtPriority'] as String? ?? 'prefer_embedded',
        blurBackground: json['blurBackground'] as String? ?? 'medium',
        autoCropSquare: json['autoCropSquare'] as bool? ?? true,
        animatedCovers: json['animatedCovers'] as bool? ?? false,
      );
}
