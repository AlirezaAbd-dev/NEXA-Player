# 🎵 NEXA Player — Full Build Plan
> A Poweramp/Stellio-class Flutter music player with glassmorphism UI, pro-grade equalizer, and cross-platform export (APK · EXE · DEB · macOS)

---

## 🔌 Install This Plugin First

Before starting implementation, install the official Flutter plugin so the agent has the right skills, rules, and Dart MCP server:

> **Dart and Flutter** (`antigravity-plugins-official/plugin/flutter`) — installs Flutter/Dart skills, architecture rules, and the Dart MCP server.

---

## 📐 Architectural Rules & Engineering Standards

> [!IMPORTANT]
> These rules govern every file written in this project. All agents and all phases must obey them.

### 1. Feature-Based Folder Structure (Vertical Slices)
```
lib/
├── core/                    # Design system, theme, constants, extensions
│   ├── design_system/       # Colors, typography, spacing, glassmorphism tokens
│   ├── theme/               # ThemeData light/dark + custom theme engine
│   ├── extensions/          # BuildContext, String, Duration helpers
│   ├── utils/               # Permission, file helpers, formatters
│   └── di/                  # Dependency injection (get_it + injectable)
├── features/
│   ├── player/              # Now-playing screen, mini player, waveform
│   ├── library/             # Songs, albums, artists, genres, folders
│   ├── playlists/           # Create / edit / delete playlists
│   ├── equalizer/           # EQ, effects, presets, real-time DSP
│   ├── scanner/             # Media scanner, metadata, folder watcher
│   ├── lyrics/              # Synced & unsynced lyrics display
│   ├── settings/            # All settings groups (audio, appearance…)
│   ├── themes/              # Theme picker, custom theme editor
│   └── search/              # Cross-library search
├── shared/
│   ├── widgets/             # Reusable DS widgets (GlassCard, AppBar…)
│   ├── models/              # Shared data models (Track, Album, Artist…)
│   └── services/            # Shared services (audio, DB, permissions)
└── app/                     # App entry, router, bootstrap
```

### 2. SOLID Principles (enforced per feature)
| Principle | Rule |
|-----------|------|
| **S** — Single Responsibility | One class = one job. `AudioPlayer` plays. `AudioEffectsEngine` applies DSP. `MetadataReader` reads tags. |
| **O** — Open/Closed | Use abstract interfaces (`IAudioEffect`, `IPlaybackStrategy`) so new effects/views add files, never modify existing ones. |
| **L** — Liskov Substitution | All strategy/repository implementations are fully substitutable. |
| **I** — Interface Segregation | No fat interfaces. `IEqualizer`, `ICompressor`, `IReverb` are separate. |
| **D** — Dependency Inversion | Features depend on abstractions, injected by `get_it`. |

### 3. Design System Rules
- Every color, radius, blur, shadow, spacing value lives in `core/design_system/`.
- **No magic numbers** anywhere in widget trees.
- Every widget is a `StatelessWidget` consuming from the DS. Zero inline styles.
- Glassmorphism tokens: `GlassTokens.blur`, `GlassTokens.opacity`, `GlassTokens.borderColor`.

### 4. State Management — Riverpod 2 (code-gen)
- Every feature has its own `*Provider` file.
- UI reads state via `ConsumerWidget`; never touches services directly.
- Side-effects go through `AsyncNotifier`.

### 5. Responsiveness
- Use `LayoutBuilder` + breakpoints from DS for phone/tablet/desktop.
- Never hardcode pixel widths; use `MediaQuery` ratios or `flex`.

### 6. Routing — go_router
- Declarative, typed routes. Deep-link ready.
- Shell route for persistent bottom navigation / mini player.

### 7. Testing Strategy
- Unit tests: all services and state notifiers.
- Widget tests: all DS components and critical screens.
- Integration tests: media scan → play → EQ flow.

### 8. Performance Rules
- Audio runs on a dedicated isolate / native thread.
- UI never blocks on I/O.
- Waveform rendered via `CustomPainter` + pre-computed amplitude data.
- DB (Drift) uses lazy loading + pagination for large libraries.

### 9. Additional Engineering Standards
- **Null safety** everywhere — no `!` force-unwraps without comment.
- **Linting**: `very_good_analysis` + custom `analysis_options.yaml`.
- **Git**: conventional commits, feature branches, PR per phase.
- **Localization**: `flutter_localizations` + `intl`, RTL-ready from day 1.
- **Error handling**: Result<T, Failure> pattern — no raw exceptions in UI.
- **Logging**: `talker` with rotating log file, debug overlay in dev mode.
- **Semantic versioning** for APK/EXE/DEB/DMG artifacts.

