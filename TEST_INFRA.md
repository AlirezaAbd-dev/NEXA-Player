# TEST_INFRA.md — NEXA Player Testing Infrastructure & Test Suite Architecture

## 1. Overview & Testing Philosophy

NEXA Player is an offline-first, high-fidelity music player for mobile and cross-platform desktop targets. The test infrastructure guarantees rock-solid reliability, zero runtime crashes, seamless responsive adaptation, and visual precision across all supported platforms.

### Core Testing Principles
1. **Opaque-Box Verification**: Tests interact strictly through observable interfaces: UI widgets, semantic keys (`E2EKeys`), standard gestures (`tap`, `drag`, `scroll`), layout geometry, and public service contracts. Tests never manipulate private internal state.
2. **Progressive Testability**: Tests are designed to verify features incrementally as milestones land. Harnesses provide stable interface contracts that decouple test execution from ongoing milestone implementation.
3. **Multi-Tier Hierarchy**: Tests are partitioned into rigorous tiers from unit isolation to full application scenarios and adversarial stress testing.
4. **Deterministic Authoritative Expectations**: Every assertion is derived from explicit requirements in `PROJECT.md`, `ORIGINAL_REQUEST.md`, and design token specifications—never guessing or matching arbitrary implementation outputs.
5. **Zero Lint & Analyzer Tolerance**: All test files must compile cleanly with `0 issues` under `dart analyze` and pass with `100% success` under `flutter test`.

---

## 2. Test Architecture & Tier Structure

The testing suite is structured into 5 distinct tiers:

```
┌─────────────────────────────────────────────────────────────┐
│ Tier 5: Adversarial, Stress & Negative Boundary Hardening    │
├─────────────────────────────────────────────────────────────┤
│ Tier 4: Real-World End-to-End Application Scenarios         │
├─────────────────────────────────────────────────────────────┤
│ Tier 3: Cross-Feature Combinations (Pairwise Matrix)        │
├─────────────────────────────────────────────────────────────┤
│ Tier 2: Boundary Conditions, Edge & Corner Cases            │
├─────────────────────────────────────────────────────────────┤
│ Tier 1: Feature Coverage & Functional Acceptance            │
└─────────────────────────────────────────────────────────────┘
```

- **Tier 1: Feature Coverage**: Validates happy paths and core contracts for every feature area (DI, Logging, Result, Themes, Glass Widgets, Shell Navigation, Responsive Layout).
- **Tier 2: Boundary & Corner Cases**: Tests extreme inputs, edge dimensions, missing data, corrupted storage, rapid actions, and zero-value bounds.
- **Tier 3: Cross-Feature Combinations**: Pairwise validation combining themes, brightness modes, layout breakpoints, navigation tabs, and error states.
- **Tier 4: Real-World Application Scenarios**: Simulates end-to-end user journeys (first launch, theme customization, library exploration across device rotation, player docking).
- **Tier 5: Adversarial & Stress Scenarios**: High-frequency interaction stress, memory stability, overflow prevention, and graceful degradation under hardware blur limits.

---

## 3. Feature Mapping & Coverage Matrix

Every feature from `PROJECT.md § Feature Inventory` is mapped into a designated testing area:

