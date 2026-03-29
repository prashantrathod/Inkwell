#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SCRIPT_DIR"

echo "==> Generating app icon..."
swiftc gen_icon.swift -o gen_icon -framework Cocoa
./gen_icon AppIcon.iconset
iconutil -c icns AppIcon.iconset -o AppIcon.icns

echo "==> Building Inkwell.app..."
APP="Inkwell.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

swiftc main.swift -o "$APP/Contents/MacOS/Inkwell" \
  -framework Cocoa \
  -framework WebKit \
  -target x86_64-apple-macos12.0

cp Info.plist "$APP/Contents/"
cp AppIcon.icns "$APP/Contents/Resources/"
cp "$PROJECT_DIR/markdown-editor.html" "$APP/Contents/Resources/"

echo "==> Creating DMG..."
DMG_DIR="dmg_staging"
rm -rf "$DMG_DIR"
mkdir -p "$DMG_DIR"
cp -R "$APP" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

rm -f "$PROJECT_DIR/Inkwell.dmg"
hdiutil create \
  -volname "Inkwell" \
  -srcfolder "$DMG_DIR" \
  -ov \
  -format UDZO \
  "$PROJECT_DIR/Inkwell.dmg"

echo "==> Done!"
echo "    App: $SCRIPT_DIR/$APP"
echo "    DMG: $PROJECT_DIR/Inkwell.dmg"
