# Project: NEXA Player (Phase 0 & Phase 1)

## Architecture
NEXA Player follows a strict vertical-slice, feature-based Clean Architecture adhering to SOLID principles:
- **`lib/core/`**: Cross-cutting foundation. Contains design tokens, theme system, dependency injection definitions, extensions, utilities (`Result<T, Failure>`), and constants.
- **`lib/shared/`**: Reusable domain entities, abstract service contracts (`IStorageService`, `ILoggingService`, `IAudioEngine`), and reusable presentation widgets (`GlassCard`, `GlassAppBar`, `TrackTile`, `AlbumCard`, etc.).
- **`lib/features/`**: Vertical feature modules (`library`, `playlists`, `settings`, `themes`, `player`, `equalizer`, `scanner`, `lyrics`, `search`). Each contains its own presentation/logic slices.
- **`lib/app/`**: Application-level bootstrapping, `go_router` declarative routing configuration with `StatefulShellRoute`, and the root `NexaApp` widget.
- **Dependency Flow**:
  - Services implement abstract interfaces in `lib/shared/services/` and register with `get_it`.
  - UI State Management is powered by Riverpod 2 (`AsyncNotifier` / `Notifier`). Riverpod providers consume `get_it` service abstractions and expose reactive state to UI widgets.
  - UI widgets (`ConsumerWidget`) listen exclusively to Riverpod providers; widgets never call `get_it` directly.

## Feature Inventory
Every feature discovered in the Survey phase is mapped to a designated milestone:

| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| F0.1 | Feature-Based Directory Layout | Vertical slice directory structure: `lib/core/`, `lib/features/`, `lib/shared/`, `lib/app/` with barrel files | M1 | survey |
| F0.2 | SOLID Interface Contracts | Segregated abstract interfaces (`ILoggingService`, `IStorageService`) decoupling concrete dependencies | M1 | survey |
| F0.3 | Dependency Injection Container | `get_it` service locator registering core singleton services on app startup | M1 | survey |
| F0.4 | Structured Logging System | `talker_flutter` integration with log filtering, crash capture, and developer inspectability | M1 | survey |
| F0.5 | Result & Failure Monad | `Result<T, Failure>` type wrapping computations in functional success/failure branches | M1 | survey |
| F0.6 | Riverpod 2 State Foundation | `ProviderScope` container wrapping root widget; Riverpod 2 providers exposing services | M1 | survey |
| F0.7 | Core Extensions & Utils | `BuildContext` helpers for theme, color scheme, media query, duration and string formatters | M1 | survey |
| F0.8 | Glassmorphism Token Suite | Centralized tokens in `core/design_system/`: blur (16–24dp), opacity (0.12–0.18), border (1dp white@25%), radii, shadows | M3 | survey |
| F0.9 | Spacing & Typography Scale | 8-step spacing scale (4, 8, 12, 16, 24, 32, 48, 64 dp) and M3 typography hierarchy | M3 | survey |
| F0.10 | 8 Built-in Preset Themes | Pre-configured Material 3 palettes: Midnight Black (AMOLED), Deep Space, Sakura, Ocean Blue, Forest Green, Lava, Daylight, Neon Purple | M2 | survey |
| F0.11 | Dark / Light / System Mode | Triple-state brightness mode toggle with smooth animated transitions | M2 | survey |
| F0.12 | Custom HSL Theme Editor | Interactive HSL color picker allowing dynamic customization of primary, secondary, surface, and background tokens | M2 | survey |
| F0.13 | Theme Persistence | Persistent storage of selected theme preset, mode, and custom HSL values via `IStorageService` | M2 | survey |
| F1.1 | GlassCard Widget | Reusable frosted glass container with configurable blur, opacity, border, gradient, and border radius | M3 | survey |
| F1.2 | GlassAppBar Widget | Frosted glass top app bar with blurred background, title, navigation icon, and action buttons | M3 | survey |
| F1.3 | GlassBottomNav Widget | Persistent glass bottom navigation bar for 5 primary tabs with active glow indicators | M3 | survey |
| F1.4 | GlassFAB Widget | Frosted floating action button with accent glow shadow and press animation | M3 | survey |
| F1.5 | GlassButton Widget | Filled, outlined, and ghost glass buttons with press scale animation and loading indicator | M3 | survey |
| F1.6 | GlassTextField Widget | Frosted search and input text field with prefix/suffix icons, clear button, and focus styling | M3 | survey |
| F1.7 | GlassChip Widget | Selectable frosted chip with border, accent selection state, and optional icon | M3 | survey |
| F1.8 | TrackTile Widget | Reusable music list item: artwork thumbnail, title marquee, artist/album subtitle, duration, overflow menu | M3 | survey |
| F1.9 | AlbumCard Widget | Reusable card for album display in both grid and list view modes with glass details overlay | M3 | survey |
| F1.10 | ArtistCard Widget | Reusable artist card with circular/rounded artwork avatar and track/album count | M3 | survey |
| F1.11 | GenreCard Widget | Reusable genre card with dynamic color gradient, genre title, and track count | M3 | survey |
| F1.12 | Feedback Overlays | `AppSnackbar`, `AppDialog`, `AppBottomSheet` with frosted glass background, blur, and spring entrance | M3 | survey |
| F1.13 | Declarative Shell Router | `go_router` `StatefulShellRoute.indexedStack` managing navigation across 5 persistent tabs | M4 | survey |
| F1.14 | 5 Primary Tabs | Shell tabs: Songs (`/songs`), Albums (`/albums`), Artists (`/artists`), Playlists (`/playlists`), Settings (`/settings`) | M4 | survey |
| F1.15 | Mini-Player Anchor Slot | Persistent slot positioned directly above the bottom navigation bar in the shell layout | M4 | survey |
| F1.16 | Responsive Layout Breakpoints | Layout adaptation for Phone Portrait (<600dp), Phone Landscape/Tablet (600–840dp), Desktop (>840dp) | M4 | survey |
| F1.17 | Design System Showcase Screen | Comprehensive showcase screen displaying all DS components, tokens, themes, and layouts (`/design-system`) | M3 | survey |
| F1.18 | Zero Static Analysis Warnings | Strict static analysis via `analysis_options.yaml` enforcing zero errors and zero warnings | M5 | survey |
| F1.19 | Automated Unit & Widget Tests | Multi-tiered test suite (DI, Notifiers, Router, Result, GlassCard, Nav, Themes, Responsive Breakpoints) | M5 | survey |

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| E2E | E2E Testing Suite | Requirements-driven opaque-box test harness & test suite (Tiers 1-4) published as `TEST_READY.md` | none | DONE |
| M1 | Core Architecture & Foundation | Directory structure, Result monad, logging service, storage service, GetIt DI container, Riverpod setup | none | DONE |
| M2 | Theme Engine & Customization | 8 Theme presets, ThemeController AsyncNotifier, HSL custom theme model & editor, persistence | M1 | DONE |
| M3 | Glassmorphism Design System | Design tokens, GlassCard, GlassAppBar, GlassBottomNav, TrackTile, AlbumCard, overlays, DS showcase screen | M1 | IN_PROGRESS |
| M4 | Shell Navigation & App Assembly | GoRouter StatefulShellRoute, 5 tabs, MiniPlayerSlot, responsive breakpoints, root NexaApp | M2, M3 | PLANNED |
| M5 | Final Verification & Hardening | Pass 100% of E2E test suite (Tiers 1-4), Tier 5 adversarial hardening, zero lint issues, forensic audit | M4, E2E | PLANNED |

