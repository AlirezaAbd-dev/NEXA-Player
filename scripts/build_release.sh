#!/usr/bin/env bash
# ==============================================================================
# NEXA Player — Multi-Platform Release Build & Packaging Script
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
DIST_DIR="${ROOT_DIR}/dist"

VERSION="1.0.0+1"
APP_NAME="NEXA-Player"

echo "🎵 ============================================================"
echo "🎵  NEXA Player v${VERSION} Release Engineering Pipeline"
echo "🎵 ============================================================"

cd "${ROOT_DIR}"

# Step 1: Pre-Flight Static Analysis
echo "🔍 [1/5] Running static analysis..."
flutter analyze --fatal-infos

# Step 2: Full Verification Test Suite
echo "🧪 [2/5] Running test suite and performance benchmarks..."
flutter test test/unit/ test/widget/ test/benchmark/

# Create clean distribution directory
mkdir -p "${DIST_DIR}"

# Step 3: Android Release Packaging (APK split-per-abi & universal)
echo "📱 [3/5] Building Android Release APKs..."
flutter build apk --release --split-per-abi
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "${DIST_DIR}/${APP_NAME}-v${VERSION}-android-arm64.apk"
cp build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk "${DIST_DIR}/${APP_NAME}-v${VERSION}-android-arm32.apk"
cp build/app/outputs/flutter-apk/app-x86_64-release.apk "${DIST_DIR}/${APP_NAME}-v${VERSION}-android-x86_64.apk"

# Step 4: Linux Desktop Release Build
echo "🐧 [4/5] Building Linux Desktop Release..."
if command -v cmake &> /dev/null && command -v clang &> /dev/null; then
  flutter build linux --release
  tar -czf "${DIST_DIR}/${APP_NAME}-v${VERSION}-linux-x64.tar.gz" -C build/linux/x64/release/bundle .
  echo "✅ Linux release bundle packaged."
else
  echo "⚠️ Skipping Linux native build: cmake/clang toolchain not present."
fi

# Step 5: Checksum Manifest Generation
echo "🔒 [5/5] Generating cryptographic SHA-256 checksums..."
cd "${DIST_DIR}"
sha256sum * > SHA256SUMS.txt
cd "${ROOT_DIR}"

echo "🎉 ============================================================"
echo "🎉  NEXA Player v${VERSION} Build Pipeline Complete!"
echo "🎉  Artifacts staged in ${DIST_DIR}/"
echo "🎉 ============================================================"