---

## 🎨 Design System — Next-Gen Bionic Glassmorphism & Motion UX Standard

> [!IMPORTANT]
> NEXA Player does NOT use flat opaque boxes or simple solid grey cards. True glassmorphism requires refractive optical depth, luminous back-light, specular gradient bevels, ambient chromatic glows, and fluid kinetic motion.

```
1. Optical Refraction Canvas (Ambient Aurora Mesh)
   - Multi-layer fluid mesh background (drifting chromatic glow orbs).
   - Dynamic track-color extraction: Glowing backdrop harmonizes with the playing song's artwork palette.
   - Guaranteed optical depth: Backdrops provide rich light for BackdropFilter (sigma 20–32dp) to diffuse.

2. Bionic Glass Surface Tokens
   - blur:          20–32 dp (frosted optical diffusion)
   - fill:          LinearGradient(135°, [surface@22%, surface@08%])
   - specularBorder: LinearGradient(135°, [white@42%, white@08%]) at 1.2 dp
   - innerHighlight: Top-edge 1dp glossy sheen [white@35% -> transparent]
   - borderRadius:  24 dp (cards), 56 dp (floating capsules/pills), 100 dp (circular action controls)
   - ambientGlow:   Diffuse colored shadows matching accent color (accent@25%, blur 24dp, spread 2dp)

3. Motion & Micro-Interactions (Kinetic Spring Physics)
   - Tactile press: Cards and buttons scale down to 0.98 with spring damping (Curves.easeOutBack) on tap.
   - Animated visualizer: Mini 3-bar / 4-bar equalizer pulsing rhythmically when audio is playing.
   - Ambient pulse: Subtle breathing glow on the active mini-player and now-playing artwork.
   - Staggered entrances: Smooth slide-and-fade for lists and grids.

4. High-Fidelity Artwork & Skeuomorphic Vinyl
   - Sleek vinyl disc with radial grooves and specular light reflection peeking from sleeves.
   - Rich procedural artistic fallbacks with gradient meshes and musical iconography.
```

**Themes built-in (8 presets + fully custom):**
- 🌑 Midnight Black (True AMOLED with electric cyan specular rim)
- 🌙 Deep Space (Dark interstellar indigo with neon sapphire glow)
- 🌸 Sakura (Ethereal rose quartz glass with crimson glow)
- 🌊 Ocean Blue (Aquamarine oceanic glass with deep sea reflections)
- 🌿 Forest Green (Emerald frosted glass with mint accents)
- 🔥 Lava (Obsidian glass with volcanic amber glow)
- ☀️ Daylight (Frosted ice glass with pure prism refraction)
- 💜 Neon Purple (Cyberpunk violet with ultraviolet back-glow)
- 🎨 Custom (HSL color picker with real-time WCAG 2.1 AA contrast clamping)

---

## 📋 Complete Settings List

### 🔊 Audio Settings
| Setting | Description |
|---------|-------------|
| Gapless playback | Remove silence between tracks |
| Crossfade on track change | Smooth transition between songs |
| Crossfade length | 1–12 seconds slider |
| Fading on play/pause | Gradual fade in/out |
| Audio buffer size | Low / Medium / High / Custom (ms) |
| Audio output | Auto / Speaker / Headset / Bluetooth / USB DAC |
| Sample rate | 44.1 / 48 / 88.2 / 96 / 192 kHz |
| Bit depth output | 16 / 24 / 32-bit float |
| Dithering | Off / Triangular / Shaped |
| Hi-Res audio mode | Bypass Android AudioFlinger (root/USB DAC) |
| Replaygain | Off / Track / Album / Smart |
| Replaygain preamp | -12 to +12 dB |
| DVC (Direct Volume Control) | Hardware volume bypass |
| Stereo widening | Off / Software / Hardware |

