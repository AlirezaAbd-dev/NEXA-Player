/// Immutable model representing lyrics fetching, formatting, and ID3 tag metadata settings.
class MetadataLyricsSettings {
  const MetadataLyricsSettings({
    this.translateMetadata = false,
    this.translationProvider = 'google', // google, deepl, local
    this.preferredLyricsSource = 'lrclib', // embedded, genius, lrclib, offline
    this.autoFetchLyrics = true,
    this.lyricsFontSize = 22.0, // 14 to 34
    this.lyricsHighlightColorHex = '0xFF00E5FF', // Cyan accent default
    this.writeTagsToFile = false,
    this.writeArtToFile = false,
  });

  final bool translateMetadata;
  final String translationProvider;
  final String preferredLyricsSource;
  final bool autoFetchLyrics;
  final double lyricsFontSize;
  final String lyricsHighlightColorHex;
  final bool writeTagsToFile;
  final bool writeArtToFile;

  MetadataLyricsSettings copyWith({
    bool? translateMetadata,
    String? translationProvider,
    String? preferredLyricsSource,
    bool? autoFetchLyrics,
    double? lyricsFontSize,
    String? lyricsHighlightColorHex,
    bool? writeTagsToFile,
    bool? writeArtToFile,
  }) {
    return MetadataLyricsSettings(
      translateMetadata: translateMetadata ?? this.translateMetadata,
      translationProvider:
          translationProvider ?? this.translationProvider,
      preferredLyricsSource:
          preferredLyricsSource ?? this.preferredLyricsSource,
      autoFetchLyrics: autoFetchLyrics ?? this.autoFetchLyrics,
      lyricsFontSize: lyricsFontSize ?? this.lyricsFontSize,
      lyricsHighlightColorHex:
          lyricsHighlightColorHex ?? this.lyricsHighlightColorHex,
      writeTagsToFile: writeTagsToFile ?? this.writeTagsToFile,
      writeArtToFile: writeArtToFile ?? this.writeArtToFile,
    );
  }

  Map<String, dynamic> toJson() => {
        'translateMetadata': translateMetadata,
        'translationProvider': translationProvider,
        'preferredLyricsSource': preferredLyricsSource,
        'autoFetchLyrics': autoFetchLyrics,
        'lyricsFontSize': lyricsFontSize,
        'lyricsHighlightColorHex': lyricsHighlightColorHex,
        'writeTagsToFile': writeTagsToFile,
        'writeArtToFile': writeArtToFile,
      };

  factory MetadataLyricsSettings.fromJson(Map<String, dynamic> json) =>
      MetadataLyricsSettings(
        translateMetadata: json['translateMetadata'] as bool? ?? false,
        translationProvider:
            json['translationProvider'] as String? ?? 'google',
        preferredLyricsSource:
            json['preferredLyricsSource'] as String? ?? 'lrclib',
        autoFetchLyrics: json['autoFetchLyrics'] as bool? ?? true,
        lyricsFontSize:
            (json['lyricsFontSize'] as num?)?.toDouble() ?? 22.0,
        lyricsHighlightColorHex:
            json['lyricsHighlightColorHex'] as String? ?? '0xFF00E5FF',
        writeTagsToFile: json['writeTagsToFile'] as bool? ?? false,
        writeArtToFile: json['writeArtToFile'] as bool? ?? false,
      );
}
