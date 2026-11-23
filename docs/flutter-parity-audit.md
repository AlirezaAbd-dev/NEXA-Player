# 🚨 NEXA Player — Forensic Flutter Parity Audit (`lib/` vs. PIL Mockups)

> **Audit Date**: 2026-11-23  
> **Target Range**: Commits `a872007~1..22cb1e0` (43 UI Audit tasks `00/42` through `42/42`)  
> **Audit Status**: **CRITICAL DISCREPANCY IDENTIFIED**

---

## 1. Executive Summary

A forensic review of commits `a872007` through `22cb1e0` was conducted to compare actual Flutter source code changes (`lib/`, `test/`) against the generated screenshot assets (`docs/screenshots/*.png`).

| Category | Total Count | Percentage | Description |
| :--- | :---: | :---: | :--- |
| **`VERIFIED_IN_FLUTTER`** | **0** | **0.0%** | Zero screens had 100% of audit requirements landed in `lib/` AND verified via `flutter test` / `flutter analyze`. |
| **`PARTIAL`** | **14** | **33.3%** | Commits modified some `lib/` files (Screens `01`–`10`, `11`, `12`, `15`, `16`, `18`), but key audit items (e.g. `ReorderableListView`, spline math, thumb colors, gutter padding) remained in PIL only. |
| **`PIL_ONLY_MISSING`** | **28** | **66.7%** | Entirely mocked in Python PIL (`generate_all_screens_complete.py`, `vector_icons.py`); **zero** `.dart` files modified in `lib/` or `test/`. |
| **Total Screens** | **42** | **100.0%** | Full NEXA Player surface portfolio. |

---

## 2. Git Diff Telemetry

### Commits in Audit Range (`a872007~1..22cb1e0`)
- **Total commits**: 43
- **Commits touching `lib/`**: 11 (Commits `a872007`, `d8a518d`, `b3591ff`, `5a650f7`, `cc60746`, `1f2af56`, `e21d05e`, `32754a9`, `5608140`, `a651826`, `78b79c9`)
- **Commits modifying ONLY `docs/screenshots/` (zero `lib/` changes)**: 32 (Commits `a9940b6` through `22cb1e0`)

### `git diff --stat a872007~1..22cb1e0 -- lib/ test/`
```text
 lib/app/shell/mini_player_slot.dart                | 223 ++++++++++++---------
 lib/core/theme/app_theme.dart                      |  45 +++++
 .../presentation/widgets/server_config_dialog.dart |   3 +-
 .../presentation/screens/equalizer_screen.dart     |   4 +-
 .../widgets/preset_selector_modal.dart             |   8 +-
 .../presentation/screens/album_detail_screen.dart  |  40 ++--
 .../presentation/screens/albums_tab_screen.dart    |  26 ++-
 .../presentation/screens/artist_detail_screen.dart |   3 +
 .../presentation/screens/artists_tab_screen.dart   | 105 ++++++++--
 .../presentation/screens/folders_tab_screen.dart   |  27 ++-
 .../presentation/screens/songs_tab_screen.dart     |  47 ++++-
 .../screens/playlist_detail_screen.dart            |  41 ++++
 .../presentation/screens/playlists_tab_screen.dart |  68 ++++++-
 .../screens/scanner_settings_screen.dart           |  76 +++++--
 .../presentation/widgets/audio_status_strip.dart   |   2 +-
 .../presentation/widgets/settings_tiles.dart       |   4 +-
 .../screens/custom_theme_editor_screen.dart        |   4 -
 .../presentation/screens/theme_picker_screen.dart  |   3 +-
 .../presentation/widgets/theme_preset_card.dart    |  11 +-
 lib/shared/widgets/cards/album_card.dart           |  53 +++--
 lib/shared/widgets/cards/artist_card.dart          | 141 ++++++++-----
 lib/shared/widgets/cards/track_tile.dart           |  84 ++++++--
 22 files changed, 725 insertions(+), 293 deletions(-)
```

### `git diff --stat a872007~1..22cb1e0 -- ':!lib/' ':!test/'`
```text
 42 screenshot files updated in docs/screenshots/ (all generated via Python PIL)
```

