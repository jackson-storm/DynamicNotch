#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/DynamicNotch.xcodeproj}"
SCHEME="${SCHEME:-DynamicNotch}"
CONFIGURATION="${CONFIGURATION:-Release}"
DESTINATION="${DESTINATION:-platform=macOS}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$ROOT_DIR/build/DerivedData}"
CLONED_SOURCE_PACKAGES_PATH="${CLONED_SOURCE_PACKAGES_PATH:-}"
CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-NO}"

APP_NAME="${APP_NAME:-DynamicNotch.app}"
VOLUME_NAME="${VOLUME_NAME:-DynamicNotch}"
OUTPUT_DIR="${OUTPUT_DIR:-$ROOT_DIR/build/dmg}"
DMG_NAME="${DMG_NAME:-DynamicNotch.dmg}"

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dynamicnotch-dmg.XXXXXX")"

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

echo "Resolving Swift packages..."
if [[ -n "$CLONED_SOURCE_PACKAGES_PATH" ]]; then
  xcodebuild \
    -resolvePackageDependencies \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -clonedSourcePackagesDirPath "$CLONED_SOURCE_PACKAGES_PATH"
else
  xcodebuild \
    -resolvePackageDependencies \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME"
fi

echo "Building $APP_NAME ($CONFIGURATION)..."
if [[ -n "$CLONED_SOURCE_PACKAGES_PATH" ]]; then
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -clonedSourcePackagesDirPath "$CLONED_SOURCE_PACKAGES_PATH" \
    CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
    build
else
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED="$CODE_SIGNING_ALLOWED" \
    build
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build finished, but app was not found at: $APP_PATH" >&2
  exit 1
fi

echo "Staging DMG contents..."
ditto "$APP_PATH" "$STAGING_DIR/$APP_NAME"
ln -s /Applications "$STAGING_DIR/Applications"

mkdir -p "$OUTPUT_DIR"
rm -f "$DMG_PATH"

echo "Creating DMG: $DMG_PATH"
hdiutil create \
  -volname "$VOLUME_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo "Created: $DMG_PATH"
