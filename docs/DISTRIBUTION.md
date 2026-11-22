# 📦 NEXA Player — Export & Distribution Guide

Welcome to the **NEXA Player** Export & Multi-Platform Distribution Guide. This document details the build systems, platform packaging pipelines, release artifacts, and continuous integration workflows for Android, Linux, Windows, and macOS.

---

## 🎯 Target Platforms & Release Artifacts

| Platform | Format | Description | Default Destination |
| :--- | :--- | :--- | :--- |
| **Android** | `.apk` (Split ABI) | Optimized binaries for `arm64-v8a`, `armeabi-v7a`, `x86_64` | `dist/android/*.apk` |
| **Android** | `.aab` | Google Play Store Distribution App Bundle | `dist/android/app-release.aab` |
| **Linux** | `.deb` | Debian/Ubuntu package with desktop shortcut & system icons | `dist/linux/nexa-player_*.deb` |
| **Windows** | `.exe` | Inno Setup standalone setup wizard with audio file associations | `dist/windows/*-setup.exe` |
| **macOS** | `.dmg` | Apple Disk Image with drag-and-drop `/Applications` symlink | `dist/macos/*.dmg` |

---

## 🎨 Branding, App Icons & Native Splash

NEXA Player features an **Obsidian AMOLED** design language with neon cyan and electric orchid accent glows. All branding assets are rendered in ultra-high resolution ($1024 \times 1024$).

### Regenerating App Icons & Splash Screen
If brand vectors or theme colors change, regenerate all platform assets with:

```bash
# 1. Generate master vectors (1024x1024 full, adaptive foreground, 512x512 splash emblem)
python3 tool/generate_branding_assets.py

# 2. Generate platform launcher icons (Android, iOS, Windows, macOS, Web, Linux)
dart run flutter_launcher_icons

# 3. Generate native Android 12+ and iOS launch splash screens (#0A0D14 obsidian background)
dart run flutter_native_splash:create
```

---

## 🚀 Building Release Binaries Locally

### 1. Android (APK & AAB)
**Prerequisites:** Android SDK 35, Java JDK 17. Min SDK: 24 (Android 7.0+ Nougat).

```bash
# Build split APKs per ABI (drastically reduces download size to ~20MB)
flutter build apk --release --split-per-abi

# Build unified Google Play Store Bundle
flutter build appbundle --release
```
*Generated outputs:*
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

---

### 2. Linux Desktop (.deb Package)
**Prerequisites:** Ubuntu/Debian host, `dpkg-deb`, `clang`, `cmake`, `ninja-build`, `libgtk-3-dev`, `libasound2-dev`.

```bash
# Run the automated Debian packaging script
./packaging/linux/build_deb.sh
```
*Generated output:*
- `dist/linux/nexa-player_1.0.0-1_amd64.deb`

To test install locally on Ubuntu/Debian:
```bash
sudo dpkg -i dist/linux/nexa-player_1.0.0-1_amd64.deb
```

---

### 3. Windows Desktop (Inno Setup Installer .exe)
**Prerequisites:** Windows 10/11 x64, Visual Studio with "Desktop development with C++", [Inno Setup 6](https://jrsoftware.org/isdl.php).

```powershell
# 1. Build release binaries
flutter build windows --release

# 2. Compile Inno Setup installer
ISCC.exe packaging\windows\installer.iss
```
*Generated output:*
- `dist/windows/nexa-player-1.0.0-windows-setup.exe`

Features included in the Windows installer:
- Automated start menu and optional desktop shortcuts.
- Native shell file associations for audio formats (`.mp3`, `.flac`, `.wav`, `.m4a`, `.ogg`, `.opus`, `.aac`).
- Clean uninstaller registered in Windows Settings > Installed Apps.

---

### 4. macOS Desktop (.dmg Image)
**Prerequisites:** macOS host with Xcode installed.

```bash
# Run the automated macOS disk image builder
./packaging/macos/build_dmg.sh
```
*Generated output:*
- `dist/macos/NEXA-Player-1.0.0-macos.dmg`

---

## 🤖 Continuous Integration & GitHub Actions Matrix

The repository includes a production multi-platform CI/CD workflow at [`.github/workflows/build_and_release.yml`](../.github/workflows/build_and_release.yml).

- **Matrix Jobs:** Builds all 4 platforms concurrently (Android on Ubuntu, Linux on Ubuntu, Windows on `windows-latest`, macOS on `macos-latest`).
- **Trigger:**
  - Every `push` and `pull_request` on `main` runs test suites and builds verification artifacts.
  - Pushing a git tag matching `v*` (e.g., `v1.0.0`) automatically creates a GitHub Release with the compiled binaries attached.

---

## 🛠 Release Manager CLI Tool

Manage version increments and changelog generation using the built-in tool:

```bash
# Check current release version and staged artifacts
dart run tool/release_manager.dart status

# Bump patch version (e.g. 1.0.0+1 -> 1.0.1+2)
dart run tool/release_manager.dart bump patch

# Bump minor version (e.g. 1.0.0+1 -> 1.1.0+2)
dart run tool/release_manager.dart bump minor

# Bump major version (e.g. 1.0.0+1 -> 2.0.0+2)
dart run tool/release_manager.dart bump major

# Update CHANGELOG.md with recent commits
dart run tool/release_manager.dart changelog
```
