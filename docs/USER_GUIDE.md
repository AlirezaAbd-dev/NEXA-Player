# 📖 NEXA Player — Comprehensive User & Feature Manual

> **Version:** `1.0.0 "Obsidian"`  
> **Acoustic Fidelity:** 32-bit Floating Point DSP · High-Resolution Bit-Perfect Output  
> **Visual Styling:** Neo-Modern Obsidian AMOLED (`#000000`) with Specular Glassmorphism

---

## 📑 Table of Contents
1. [Introduction & First Launch](#1-introduction--first-launch)
2. [Music Library & Smart Sorting](#2-music-library--smart-sorting)
3. [The Now Playing Experience (3 Hero Modes)](#3-the-now-playing-experience-3-hero-modes)
4. [3D Perspective Card Flip & Audio Metadata](#4-3d-perspective-card-flip--audio-metadata)
5. [Studio Equalizer & Psychoacoustic DSP](#5-studio-equalizer--psychoacoustic-dsp)
6. [Interactive LRC Lyrics Engine](#6-interactive-lrc-lyrics-engine)
7. [Audio Trimmer & Ringtone Maker](#7-audio-trimmer--ringtone-maker)
8. [ID3 Tag Editor & Artwork Extractor](#8-id3-tag-editor--artwork-extractor)
9. [Audio Visualizers & Spectrum Analyzers](#9-audio-visualizers--spectrum-analyzers)
10. [Homescreen Widgets & Dynamic Material You Palette](#10-homescreen-widgets--dynamic-material-you-palette)
11. [Bedside Standby Turntable Mode](#11-bedside-standby-turntable-mode)
12. [In-App Car Mode & Android Auto](#12-in-app-car-mode--android-auto)
13. [Wear OS Smartwatch Remote Companion](#13-wear-os-smartwatch-remote-companion)
14. [Cloud & Network Streaming Hub (DLNA & NAS)](#14-cloud--network-streaming-hub-dlna--nas)
15. [Settings, Storage Cache & Backup](#15-settings-storage-cache--backup)

---

## 1. Introduction & First Launch

NEXA Player is an audiophile-grade music player engineered for uncompromised sound reproduction, tactile glassmorphism aesthetics, and cross-platform flexibility across Android, Linux, and Windows.

### Initial Permission Onboarding
Upon launching NEXA Player for the first time:
1. Grant the **Storage / Audio Media Permission** prompt so the native media scanner can locate your audio files.
2. The scanner automatically catalogs supported lossless and lossy audio codecs:
   - **Lossless:** FLAC, ALAC, WAV, AIFF, DSD (DSF/DFF).
   - **Compressed:** MP3, AAC, M4A, OGG Vorbis, Opus, WMA.
3. The database builds an in-memory SQLite index and extracts embedded ID3v2 / Vorbis comment tags and album art.

---

## 2. Music Library & Smart Sorting

The library is organized into five top-level tabs:
* **Songs Tab:** Full library listing with instant fuzzy search filtering, multi-select batch queueing, and swipe gestures.
* **Albums Tab:** Multi-column grid with dynamic aspect-ratio album art tiles, release year badges, and track counts.
* **Artists Tab:** Grouped discography views showcasing complete album chronologies.
* **Playlists Tab:** Dynamic smart playlists (Favorites, Recently Added, Most Played, History) alongside custom user playlists.
* **Folders Tab:** Hierarchical directory tree navigation for users who manage music via folder hierarchies on internal storage, SD cards, or OTG drives.

---

## 3. The Now Playing Experience (3 Hero Modes)

Tap any track or the persistent mini-player to open the **Now Playing Screen**. NEXA Player provides three distinct visual layout modes:

1. **Standard Mode:**
   - Full-bleed square artwork card with diffuse colored ambient back-glow.
   - Seekable, animated **Waveform Seeker** rendered from pre-computed audio amplitudes.
   - 5-Star interactive track rating and 1-tap heart favorite toggle.
   - Up Next Queue drawer and Sleep Timer modal sheets.
2. **Vinyl Turntable Mode:**
   - Realistic 33⅓ RPM rotating vinyl record with physical specular reflection grooves.
   - Pivoting tonearm tracking playback progress.
3. **Artwork Hero Mode:**
   - Maximized full-screen album artwork with minimalist floating transport controls.

---

## 4. 3D Perspective Card Flip & Audio Metadata

* **Gesture:** Long-press the album artwork card on the Now Playing screen.
* **Result:** The card executes an interactive **3D Perspective Y-axis Flip**, revealing the hidden technical audio metadata card:
  - Exact audio codec (FLAC, MP3, DSD).
  - Bit depth & Sample rate (e.g. `24-bit / 96.0 kHz`, `DSD 5.6 MHz`).
  - Bitrate (e.g. `1411 kbps`, `320 kbps`).
  - File format, container, channels (Stereo / 5.1), and exact file system path.

---

## 5. Studio Equalizer & Psychoacoustic DSP

Access the equalizer from the Now Playing top bar or Settings:
* **10-Band Parametric EQ:** Centered at ISO frequencies: `31Hz, 62Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz` with $\pm 12\text{ dB}$ range.
* **16 Calibrated Factory Presets:** Flat, Rock, Pop, Jazz, Classical, Hip Hop, Electronic, Acoustic, Dance, Deep, Metal, R&B, Vocal, Bass Boost, Treble Boost, Loudness.
* **DSP Processing:**
  - **Bass Boost:** Low-frequency harmonic excitation.
  - **Virtualizer:** Spatial psychoacoustic stereo widening.
  - **Reverb Simulation:** Room, Studio, Chamber, Hall, Cathedral, Plate acoustics.
  - **Preamp Gain:** Digital pre-attenuation ($\pm 12\text{ dB}$) with automatic clipping prevention.

---

## 6. Interactive LRC Lyrics Engine

* **Synchronized Scrolling:** Highlights current singing lyric lines in real-time with smooth scrolling.
* **Direct Seeking:** Tap any lyric line to jump audio playback directly to that timestamp.
* **Timestamp Nudge:** Adjust lyric synchronization forwards or backwards by $\pm 100\text{ ms}$ or $\pm 500\text{ ms}$ to compensate for track padding.
* **Built-in LRC Editor:** Create, edit, and export synchronized `.lrc` companion files to disk.

---

## 7. Audio Trimmer & Ringtone Maker

Create custom ringtones, notification chimes, and alarm tones:
1. Open any track and select **Trim Audio / Make Ringtone** from the context menu.
2. Scrub dual start and end sliders across the zoomed audio waveform.
3. Preview the selected snippet with millisecond accuracy.
4. Export as a native system Ringtone, Notification, or Alarm.

---

## 8. ID3 Tag Editor & Artwork Extractor

1. Select **Edit Tags** on any song or album.
2. Edit Title, Artist, Album, Year, Track Number, Disc Number, and Genre.
3. Automatically updates both the underlying audio file metadata and the SQLite library index.

---

## 9. Audio Visualizers & Spectrum Analyzers

Toggle the real-time FFT audio visualizer on Now Playing or Lock Screen:
* **Styles:**
  1. **Bars:** 32-band reactive frequency equalizer bars with peak caps.
  2. **Waveform:** Oscilloscope time-domain audio curve.
  3. **Circle:** Circular radiating halo visualizer centered on album art.
  4. **Spectrogram:** Waterfall frequency intensity display.
  5. **VU Meter:** Dual analog needle decibel meters with needle inertia.
* **Customization:** Sensitivity, FPS cap (30 / 60 / 120 FPS), FFT window size, and custom gradient accents.

---

## 10. Homescreen Widgets & Dynamic Material You Palette

* **4 Interactive Widgets:**
  - **4×1 Compact Pill:** Quick play/pause, skip, and compact track info.
  - **4×2 Hero Vinyl:** Rotating turntable record with full transport buttons.
  - **2×2 Minimal Square:** Album art with overlay controls.
  - **4×3 Karaoke Seeker:** Live synchronized lyrics display with waveform scrubber.
* **Dynamic Palette:** Automatically samples dominant colors from album art to dynamically tint widgets, backgrounds, and accents.

---

## 11. Bedside Standby Turntable Mode

* **Activation:** Tap the bedside moon icon or place phone in landscape charging orientation.
* **Features:**
  - True AMOLED `#000000` power-saving night display with burn-in prevention pixel shifting.
  - High-visibility analog/digital bedside clock.
  - Subtle rotating vinyl disc with dimming controls.

---

## 12. In-App Car Mode & Android Auto

* **In-App Car Mode HUD:**
  - Glare-free high-contrast dashboard with $\ge 72\text{ dp}$ touch targets.
  - Neon halo Play/Pause button, $\pm 15\text{s}$ seek jumps, and quick queue drawer.
  - Landscape cradle support and wake-lock prevention.
* **Android Auto:** Full `MediaBrowserService` integration enabling voice commands (*"Hey Google, play Starboy on NEXA Player"*) and steering-wheel controls.

---

## 13. Wear OS Smartwatch Remote Companion

* Control playback, volume, and playlists directly from your wrist (Samsung Galaxy Watch, Google Pixel Watch).
* Interactive animated rotary crown painter simulating physical bezel scrubbing.

---

## 14. Cloud & Network Streaming Hub (DLNA & NAS)

* **UPnP / DLNA Audio Casting:** Stream bit-perfect music over Wi-Fi to network speakers, Sonos systems, Denon AVRs, and smart displays with full remote volume control.
* **Remote WebDAV / NAS Storage:** Mount Synology, QNAP, TrueNAS, or Nextcloud music folders. Stream lossless FLAC/DSD directly without filling device storage.
* **Audiophile Web Radio:** Instant 1-tap streaming of curated 24-bit FLAC stations (Radio Paradise, Linn Jazz, SomaFM).
* **Smart Streaming Cache:** Configurable disk quota (512 MB – 4 GB) with automated LRU eviction and offline caching.

---

## 15. Settings, Storage Cache & Backup

* **Fuzzy Settings Search:** Type any setting name in the Settings Hub for immediate deep-linked navigation.
* **Backup & Restore:** Export custom equalizer presets, playlists, and app preferences to a single JSON archive.