### 🎮 Control Settings
| Setting | Description |
|---------|-------------|
| Resume after call | Auto-resume playback after phone call ends |
| Long audio focus | Pause on short focus loss, stop on long |
| Headset unplugged | Pause / Stop / Nothing |
| On headset plugged | Play / Resume / Nothing |
| On Bluetooth connected | Play / Resume / Nothing |
| Volume buttons | Volume / Track skip / Scroll |
| On volume = 0 | Pause / Nothing |
| Shake for next track | Sensitivity slider |
| Long press play | Stop / Sleep timer / Nothing |
| Double tap | Next / Restart track |
| Swipe on notification | Seek / Skip |
| Car mode | Auto-launch, simplified UI, large controls |
| Sleep timer | Custom duration, end-of-track aware |

### 🖼 Album Art
| Setting | Description |
|---------|-------------|
| Download missing covers | Toggle |
| Only via Wi-Fi | Toggle |
| Save without extension | Toggle |
| Saved covers folder | Path picker |
| Cover download quality | Low / Medium / High / Original |
| Max download size | 500 KB / 1 MB / 2 MB / Unlimited |
| Delete covers cache | Action button |
| Embedded art priority | Prefer embedded / Prefer downloaded |
| Blur background | None / Low / Medium / High |
| Auto-crop to square | Toggle |
| Animated covers (GIF/APNG) | Toggle |

### 📂 Scanner Settings
| Setting | Description |
|---------|-------------|
| Scan folders | Included paths list |
| Excluded folders | Blacklist paths |
| Scan on launch | Toggle |
| Notify about new tracks | Toggle |
| Tag encoding | Auto / UTF-8 / ISO-8859-1 / Custom |
| Skip .nomedia directories | Toggle |
| Skip .mp4 files | Toggle |
| Skip .ogg/.oga files | Toggle |
| Skip short audio files | Minimum duration (seconds) |
| Skip small files | Minimum size (KB) |
| Drop the database | Dangerous: wipe & rescan |
| Scan network shares (SMB) | Toggle + path list |
| Watch for changes | Real-time folder watcher |
| Recognized extensions | Editable list (.mp3, .flac, .m4a…) |

### 🎨 Appearance
| Setting | Description |
|---------|-------------|
| Theme preset | 8 built-in + Custom |
| Dark / Light / System | Mode selector |
| Custom theme editor | Full HSL color picker per token |
| Notification style | 9.0 style / Compact / Media style |
| Lock screen controls | Show album art + controls |
| Language | Full i18n list |
| Hide empty menu items | Toggle |
| Accent color source | Fixed / Average of cover / Vibrant of cover |
| Pick elements color | Per-element color override |
| List animation | None / Fade / Slide / Scale |
| Additional list field | Bitrate / BPM / Year / File size |
| Top list field | Configurable metadata |
| Bottom list field | Configurable metadata |
| Scroll to current track | Auto-scroll behavior |
| Disable auto-rotate | Toggle |
| Open main screen at startup | Songs / Albums / Artists / Last used |
| Font | System / Built-in font list |
| Font size | Small / Medium / Large / Custom |
| Icon set | Default / Filled / Rounded |
| Visualizer style | Waveform / Bars / Circle / Off |
| Mini player style | Compact / Standard / Large |
| Now Playing layout | Standard / Vinyl / Full-screen art |
| Corner radius scale | Slider (affects all cards/buttons) |
| Blur intensity | Glassmorphism backdrop blur slider |

### 🌐 Metadata
| Setting | Description |
|---------|-------------|
| Translate song metadata | Auto-translate title/album/artist |
| Translation provider | Google / DeepL / Local |
| Preferred lyrics source | Embedded / Genius / LRCLIB / LRCLib offline |
| Auto-fetch lyrics | Toggle |
| Lyrics font size | Slider |
| Lyrics highlight color | Color picker |
| Write tags to file | Save edited metadata to file |
| Artwork write to file | Embed downloaded art into file |

### ⚡ Power Saving
| Setting | Description |
|---------|-------------|
| Power saving mode | Auto / On / Off |
| Reduce animations in power save | Toggle |
| Pause on low battery | Threshold % |
| Stop service when minimized | Toggle |
| Wake lock | Prevent CPU sleep during playback |

### 🔔 Notifications & Widgets
| Setting | Description |
|---------|-------------|
| Show playback notification | Toggle |
| Notification actions | Configurable (5 slots) |
| Home screen widget | 2×2 / 4×1 / 4×2 |
| Android Auto | Enable CarPlay/AA integration |
| Wear OS | Toggle |

### 🛡 Privacy & Storage
| Setting | Description |
|---------|-------------|
| Analytics | Opt-in/out |
| Crash reporting | Toggle |
| Export settings | JSON backup |
| Import settings | Restore from backup |
| Clear playback history | Action |
| Clear search history | Action |

