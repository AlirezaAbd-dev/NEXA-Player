/// Source origin where a track's lyrics were retrieved from.
enum LyricsSource {
  /// Extracted directly from embedded ID3/FLAC/Vorbis audio tags.
  embedded('Embedded Tag'),

  /// Loaded from a local `.lrc` companion file in device storage.
  lrcFile('Local .LRC File'),

  /// Synced LRC companion.
  syncedLrc('Synced LRC'),

  /// Fetched from public LRCLIB API.
  lrclib('LRCLIB Online'),

  /// Manually written or pasted by user via in-app Lyrics Editor.
  manual('User Custom'),

  /// No lyrics available.
  none('None');

  const LyricsSource(this.displayName);
  final String displayName;
}
