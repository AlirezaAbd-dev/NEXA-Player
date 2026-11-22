/// Persistent storage keys for NEXA Player.
///
/// All keys are prefixed with `nexa_` to avoid namespace collisions.
abstract final class StorageKeys {
  StorageKeys._();

  // Theme & Appearance (F0.10 - F0.13)
  static const String themePreset = 'nexa_theme_preset';
  static const String themeMode = 'nexa_theme_mode';
  static const String customPrimaryColor = 'nexa_custom_primary_color';
  static const String customSurfaceColor = 'nexa_custom_surface_color';
  static const String customBackgroundColor = 'nexa_custom_background_color';
  static const String glassBlurIntensity = 'nexa_glass_blur_intensity';
  static const String glassOpacityIntensity = 'nexa_glass_opacity_intensity';

  // Playback & Queue State
  static const String volume = 'nexa_player_volume';
  static const String isMuted = 'nexa_player_is_muted';
  static const String repeatMode = 'nexa_player_repeat_mode';
  static const String shuffleEnabled = 'nexa_player_shuffle_enabled';
  static const String lastTrackId = 'nexa_player_last_track_id';
  static const String lastPositionMs = 'nexa_player_last_position_ms';

  // Audio Engine & Equalizer
  static const String equalizerEnabled = 'nexa_eq_enabled';
  static const String equalizerPreset = 'nexa_eq_preset';
  static const String equalizerPreamp = 'nexa_eq_preamp';
  static const String equalizerBands = 'nexa_eq_bands';
  static const String equalizerReverb = 'nexa_eq_reverb';
  static const String equalizerCustomPresets = 'nexa_eq_custom_presets';
  static const String bassBoost = 'nexa_eq_bass_boost';
  static const String virtualizer = 'nexa_eq_virtualizer';
  static const String crossfadeDurationMs = 'nexa_audio_crossfade_ms';

  // Library & App State
  static const String onboardingCompleted = 'nexa_onboarding_completed';
  static const String libraryScanFolders = 'nexa_library_scan_folders';
  static const String lastScanTimestamp = 'nexa_last_scan_timestamp';
  static const String sortOrder = 'nexa_library_sort_order';
  static const String sortAscending = 'nexa_library_sort_ascending';

  // Search
  static const String recentSearches = 'nexa_recent_searches';

  // Audio Settings
  static const String audioGapless = 'nexa_audio_gapless';
  static const String audioCrossfadeEnabled = 'nexa_audio_crossfade_enabled';
  static const String audioCrossfadeDuration = 'nexa_audio_crossfade_duration';
  static const String audioFadingOnPlayPause = 'nexa_audio_fading_play_pause';
  static const String audioBufferSize = 'nexa_audio_buffer_size';
  static const String audioOutputRouting = 'nexa_audio_output_routing';
  static const String audioSampleRate = 'nexa_audio_sample_rate';
  static const String audioBitDepth = 'nexa_audio_bit_depth';
  static const String audioDithering = 'nexa_audio_dithering';
  static const String audioHiResMode = 'nexa_audio_hires_mode';
  static const String audioReplayGainMode = 'nexa_audio_replaygain_mode';
  static const String audioReplayGainPreamp = 'nexa_audio_replaygain_preamp';
  static const String audioDvcEnabled = 'nexa_audio_dvc_enabled';
  static const String audioStereoWidening = 'nexa_audio_stereo_widening';

