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

  @override
  String get playingFrom => 'PLAYING FROM';

  @override
  String get castAudio => 'Cast Audio';

  @override
  String get bedsideStandbyMode => 'Bedside Standby Mode';

  @override
  String get carDrivingMode => 'Car Driving Mode';

  @override
  String get acousticEngine => 'ACOUSTIC ENGINE';

  @override
  String get systemAndStorage => 'SYSTEM & STORAGE';

  @override
  String get playbackAndControls => 'Playback & Controls';

  @override
  String get audioSettings => 'Audio Settings';

  @override
  String get scannerSettings => 'Scanner Settings';

  @override
  String get lockScreenPlayerTitle => 'Lockscreen Player';

  @override
  String get lockScreenPlayerSubtitle => 'Show full-screen player over the lock screen while music is playing';

  @override
  String get unlockToDismiss => 'Unlock & Close';

  @override
  String get swipeToUnlock => 'Swipe up or tap close to dismiss';

  @override
  String matchingSettingsCount(int count) {
    return 'MATCHING SETTINGS ($count)';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'No settings found for \"$query\"';
  }

  @override
  String get statusOn => 'ON';

  @override
  String get statusOff => 'OFF';

  @override
  String get playbackAndControlsSubtitle => 'Telephony resume, Focus ducking, Gestures, Car mode';

  @override
  String get homescreenWidgetsAndStandby => 'Homescreen Widgets & Standby';

  @override
  String get homescreenWidgetsAndStandbySubtitle => '4×1, 4×2 Hero Vinyl, 2×2, 4×3 Karaoke & OLED Bedside';

  @override
  String get audioSettingsSubtitle => 'Bit-perfect Hi-Res, Gapless, DVC, Sample rate';

  @override
  String get equalizerAndDspSubtitle => '10-Band Parametric EQ, Z-Bass, Reverb, Presets';

  @override
  String get visualizerAndSpectrum => 'Visualizer & Spectrum';

  @override
  String get visualizerAndSpectrumSubtitle => 'FFT Bars, Circle, Wave, Spectrogram, VU Meter';

  @override
  String get autoAndWearables => 'Auto & Wearables';

  @override
  String get autoAndWearablesSubtitle => 'Android Auto, Car Mode HUD, Galaxy/Pixel Watch companion';

  @override
  String get cloudAndNetworkStreaming => 'Cloud & Network Streaming';

  @override
  String get cloudAndNetworkStreamingSubtitle => 'UPnP/DLNA Casting, WebDAV/NAS sync, Lossless Web Radio';

  @override
  String get scannerSettingsSubtitle => 'Included folders, skip rules, tag encoding, database';

  @override
  String get albumArtTitle => 'Album Art';

  @override
  String get albumArtSubtitle => 'Online cover download, quality, priority, cache wipe';

  @override
  String get lyricsAndMetadataTitle => 'Lyrics & Metadata';

  @override
  String get lyricsAndMetadataSubtitle => 'LRCLIB auto-fetch, karaoke font size, tag writeback';

  @override
  String get powerSavingTitle => 'Power Saving';

  @override
  String get powerSavingSubtitle => 'Battery saving threshold, animations reduction, wake locks';

  @override
  String get notificationsAndWidgetsTitle => 'Notifications & Widgets';

  @override
  String get notificationsAndWidgetsSubtitle => 'Media notification layout, Android Auto, Wear OS';

  @override
  String get privacyAndStorageTitle => 'Privacy & Storage';

  @override
  String get privacyAndStorageSubtitle => 'JSON settings export/import, search history purge';

  @override
  String get designSystemShowcaseTitle => 'Design System Showcase';

  @override
  String get designSystemShowcaseSubtitle => 'Live tactile interactive widget lab';

  @override
  String get aboutNexaTitle => 'About NEXA';

  @override
  String get aboutNexaSubtitle => 'v1.0.0 Obsidian, changelog, legal licenses, credits';

  @override
  String get eqActive => 'ACTIVE';

  @override
  String get eqBypass => 'BYPASS';

  @override
  String get soundPresetLabel => 'SOUND PRESET';

  @override
  String get preampLabel => 'PREAMP';

  @override
  String get parametricFilterLabel => '10-BAND PARAMETRIC FILTER';

  @override
  String get psychoacousticDspEffects => 'PSYCHOACOUSTIC DSP EFFECTS';

  @override
  String get bassBoostLabel => 'BASS BOOST';

  @override
  String get virtualizer3dLabel => '3D VIRTUALIZER';

  @override
  String get acousticReverbLabel => 'ACOUSTIC REVERB';

  @override
  String playingNextSnack(String title) {
    return 'Playing next: $title';
  }

  @override
  String addedToQueueSnack(String title) {
    return 'Added to queue: $title';
  }

  @override
  String get playNextAction => 'Play next';

  @override
  String get addToQueueAction => 'Add to queue';

  @override
  String get addToPlaylistAction => 'Add to playlist';

  @override
  String get editTagsAndCoverAction => 'Edit tags & cover';
}
