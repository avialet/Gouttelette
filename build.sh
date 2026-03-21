#!/bin/bash
set -e

APP_NAME="Gouttelette"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "🔨 Building $APP_NAME v$VERSION..."

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

SOURCES=$(find Gouttelette -name "*.swift" | tr '\n' ' ')

swiftc \
    $SOURCES \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macosx13.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework CoreGraphics \
    -framework QuartzCore \
    -framework Carbon \
    -Osize \
    -whole-module-optimization

cp Resources/Info.plist "$CONTENTS/"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"

# Nettoyer les attributs étendus avant signature
xattr -cr "$APP_BUNDLE"

codesign --force --sign - --entitlements Resources/Gouttelette.entitlements "$APP_BUNDLE"

echo "✅ $APP_NAME.app prêt dans $BUILD_DIR/"