| Feature ID | Feature Name | Area | Milestone | Primary Verification Tier |
|---|---|---|---|---|
| **F0.1** | Feature-Based Directory Layout | Area A (Foundation) | M1 | Tier 1, Static Analysis |
| **F0.2** | SOLID Interface Contracts | Area A (Foundation) | M1 | Tier 1, Tier 2 |
| **F0.3** | Dependency Injection Container | Area A (Foundation) | M1 | Tier 1, Tier 2 |
| **F0.4** | Structured Logging System | Area A (Foundation) | M1 | Tier 1, Tier 2, Tier 5 |
| **F0.5** | Result & Failure Monad | Area A (Foundation) | M1 | Tier 1, Tier 2, Tier 3 |
| **F0.6** | Riverpod 2 State Foundation | Area A (Foundation) | M1 | Tier 1, Tier 3, Tier 4 |
| **F0.7** | Core Extensions & Utils | Area A (Foundation) | M1 | Tier 1, Tier 2 |
| **F0.8** | Glassmorphism Token Suite | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F0.9** | Spacing & Typography Scale | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F0.10** | 8 Built-in Preset Themes | Area B (Themes) | M2 | Tier 1, Tier 3, Tier 4 |
| **F0.11** | Dark / Light / System Mode | Area B (Themes) | M2 | Tier 1, Tier 3 |
| **F0.12** | Custom HSL Theme Editor | Area B (Themes) | M2 | Tier 1, Tier 2, Tier 4 |
| **F0.13** | Theme Persistence | Area B (Themes) | M2 | Tier 1, Tier 2, Tier 4 |
| **F1.1** | GlassCard Widget | Area C (Design System) | M3 | Tier 1, Tier 2, Tier 5 |
| **F1.2** | GlassAppBar Widget | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F1.3** | GlassBottomNav Widget | Area C (Design System) | M3 | Tier 1, Tier 3, Tier 4 |
| **F1.4** | GlassFAB Widget | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F1.5** | GlassButton Widget | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F1.6** | GlassTextField Widget | Area C (Design System) | M3 | Tier 1, Tier 2, Tier 5 |
| **F1.7** | GlassChip Widget | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F1.8** | TrackTile Widget | Area C (Design System) | M3 | Tier 1, Tier 2, Tier 4 |
| **F1.9** | AlbumCard Widget | Area C (Design System) | M3 | Tier 1, Tier 2, Tier 4 |
| **F1.10** | ArtistCard Widget | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F1.11** | GenreCard Widget | Area C (Design System) | M3 | Tier 1, Tier 2 |
| **F1.12** | Feedback Overlays | Area C (Design System) | M3 | Tier 1, Tier 2, Tier 4 |
| **F1.13** | Declarative Shell Router | Area D (Navigation) | M4 | Tier 1, Tier 2, Tier 4 |
| **F1.14** | 5 Primary Tabs | Area D (Navigation) | M4 | Tier 1, Tier 3, Tier 4 |
| **F1.15** | Mini-Player Anchor Slot | Area D (Navigation) | M4 | Tier 1, Tier 3, Tier 4 |
| **F1.16** | Responsive Layout Breakpoints | Area D (Navigation) | M4 | Tier 1, Tier 2, Tier 3, Tier 4 |
| **F1.17** | Design System Showcase Screen | Area C (Design System) | M3 | Tier 1, Tier 4 |
| **F1.18** | Zero Static Analysis Warnings | Area E (Quality) | M5 | Static Analysis, CI Gate |
| **F1.19** | Automated Unit & Widget Tests | Area E (Quality) | M5 | Test Suite Execution |

---

## 4. Test Case Inventory

### Tier 1: Feature Coverage (>=5 test cases per feature area)

#### Area A: Architecture, DI & Foundation (F0.1–F0.7)
- `T1.A.1`: Verify `get_it` container registers and resolves `ILoggingService` and `IStorageService` singletons without throwing.
- `T1.A.2`: Verify `Result.success` correctly encapsulates value, returns `isSuccess == true`, and executes `onSuccess` callback via `fold`/`when`.
- `T1.A.3`: Verify `Result.failure` encapsulates `Failure`, returns `isFailure == true`, and executes `onFailure` callback via `fold`/`when`.
- `T1.A.4`: Verify `IStorageService` persists and retrieves string and boolean values matching exact keys.
- `T1.A.5`: Verify `Duration` extension formatters convert millisecond durations to standard `mm:ss` (e.g. `225000ms -> "03:45"`) and `hh:mm:ss` strings.
- `T1.A.6`: Verify `ILoggingService` delegates debug, info, warning, and error messages to structured logging without unhandled exceptions.

#### Area B: Theme Engine & Customization (F0.10–F0.13)
- `T1.B.1`: Verify switching between all 8 preset themes (Midnight Black, Deep Space, Sakura, Ocean Blue, Forest Green, Lava, Daylight, Neon Purple) updates active color tokens.
- `T1.B.2`: Verify Midnight Black preset resolves dark background color to absolute `#000000` (AMOLED black).
- `T1.B.3`: Verify Daylight preset applies crisp light background `#F8FAFC` and dark text contrast.
- `T1.B.4`: Verify switching brightness mode between `ThemeMode.dark`, `ThemeMode.light`, and `ThemeMode.system` triggers reactive rebuilds.
- `T1.B.5`: Verify Custom Theme HSL model produces valid `ColorScheme` from hue, saturation, and lightness inputs.
- `T1.B.6`: Verify Theme persistence writes active preset and mode keys to `IStorageService` upon modification.