  // Control Settings
  static const String controlResumeAfterCall = 'nexa_control_resume_after_call';
  static const String controlAudioFocusPolicy = 'nexa_control_audio_focus_policy';
  static const String controlHeadsetUnplugged = 'nexa_control_headset_unplugged';
  static const String controlHeadsetPlugged = 'nexa_control_headset_plugged';
  static const String controlBluetoothConnected = 'nexa_control_bluetooth_connected';
  static const String controlVolumeButtonsAction = 'nexa_control_volume_buttons_action';
  static const String controlPauseOnZeroVolume = 'nexa_control_pause_zero_volume';
  static const String controlShakeNextTrack = 'nexa_control_shake_next';
  static const String controlShakeSensitivity = 'nexa_control_shake_sensitivity';
  static const String controlLongPressPlay = 'nexa_control_long_press_play';
  static const String controlDoubleTap = 'nexa_control_double_tap';
  static const String controlSwipeNotification = 'nexa_control_swipe_notification';
  static const String controlCarMode = 'nexa_control_car_mode';
  static const String controlDefaultSleepTimerMinutes = 'nexa_control_sleep_timer_default_min';

  // Album Art Settings
  static const String artDownloadMissing = 'nexa_art_download_missing';
  static const String artWifiOnly = 'nexa_art_wifi_only';
  static const String artSaveWithoutExtension = 'nexa_art_save_no_ext';
  static const String artSavedFolder = 'nexa_art_saved_folder';
  static const String artDownloadQuality = 'nexa_art_download_quality';
  static const String artMaxDownloadSize = 'nexa_art_max_download_size';
  static const String artEmbeddedPriority = 'nexa_art_embedded_priority';
  static const String artBlurBackground = 'nexa_art_blur_background';
  static const String artAutoCropSquare = 'nexa_art_auto_crop_square';
  static const String artAnimatedCovers = 'nexa_art_animated_covers';

  // Scanner Additional Settings
  static const String scannerExcludedFolders = 'nexa_scanner_excluded_folders';
  static const String scannerScanOnLaunch = 'nexa_scanner_scan_on_launch';
  static const String scannerNotifyNewTracks = 'nexa_scanner_notify_new_tracks';
  static const String scannerTagEncoding = 'nexa_scanner_tag_encoding';
  static const String scannerSkipNoMedia = 'nexa_scanner_skip_nomedia';
  static const String scannerSkipMp4 = 'nexa_scanner_skip_mp4';
  static const String scannerSkipOgg = 'nexa_scanner_skip_ogg';
  static const String scannerSkipShortAudio = 'nexa_scanner_skip_short_audio';
  static const String scannerMinDurationSeconds = 'nexa_scanner_min_duration_seconds';
  static const String scannerSkipSmallFiles = 'nexa_scanner_skip_small_files';
  static const String scannerMinSizeBytes = 'nexa_scanner_min_size_bytes';
  static const String scannerScanNetworkShares = 'nexa_scanner_scan_network_shares';
  static const String scannerWatchForChanges = 'nexa_scanner_watch_changes';
  static const String scannerRecognizedExtensions = 'nexa_scanner_recognized_extensions';

  // Appearance Additional Settings
  static const String appearanceNotificationStyle = 'nexa_appearance_notif_style';
  static const String appearanceLockScreenControls = 'nexa_appearance_lockscreen_controls';
  static const String appearanceLanguage = 'nexa_appearance_language';
  static const String appearanceHideEmptyMenuItems = 'nexa_appearance_hide_empty_menus';
  static const String appearanceAccentColorSource = 'nexa_appearance_accent_color_source';
  static const String appearanceListAnimation = 'nexa_appearance_list_animation';
  static const String appearanceAdditionalListField = 'nexa_appearance_additional_list_field';
  static const String appearanceScrollToCurrentTrack = 'nexa_appearance_scroll_current_track';
  static const String appearanceDisableAutoRotate = 'nexa_appearance_disable_auto_rotate';
  static const String appearanceStartupScreen = 'nexa_appearance_startup_screen';
  static const String appearanceFontSize = 'nexa_appearance_font_size';
  static const String appearanceVisualizerStyle = 'nexa_appearance_visualizer_style';
  static const String appearanceMiniPlayerStyle = 'nexa_appearance_mini_player_style';
  static const String appearanceNowPlayingLayout = 'nexa_appearance_now_playing_layout';
  static const String appearanceCornerRadius = 'nexa_appearance_corner_radius';

