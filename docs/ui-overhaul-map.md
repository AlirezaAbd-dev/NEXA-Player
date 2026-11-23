# 🗺️ NEXA Player — UI Overhaul Inventory & Transition Map
> **Document Status**: Baseline Snapshot (Phase 0 — Task 0.1)  
> **Associated Task**: `01a204da-c5b6-7e91-a0ad-e32ee31ae3ba`  
> **Constraint**: Read-only inventory. Zero `.dart` files modified during this phase.

---

## 1. Executive Summary & Design System Transition

This document establishes the authoritative inventory of all design tokens, surfaces, shared presentation widgets, and screens across the **NEXA Player** codebase. It defines the baseline snapshot before transitioning from legacy 1.0px bordered neon glassmorphism to the **Tactile Studio Instrument** borderless tonal elevation standard ($L_0$ through $L_4$).

```
┌────────────────────────────────────────────────────────┐
│           LEGACY GLASSMORPHISM (Obsidian)              │
│  - Hairline 1.0px white@25% borders on every card     │
│  - Heavy BackdropFilter blurs (16–24dp)                │
│  - High GPU compositing overhead                       │
└──────────────────────────┬─────────────────────────────┘
                           │
                           ▼
┌────────────────────────────────────────────────────────┐
│        TACTILE STUDIO INSTRUMENT (Borderless)          │
│  - L0 (Canvas): #050507 (Dark) / #F4F5F7 (Daylight)    │
│  - L1 (Recessed): #0D0E12 (Dark) / #E8EAF0 (Daylight)  │
│  - L2 (Surface): #14151B + 4% tint / #FFFFFF           │
│  - L3 (Floating): #1D1F28 + 8% tint / #FFFFFF + shadow │
│  - L4 (Interactive): High-chroma accent fill           │
│  - Zero raw borders (SurfaceBorderReason only)         │
└────────────────────────────────────────────────────────┘
```

---

## 2. Design Tokens, Themes & Surface Infrastructure

### 2.1 Core Design System Tokens
| Component / Token File | Path | Current Responsibility |
|---|---|---|
| `GlassTokens` | `lib/core/design_system/glass_tokens.dart` | Blur radii (8, 16, 24, 32dp), opacity thresholds (0.08–0.24), 1.0px border widths, specular gradients, corner radii (8, 12, 16, 24dp). |
| `AppSpacing` | `lib/core/design_system/app_spacing.dart` | 8-step spacing scale (4, 8, 12, 16, 24, 32, 48, 64dp) and EdgeInsets helpers. |
| `AppTypography` | `lib/core/design_system/app_typography.dart` | Material 3 typography scale (display, headline, title, body, label). |
| `DesignSystem` | `lib/core/design_system/design_system.dart` | Central barrel export for design system tokens. |

### 2.2 Theme Engine & Palettes
| Component / File | Path | Current Responsibility |
|---|---|---|
| `ColorPalettes` | `lib/core/theme/color_palettes.dart` | 8 built-in theme palettes (Midnight, Obsidian, Cyberpunk, Aurora, Synthwave, Emerald, Daylight, Sakura). |
| `AppThemePreset` | `lib/core/theme/theme_preset.dart` | Enum representing available presets and metadata. |
| `ThemeState` | `lib/core/theme/theme_state.dart` | State model tracking active preset, brightness mode (dark/light/system), and custom HSL values. |
| `CustomThemeData` | `lib/core/theme/custom_theme_data.dart` | Data model for user-customized HSL theme tokens. |
| `ThemeController` | `lib/core/theme/theme_controller.dart` | AsyncNotifier managing persistent theme switching. |
| `DynamicPaletteService` | `lib/core/theme/dynamic_palette_service.dart` | Extracts primary/accent hues from album artwork for adaptive dynamic theming. |
| `DynamicPaletteProviders` | `lib/core/theme/dynamic_palette_providers.dart` | Riverpod providers exposing dynamic color palettes. |
| `AppTheme` | `lib/core/theme/app_theme.dart` | ThemeData factory constructing Material 3 themes with CustomThemeExtension. |