## Interface Contracts

### 1. `lib/core/utils/result.dart`
```dart
sealed class Result<T, E extends Failure> {
  const Result();
  factory Result.success(T value) = Success<T, E>;
  factory Result.failure(E failure) = Error<T, E>;

  bool get isSuccess;
  bool get isFailure;
  T? get valueOrNull;
  E? get failureOrNull;
  R when<R>({
    required R Function(T value) success,
    required R Function(E failure) failure,
  });
  R fold<R>(R Function(T value) onSuccess, R Function(E failure) onFailure);
}
```

### 2. `lib/shared/services/storage/storage_service.dart`
```dart
abstract interface class IStorageService {
  Future<Result<void, StorageFailure>> setString(String key, String value);
  Result<String?, StorageFailure> getString(String key);
  Future<Result<void, StorageFailure>> setBool(String key, bool value);
  Result<bool?, StorageFailure> getBool(String key);
  Future<Result<void, StorageFailure>> remove(String key);
  Future<Result<void, StorageFailure>> clear();
}
```

### 3. `lib/shared/services/logging/logging_service.dart`
```dart
abstract interface class ILoggingService {
  void debug(String message);
  void info(String message);
  void warning(String message);
  void error(String message, [Object? error, StackTrace? stackTrace]);
}
```

### 4. `lib/core/theme/theme_controller.dart` & `theme_state.dart`
```dart
enum ThemePreset {
  midnightBlack,
  deepSpace,
  sakura,
  oceanBlue,
  forestGreen,
  lava,
  daylight,
  neonPurple,
  custom,
}

class ThemeState extends Equatable {
  final ThemePreset preset;
  final ThemeMode themeMode;
  final Color? customPrimary;
  final Color? customSurface;
  final Color? customBackground;
  // ...
}
```

## Code Layout
```
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   └── router/
│       ├── app_router.dart
│       ├── app_routes.dart
│       └── shell_scaffold.dart
├── core/
│   ├── constants/
│   ├── design_system/
│   │   ├── tokens/
│   │   └── design_system.dart
│   ├── di/
│   ├── extensions/
│   ├── theme/
│   └── utils/
├── features/
│   ├── library/
│   ├── player/
│   ├── playlists/
│   ├── settings/
│   └── themes/
└── shared/
    ├── models/
    ├── services/
    └── widgets/
        ├── cards/
        ├── feedback/
        ├── glass/
        └── layout/
test/
├── e2e/
├── unit/
└── widget/
```
