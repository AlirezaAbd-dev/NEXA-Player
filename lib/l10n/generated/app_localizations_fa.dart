import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'پخش‌کننده نِکسا';

  @override
  String get tabLibrary => 'کتابخانه';

  @override
  String get tabSongs => 'آهنگ‌ها';

  @override
  String get tabAlbums => 'آلبوم‌ها';

  @override
  String get tabArtists => 'هنرمندان';

  @override
  String get tabFolders => 'پوشه‌ها';

  @override
  String get tabPlaylists => 'لیست‌های پخش';

  @override
  String get tabSearch => 'جستجو';

  @override
  String get tabSettings => 'تنظیمات';

  @override
  String get sortTitle => 'عنوان';

  @override
  String get sortArtist => 'هنرمند';

  @override
  String get sortAlbum => 'آلبوم';

  @override
  String get sortDuration => 'مدت زمان';

  @override
  String get sortDateAdded => 'تاریخ افزودن';

  @override
  String get sortYear => 'سال';

  @override
  String get sortName => 'نام';

  @override
  String get sortTrackCount => 'تعداد آهنگ';

  @override
  String get sortSongCount => 'تعداد آهنگ';

  @override
  String get sortRecentlyUpdated => 'آخرین به‌روزرسانی';

  @override
  String get sortSongsTooltip => 'مرتب‌سازی آهنگ‌ها';

  @override
  String get sortAlbumsTooltip => 'مرتب‌سازی آلبوم‌ها';

  @override
  String get sortArtistsTooltip => 'مرتب‌سازی هنرمندان';

  @override
  String get sortFoldersTooltip => 'مرتب‌سازی پوشه‌ها';

  @override
  String get sortPlaylistsTooltip => 'مرتب‌سازی لیست‌های پخش';

  @override
  String get searchLibraryTooltip => 'جستجو در کتابخانه';

  @override
  String get searchSongsHint => 'جستجوی آهنگ، هنرمند، آلبوم...';

  @override
  String get searchAllHint => 'جستجوی آهنگ، آلبوم، هنرمند...';

  @override
  String get searchSettingsHint => 'جستجو در صدا، کنترل‌ها، پوسته، ژست‌ها...';

  @override
  String allSongsCount(int count) {
    return 'همه آهنگ‌ها ($count)';
  }

  @override
  String albumsCountMeta(int count) {
    return '$count آلبوم · کیفیت بالا';
  }

  @override
  String artistsCountMeta(int count) {
    return '$count هنرمند در کتابخانه';
  }

  @override
  String foldersCountMeta(int count) {
    return '$count پوشه نمایه‌شده';
  }

  @override
  String playlistsCountMeta(int count) {
    return '$count لیست پخش · ۳ لیست هوشمند';
  }

  @override
  String tracksCount(int count) {
    return '$count آهنگ';
  }

  @override
  String get jumpToPlaying => 'رفتن به در حال پخش';

  @override
  String get playAll => 'پخش همه';

  @override
  String get shuffle => 'پخش تصادفی';

  @override
  String get smartPlaylists => 'لیست‌های هوشمند';

  @override
  String get myPlaylists => 'لیست‌های من';

  @override
  String get newPlaylist => 'لیست جدید';

  @override
  String get createPlaylist => 'ساخت لیست پخش';

  @override
  String get playlistNameHint => 'نام لیست پخش';

  @override
  String get cancel => 'لغو';

  @override
  String get create => 'ساختن';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'ذخیره';

  @override
  String get done => 'انجام شد';

  @override
  String get noAlbumsFound => 'آلبومی پیدا نشد. رسانه خود را در تنظیمات اسکن کنید!';

  @override
  String get noArtistsFound => 'هنرمندی پیدا نشد. رسانه خود را در تنظیمات اسکن کنید!';

  @override
  String get noPlaylistsYet => 'هنوز لیست پخشی ندارید. برای ساختن روی «+ لیست جدید» بزنید!';

  @override
  String get noMatchesFound => 'موردی پیدا نشد';

  @override
  String get exploreLibrary => 'کاوش کتابخانه';

  @override
  String get recentSearches => 'جستجوهای اخیر';

  @override
  String get clear => 'پاک کردن';

  @override
  String get favorites => 'علاقه‌مندی‌ها';

  @override
  String get upOneFolder => 'پوشه بالایی';

  @override
  String get importM3u => 'ورود M3U';

  @override
  String get dailyEssentials => 'تنظیمات اصلی';

  @override
  String get language => 'زبان برنامه';

  @override
  String get languageSubtitleSystem => 'پیش‌فرض سیستم (مطابق زبان گوشی)';

  @override
  String get languageSubtitleEnglish => 'English';

  @override
  String get languageSubtitlePersian => 'فارسی';

  @override
  String get languageSystemDefault => 'پیش‌فرض سیستم';

  @override
  String get languageEnglish => 'English';

  @override
  String get languagePersian => 'فارسی';

  @override
  String get themeAndAppearance => 'پوسته و ظاهر';

  @override
  String get equalizerAndDsp => 'اکولایزر و پردازش صدا';

  @override
  String get bassBoost => 'تقویت باس';

  @override
  String get virtualizer => 'فضاسازی سه‌بعدی';

  @override
  String get preamp => 'پیش‌تقویت';

  @override
  String get reverb => 'اکو و فضا';

  @override
  String get reset => 'بازنشانی';

  @override
  String get presets => 'پیش‌تنظیم‌ها';

  @override
  String get upNext => 'صف بعدی';

  @override
  String get lyrics => 'متن آهنگ';

  @override
  String get queue => 'صف پخش';

  @override
  String get playingFrom => 'پخش از';

  @override
  String get castAudio => 'پخش روی دستگاه دیگر';

  @override
  String get bedsideStandbyMode => 'حالت شب کنار تخت';

  @override
  String get carDrivingMode => 'حالت رانندگی خودرو';

  @override
  String get acousticEngine => 'موتور صوتی';

  @override
  String get systemAndStorage => 'سیستم و حافظه';

  @override
  String get playbackAndControls => 'پخش و کنترل‌ها';

  @override
  String get audioSettings => 'تنظیمات صدا';

  @override
  String get scannerSettings => 'تنظیمات اسکنر';

  @override
  String get lockScreenPlayerTitle => 'پخش‌کننده صفحه قفل';

  @override
  String get lockScreenPlayerSubtitle => 'نمایش پخش‌کننده تمام‌صفحه روی صفحه قفل هنگام پخش موسیقی';

  @override
  String get unlockToDismiss => 'باز کردن قفل و بستن';

  @override
  String get swipeToUnlock => 'برای بستن به بالا بکشید یا دکمه بستن را بزنید';

  @override
  String matchingSettingsCount(int count) {
    return 'تنظیمات یافت‌شده ($count)';
  }

  @override
  String noSettingsFoundFor(String query) {
    return 'تنظیمی برای «$query» پیدا نشد';
  }

  @override
  String get statusOn => 'روشن';

  @override
  String get statusOff => 'خاموش';

  @override
  String get playbackAndControlsSubtitle => 'ادامه پس از تماس، کاهش صدا، ژست‌ها، حالت خودرو';

  @override
  String get homescreenWidgetsAndStandby => 'ویجت‌های صفحه اصلی و حالت شب';

  @override
  String get homescreenWidgetsAndStandbySubtitle => 'ویجت ۴×۱، ۴×۲ وینیل، ۲×۲، ۴×۳ کارائوکه و ساعت کنار تخت';

  @override
  String get audioSettingsSubtitle => 'پخش Hi-Res بدون افت، بدون وقفه، DVC و نرخ نمونه‌برداری';

  @override
  String get equalizerAndDspSubtitle => 'اکولایزر ۱۰ بانده، تقویت باس، اکو و پیش‌تنظیم‌ها';

  @override
  String get visualizerAndSpectrum => 'ویژوالایزر و طیف صدا';

  @override
  String get visualizerAndSpectrumSubtitle => 'میله‌های FFT، دایره، موج، طیف‌نگار و VU متر';

  @override
  String get autoAndWearables => 'خودرو و ساعت هوشمند';

  @override
  String get autoAndWearablesSubtitle => 'Android Auto، حالت رانندگی و همراه ساعت هوشمند';

  @override
  String get cloudAndNetworkStreaming => 'پخش ابری و شبکه';

  @override
  String get cloudAndNetworkStreamingSubtitle => 'پخش UPnP/DLNA، همگام‌سازی WebDAV/NAS و رادیو';

  @override
  String get scannerSettingsSubtitle => 'پوشه‌های اسکن، قوانین فیلتر، کدگذاری تگ و پایگاه داده';

  @override
  String get albumArtTitle => 'کاور آلبوم';

  @override
  String get albumArtSubtitle => 'دانلود آنلاین کاور، کیفیت، اولویت و پاک‌سازی کش';

  @override
  String get lyricsAndMetadataTitle => 'متن آهنگ و ابرداده';

  @override
  String get lyricsAndMetadataSubtitle => 'دریافت خودکار LRCLIB، اندازه فونت کارائوکه و ویرایش تگ';

  @override
  String get powerSavingTitle => 'صرفه‌جویی در باتری';

  @override
  String get powerSavingSubtitle => 'آستانه مصرف باتری، کاهش انیمیشن و قفل بیداری';

  @override
  String get notificationsAndWidgetsTitle => 'اعلان‌ها و ویجت‌ها';

  @override
  String get notificationsAndWidgetsSubtitle => 'چیدمان اعلان پخش، Android Auto و Wear OS';

  @override
  String get privacyAndStorageTitle => 'حریم خصوصی و ذخیره‌سازی';

  @override
  String get privacyAndStorageSubtitle => 'خروجی و ورودی JSON تنظیمات، پاک کردن تاریخچه جستجو';

  @override
  String get designSystemShowcaseTitle => 'نمایشگاه سیستم طراحی';

  @override
  String get designSystemShowcaseSubtitle => 'آزمایشگاه زنده ویجت‌ها و سطوح لمسی';

  @override
  String get aboutNexaTitle => 'درباره نِکسا';

  @override
  String get aboutNexaSubtitle => 'نسخه ۱.۰.۰، تغییرات، مجوزها و سازندگان';

  @override
  String get eqActive => 'فعال';

  @override
  String get eqBypass => 'غیرفعال';

  @override
  String get soundPresetLabel => 'پیش‌تنظیم صدا';

  @override
  String get preampLabel => 'پیش‌تقویت';

  @override
  String get parametricFilterLabel => 'فیلتر پارامتریک ۱۰ بانده';

  @override
  String get psychoacousticDspEffects => 'افکت‌های پردازش صدا (DSP)';

  @override
  String get bassBoostLabel => 'تقویت باس';

  @override
  String get virtualizer3dLabel => 'فضاسازی سه‌بعدی';

  @override
  String get acousticReverbLabel => 'اکو و فضای آکوستیک';

  @override
  String playingNextSnack(String title) {
    return 'پخش بعدی: $title';
  }

  @override
  String addedToQueueSnack(String title) {
    return 'به صف پخش اضافه شد: $title';
  }

  @override
  String get playNextAction => 'پخش به عنوان بعدی';

  @override
  String get addToQueueAction => 'افزودن به صف پخش';

  @override
  String get addToPlaylistAction => 'افزودن به لیست پخش';

  @override
  String get editTagsAndCoverAction => 'ویرایش تگ و کاور';
}