### 2.3 Shared Glassmorphic & Surface Widgets
| Widget Class | Path | Elements to Refactor in Phase 1+ |
|---|---|---|
| `GlassCard` | `lib/shared/widgets/glass/glass_card.dart` | Uses `Border.all(1.0)`. Must delegate to borderless `NexaSurface`. |
| `GlassButton` | `lib/shared/widgets/glass/glass_button.dart` | Outlined variants use borders. Move to tonal elevation fills. |
| `GlassAppBar` | `lib/shared/widgets/glass/glass_app_bar.dart` | Frosted blur top bar; convert to `L0`/`L1` adaptive background wash. |
| `GlassBottomNav` | `lib/shared/widgets/glass/glass_bottom_nav.dart` | 5-tab bar; convert bottom container to `L2`/`L3` borderless pill dock. |
| `GlassChip` | `lib/shared/widgets/glass/glass_chip.dart` | Filter chips; remove borders; use `L1` (inactive) / `L4` (active). |
| `GlassFAB` | `lib/shared/widgets/glass/glass_fab.dart` | Floating action button; convert to `L4` interactive pill. |
| `GlassTextField` | `lib/shared/widgets/glass/glass_text_field.dart` | Search inputs; remove border; use `L1` recessed input well. |
| `AppAmbientBackground` | `lib/shared/widgets/glass/app_ambient_background.dart` | Mesh/radial gradient background; blend with `L0` canvas. |

### 2.4 Domain Cards & Overlays
| Widget Class | Path | Description |
|---|---|---|
| `TrackTile` | `lib/shared/widgets/cards/track_tile.dart` | Song row item with artwork, title marquee, artist/album subtitle, duration. |
| `AlbumCard` | `lib/shared/widgets/cards/album_card.dart` | 2-column grid and list view card with glass overlay. |
| `ArtistCard` | `lib/shared/widgets/cards/artist_card.dart` | Circular avatar artist item with track/album counts. |
| `GenreCard` | `lib/shared/widgets/cards/genre_card.dart` | Genre tile with color gradient and track counter. |
| `AppBottomSheet` | `lib/shared/widgets/feedback/app_bottom_sheet.dart` | Modal bottom sheet; convert to `L3` floating surface. |
| `AppDialog` | `lib/shared/widgets/feedback/app_dialog.dart` | Modal alert dialog; convert to `L3` floating surface. |
| `AppSnackbar` | `lib/shared/widgets/feedback/app_snackbar.dart` | Toast snackbar notification. |

---

## 3. Exhaustive 36-Screen Portfolio (Grouped by 7 Sections)

### Section 1: Hero Audio & Playback Experiences
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **1.1** | Now Playing Screen | `lib/features/player/presentation/screens/now_playing_screen.dart` | `/player` | 56-bar tactile waveform scrubber, 3D metadata flip, 5-star rating, sleep timer, EQ shortcut. |
| **1.2** | Studio Equalizer & DSP | `lib/features/equalizer/presentation/screens/equalizer_screen.dart` | `/equalizer` | 10-band Catmull-Rom spline, Preamp (-15 to +15dB), Z-Bass, 3D Virtualizer, Reverb presets. |
| **1.3** | Ringtone Trimmer | `lib/features/playlists/presentation/screens/ringtone_trimmer_screen.dart` | `/ringtone-trimmer` | Dual-handle precision waveform slicer, millisecond readout, audition player, export targets. |
| **1.4** | Synced Lyrics & Karaoke | `lib/features/lyrics/presentation/screens/lyrics_screen.dart` | `/lyrics` | Real-time active lyric line tracking, auto-scroll centering, +/-0.1s offset calibration bar. |
| **1.5** | Real-Time FFT Visualizer | `lib/features/visualizer/presentation/screens/visualizer_settings_screen.dart` | `/settings/visualizer` | 5 visualizer modes (Bars, Circle, Wave, Spectrogram, VU Meter), FPS cap, sensitivity slider. |

