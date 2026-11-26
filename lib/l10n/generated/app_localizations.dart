import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'NEXA Player'**
  String get appTitle;

  /// No description provided for @tabLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get tabLibrary;

  /// No description provided for @tabSongs.
  ///
  /// In en, this message translates to:
  /// **'Songs'**
  String get tabSongs;

  /// No description provided for @tabAlbums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get tabAlbums;

  /// No description provided for @tabArtists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get tabArtists;

  /// No description provided for @tabFolders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get tabFolders;

  /// No description provided for @tabPlaylists.
  ///
  /// In en, this message translates to:
  /// **'Playlists'**
  String get tabPlaylists;

  /// No description provided for @tabSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get tabSearch;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @sortTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get sortTitle;

  /// No description provided for @sortArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get sortArtist;

  /// No description provided for @sortAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get sortAlbum;

  /// No description provided for @sortDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortDuration;

  /// No description provided for @sortDateAdded.
  ///
  /// In en, this message translates to:
  /// **'Date Added'**
  String get sortDateAdded;

  /// No description provided for @sortYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get sortYear;

  /// No description provided for @sortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get sortName;

  /// No description provided for @sortTrackCount.
  ///
  /// In en, this message translates to:
  /// **'Track Count'**
  String get sortTrackCount;

  /// No description provided for @sortSongCount.
  ///
  /// In en, this message translates to:
  /// **'Song Count'**
  String get sortSongCount;

  /// No description provided for @sortRecentlyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently Updated'**
  String get sortRecentlyUpdated;

  /// No description provided for @sortSongsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort songs'**
  String get sortSongsTooltip;

  /// No description provided for @sortAlbumsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort albums'**
  String get sortAlbumsTooltip;

  /// No description provided for @sortArtistsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort artists'**
  String get sortArtistsTooltip;

  /// No description provided for @sortFoldersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort folders'**
  String get sortFoldersTooltip;

  /// No description provided for @sortPlaylistsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort playlists'**
  String get sortPlaylistsTooltip;

  /// No description provided for @searchLibraryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Search library'**
  String get searchLibraryTooltip;

  /// No description provided for @searchSongsHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, artists, albums...'**
  String get searchSongsHint;

  /// No description provided for @searchAllHint.
  ///
  /// In en, this message translates to:
  /// **'Search songs, albums, artists...'**
  String get searchAllHint;

  /// No description provided for @searchSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Search audio, controls, theme, gestures...'**
  String get searchSettingsHint;

  /// No description provided for @allSongsCount.
  ///
  /// In en, this message translates to:
  /// **'All Songs ({count})'**
  String allSongsCount(int count);

  /// No description provided for @albumsCountMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} ALBUMS · HI-RES VERIFIED'**
  String albumsCountMeta(int count);

  /// No description provided for @artistsCountMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} ARTISTS IN LIBRARY'**
  String artistsCountMeta(int count);

  /// No description provided for @foldersCountMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} STORAGE FOLDERS INDEXED'**
  String foldersCountMeta(int count);

  /// No description provided for @playlistsCountMeta.
  ///
  /// In en, this message translates to:
  /// **'{count} PLAYLISTS · 3 DYNAMIC SMART'**
  String playlistsCountMeta(int count);

  /// No description provided for @tracksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tracks'**
  String tracksCount(int count);

  /// No description provided for @jumpToPlaying.
  ///
  /// In en, this message translates to:
  /// **'Jump to Playing'**
  String get jumpToPlaying;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play All'**
  String get playAll;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @smartPlaylists.
  ///
  /// In en, this message translates to:
  /// **'SMART PLAYLISTS'**
  String get smartPlaylists;

  /// No description provided for @myPlaylists.
  ///
  /// In en, this message translates to:
  /// **'MY PLAYLISTS'**
  String get myPlaylists;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New Playlist'**
  String get newPlaylist;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create Playlist'**
  String get createPlaylist;

  /// No description provided for @playlistNameHint.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistNameHint;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @noAlbumsFound.
  ///
  /// In en, this message translates to:
  /// **'No albums found. Scan your media in Settings!'**
  String get noAlbumsFound;

  /// No description provided for @noArtistsFound.
  ///
  /// In en, this message translates to:
  /// **'No artists found. Scan your media in Settings!'**
  String get noArtistsFound;

  /// No description provided for @noPlaylistsYet.
  ///
  /// In en, this message translates to:
  /// **'No playlists yet. Tap \"+ New Playlist\" to create one!'**
  String get noPlaylistsYet;

  /// No description provided for @noMatchesFound.
  ///
  /// In en, this message translates to:
  /// **'No matches found'**
  String get noMatchesFound;

  /// No description provided for @exploreLibrary.
  ///
  /// In en, this message translates to:
  /// **'Explore Library'**
  String get exploreLibrary;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @upOneFolder.
  ///
  /// In en, this message translates to:
  /// **'Up one folder'**
  String get upOneFolder;

  /// No description provided for @importM3u.
  ///
  /// In en, this message translates to:
  /// **'Import M3U'**
  String get importM3u;

  /// No description provided for @dailyEssentials.
  ///
  /// In en, this message translates to:
  /// **'DAILY ESSENTIALS'**
  String get dailyEssentials;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSubtitleSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default (Follows device)'**
  String get languageSubtitleSystem;

  /// No description provided for @languageSubtitleEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageSubtitleEnglish;

  /// No description provided for @languageSubtitlePersian.
  ///
  /// In en, this message translates to:
  /// **'فارسی (Persian)'**
  String get languageSubtitlePersian;

  /// No description provided for @languageSystemDefault.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystemDefault;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languagePersian.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get languagePersian;

  /// No description provided for @themeAndAppearance.
  ///
  /// In en, this message translates to:
  /// **'Theme & Appearance'**
  String get themeAndAppearance;

  /// No description provided for @equalizerAndDsp.
  ///
  /// In en, this message translates to:
  /// **'Equalizer & DSP'**
  String get equalizerAndDsp;

  /// No description provided for @bassBoost.
  ///
  /// In en, this message translates to:
  /// **'Bass Boost'**
  String get bassBoost;

  /// No description provided for @virtualizer.
  ///
  /// In en, this message translates to:
  /// **'Virtualizer'**
  String get virtualizer;

  /// No description provided for @preamp.
  ///
  /// In en, this message translates to:
  /// **'Preamp'**
  String get preamp;

  /// No description provided for @reverb.
  ///
  /// In en, this message translates to:
  /// **'Reverb'**
  String get reverb;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @presets.
  ///
  /// In en, this message translates to:
  /// **'Presets'**
  String get presets;

  /// No description provided for @upNext.
  ///
  /// In en, this message translates to:
  /// **'Up Next'**
  String get upNext;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @queue.
  ///
  /// In en, this message translates to:
  /// **'Queue'**
  String get queue;

  /// No description provided for @playingFrom.
  ///
  /// In en, this message translates to:
  /// **'PLAYING FROM'**
  String get playingFrom;

  /// No description provided for @castAudio.
  ///
  /// In en, this message translates to:
  /// **'Cast Audio'**
  String get castAudio;

  /// No description provided for @bedsideStandbyMode.
  ///
  /// In en, this message translates to:
  /// **'Bedside Standby Mode'**
  String get bedsideStandbyMode;

  /// No description provided for @carDrivingMode.
  ///
  /// In en, this message translates to:
  /// **'Car Driving Mode'**
  String get carDrivingMode;

  /// No description provided for @acousticEngine.
  ///
  /// In en, this message translates to:
  /// **'ACOUSTIC ENGINE'**
  String get acousticEngine;

  /// No description provided for @systemAndStorage.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM & STORAGE'**
  String get systemAndStorage;

  /// No description provided for @playbackAndControls.
  ///
  /// In en, this message translates to:
  /// **'Playback & Controls'**
  String get playbackAndControls;

  /// No description provided for @audioSettings.
  ///
  /// In en, this message translates to:
  /// **'Audio Settings'**
  String get audioSettings;

  /// No description provided for @scannerSettings.
  ///
  /// In en, this message translates to:
  /// **'Scanner Settings'**
  String get scannerSettings;

  /// No description provided for @lockScreenPlayerTitle.
  ///
  /// In en, this message translates to:
  /// **'Lockscreen Player'**
  String get lockScreenPlayerTitle;

  /// No description provided for @lockScreenPlayerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show full-screen player over the lock screen while music is playing'**
  String get lockScreenPlayerSubtitle;

  /// No description provided for @unlockToDismiss.
  ///
  /// In en, this message translates to:
  /// **'Unlock & Close'**
  String get unlockToDismiss;

  /// No description provided for @swipeToUnlock.
  ///
  /// In en, this message translates to:
  /// **'Swipe up or tap close to dismiss'**
  String get swipeToUnlock;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fa': return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
