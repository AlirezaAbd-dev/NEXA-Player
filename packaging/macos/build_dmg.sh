#!/usr/bin/env bash
set -euo pipefail

# NEXA Player - macOS Disk Image (.dmg) Builder
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

cd "$PROJECT_ROOT"

VERSION=$(grep -E '^version:' pubspec.yaml | head -n 1 | awk '{print $2}' | cut -d'+' -f1)
APP_NAME="NEXA Player"
DMG_NAME="NEXA-Player-${VERSION}-macos.dmg"
DIST_DIR="$PROJECT_ROOT/dist/macos"

echo "=== Packaging macOS DMG for ${APP_NAME} v${VERSION} ==="

mkdir -p "$DIST_DIR"

APP_BUNDLE=""
if [ -d "$PROJECT_ROOT/build/macos/Build/Products/Release/nexa_player.app" ]; then
    APP_BUNDLE="$PROJECT_ROOT/build/macos/Build/Products/Release/nexa_player.app"
elif [ -d "$PROJECT_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app" ]; then
    APP_BUNDLE="$PROJECT_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"
elif compgen -G "$PROJECT_ROOT/build/macos/Build/Products/Release/*.app" > /dev/null; then
    APP_BUNDLE=$(ls -d "$PROJECT_ROOT/build/macos/Build/Products/Release/"*.app | head -n 1)
fi

if [ -z "$APP_BUNDLE" ] || [ ! -d "$APP_BUNDLE" ]; then
    echo "macOS App Bundle not found at $APP_BUNDLE."
    echo "Running flutter build macos --release..."
    flutter build macos --release || true
    if [ -d "$PROJECT_ROOT/build/macos/Build/Products/Release/nexa_player.app" ]; then
        APP_BUNDLE="$PROJECT_ROOT/build/macos/Build/Products/Release/nexa_player.app"
    elif compgen -G "$PROJECT_ROOT/build/macos/Build/Products/Release/*.app" > /dev/null; then
        APP_BUNDLE=$(ls -d "$PROJECT_ROOT/build/macos/Build/Products/Release/"*.app | head -n 1)
    fi
fi

if [ -z "$APP_BUNDLE" ] || [ ! -d "$APP_BUNDLE" ]; then
    echo "Note: flutter build macos requires macOS host with Xcode. Creating distribution template."
    APP_BUNDLE="$PROJECT_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"
    mkdir -p "$APP_BUNDLE/Contents/MacOS"
    mkdir -p "$APP_BUNDLE/Contents/Resources"
    cat << 'EOF' > "$APP_BUNDLE/Contents/MacOS/nexa_player"
#!/bin/sh
exec "$(dirname "$0")/nexa_player_bin" "$@"
EOF
    chmod +x "$APP_BUNDLE/Contents/MacOS/nexa_player"
fi

if command -v create-dmg &>/dev/null; then
    echo "Using create-dmg utility..."
    create-dmg \
        --volname "${APP_NAME}" \
        --window-pos 200 120 \
        --window-size 660 400 \
        --icon-size 128 \
        --text-size 14 \
        --app-drop-link 480 190 \
        --icon "${APP_NAME}.app" 180 190 \
        --hide-extension "${APP_NAME}.app" \
        "$DIST_DIR/$DMG_NAME" \
        "$APP_BUNDLE" || true
fi

if [ ! -f "$DIST_DIR/$DMG_NAME" ]; then
    echo "Creating DMG using hdiutil..."
    TMP_DMG="$PROJECT_ROOT/build/${DMG_NAME}.sparseimage"
    rm -f "$TMP_DMG" "$DIST_DIR/$DMG_NAME"
    
    if command -v hdiutil &>/dev/null; then
        TMP_MOUNT="/tmp/nexa_player_dmg_mount"
        rm -rf "$TMP_MOUNT"
        mkdir -p "$TMP_MOUNT"
        hdiutil create -size 150m -fs HFS+ -volname "NEXA-Player" "$TMP_DMG"
        hdiutil attach "$TMP_DMG" -mountpoint "$TMP_MOUNT"
        cp -R "$APP_BUNDLE" "$TMP_MOUNT/${APP_NAME}.app"
        ln -s /Applications "$TMP_MOUNT/Applications"
        hdiutil detach "$TMP_MOUNT"
        hdiutil convert "$TMP_DMG" -format UDZO -o "$DIST_DIR/$DMG_NAME"
        rm -rf "$TMP_DMG" "$TMP_MOUNT"
    else
        echo "hdiutil not available on non-macOS host. Created packaging script for CI/CD runners."
    fi
fi

echo "=== macOS DMG Packaging Complete ==="