#### Area C: Glassmorphism Design System & Components (F0.8, F0.9, F1.1–F1.12, F1.17)
- `T1.C.1`: Verify `GlassCard` applies `ClipRRect`, `BackdropFilter` with blur sigma 16–24dp, and 1dp border with alpha transparency.
- `T1.C.2`: Verify `GlassAppBar` renders title, leading widget, actions, and translucent frosted glass styling.
- `T1.C.3`: Verify `GlassBottomNav` renders 5 primary tab destinations with active glow indicators and dispatches tap callbacks.
- `T1.C.4`: Verify `TrackTile` displays track artwork placeholder, title, artist, duration, and trailing popup menu.
- `T1.C.5`: Verify `AlbumCard` renders album cover art, title, and artist subtitle in both grid and list orientations.
- `T1.C.6`: Verify feedback overlays (`AppSnackbar`, `AppDialog`, `AppBottomSheet`) display frosted glass background and dismiss properly.
- `T1.C.7`: Verify `GlassButton` renders filled, outlined, and ghost variants and fires `onPressed` callback.

#### Area D: Shell Navigation, Mini-Player & Responsive Layout (F1.13–F1.16)
- `T1.D.1`: Verify default launch route initializes at Tab 0 (`/songs`) with Songs screen rendered.
- `T1.D.2`: Verify tapping each tab (Songs, Albums, Artists, Playlists, Settings) switches the active screen branch.
- `T1.D.3`: Verify tab scroll state and sub-navigation are preserved when switching between tabs (`StatefulShellRoute`).
- `T1.D.4`: Verify `MiniPlayerSlot` is visible directly above bottom navigation bar across all 5 primary tabs.
- `T1.D.5`: Verify tapping `MiniPlayerSlot` navigates to fullscreen `/player` (Now Playing), hiding the shell navigation bar.
- `T1.D.6`: Verify compact screen width (<600dp) renders `GlassBottomNav` and hides `NavigationRail`.
- `T1.D.7`: Verify expanded screen width (>840dp) renders persistent `NavigationRail` and hides `GlassBottomNav`.

#### Area E: Quality & Static Analysis (F1.18, F1.19)
- `T1.E.1`: Verify `dart analyze` reports 0 errors, 0 warnings, and 0 lints.
- `T1.E.2`: Verify `flutter test` executes all unit and widget tests with 100% pass rate.
- `T1.E.3`: Verify widget tree contains zero hardcoded magic numbers for glass tokens, spacing, and border radii.
- `T1.E.4`: Verify unhandled errors inside services are converted to `Result.failure` without crashing the Flutter framework.
- `T1.E.5`: Verify `ProviderScope` properly encapsulates state overrides during testing without leaking across test cases.

---

### Tier 2: Boundary & Corner Cases (>=5 test cases per feature area)

#### Area A: Architecture & Foundation
- `T2.A.1`: `Result` with null value (`Result<void, Failure>.success(null)`) executes success branch safely.
- `T2.A.2`: `IStorageService.getString` for a nonexistent key returns `Result.success(null)` without throwing.
- `T2.A.3`: `IStorageService.clear()` on an already empty storage succeeds gracefully.
- `T2.A.4`: `IStorageService` handles extreme string payloads (e.g. 500KB serialized JSON data).
- `T2.A.5`: Duration formatter handles zero duration (`Duration.zero -> "00:00"`) and negative duration safely.
- `T2.A.6`: Calling unregistered service via `get_it` throws descriptive `StateError` rather than crashing silently.

#### Area B: Theme Engine
- `T2.B.1`: Custom HSL editor handles boundary hue values: `0.0°` (red) and `360.0°` (wrap-around red).
- `T2.B.2`: Custom HSL editor handles saturation `0.0` (pure grayscale monochrome) and `1.0` (maximum saturation).
- `T2.B.3`: Custom HSL editor clamps lightness `0.0` (pure black) and `1.0` (pure white) with contrast protection to prevent invisible text.
- `T2.B.4`: Theme engine gracefully recovers when storage contains corrupted/unrecognized theme preset name, falling back to default.
- `T2.B.5`: Rapid theme switching (10 theme preset changes in <500ms) completes without dropping frames or corrupting state.

#### Area C: Glassmorphism Design System
- `T2.C.1`: `GlassCard` with zero padding and zero border radius renders without clipping or layout assertion errors.
- `T2.C.2`: `GlassCard` with `enableBlur: false` renders translucent fallback surface without `BackdropFilter` (for high-volume scrolling).
- `T2.C.3`: `TrackTile` with an extremely long title (200+ characters) truncates with ellipsis without overflowing parent boundaries.
- `T2.C.4`: `GlassTextField` handles empty text, multi-line input, unicode characters, and RTL (Persian/Arabic) text without layout displacement.
- `T2.C.5`: `AlbumCard` with null or missing artwork renders default fallback gradient with icon without throw.
- `T2.C.6`: Nested `GlassCard` inside another `GlassCard` renders separate borders without infinite backdrop blur recursion.