### Section 2: Core Library Navigation & Detail Views
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **2.1** | Songs Tab + Mini-Player | `lib/features/library/presentation/screens/songs_tab_screen.dart`<br/>`lib/app/shell/mini_player_slot.dart` | `/songs` (Shell Tab 0) | Direct track listing, sorting, quick play, persistent floating mini-player pill. |
| **2.2** | Albums Grid View | `lib/features/library/presentation/screens/albums_tab_screen.dart` | `/albums` (Shell Tab 1) | 2-column album grid, release year badge, track count chip, fast scroll. |
| **2.3** | Album Detail View | `lib/features/library/presentation/screens/album_detail_screen.dart` | Pushed from Albums | Full-bleed hero art header, release metadata, track listing, favorite toggles. |
| **2.4** | Artists Tab View | `lib/features/library/presentation/screens/artists_tab_screen.dart` | `/artists` (Shell Tab 2) | Circular artist portraits, track/album counts, alphabetical fast-scroll index. |
| **2.5** | Artist Detail View | `lib/features/library/presentation/screens/artist_detail_screen.dart` | Pushed from Artists | Discography catalog, top tracks, releases grouped by studio albums and EPs. |
| **2.6** | Playlists Tab View | `lib/features/playlists/presentation/screens/playlists_tab_screen.dart` | `/playlists` (Shell Tab 3) | Smart playlists (Recently Added, Most Played, Favorites), user playlists, create FAB. |
| **2.7** | Playlist Detail View | `lib/features/playlists/presentation/screens/playlist_detail_screen.dart` | Pushed from Playlists | Reorderable track list, total runtime calculation, M3U export, tag editor launcher. |
| **2.8** | Folders Storage Browser | `lib/features/library/presentation/screens/folders_tab_screen.dart` | Sub-view of Library | File directory tree navigation, breadcrumbs, folder track count, play folder trigger. |

### Section 3: Instant Search & Discovery
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **3.1** | Cross-Library Search | `lib/features/search/presentation/screens/search_screen.dart` | `/search` | Sub-10ms indexed search, category filter chips (Songs, Albums, Artists), recent history, voice input modal. |

### Section 4: Theme Engine, Custom Styling & Design System
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **4.1** | Built-in Theme Picker | `lib/features/themes/presentation/screens/theme_picker_screen.dart` | `/settings/theme` | 8 preset swatch cards with WCAG AA badges and 1-tap theme activation. |
| **4.2** | Custom HSL Theme Editor | `lib/features/themes/presentation/screens/custom_theme_editor_screen.dart` | `/settings/theme/custom` | Interactive Hue/Saturation/Lightness sliders, live preview box, real-time contrast ratio readout. |
| **4.3** | Design System Showcase | `lib/features/settings/presentation/screens/design_system_showcase_screen.dart` | `/settings/design-system` | Living catalog of all components, buttons, typography, cards, and spacing scales. |
| **4.4** | Daylight Mode (Light Variation) | `lib/features/library/presentation/screens/songs_tab_screen.dart` (Daylight) | Preset switch | High-contrast light mode with crisp typography and subtle shadows. |
| **4.5** | Sakura Mode (Color Variation) | `lib/features/library/presentation/screens/albums_tab_screen.dart` (Sakura) | Preset switch | Deep cherry blossom dark preset with magenta/pink accents. |

### Section 5: Multi-Device Ecosystem, Auto & Wearables
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **5.1** | Car Mode Dashboard | `lib/features/auto/presentation/screens/car_mode_screen.dart` | `/car-mode` | True AMOLED `#000000` canvas, oversized $\ge 72\text{dp}$ touch targets, blind swipe controls. |
| **5.2** | Wear OS Remote Companion | `lib/features/auto/presentation/screens/wear_companion_screen.dart` | `/wear` | Circular/square smartwatch UI, rotary bezel progress scrubber, transport controls. |
| **5.3** | Homescreen Widgets Showcase | `lib/features/widgets/presentation/screens/widget_showcase_screen.dart` | `/widgets` | 4 widget layouts (4x1 Capsule, 4x2 Hero Vinyl, 2x2 Square, 4x3 Karaoke) + live customizer. |
| **5.4** | Ambient Bedside Standby | `lib/features/player/presentation/screens/standby_mode_screen.dart` | `/standby` | Anti-burn-in micro-drift, rotating vinyl with tonearm, clock, 3-tier dimming. |