---

## 3. 42-Screen Forensic Checklist Table

| # | Screen Name | Real Flutter File (`lib/`) | Parity Status | Forensic Gap Analysis (PIL vs `lib/`) |
| :---: | :--- | :--- | :---: | :--- |
| **01** | Songs Tab & Mini-Player | `lib/features/library/presentation/screens/songs_tab_screen.dart`<br>`lib/app/shell/mini_player_slot.dart` | `PARTIAL` | Landed $L_0$ track rows & mini-player layout in `lib/`, but missing test coverage and theme-propagation check in `MiniPlayerSlot`. |
| **02** | Albums Grid View | `lib/features/library/presentation/screens/albums_tab_screen.dart`<br>`lib/shared/widgets/cards/album_card.dart` | `PARTIAL` | Grid pinch-to-zoom and clean sleeve metadata landed in `lib/`, but 2-line title wrapping needs strict bounded constraints test. |
| **03** | Album Detail Screen | `lib/features/library/presentation/screens/album_detail_screen.dart` | `PARTIAL` | Hero artwork header dissolve landed, but favorite button micro-interaction and sub-screen route honesty need test verification. |
| **04** | Artists Tab View | `lib/features/library/presentation/screens/artists_tab_screen.dart`<br>`lib/shared/widgets/cards/artist_card.dart` | `PARTIAL` | Monogram fallback & direct-on-$L_0$ rows landed in `lib/`, but fast alphabet jump strip needs gesture boundary verification. |
| **05** | Artist Detail Screen | `lib/features/library/presentation/screens/artist_detail_screen.dart` | `PARTIAL` | Only 3 lines added to `lib/`; discography album vs EP separation and Play Top / Shuffle actions were mostly PIL mockups. |
| **06** | Playlists Tab View | `lib/features/playlists/presentation/screens/playlists_tab_screen.dart` | `PARTIAL` | Smart playlist ribbon landed, but 2x2 collage artwork fallback and quick creation FAB need unit/widget tests. |
| **07** | Playlist Detail Screen | `lib/features/playlists/presentation/screens/playlist_detail_screen.dart` | `PARTIAL` | Total runtime calculation landed, but `ReorderableListView` drag-and-drop handles and M3U export actions were not wired in `lib/`. |
| **08** | Folders Storage Browser | `lib/features/library/presentation/screens/folders_tab_screen.dart` | `PARTIAL` | Breadcrumb row updated, but hidden bottom navigation on pushed directory navigation not enforced in `lib/`. |
| **09** | Settings Hub Overview | `lib/features/settings/presentation/screens/settings_hub_screen.dart` | `PARTIAL` | Only 2 lines changed in `audio_status_strip.dart`; 6 category leading icons, single search bar, and 1-tap preset pills missing in `lib/`. |
| **10** | Scanner Settings | `lib/features/settings/presentation/screens/scanner_settings_screen.dart` | `PARTIAL` | Whitelist/blacklist paths landed, but white switch thumbs (`#FFFFFF`) not globally wired into `SwitchThemeData`. |
| **11** | Theme Picker | `lib/features/themes/presentation/screens/theme_picker_screen.dart` | `PARTIAL` | Only 3 lines changed in `theme_preset_card.dart`; live miniature track player previews inside swatches missing in `lib/`. |
| **12** | Custom Theme Editor | `lib/features/themes/presentation/screens/custom_theme_editor_screen.dart` | `PARTIAL` | 4 lines deleted in `lib/`; WCAG contrast readout (`>= 4.5:1`), contrast lock toggle, and safe slider padding only existed in PIL. |
| **13** | Design System Showcase | `lib/features/settings/presentation/screens/design_system_showcase_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Token sync, pill centering, and elevated cards showcase only implemented in PIL script. |
| **14** | Now Playing Screen | `lib/features/player/presentation/screens/now_playing_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Gearshift scrubber, transient edge-slide HUDs, A/B loop pins, and 5-control bottom dock only existed in PIL. |
| **15** | Daylight Mode Songs | `lib/features/library/presentation/screens/songs_tab_screen.dart`<br>`lib/core/theme/color_palettes.dart` | `PARTIAL` | Only `songs_tab_screen.dart` updated; `SystemUiOverlayStyle.dark` status bar icons and Daylight theme token propagation missing in `lib/`. |
| **16** | Sakura Mode Albums | `lib/features/library/presentation/screens/albums_tab_screen.dart`<br>`lib/core/theme/color_palettes.dart` | `PARTIAL` | Only `albums_tab_screen.dart` updated; zero-cyan bleed and full magenta/crimson propagation in `MiniPlayerSlot` missing in `lib/`. |
| **17** | Desktop 3-Zone Studio Layout | `lib/features/player/presentation/screens/desktop_layout_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. 3-zone layout, sidebar NavigationRail, intrinsic density pill, and transport bar only existed in PIL. |
| **18** | Studio Equalizer & DSP | `lib/features/equalizer/presentation/screens/equalizer_screen.dart` | `PARTIAL` | Only 4 lines changed in `equalizer_screen.dart`; 38dp left gutter, Catmull-Rom cubic spline, and 270° rotary knob cards missing in `lib/`. |
| **19** | Precision Ringtone Trimmer | `lib/features/player/presentation/screens/ringtone_trimmer_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Floating timestamp badges, interactive fade handles, $\pm 0.1\text{s}$ steppers, and 4-way export selector missing in `lib/`. |
| **20** | Kinetic Synced Lyrics | `lib/features/player/presentation/screens/lyrics_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Optical depth-of-field blur (`ImageFiltered`), reduced motion guard, and vector calibration pill missing in `lib/`. |
| **21** | Bottom-Anchored Search | `lib/features/search/presentation/screens/search_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Bottom-anchored search bar above keyboard, voice mic button, token parser, and filter chips missing in `lib/`. |
| **22** | In-Page Settings Search | `lib/features/settings/presentation/screens/settings_hub_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Top fuzzy search query filter, breadcrumb chip result navigation, and inline switches missing in `lib/`. |
| **23** | Audio Output & DVC | `lib/features/settings/presentation/screens/audio_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Direct Volume Control (DVC), Fletcher-Munson whisper loudness, SoX resampler, and 32-bit notice missing in `lib/`. |
| **24** | Real-Time FFT Visualizer | `lib/features/visualizer/presentation/screens/visualizer_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Dynamic bar width math (zero right-edge spill), 5-mode selector, parameter card, and fullscreen icon missing in `lib/`. |
| **25** | Homescreen Widgets Showcase | `lib/features/widgets/presentation/screens/widget_showcase_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. 5-way widget carousel, 2x2 circular vinyl rim, 4x3 karaoke widget, and live customizer sheet missing in `lib/`. |
| **26** | Bedside Standby Turntable | `lib/features/player/presentation/screens/standby_bedside_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Pure `#000000` AMOLED mode, centered clock/date, vector tonearm, and bedside dimming dock missing in `lib/`. |
| **27** | Car Mode Dashboard | `lib/features/auto/presentation/screens/car_mode_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Zero Unicode tofu, padded top telemetry (98% battery), $\ge 76\text{dp}$ touch targets, and pure AMOLED mode missing in `lib/`. |
| **28** | Wear OS Remote Companion | `lib/features/auto/presentation/screens/wear_companion_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Watch clock safe clearance, centered track labels, 270° rotary sweep arc (75% vol), and dual-mode toggle missing in `lib/`. |
| **29** | Auto & Wearables Settings | `lib/features/auto/presentation/screens/auto_wearable_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Ecosystem quick-launch tiles, car BT device selector, MediaBrowser toggle, and white switches missing in `lib/`. |
| **30** | About NEXA & Specs | `lib/features/settings/presentation/screens/about_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Centered brand emblem, 4-row audio architecture table, tap-to-copy version pill, and unified link cards missing in `lib/`. |
| **31** | Album Art & Cache Settings | `lib/features/settings/presentation/screens/album_art_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Drag handles on resolution priority, visual cache quota bar (184 MB / 500 MB), and centered clear cache CTA missing in `lib/`. |
| **32** | Gestures & Controls Settings | `lib/features/settings/presentation/screens/control_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Now Playing gesture toggles, shake-to-skip sensitivity label, and white switches missing in `lib/`. |
| **33** | Notifications & Lock Screen | `lib/features/settings/presentation/screens/notifications_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Live mock media notification preview card with squiggly seekbar, inline blur slider (`40%`), and white switch thumbs missing in `lib/`. |
| **34** | Power Saving & Audio Focus | `lib/features/settings/presentation/screens/power_saving_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. `PowerManager` OS exemption status badge, inline 5-way sleep timer preset pills, and white switch thumbs missing in `lib/`. |
| **35** | Privacy & Storage Backup | `lib/features/settings/presentation/screens/privacy_storage_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. 100% On-Device shield status banner, playback/search history toggles, AES-256 backup encryption, and crimson destructive styling missing in `lib/`. |
| **36** | Metadata & Lyrics Settings | `lib/features/settings/presentation/screens/metadata_lyrics_settings_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Tag encoding fallback pills (`UTF-8`, `Windows-1256`, etc.), lyrics provider drag handles, and inline offset steppers missing in `lib/`. |
| **37** | Cloud & Streaming Hub | `lib/features/cloud/presentation/screens/cloud_streaming_hub_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Intrinsic status pill widths (`Connected`, `Available`), distinct vector icons, interactive buffer deck, and back navigation missing in `lib/`. |
| **38** | Network Server Browser | `lib/features/cloud/presentation/screens/network_server_browser_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Full track titles without premature truncation, interactive SMB breadcrumbs, bulk actions, and cache state icons missing in `lib/`. |
| **39** | DLNA Cast Picker | `lib/features/cloud/presentation/widgets/cast_device_picker_modal.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Border ban on active Sonos Arc, shrink-wrapped bottom sheet height, distinct device icons, and Stop Cast action missing in `lib/`. |
| **40** | Headphone AutoEQ Calibration | `lib/features/equalizer/presentation/screens/autoeq_picker_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Bounded telemetry micro-pills (zero card border spill), 3-way target curve selector, form-factor icons, and auto-bind card missing in `lib/`. |
| **41** | Sonic Constellation Star Map | `lib/features/player/presentation/screens/sonic_constellation_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. Full-bleed canvas without bottom nav/mini-player, vector telemetry arrows, smart label placement, and borderless lasso dock missing in `lib/`. |
| **42** | Desktop Studio Dock Inspector | `lib/features/player/presentation/screens/desktop_layout_screen.dart` | `PIL_ONLY_MISSING` | **Zero** changes in `lib/`. `Rock (+4.5 dB)` right margin alignment, Catmull-Rom cubic spline, reorderable queue, and centered shortcut keycaps missing in `lib/`. |

---

## 4. Remediation Plan

To achieve true, verified Flutter parity without synthetic PIL cheats:
1. **Toolchain Setup**: Ensure Flutter/Dart SDK is present and operational in the environment for `flutter analyze` and `flutter test`.
2. **Batch A (Shared Shell & Systemic Parity)**:
   - Configure global `SwitchThemeData.thumbColor` (`#FFFFFF` on selected) in `app_theme.dart`.
   - Remove any raw LaTeX or Unicode symbol strings (`□`, `★`, `✓`, `$L_0$`) in `lib/` widgets.
   - Enforce route honesty (hide bottom nav on pushed sub-screens: `08`, `18`, `21`, `37`, `40`, `41`, `42`).
3. **Batch B (Urgent Layout & Overflow Screens in `lib/`)**:
   - Port Screens `09`, `11`, `12`, `14`, `15`, `16`, `17`, `18`, `24`, `27`, `28`, `37`, `40`, `41`, `42`.
4. **Batch C (Remaining High/Medium/Low Detail Screens in `lib/`)**:
   - Port Screens `05`–`08`, `10`, `13`, `19`–`23`, `25`–`26`, `29`–`36`, `38`–`39`.
5. **Real Flutter Golden Verification**:
   - Implement real Flutter widget golden tests (`test/golden/`) covering key viewports (`360x780`, `412x915`, `1280x800`).
