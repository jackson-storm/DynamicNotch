#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_OUTPUT="$(mktemp -d "${TMPDIR:-/tmp}/dynamicnotch-tools.XXXXXX")"
xcrun swiftc -parse-as-library \
  "$ROOT_DIR/DynamicNotch/Features/Calculator/Models/MiniCalculatorEngine.swift" \
  "$ROOT_DIR/DynamicNotch/Features/HUD/Services/DisplayDDCProtocol.swift" \
  "$ROOT_DIR/DynamicNotch/Features/HomePage/Components/HomePageScrollGesture.swift" \
  "$ROOT_DIR/DynamicNotch/Features/ScreenshotHub/Services/ScreenshotCaptureFlow.swift" \
  "$ROOT_DIR/tests/standalone/IslandToolsTests.swift" \
  -o "$TEST_OUTPUT/island-tools-tests"
"$TEST_OUTPUT/island-tools-tests"