  // Metadata & Lyrics Settings
  static const String metadataTranslateMetadata = 'nexa_metadata_translate_metadata';
  static const String metadataTranslationProvider = 'nexa_metadata_translation_provider';
  static const String metadataPreferredLyricsSource = 'nexa_metadata_pref_lyrics_source';
  static const String metadataAutoFetchLyrics = 'nexa_metadata_auto_fetch_lyrics';
  static const String metadataLyricsFontSize = 'nexa_metadata_lyrics_font_size';
  static const String metadataLyricsHighlightColor = 'nexa_metadata_lyrics_highlight_color';
  static const String metadataWriteTagsToFile = 'nexa_metadata_write_tags_file';
  static const String metadataArtworkWriteToFile = 'nexa_metadata_art_write_file';

  // Power Saving Settings
  static const String powerSavingMode = 'nexa_power_saving_mode';
  static const String powerReduceAnimations = 'nexa_power_reduce_animations';
  static const String powerPauseLowBattery = 'nexa_power_pause_low_battery';
  static const String powerLowBatteryThreshold = 'nexa_power_low_battery_threshold';
  static const String powerStopServiceMinimized = 'nexa_power_stop_service_minimized';
  static const String powerWakeLock = 'nexa_power_wake_lock';

  // Notifications & Widgets
  static const String notificationShowPlayback = 'nexa_notif_show_playback';
  static const String notificationActions = 'nexa_notif_actions';
  static const String notificationWidgetFormat = 'nexa_notif_widget_format';
  static const String notificationAndroidAuto = 'nexa_notif_android_auto';
  static const String notificationWearOs = 'nexa_notif_wear_os';

  // Privacy & Storage
  static const String privacyCrashReporting = 'nexa_privacy_crash_reporting';
  static const String privacyAnalytics = 'nexa_privacy_analytics';

  // Visualizer & Spectrum Settings (Phase 10)
  static const String visualizerStyle = 'nexa_visualizer_style';
  static const String visualizerColor = 'nexa_visualizer_color';
  static const String visualizerSensitivity = 'nexa_visualizer_sensitivity';
  static const String visualizerFpsCap = 'nexa_visualizer_fps_cap';
  static const String visualizerFftSize = 'nexa_visualizer_fft_size';
  static const String visualizerShowOnLockscreen = 'nexa_visualizer_show_lockscreen';

  // Dynamic Theme & Widgets (Phase 12)
  static const String dynamicAlbumArtTheme = 'nexa_dynamic_album_art_theme';
  static const String widgetThemeMode = 'nexa_widget_theme_mode';
  static const String widgetShowVinyl = 'nexa_widget_show_vinyl';
  static const String widgetBackgroundOpacity = 'nexa_widget_bg_opacity';
  static const String widgetCornerRadius = 'nexa_widget_corner_radius';
  static const String widgetShowGlow = 'nexa_widget_show_glow';
  static const String widgetAdaptiveColors = 'nexa_widget_adaptive_colors';

  // Auto & Wearable Ecosystem (Phase 13)
  static const String carModeKeepScreenAwake = 'nexa_car_keep_screen_awake';
  static const String carModeLargeButtons = 'nexa_car_large_buttons';
  static const String carModeBluetoothAutoLaunch = 'nexa_car_bt_auto_launch';
  static const String wearCompanionEnabled = 'nexa_wear_companion_enabled';

  // Cloud & Network Streaming (Phase 14)
  static const String networkServersList = 'nexa_network_servers_list';
  static const String cloudCacheMaxMb = 'nexa_cloud_cache_max_mb';
  static const String cloudAutoDiscoverCast = 'nexa_cloud_auto_discover_cast';
  static const String cloudBufferAheadSec = 'nexa_cloud_buffer_ahead_sec';
  static const String cloudLosslessAudio = 'nexa_cloud_lossless_audio';
  static const String lastCastDeviceId = 'nexa_last_cast_device_id';
}