---

## 🎛 Equalizer — Full DSP Engine

### Bands
| Band | Range |
|------|-------|
| Preamp | -12 to +12 dB |
| Sub-bass (20 Hz) | -12 to +12 dB |
| Bass (60 Hz) | -12 to +12 dB |
| Upper Bass (125 Hz) | -12 to +12 dB |
| Low-mid (250 Hz) | -12 to +12 dB |
| Mid (500 Hz) | -12 to +12 dB |
| Upper-mid (1 kHz) | -12 to +12 dB |
| Presence (2 kHz) | -12 to +12 dB |
| Upper-presence (4 kHz) | -12 to +12 dB |
| Brilliance (8 kHz) | -12 to +12 dB |
| Air (16 kHz) | -12 to +12 dB |
| Ultra-air (20 kHz) | -12 to +12 dB |

### Effects Engine (Poweramp-class)
| Effect | Parameters |
|--------|-----------|
| **Bass Boost (Z-Bass)** | Strength 0–1000, Frequency, Harmonics — psychoacoustic, lossless |
| **Z-Mids** | Mid-frequency shaping |
| **Z-Treble** | High-frequency air enhancement |
| **Balance** | L/R channel balance -100 to +100 |
| **Stereo Expand** | Width 0–300%, psychoacoustic crosstalk |
| **Mono** | Mix down to mono toggle |
| **Compressor** | Threshold, Ratio, Attack, Release, Knee, Makeup gain |
| **Tone** | Low / High shelving |
| **Speed / Tempo** | 0.5×–2.0×, pitch-locked |
| **Pitch** | -12 to +12 semitones, formant-corrected |
| **Echo / Delay** | Time, Feedback, Mix, Stereo offset |
| **Auto-Wah** | Frequency, Depth, Rate, Resonance |
| **Reverb** | Room size, Damping, Width, Mix, Pre-delay, Pre-delay mix |
| **Flanger** | Rate, Depth, Feedback, Delay, Phase |
| **Damp** | High-frequency roll-off, warmth |
| **Filter** | Low-pass / High-pass / Band-pass, Cutoff, Q |
| **Fade** | Fade-in / Fade-out duration per track |
| **Crossfeed** | Headphone listening correction, Strength, Cutoff |
| **Psychoacoustic Bass** | Harmonic bass extension for small speakers |

### EQ Presets (Built-in 20+)
Flat · Rock · Pop · Jazz · Classical · Hip-Hop · Electronic · Bass Boost · Vocal Boost · Acoustic · Metal · R&B · Dance · Lounge · Piano · Treble Boost · Cinema · Podcast · Sleep · Custom (unlimited user presets)

### EQ UX Features
- Real-time frequency response curve display (smooth SVG-rendered curve)
- Drag handles on bands — responsive and buttery smooth
- A/B comparison toggle (bypass)
- Per-output profile (headset EQ ≠ speaker EQ ≠ Bluetooth EQ)
- Import/export EQ preset files

---

## 📱 Library Views

| View | Grouping | Sort Options |
|------|----------|-------------|
| **All Songs** | Flat list | Name / Artist / Album / Date added / Duration / Bitrate / File size |
| **Albums** | Grid / List | Name / Artist / Year / Track count |
| **Artists** | List / Grid | Name / Track count / Album count |
| **Genres** | Grid | Name / Track count |
| **Folders** | File-tree | Name / Size |
| **Playlists** | Grid / List | Name / Date created / Track count |
| **Queue** | Current play queue | Manual reorder (drag) |
| **Recently Added** | Chronological | — |
| **Most Played** | Play count | — |
| **Favorites** | Liked songs | — |

**Display modes per view:** List · Grid 2-col · Grid 3-col · Card (large art)

---

## 🎵 Per-Track Details & Actions

**Metadata displayed:**
- Cover art (embedded / downloaded)
- Title, Artist, Album, Album Artist
- Track #, Disc #, Year
- Genre, Composer, Lyricist, Comment
- Duration, Bitrate (CBR/VBR), Sample rate, Bit depth
- File format, File size, File path
- BPM, Key, ISRC, MusicBrainz ID
- Play count, Last played, Date added, Rating (1–5 ★)

