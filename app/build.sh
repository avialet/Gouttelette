#!/bin/bash
set -e

APP_NAME="Gouttelette"
VERSION="${1:-1.0.0}"
BUILD_DIR="build"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

echo "Building $APP_NAME v$VERSION..."

rm -rf "$BUILD_DIR"
mkdir -p "$MACOS" "$RESOURCES"

SOURCES=$(find Sources -name "*.swift" | tr '\n' ' ')
SOURCES="$SOURCES $(find VialetKit -name "*.swift" | tr '\n' ' ')"

echo "  Sources: $(echo $SOURCES | wc -w | tr -d ' ') files"

swiftc \
    $SOURCES \
    -o "$MACOS/$APP_NAME" \
    -target arm64-apple-macosx13.0 \
    -framework AppKit \
    -framework SwiftUI \
    -framework CoreGraphics \
    -framework QuartzCore \
    -framework Carbon \
    -framework ServiceManagement \
    -Osize \
    -whole-module-optimization

cp Resources/Info.plist "$CONTENTS/"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$CONTENTS/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$CONTENTS/Info.plist"

for lang in fr en de it es; do
    mkdir -p "$RESOURCES/${lang}.lproj"
    cp Resources/${lang}.lproj/*.strings "$RESOURCES/${lang}.lproj/" 2>/dev/null || true
done

xattr -cr "$APP_BUNDLE" 2>/dev/null
codesign --force --sign - --deep --entitlements Resources/Gouttelette.entitlements "$APP_BUNDLE"

SIZE=$(du -sh "$MACOS/$APP_NAME" | cut -f1)
echo "Built $APP_BUNDLE (v$VERSION) — binary: $SIZE"