### Section 6: Audiophile Settings Hub & System Subsections
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **6.1** | Settings Hub Overview | `lib/features/settings/presentation/screens/settings_hub_screen.dart` | `/settings` (Shell Tab 4) | Master categorical list of all 12 configuration subsections with icons and badges. |
| **6.2** | In-Page Settings Search | `lib/features/settings/presentation/screens/settings_hub_screen.dart` | Top search bar | Instant fuzzy search indexing all settings items with breadcrumb jump navigation. |
| **6.3** | Audio Output & DVC | `lib/features/settings/presentation/screens/audio_settings_screen.dart` | `/settings/audio` | Direct Volume Control (DVC), ReplayGain 2.0, gapless, crossfade, USB DAC sample rate. |
| **6.4** | Auto & Wearables Config | `lib/features/auto/presentation/screens/auto_wearable_settings_screen.dart` | `/settings/auto` | Keep awake in car cradle, bluetooth auto-launch, Wear OS sync interval. |
| **6.5** | Media Scanner & Folders | `lib/features/settings/presentation/screens/scanner_settings_screen.dart` | `/settings/scanner` | Folder whitelist/blacklist, minimum duration filter, rescan triggers. |
| **6.6** | Album Art & Cache | `lib/features/settings/presentation/screens/album_art_settings_screen.dart` | `/settings/album-art` | Art resolution, prefer embedded vs folder art, cache size gauge, clear cache action. |
| **6.7** | Gestures & Headset Controls | `lib/features/settings/presentation/screens/control_settings_screen.dart` | `/settings/controls` | Headset double/triple click actions, shake-to-skip sensitivity, volume key seek. |
| **6.8** | Lock Screen & Notifications | `lib/features/settings/presentation/screens/notifications_settings_screen.dart` | `/settings/notifications` | Media notification style, notification seekbar toggle, lock screen widget visibility. |
| **6.9** | Power Saving & Audio Focus | `lib/features/settings/presentation/screens/power_saving_settings_screen.dart` | `/settings/power-saving` | Audio focus duck vs pause, pause on unplug, CPU wakelocks, battery optimization guide. |
| **6.10** | Privacy & JSON Backup | `lib/features/settings/presentation/screens/privacy_storage_settings_screen.dart` | `/settings/privacy` | Playback history toggle, export full settings/playlists to encrypted JSON, restore. |
| **6.11** | Metadata & Lyrics Provider | `lib/features/settings/presentation/screens/metadata_lyrics_settings_screen.dart` | `/settings/metadata` | Tag encoding fallback (UTF-8, ID3v2), LRCLIB provider preferences, local LRC preference. |
| **6.12** | About NEXA & Specs | `lib/features/settings/presentation/screens/about_settings_screen.dart` | `/settings/about` | Audio engine technical specifications, version build info, licenses, changelog dialog. |

### Section 7: Responsive Desktop Layout & Cloud Network Streaming Hub
| Screen / Section # | Screen Name | File Path | Route / Access | Key Controls & Notes |
|---|---|---|---|---|
| **7.1** | Desktop 3-Zone Studio Layout | `lib/app/shell/scaffold_with_nav_bar.dart` | Width $\ge 720\text{dp}$ | Side NavigationRail, expanded multi-column content stage, persistent bottom transport bar. |
| **7.2** | Cloud Streaming Hub | `lib/features/cloud/presentation/screens/cloud_streaming_hub_screen.dart` | `/cloud` | Active casting target card, configured network servers (WebDAV/NAS), web radio, cache gauge. |
| **7.3** | Network Storage Browser | `lib/features/cloud/presentation/screens/network_server_browser_screen.dart` | `/cloud/browse` | Remote directory breadcrumbs, audio format badges (DSD, FLAC, MP3), 1-tap cache trigger. |
| **7.4** | Casting Picker & Web Radio | `lib/features/cloud/presentation/widgets/cast_device_picker_modal.dart`<br/>`lib/features/cloud/presentation/screens/web_radio_screen.dart` | Modal / `/cloud/radio` | DLNA/UPnP network discovery radar, speaker volume slider, audiophile web radio streams. |

---

## 4. Audio Engine, DSP & State Controllers (Read-Only Contracts)

> **Mandatory Rule**: All UI refactoring in Phase 1 through Phase 5 must strictly consume existing state streams and controllers. Zero modifications to native FFI or decoding pipelines.