**Per-track actions:**
- Play / Add to queue / Play next
- Add to playlist / Remove from playlist
- Edit metadata (full tag editor)
- View lyrics (synced LRC + unsynced)
- Share (file + metadata card image)
- Delete from device
- **Trim for ringtone** (waveform trim UI, export as .m4r/.ogg)
- Set as ringtone / notification / alarm
- Find in folder
- Find similar (by genre/BPM/key)
- Copy track info to clipboard

---

## 🎼 Now Playing Screen — UX Blueprint

```
┌────────────────────────────────┐
│  [back]    Queue ⣿   ⋯ Menu   │   ← Transparent app bar
│                                │
│    ╔══════════════════╗        │
│    ║   Album Art      ║        │   ← Rotating vinyl or art card
│    ║   (blurred bg    ║        │   ← Swipe left/right = next/prev
│    ║    parallax)     ║        │
│    ╚══════════════════╝        │
│                                │
│    Song Title                  │   ← Marquee if too long
│    Artist · Album              │
│    ★★★★☆    ♥  Lyrics  ⋯     │
│                                │
│  ══ Waveform visualizer ═══   │   ← Amplitude bars, real-time, seekable
│  0:42 ─────●────────── 4:12   │   ← Scrub seek bar
│                                │
│    ⏮  ⏪  ▶  ⏩  ⏭          │   ← Controls
│    🔀  ❤  💾  🔁  📢         │   ← Shuffle, fav, save, repeat, vol
│                                │
│  ▼ Swipe up for EQ/Effects    │   ← Bottom sheet gesture
└────────────────────────────────┘
```

**UX highlights:**
- Swipe art L/R → skip track (with spring physics)
- Long press art → 3D flip to show track metadata
- Swipe up → EQ/Effects bottom sheet
- Tap waveform → precise seek
- Double tap → restart track
- Pinch art → expand to full screen
- Haptic feedback on all interactions
- Animated color extraction from album art → tints entire UI

---

## 🗺 Build Plan — Phases

---

### Phase 0 — Foundation & Tooling
**Goal:** Runnable Flutter project with CI, linting, DI, routing, DS skeleton.

**Tasks:**
1. `flutter create nexa_player --template=app --platforms=android,ios,windows,macos,linux`
2. Configure `analysis_options.yaml` with `very_good_analysis`
3. Add core dependencies to `pubspec.yaml`:
   - `riverpod` + `flutter_riverpod` + `riverpod_generator`
   - `go_router`
   - `get_it` + `injectable`
   - `drift` + `sqlite3_flutter_libs`
   - `freezed` + `json_serializable`
   - `talker_flutter`
4. Set up feature-based folder structure (empty feature folders + barrel files)
5. Create `core/design_system/` with glassmorphism tokens
6. Create `core/theme/` with 8 preset `ThemeData` objects
7. Set up `go_router` with shell route for bottom nav
8. Set up `get_it` + `injectable` DI container
9. Set up GitHub Actions: analyze → test → build APK

**Deliverable:** App boots, shows placeholder home, theme switcher works.

---

### Phase 1 — Design System & Shell UI
**Goal:** Full glassmorphism DS with every reusable widget. Shell navigation.

**Tasks:**
1. `GlassCard` widget (blur, opacity, border, gradient)
2. `GlassAppBar` (transparent, blurred)
3. `GlassBottomNav` (5 tabs: Songs, Albums, Artists, Playlists, Settings)
4. `GlassFAB`, `GlassButton`, `GlassTextField`, `GlassChip`
5. `TrackTile` widget (cover art, title, artist, duration, trailing menu)
6. `AlbumCard` widget (grid/list modes)
7. `ArtistCard` widget
8. `GenreCard` widget
9. `AppSnackbar`, `AppDialog`, `AppBottomSheet` wrappers
10. Dark/Light/System mode toggle with animated transition
11. Theme picker screen (8 presets + Custom)
12. Full custom theme editor (HSL picker per token)
13. Responsive layout: phone portrait / phone landscape / tablet

**Libraries:**
- `flutter_animate` — micro-animations
- `shimmer` — loading skeletons
- `flex_color_scheme` — Material 3 theme generation
- `flutter_colorpicker` — custom theme editor

**Deliverable:** Storybook-style widget preview, all DS components, theme system complete.

---

### Phase 2 — Media Scanner & Local Library
**Goal:** Scan device storage, read metadata, populate Drift DB.

