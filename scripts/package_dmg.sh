#!/bin/zsh

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="$ROOT_DIR/MDQuickLookPreview.xcodeproj"
PROJECT_SPEC_PATH="$ROOT_DIR/project.yml"
SCHEME="MDQuickLookHost"
CONFIGURATION="Release"
DERIVED_DATA_PATH="$ROOT_DIR/build/DerivedData"
STAGING_DIR="$ROOT_DIR/build/dmg"
DIST_DIR="$ROOT_DIR/dist"
APP_NAME="MD Quick Look"
APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"

mkdir -p "$DIST_DIR"
rm -rf "$DERIVED_DATA_PATH" "$STAGING_DIR"
mkdir -p "$STAGING_DIR"

if [[ ! -d "$PROJECT_PATH" || "$PROJECT_SPEC_PATH" -nt "$PROJECT_PATH/project.pbxproj" ]]; then
  echo "Generating Xcode project..."
  (cd "$ROOT_DIR" && xcodegen generate >/dev/null)
fi

echo "Building $APP_NAME ($CONFIGURATION)..."
xcodebuild \
  -project "$PROJECT_PATH" \
  -scheme "$SCHEME" \
  -configuration "$CONFIGURATION" \
  -derivedDataPath "$DERIVED_DATA_PATH" \
  -destination 'platform=macOS' \
  build

if [[ ! -d "$APP_PATH" ]]; then
  echo "Expected app not found: $APP_PATH" >&2
  exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$INFO_PLIST")"
DMG_NAME="MD-Quick-Look-${VERSION}.dmg"
DMG_PATH="$DIST_DIR/$DMG_NAME"

echo "Assembling DMG payload..."
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating $DMG_PATH ..."
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH" >/dev/null

echo
echo "Done"
echo "App: $APP_PATH"
echo "DMG: $DMG_PATH"
echo
echo "Note: this build is ad-hoc signed. For frictionless distribution to other Macs,"
echo "use an Apple Developer ID certificate and notarize the app before shipping."
