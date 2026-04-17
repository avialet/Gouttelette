#!/bin/bash
set -e

APP_NAME="Gouttelette"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_NAME="$APP_NAME-$VERSION.dmg"
DMG_PATH="$BUILD_DIR/$DMG_NAME"
STAGING="$BUILD_DIR/dmg-staging"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found. Run build.sh first."
    exit 1
fi

echo "Creating DMG..."

rm -rf "$STAGING"
mkdir -p "$STAGING"
cp -R "$APP_BUNDLE" "$STAGING/"
ln -s /Applications "$STAGING/Applications"

rm -f "$DMG_PATH"
hdiutil create "$DMG_PATH" \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDBZ \
    -quiet

rm -rf "$STAGING"

SIZE=$(du -sh "$DMG_PATH" | cut -f1)
echo "Created $DMG_PATH — $SIZE"