**Tasks:**
1. `MediaScannerService` — recursively scan folders using `on_audio_query`
2. `MetadataReaderService` — read ID3v2, Vorbis, AAC, FLAC tags via `metadata_god`
3. `AlbumArtService` — extract embedded art + download from MusicBrainz/Last.fm
4. `Drift` database schema: `Tracks`, `Albums`, `Artists`, `Genres`, `Playlists`, `PlaylistTracks`
5. Scanner settings screen (include/exclude folders, extensions, skip rules)
6. Background scan with `WorkManager` + progress notification
7. Folder watcher for real-time library updates
8. All Songs list view (virtual scroll, `ListView.builder`)
9. Albums grid/list view
10. Artists list view
11. Genres grid view
12. Folders tree view
13. Recently Added / Most Played / Favorites auto-playlists
14. Sort & display mode controls per view
15. Track detail screen (all metadata, full tag editor)

**Libraries:**
- `on_audio_query` — platform media store query
- `metadata_god` — full tag read/write (Dart FFI)
- `drift` — reactive SQLite
- `workmanager` — background tasks

**Deliverable:** Full library browsable from real device storage, all views work.

---

### Phase 3 — Audio Engine & Playback
**Goal:** Gapless, crossfade, background playback, platform audio session.

**Tasks:**
1. `AudioEngineService` wrapping `just_audio` with custom pipeline
2. `PlaybackQueueService` — queue management, shuffle strategies
3. Playback modes: ordered / shuffle / repeat-one / repeat-all
4. Gapless playback configuration
5. Crossfade implementation (dual-player approach)
6. Fade in/out on play/pause
7. `AudioSessionService` — interruption handling (calls, notifications)
8. Media notification with `audio_service`
9. Lock screen controls
10. Headset plug/unplug events
11. Bluetooth events
12. Volume button actions
13. Sleep timer service
14. Shake-to-skip (`sensors_plus`)
15. Resume after call
16. Mini player widget (persistent above bottom nav, expandable)
17. Queue screen with drag-to-reorder
18. Android Auto / CarPlay metadata

**Libraries:**
- `just_audio` — gapless engine, platform audio decoders
- `audio_service` — background service + media notification
- `audio_session` — session management, interruption handling
- `sensors_plus` — shake detection
- `volume_controller` — volume events

**Deliverable:** Full background playback, all control scenarios, mini player.

---

### Phase 4 — Now Playing Screen (UX Hero)
**Goal:** The showstopper screen. Glassmorphism. Waveform. Physics animations.

**Tasks:**
1. Full-screen Now Playing layout with 3 layout variants (Standard / Vinyl / Art)
2. Album art display — swipe L/R (spring physics), 3D flip on long press
3. Animated vinyl record view (rotation, arm animation)
4. Dynamic color extraction from album art → theme tinting (`palette_generator`)
5. Waveform visualizer (pre-computed amplitude data, `CustomPainter`, seekable)
6. Seek bar with waveform overlay
7. Progress indicator with MM:SS + remaining time
8. Playback controls with haptic feedback
9. Rating widget (5 stars, heart toggle)
10. Track info marquee for long titles
11. Animated background (blurred art + parallax)
12. Queue peek (bottom of screen, expandable)
13. Share track as metadata card image (canvas render)
14. Animated color transitions when track changes
15. Landscape layout (art left, controls right)

**Libraries:**
- `palette_generator` — art color extraction
- `flutter_animate` — spring physics, fade, scale
- `marquee` — scrolling text
- `haptic_feedback` — built-in

**Deliverable:** Now Playing screen is indistinguishable from Poweramp quality.

---

### Phase 5 — Equalizer & DSP Engine
**Goal:** Poweramp-class audio effects. Real-time, lossless quality.

**Tasks:**
1. `DspEngineService` — platform channel bridge to native audio processing
2. Android: 32-bit/64-bit native C++ DSP via JNI (`oboe` + custom biquad IIR filters)
3. iOS/macOS: AVAudioEngine graph with custom `AVAudioUnit` nodes
4. Windows/Linux: `miniaudio` backend with custom filter chain
5. 10-band parametric EQ + Preamp
6. Full band list: 20 Hz → 20 kHz (12 bands)
7. Bass Boost (Z-Bass psychoacoustic) — harmonic enhancement
8. Z-Mids, Z-Treble tone shapers
9. Balance (L/R)
10. Stereo Expand (psychoacoustic width)
11. Mono downmix
12. Compressor (full parametric)
13. Reverb (Schroeder/FDN algorithm)
14. Echo / Delay (stereo)
15. Flanger (LFO modulated delay)
16. Auto-Wah (envelope follower)
17. Speed/Tempo (SoundTouch algorithm)
18. Pitch shift (formant-preserving)
19. Damp filter
20. Low-pass / High-pass / Band-pass filter
21. Fade per track
22. Crossfeed (headphone correction)
23. Per-output EQ profile (headset / speaker / BT)
24. EQ UI: draggable band handles + SVG frequency response curve
25. Preset manager (save / load / export / import)
26. 20+ built-in presets
27. A/B bypass toggle
28. Real-time visualizer (FFT spectrum bars on EQ screen)