#### Area D: Shell Navigation & Responsive Layout
- `T2.D.1`: Window width exactly at compact breakpoint boundary (`599.9dp` vs `600.0dp`) toggles responsive layout correctly.
- `T2.D.2`: Window width exactly at expanded breakpoint boundary (`839.9dp` vs `840.0dp`) toggles between rail and bottom nav.
- `T2.D.3`: Extreme narrow screen width (`320dp`) renders shell and tabs without `RenderFlex` overflow errors.
- `T2.D.4`: Deep link navigation to nonexistent route (`/unknown/path`) falls back safely to `/songs` without white screen of death.
- `T2.D.5`: Repeated rapid taps on the currently active tab triggers pop-to-root without reconstructing the entire shell view.
- `T2.D.6`: `MiniPlayerSlot` with empty playback state collapses to compact height or placeholder without pushing bottom nav offscreen.

#### Area E: Quality & Robustness
- `T2.E.1`: Multiple concurrent async storage operations (`setString`, `setBool`, `remove`) complete without race conditions.
- `T2.E.2`: Window resize during active route animation adapts layout smoothly without layout crashes.
- `T2.E.3`: Disposing and recreating `ProviderScope` releases all active subscriptions without memory leaks.
- `T2.E.4`: Failure monad preserves nested error causes and stack traces without truncation.
- `T2.E.5`: Rapid device orientation changes (portrait -> landscape -> portrait) emit zero `FlutterError` warnings.

---

### Tier 3: Cross-Feature Combinations (Pairwise Coverage)

Pairwise interaction matrix validating multi-dimensional state combinations:

| Dimension 1: Theme Preset | Dimension 2: Brightness Mode | Dimension 3: Breakpoint | Dimension 4: Active Tab | Dimension 5: Mini-Player State |
|---|---|---|---|---|
| Midnight Black | Dark | Compact (390dp) | Songs (`/songs`) | Empty / Placeholder |
| Deep Space | Dark | Medium (720dp) | Albums (`/albums`) | Active / Playing |
| Sakura | Light | Expanded (1024dp) | Artists (`/artists`) | Empty / Placeholder |
| Ocean Blue | Dark | Compact (390dp) | Playlists (`/playlists`) | Active / Playing |
| Forest Green | System (Dark) | Medium (720dp) | Settings (`/settings`) | Empty / Placeholder |
| Lava | Dark | Expanded (1200dp) | Songs (`/songs`) | Active / Playing |
| Daylight | Light | Compact (390dp) | Albums (`/albums`) | Empty / Placeholder |
| Neon Purple | Dark | Medium (720dp) | Artists (`/artists`) | Active / Playing |
| Custom HSL | Dark | Expanded (1024dp) | Settings (`/settings`) | Active / Playing |
| Custom HSL | Light | Compact (390dp) | Playlists (`/playlists`) | Empty / Placeholder |

#### Concrete Interaction Tests
- `T3.1`: **Midnight Black + Compact + Songs**: Pure black AMOLED background `#000000`, glass bottom nav rendered, frosted mini-player slot visible, track list scrollable.
- `T3.2`: **Sakura + Expanded + Artists**: Light background `#FFF5F7`, side `NavigationRail` rendered, artist cards in 4-column responsive grid, glass cards display rose accent borders.
- `T3.3`: **Ocean Blue + Medium + Albums**: Dark marine background `#0B192C`, 3-column album grid, mini-player slot docked above bottom navigation, zero horizontal overflow.
- `T3.4`: **Custom HSL + Compact + Theme Switcher**: Dynamic primary color applied to tab indicators, glass card borders, and sliders simultaneously.
- `T3.5`: **Daylight + Expanded + Settings**: Light theme `#F8FAFC`, navigation rail on leading edge, theme preset picker displayed in multi-column layout.

---

### Tier 4: Real-World Application Scenarios (>=5 realistic application flows)

#### Scenario 1: Fresh Install & Cold Boot Journey
1. App is launched for the first time with an empty storage container.
2. DI container initializes singletons (`IStorageService`, `ILoggingService`, `Talker`).
3. Theme engine loads defaults (Midnight Black preset, Dark mode).
4. Declarative router routes to initial location `/songs`.
5. Shell scaffold renders top `GlassAppBar` ("NEXA Songs"), empty library placeholder, persistent `MiniPlayerSlot`, and `GlassBottomNav` with Songs active.
6. Asserts zero layout overflow warnings and clean initial state.

