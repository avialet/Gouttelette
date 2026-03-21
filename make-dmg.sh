#!/bin/bash
set -e

APP_NAME="Gouttelette"
VERSION="${1:-1.0.0}"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ $APP_BUNDLE introuvable. Lance d'abord ./build.sh"
    exit 1
fi

DMG_TEMP="$BUILD_DIR/dmg-temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

cp -R "$APP_BUNDLE" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

rm -f "$BUILD_DIR/$DMG_NAME"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DMG_TEMP" \
    -ov \
    -format UDBZ \
    "$BUILD_DIR/$DMG_NAME"

rm -rf "$DMG_TEMP"
echo "✅ DMG créé : $BUILD_DIR/$DMG_NAME"