**Libraries:**
- `flutter_equalizer` or custom platform channel (native C++ for precision)
- `fftea` — FFT for spectrum display
- `soundtouch_flutter` — tempo/pitch processing

**Deliverable:** Every effect listed works, sounds like Poweramp class quality.

---

### Phase 6 — Playlists & Track Operations
**Goal:** Full playlist CRUD, sharing, ringtone trimmer, batch operations.

**Tasks:**
1. Playlist create / edit / delete / reorder tracks
2. Smart playlists (auto-rule based: genre, BPM, rating, date)
3. M3U / M3U8 / PLS import and export
4. Track editor: edit all ID3 tags + write to file
5. **Ringtone Trimmer** — waveform view, two drag handles, trim & export
6. Set as ringtone / notification / alarm (Android API)
7. Share track: file share + metadata card image (branded)
8. Delete track (with confirmation, MTP safe)
9. Batch operations: select multiple, batch add to playlist / delete / share
10. Drag-to-reorder in playlists
11. Playlist cover auto-generated from track art collage

**Libraries:**
- `file_picker` — file import
- `share_plus` — OS share sheet
- `permission_handler` — storage/ringtone permissions

**Deliverable:** Every track operation works. Playlist system complete.

---

### Phase 7 — Lyrics
**Goal:** Synced (karaoke-style) + unsynced lyrics display.

**Tasks:**
1. `LyricsService` — read embedded LRC tags
2. Online fetch: LRCLIB API (free, no key)
3. Genius fallback (web scrape)
4. LRC parser (synced, word-by-word)
5. Lyrics screen: auto-scroll, highlight current line, glassmorphism card
6. Blurred album art background behind lyrics
7. Lyrics editor (manual edit + save to file)
8. Translation toggle (DeepL / Google Translate API)
9. Lyrics display on Now Playing (swipe tab)

**Deliverable:** Synced karaoke lyrics with beautiful UX.

---

### Phase 8 — Search
**Goal:** Fast, instant cross-library full-text search.

**Tasks:**
1. Drift FTS5 virtual table for full-text search
2. Search across: title, artist, album, genre, composer, lyrics
3. Instant results as-you-type (debounced, 150ms)
4. Result sections: Songs / Albums / Artists / Genres / Playlists
5. Recent searches history
6. Fuzzy matching for typos
7. Voice search (speech_to_text)

**Deliverable:** Sub-100ms search across 100k+ track library.

---

### Phase 9 — Settings (Complete)
**Goal:** Every setting from the spec, organized, with previews.

**Tasks:**
1. Settings home with grouped list (icons, search bar)
2. Audio settings screen (all 14 items)
3. Control settings screen (all 13 items)
4. Album Art settings screen (all 11 items)
5. Scanner settings screen (all 15 items)
6. Appearance settings screen (all 20 items)
7. Equalizer settings (presets, per-output, link to EQ screen)
8. Metadata / Lyrics settings
9. Power Saving settings
10. Notifications & Widgets settings
11. Privacy & Storage settings
12. Export / Import settings (JSON)
13. About screen (version, changelog, licenses)
14. Settings search (fuzzy, finds any setting by keyword)

**Deliverable:** Richer settings than Stellio, all working.

---

### Phase 10 — Visualizer & Spectrum
**Goal:** Beautiful real-time audio visualization in the player.

**Tasks:**
1. Waveform pre-processor: analyze audio file → amplitude array → cache in DB
2. Seekable waveform bar (like SoundCloud / Poweramp)
3. FFT real-time spectrum (bars, circle, wave modes)
4. Spectrogram view option
5. VU meters
6. Visualizer settings: style, color, sensitivity, FPS cap
7. Visualizer on lock screen and notification (Android)