#### Scenario 2: Personalization & Theme Customization Journey
1. User starts on `/songs` tab.
2. User taps Settings tab (`/settings`).
3. User taps Theme Settings tile -> navigates to `/settings/theme` (Theme Picker).
4. User inspects the 8 preset cards, taps "Ocean Blue" preset card.
5. Asserts scaffold background color immediately updates to Ocean Blue dark palette (`#0B192C`).
6. User toggles brightness mode to Light -> verifies background updates to light blue (`#F0F9FF`).
7. User navigates back to `/songs` -> verifies new theme persists across all shell tabs.
8. Test simulates app restart (`pumpWidget` with fresh container) -> verifies persisted theme is reloaded from storage.

#### Scenario 3: Custom HSL Palette Authoring Journey
1. User navigates to Settings -> Theme -> Custom Theme Editor (`/settings/theme/custom`).
2. Custom theme screen renders live preview card, HSL Hue slider (0–360°), Saturation slider (0–100%), and Lightness slider (0–100%).
3. User drags Hue slider to 280° (purple), Saturation to 90%, Lightness to 55%.
4. Live preview card reacts in real time displaying the new derived primary accent.
5. User taps "Save Custom Theme".
6. User navigates back to Shell -> verifies glass card borders, FAB glow, and active tab indicator use the new custom purple color.

#### Scenario 4: Responsive Window Resize & Device Rotation Journey
1. App renders in Phone Portrait mode (390 x 844dp, DPR 3.0).
2. Asserts `GlassBottomNav` is visible at the bottom; `NavigationRail` is absent; album grid displays 2 columns.
3. Window dynamically resizes to Phone Landscape (844 x 390dp, DPR 3.0).
4. Asserts layout adjusts without vertical clipping or `RenderFlex` overflow errors.
5. Window resizes to Desktop / Tablet Landscape (1024 x 768dp, DPR 2.0).
6. Asserts `GlassBottomNav` is hidden; `NavigationRail` appears on the leading side; album grid expands to 4 columns; `MiniPlayerSlot` docks horizontally.
7. Asserts zero `FlutterError` exceptions throughout the dynamic transition.

#### Scenario 5: Mini-Player Docking & Fullscreen Player Navigation Journey
1. User is browsing Albums tab (`/albums`).
2. Persistent `MiniPlayerSlot` is visible above bottom navigation bar showing track title and play/pause controls.
3. User taps the mini-player card.
4. Router transitions to `/player` (Now Playing) using fullscreen page transition over root navigator.
5. Asserts `NowPlaying` screen covers the entire viewport; bottom navigation bar and mini-player slot are hidden.
6. User taps the back button / dismisses player.
7. Router returns to `/albums` tab with exact scroll position preserved.

---

### Tier 5: Adversarial, Stress & Negative Boundary Hardening
- `T5.1`: **Rapid Tab Fuzzing**: Dispatches 50 tab tap events in random order across 1 second. Asserts no race conditions, no unhandled exceptions, and final state matches last tapped tab.
- `T5.2`: **Extreme Viewport Stress**: Resizes viewport down to 240 x 320dp and up to 3840 x 2160dp (4K). Asserts no fatal crash or division by zero in responsive builders.
- `T5.3`: **Memory Leak & Garbage Collection Hardening**: Cycles through tabs 100 times. Verifies state disposals and assertions for leaked listeners.
- `T5.4`: **Storage Crash Resilience**: Simulates storage write failures using `Result.failure(StorageFailure)`. Asserts UI shows non-intrusive error snackbar without crashing the app.

---

## 5. Opaque-Box Test Harness & Key Registry

To maintain opaque-box test decoupling, widgets are located and manipulated using semantic keys defined in `E2EKeys`:

### Semantic Keys Registry (`E2EKeys`)