### 4.1 Playback Engine Contract (`IAudioEngine`)
- **File**: `lib/features/player/domain/services/audio_engine.dart`
- **Exposed Streams**:
  ```dart
  Stream<PlaybackStatus> get statusStream;
  Stream<Duration> get positionStream;
  Stream<Duration> get durationStream;
  Stream<Duration> get bufferedPositionStream;
  Stream<double> get volumeStream;
  Stream<double> get speedStream;
  ```
- **Operational Methods**: `load(Track)`, `play()`, `pause()`, `stop()`, `seek(Duration)`, `setVolume(double)`, `setSpeed(double)`, `setLoopMode(bool)`.

### 4.2 Equalizer & DSP Contract (`IEqualizerService`)
- **File**: `lib/features/equalizer/domain/services/equalizer_service.dart`
- **Exposed Streams**:
  ```dart
  Stream<EqualizerState> get stateStream;
  EqualizerState get currentState;
  ```
- **Operational Methods**: `setEnabled(bool)`, `setPreamp(double)`, `setBandGain(int, double)`, `setBassBoost(double)`, `setVirtualizer(double)`, `setReverb(ReverbPreset)`, `applyPreset(String)`, `resetToFlat()`.

### 4.3 Playback Queue Contract (`IPlaybackQueue`)
- **File**: `lib/features/player/domain/services/playback_queue.dart`
- **Exposed Streams & Properties**: `currentTrackStream`, `queueStream`, `currentTrack`, `queue`, `currentIndex`.
- **Operational Methods**: `setQueue(List<Track>)`, `insertNext(Track)`, `addToEnd(Track)`, `skipToNext()`, `skipToPrevious()`, `removeAt(int)`, `reorder(int, int)`.

### 4.4 Sleep Timer Contract (`ISleepTimerService`)
- **File**: `lib/features/player/domain/services/sleep_timer_service.dart`
- **Exposed Streams & Properties**: `remainingDurationStream`, `isActiveStream`, `remainingDuration`, `isActive`.
- **Operational Methods**: `startTimer(Duration)`, `cancelTimer()`, `setFinishLastSong(bool)`.

### 4.5 FFT Spectrum Engine (`FftEngine`)
- **File**: `lib/features/visualizer/domain/services/fft_engine.dart`
- **Throughput Benchmark**: $38.46\,\mu\text{s}$ per 256-point block ($> 50\times$ faster than real-time audio).
- **Operational Methods**: `computeMagnitudes(List<double> samples, {double sensitivity})`, `synthesizeTimeDomainSamples(...)`.

---

## 5. Transition Matrix for Phase 1 (Tokens & Surface Hierarchy)

| Legacy Glassmorphism Element | Replaced by Modern Tonal Element | Elevation Tier | Border Handling |
|---|---|---|---|
| Background Canvas | `NexaSurface` or Scaffold background | `L0` (`#050507` Dark / `#F4F5F7` Daylight) | Zero borders |
| Search Wells / Waveform Tracks | `NexaSurface` | `L1` (`#0D0E12` Dark / `#E8EAF0` Daylight) | Zero borders |
| Track Tiles / Cards / Grouped Containers | `NexaSurface` | `L2` (`#14151B` + 4% tint / `#FFFFFF`) | Zero borders |
| Floating Mini-Player / Bottom Sheets | `NexaSurface` | `L3` (`#1D1F28` + 8% tint / `#FFFFFF` + soft shadow) | Zero borders |
| Primary Action Buttons / Active Indicators | `NexaSurface` | `L4` (High-chroma accent fill) | Zero borders |
| Focus Ring / Keyboard Outline | Accessibility Outline | Any tier | `SurfaceBorderReason.focusRing` |
| Selected EQ Node / Waveform Trim Handle | Tactile Control Indicator | Any tier | `SurfaceBorderReason.activeControlContrast` |
| Destructive Action Outline | Destructive Secondary Button | Any tier | `SurfaceBorderReason.destructiveSecondary` |

---

## 6. Verification Checklist for Phase 0

- [x] Scan all 36 screens across the 7 application sections.
- [x] Record all design token and theme infrastructure paths.
- [x] Catalog shared presentation widgets and domain card components.
- [x] Map core audio engine and DSP service contract signatures.
- [x] Verify that 100% of recorded paths exist on disk.
- [x] Assert that **zero** `.dart` files were modified during Phase 0.
