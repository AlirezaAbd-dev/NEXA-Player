import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'NEXA Player';

  @override
  String get tabLibrary => 'Library';

  @override
  String get tabSongs => 'Songs';

  @override
  String get tabAlbums => 'Albums';

  @override
  String get tabArtists => 'Artists';

  @override
  String get tabFolders => 'Folders';

  @override
  String get tabPlaylists => 'Playlists';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabSettings => 'Settings';

  @override
  String get sortTitle => 'Title';

  @override
  String get sortArtist => 'Artist';

  @override
  String get sortAlbum => 'Album';

  @override
  String get sortDuration => 'Duration';

  @override
  String get sortDateAdded => 'Date Added';

  @override
  String get sortYear => 'Year';

  @override
  String get sortName => 'Name';

  @override
  String get sortTrackCount => 'Track Count';

  @override
  String get sortSongCount => 'Song Count';

  @override
  String get sortRecentlyUpdated => 'Recently Updated';

  @override
  String get sortSongsTooltip => 'Sort songs';

  @override
  String get sortAlbumsTooltip => 'Sort albums';

  @override
  String get sortArtistsTooltip => 'Sort artists';

  @override
  String get sortFoldersTooltip => 'Sort folders';

  @override
  String get sortPlaylistsTooltip => 'Sort playlists';

  @override
  String get searchLibraryTooltip => 'Search library';

  @override
  String get searchSongsHint => 'Search songs, artists, albums...';

  @override
  String get searchAllHint => 'Search songs, albums, artists...';

  @override
  String get searchSettingsHint => 'Search audio, controls, theme, gestures...';

  @override
  String allSongsCount(int count) {
    return 'All Songs ($count)';
  }

  @override
  String albumsCountMeta(int count) {
    return '$count ALBUMS · HI-RES VERIFIED';
  }

  @override
  String artistsCountMeta(int count) {
    return '$count ARTISTS IN LIBRARY';
  }

  @override
  String foldersCountMeta(int count) {
    return '$count STORAGE FOLDERS INDEXED';
  }

  @override
  String playlistsCountMeta(int count) {
    return '$count PLAYLISTS · 3 DYNAMIC SMART';
  }

  @override
  String tracksCount(int count) {
    return '$count tracks';
  }

  @override
  String get jumpToPlaying => 'Jump to Playing';

  @override
  String get playAll => 'Play All';

  @override
  String get shuffle => 'Shuffle';

  @override
  String get smartPlaylists => 'SMART PLAYLISTS';

  @override
  String get myPlaylists => 'MY PLAYLISTS';

  @override
  String get newPlaylist => 'New Playlist';

  @override
  String get createPlaylist => 'Create Playlist';

  @override
  String get playlistNameHint => 'Playlist name';

  @override
  String get cancel => 'Cancel';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get noAlbumsFound => 'No albums found. Scan your media in Settings!';

  @override
  String get noArtistsFound => 'No artists found. Scan your media in Settings!';

  @override
  String get noPlaylistsYet => 'No playlists yet. Tap \"+ New Playlist\" to create one!';

  @override
  String get noMatchesFound => 'No matches found';

  @override
  String get exploreLibrary => 'Explore Library';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clear => 'Clear';

  @override
  String get favorites => 'Favorites';

  @override
  String get upOneFolder => 'Up one folder';

  @override
  String get importM3u => 'Import M3U';

  @override
  String get dailyEssentials => 'DAILY ESSENTIALS';

  @override
  String get language => 'Language';

  @override
  String get languageSubtitleSystem => 'System Default (Follows device)';

  @override
  String get languageSubtitleEnglish => 'English';

  @override
  String get languageSubtitlePersian => 'فارسی (Persian)';

  @override
  String get languageSystemDefault => 'System Default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get themeAndAppearance => 'Theme & Appearance';

  @override
  String get equalizerAndDsp => 'Equalizer & DSP';

  @override
  String get bassBoost => 'Bass Boost';

  @override
  String get virtualizer => 'Virtualizer';

  @override
  String get preamp => 'Preamp';

  @override
  String get reverb => 'Reverb';

  @override
  String get reset => 'Reset';

  @override
  String get presets => 'Presets';

  @override
  String get upNext => 'Up Next';

  @override
  String get lyrics => 'Lyrics';

  @override
  String get queue => 'Queue';
}
