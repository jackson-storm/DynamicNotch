#!/usr/bin/env python3
"""Run native scroll and production home-page checks without app-host copies."""
from pathlib import Path
import plistlib
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
source = root / "DynamicNotch"
output = Path(tempfile.mkdtemp(prefix="dynamicnotch-navigation-"))
flags = ["xcrun", "swiftc", "-swift-version", "5", "-default-isolation", "MainActor", "-parse-as-library", "-target", "arm64-apple-macosx26.0"]

native_sources = [
    "Features/HomePage/Components/HomePageScrollGesture.swift",
    "Features/HomePage/Components/HomePageScrollInput.swift",
    "Features/HomePage/Models/HomePageNavigationLayout.swift",
]
native = output / "native-checks"
subprocess.run(flags + [str(source / p) for p in native_sources] + [str(root / "tests/standalone/HomePageNativeScrollTests.swift"), "-o", str(native)], check=True)
subprocess.run([str(native)], check=True)

view_sources = ['Features/Calculator/Models/MiniCalculatorEngine.swift', 'Features/Calculator/ViewModels/MiniCalculatorModel.swift', 'Features/Calculator/Views/CalculatorNotchView.swift', 'Features/ScreenshotHub/Services/ScreenshotCaptureFlow.swift', 'Features/ScreenshotHub/Services/ScreenshotRegionSelector.swift', 'Features/ScreenshotHub/ViewModels/ScreenshotCaptureModel.swift', 'Features/ScreenshotHub/Views/ScreenshotCaptureNotchView.swift', 'Features/HUD/Services/SystemAudioVolumeService.swift', 'Features/HUD/Services/DisplayDDCProtocol.swift', 'Features/HUD/Services/DisplayDDCVolumeService.swift', 'Features/HUD/Services/SystemAudioChangeObserver.swift', 'Features/HUD/ViewModels/SoundControlModel.swift', 'Features/HUD/Views/SoundControlNotchView.swift', 'Features/NowPlaying/Protocols/AudioOutputRouting.swift', 'Features/NowPlaying/Services/AudioOutputRoute.swift', 'Features/NowPlaying/Services/SystemAudioOutputRoutingService.swift', 'Features/Settings/Application/Models/DynamicNotchLanguage.swift', 'Resources/Localization/L10n.swift', 'Shared/UI/Environment/NotchScaleEnvironmentKey.swift', 'Core/SettingsEngine/SettingsStoreBase.swift', 'Features/HomePage/Settings/HomePageSettingsStore.swift', 'Features/HomePage/Models/HomePages.swift', 'Features/HomePage/Models/HomePageIndicatorSize.swift', 'Features/HomePage/Views/HomePageNotchView.swift', 'Features/HomePage/ViewModels/HomePageTools.swift', 'Features/HomePage/Components/HomePageScrollInput.swift', 'Features/HomePage/Components/HomePageScrollGesture.swift', 'Features/HomePage/Content/ToolHomePageNotchContent.swift', 'Features/HomePage/Models/HomePageNavigationLayout.swift', 'Features/HomePage/Content/HomePageNotchContent.swift', 'Features/Camera/Content/CameraActiveNotchContent.swift', 'Features/Timer/Content/LocalTimerHomePageNotchContent.swift', 'Features/VPN/Content/VpnHomePageNotchContent.swift', 'Core/NotchEngine/Protocols/NotchContentProtocol.swift', 'Core/NotchEngine/Protocols/DynamicIslandCustomizable.swift']
bundle = output / "navigation-checks.bundle"
macos = bundle / "Contents/MacOS"
macos.mkdir(parents=True)
(bundle / "Contents/Info.plist").write_bytes(plistlib.dumps({"CFBundleExecutable": "view-checks", "CFBundleIdentifier": "com.codex.navigation-checks", "CFBundlePackageType": "BNDL"}))
view = macos / "view-checks"
subprocess.run(flags + [str(source / p) for p in view_sources] + [str(root / "tests/standalone/HomePageNavigationIntegration.swift"), "-o", str(view)], check=True)
subprocess.run([str(view)], check=True)