| Key Name | ValueKey String | Purpose |
|---|---|---|
| `tabSongs` | `'tab_songs'` | Bottom navigation destination for Songs tab |
| `tabAlbums` | `'tab_albums'` | Bottom navigation destination for Albums tab |
| `tabArtists` | `'tab_artists'` | Bottom navigation destination for Artists tab |
| `tabPlaylists` | `'tab_playlists'` | Bottom navigation destination for Playlists tab |
| `tabSettings` | `'tab_settings'` | Bottom navigation destination for Settings tab |
| `shellScaffold` | `'shell_scaffold'` | Root adaptive shell scaffold container |
| `bottomNav` | `'glass_bottom_nav'` | Frosted glass bottom navigation bar |
| `navigationRail` | `'navigation_rail'` | Adaptive side navigation rail on wide displays |
| `miniPlayerSlot` | `'mini_player_slot'` | Persistent floating mini-player anchor slot |
| `miniPlayerPlayPause`| `'mini_player_play_pause'` | Play/pause button inside mini-player |
| `themeSettingsTile` | `'theme_settings_tile'` | Settings list tile opening theme picker |
| `themeCardMidnight` | `'theme_card_midnight_black'` | Preset card for Midnight Black theme |
| `themeCardDeepSpace`| `'theme_card_deep_space'` | Preset card for Deep Space theme |
| `themeCardSakura` | `'theme_card_sakura'` | Preset card for Sakura theme |
| `themeCardOceanBlue`| `'theme_card_ocean_blue'` | Preset card for Ocean Blue theme |
| `themeCardForestGreen`| `'theme_card_forest_green'` | Preset card for Forest Green theme |
| `themeCardLava` | `'theme_card_lava'` | Preset card for Lava theme |
| `themeCardDaylight` | `'theme_card_daylight'` | Preset card for Daylight theme |
| `themeCardNeonPurple`| `'theme_card_neon_purple'` | Preset card for Neon Purple theme |
| `themeCardCustom` | `'theme_card_custom'` | Preset card for Custom HSL theme |
| `themeModeDark` | `'theme_mode_dark'` | Brightness selector button for Dark mode |
| `themeModeLight` | `'theme_mode_light'` | Brightness selector button for Light mode |
| `themeModeSystem` | `'theme_mode_system'` | Brightness selector button for System mode |
| `hslHueSlider` | `'hsl_hue_slider'` | Custom theme editor hue slider |
| `hslSaturationSlider`| `'hsl_saturation_slider'` | Custom theme editor saturation slider |
| `hslLightnessSlider`| `'hsl_lightness_slider'` | Custom theme editor lightness slider |
| `hslSaveButton` | `'hsl_save_button'` | Custom theme save action button |
| `glassCard` | `'glass_card'` | Frosted glass card container |
| `glassAppBar` | `'glass_app_bar'` | Frosted glass top app bar |
| `trackTile` | `'track_tile'` | Music track list tile |
| `albumCard` | `'album_card'` | Music album card |

---

## 6. Test Suite Directory Layout

```
test/
├── e2e/
│   ├── e2e_test_helpers.dart              # E2EKeys, E2ETestHarness, E2EFixtures, TestAppWrapper
│   ├── tier1_feature_coverage_test.dart   # Tier 1: Feature coverage across areas A-E
│   ├── tier2_boundary_corner_test.dart    # Tier 2: Boundary, extreme inputs, nulls, clamps
│   ├── tier3_cross_feature_test.dart      # Tier 3: Pairwise cross-feature combinations
│   └── tier4_real_world_scenario_test.dart# Tier 4: End-to-end user journeys
├── unit/                                  # Component-level unit test suites
└── widget/                                # Component-level widget test suites
```

---

## 7. Execution Commands & Verification Protocols

### Standard Test Execution
Run the entire test suite:
```bash
flutter test
```

Run E2E test suite specifically:
```bash
flutter test test/e2e/
```

Run individual test tiers:
```bash
flutter test test/e2e/tier1_feature_coverage_test.dart
flutter test test/e2e/tier2_boundary_corner_test.dart
flutter test test/e2e/tier3_cross_feature_test.dart
flutter test test/e2e/tier4_real_world_scenario_test.dart
```

### Static Analysis Protocol
Run strict static analysis:
```bash
dart analyze
```
*Pass Criteria*: `No issues found!` (0 errors, 0 warnings, 0 linter violations).

### Defect Escalation Protocol
When an E2E test fails:
1. Determine defect classification:
   - **Spec Violation**: Implementation behavior deviates from `PROJECT.md` or `ORIGINAL_REQUEST.md`. Escalate to implementing worker/orchestrator.
   - **Layout Overflow**: RenderFlex overflow on target breakpoints. Escalate to Worker.
   - **Test Harness Flaw**: Flaky timeout or incorrect locator in test code. Fix test code directly.
2. Under no circumstance may the test writer modify code under `lib/`.