**Libraries:**
- `fftea` — FFT
- `CustomPainter` — all rendering (60fps capable)

**Deliverable:** Visualizer runs at 60fps, looks stunning.

---

### Phase 11 — Export & Distribution
**Goal:** APK · EXE · DEB · macOS DMG build artifacts.

**Tasks:**
1. **Android APK/AAB** — `flutter build apk --release`, split per ABI, min SDK 24
2. **Windows EXE** — `flutter build windows --release`, package with Inno Setup installer
3. **Linux DEB** — `flutter build linux --release`, package with `dpkg-deb`
4. **macOS DMG** — `flutter build macos --release`, package with `create-dmg`
5. Configure app icons per platform (`flutter_launcher_icons`)
6. Configure splash screens (`flutter_native_splash`)
7. GitHub Actions matrix: build all 4 platforms on push to `main`
8. Auto-increment version + changelog generation

**Deliverable:** Download-ready APK, EXE installer, DEB package, DMG image.

---

## 📦 Core Dependencies Summary

```yaml
dependencies:
  # State management
  flutter_riverpod: ^2.5.x
  riverpod_annotation: ^2.3.x
  
  # Routing
  go_router: ^14.x
  
  # DI
  get_it: ^8.x
  injectable: ^2.4.x
  
  # Database
  drift: ^2.19.x
  sqlite3_flutter_libs: ^0.5.x
  
  # Code gen
  freezed_annotation: ^2.4.x
  json_annotation: ^4.9.x
  
  # Audio engine
  just_audio: ^0.9.x
  audio_service: ^0.18.x
  audio_session: ^0.1.x
  
  # Media library
  on_audio_query: ^2.9.x
  metadata_god: ^0.6.x
  
  # UI & animations
  flutter_animate: ^4.5.x
  shimmer: ^3.0.x
  flex_color_scheme: ^7.3.x
  palette_generator: ^0.3.x
  marquee: ^2.3.x
  
  # Sensors & system
  sensors_plus: ^5.0.x
  volume_controller: ^2.x
  permission_handler: ^11.x
  
  # Files & sharing
  file_picker: ^8.x
  share_plus: ^9.x
  path_provider: ^2.1.x
  
  # Network
  dio: ^5.6.x
  cached_network_image: ^3.4.x
  
  # Lyrics
  # (custom LRCLIB + LRC parser)
  
  # Logging
  talker_flutter: ^4.4.x
  
  # FFT / DSP
  fftea: ^1.3.x

dev_dependencies:
  build_runner: ^2.4.x
  riverpod_generator: ^2.4.x
  injectable_generator: ^2.6.x
  drift_dev: ^2.19.x
  freezed: ^2.5.x
  json_serializable: ^6.8.x
  flutter_launcher_icons: ^0.14.x
  flutter_native_splash: ^2.4.x
  very_good_analysis: ^6.x
  mocktail: ^1.0.x
```

---

## 🏁 Phase Completion Checklist

| Phase | Focus | Est. Effort |
|-------|-------|-------------|
| 0 | Foundation & CI | 1–2 days |
| 1 | Design System & Shell | 3–5 days |
| 2 | Media Scanner & Library | 4–6 days |
| 3 | Audio Engine | 4–6 days |
| 4 | Now Playing Screen | 3–5 days |
| 5 | Equalizer & DSP | 7–10 days |
| 6 | Playlists & Track Ops | 3–5 days |
| 7 | Lyrics | 2–3 days |
| 8 | Search | 1–2 days |
| 9 | Settings | 3–5 days |
| 10 | Visualizer & Spectrum | 2–4 days |
| 11 | Export & Distribution | 1–2 days |
| **Total** | | **~35–55 days** |

> [!TIP]
> Use `/teamwork` to run multiple phases in parallel with autonomous subagents — e.g., Phase 1 (Design System) and Phase 2 (Scanner) can be built simultaneously since they have no dependency on each other.

> [!NOTE]
> The EQ DSP engine (Phase 5) is the most complex. It requires native C++/Swift platform channels. Plan for iteration. The psychoacoustic bass (Z-Bass) algorithm specifically needs careful tuning to match Poweramp quality.

> [!CAUTION]
> On Android, writing files and setting ringtones requires `WRITE_EXTERNAL_STORAGE` (SDK < 29) and `MANAGE_MEDIA` (SDK 33+). Handle permission flows gracefully with rationale dialogs.
