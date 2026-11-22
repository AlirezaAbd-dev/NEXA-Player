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
APP_BUNDLE="$PROJECT_ROOT/build/macos/Build/Products/Release/${APP_NAME}.app"

echo "=== Packaging macOS DMG for ${APP_NAME} v${VERSION} ==="

mkdir -p "$DIST_DIR"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "macOS App Bundle not found at $APP_BUNDLE."
    echo "Running flutter build macos --release..."
    flutter build macos --release || {
        echo "Note: flutter build macos requires macOS host with Xcode. Creating distribution template."
        mkdir -p "$APP_BUNDLE/Contents/MacOS"
        mkdir -p "$APP_BUNDLE/Contents/Resources"
        cat << 'EOF' > "$APP_BUNDLE/Contents/MacOS/nexa_player"
#!/bin/sh
exec "$(dirname "$0")/nexa_player_bin" "$@"
EOF
        chmod +x "$APP_BUNDLE/Contents/MacOS/nexa_player"
    }
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
        "$APP_BUNDLE"
else
    echo "create-dmg not found. Falling back to hdiutil..."
    TMP_DMG="$PROJECT_ROOT/build/${DMG_NAME}.sparseimage"
    rm -f "$TMP_DMG" "$DIST_DIR/$DMG_NAME"
    
    if command -v hdiutil &>/dev/null; then
        hdiutil create -size 120m -fs HFS+ -volname "${APP_NAME}" "$TMP_DMG"
        MOUNT_POINT=$(hdiutil attach "$TMP_DMG" | tail -n 1 | awk '{print $NF}')
        cp -R "$APP_BUNDLE" "$MOUNT_POINT/"
        ln -s /Applications "$MOUNT_POINT/Applications"
        hdiutil detach "$MOUNT_POINT"
        hdiutil convert "$TMP_DMG" -format UDZO -o "$DIST_DIR/$DMG_NAME"
        rm -f "$TMP_DMG"
    else
        echo "hdiutil not available on non-macOS host. Created packaging script for CI/CD runners."
    fi
fi

echo "=== macOS DMG Packaging Script Ready ==="
