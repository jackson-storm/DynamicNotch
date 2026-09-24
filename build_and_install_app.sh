#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PROJECT_PATH="${PROJECT_PATH:-$ROOT_DIR/DynamicNotch.xcodeproj}"
SCHEME="${SCHEME:-DynamicNotch}"
CONFIGURATION="${CONFIGURATION:-Release}"
DESTINATION="${DESTINATION:-platform=macOS}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/private/tmp/DynamicNotchDerivedData}"
CLONED_SOURCE_PACKAGES_PATH="${CLONED_SOURCE_PACKAGES_PATH:-}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
APP_NAME="${APP_NAME:-DynamicNotch.app}"

APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME"
TARGET_PATH="$INSTALL_DIR/$APP_NAME"

echo "Building $APP_NAME ($CONFIGURATION)..."
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

if [[ -n "$CLONED_SOURCE_PACKAGES_PATH" ]]; then
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    -clonedSourcePackagesDirPath "$CLONED_SOURCE_PACKAGES_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    build
else
  xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED_DATA_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    build
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build finished, but app was not found at: $APP_PATH" >&2
  exit 1
fi

echo "Installing to $TARGET_PATH..."
if [[ ! -d "$INSTALL_DIR" && -w "$(dirname "$INSTALL_DIR")" ]]; then
  mkdir -p "$INSTALL_DIR"
fi

if [[ -d "$INSTALL_DIR" && -w "$INSTALL_DIR" ]]; then
  rm -rf "$TARGET_PATH"
  ditto "$APP_PATH" "$TARGET_PATH"
else
  sudo mkdir -p "$INSTALL_DIR"
  sudo rm -rf "$TARGET_PATH"
  sudo ditto "$APP_PATH" "$TARGET_PATH"
fi

echo "Installed: $TARGET_PATH"
