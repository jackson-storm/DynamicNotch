#!/usr/bin/env python3
"""Render each real window root with the real player, without launching app copies."""
from pathlib import Path
import subprocess, tempfile, plistlib
root=Path(__file__).resolve().parents[1]
source=root/'DynamicNotch'
files=['Core/NotchEngine/NotchEngine.swift', 'Core/NotchEngine/Models/NotchModel.swift', 'Core/NotchEngine/Models/NotchState.swift', 'Core/NotchEngine/Protocols/NotchContentProtocol.swift', 'Core/NotchEngine/Protocols/DynamicIslandCustomizable.swift', 'Features/Notch/NotchAnimations.swift', 'Features/Notch/ViewModels/NotchViewModel.swift', 'Features/HomePage/Models/HomePageSessionMemory.swift', 'Core/NotchEngine/Models/NotchExpandInteraction.swift', 'Core/NotchEngine/Models/NotchCollapseInteraction.swift', 'Shared/UI/Modifiers/SwipeFeedbackMetrics.swift', 'Features/Notch/Components/SecondaryLiveActivityView.swift', 'Features/NowPlaying/Content/NowPlayingNotchContent.swift', 'Features/NowPlaying/ViewModels/NowPlayingViewModel.swift', 'Features/NowPlaying/Views/NowPlayingExpandedNotchView.swift', 'Features/NowPlaying/Views/NowPlayingMinimalNotchView.swift', 'Features/Timer/Views/TimerDetachedActivityView.swift', 'Features/NowPlaying/Models/NowPlayingSnapshot+Mutations.swift', 'Features/NowPlaying/Models/NowPlayingSourceFilter.swift', 'Features/NowPlaying/Models/NowPlayingProgressTintStyle.swift', 'Features/NowPlaying/Services/NowPlayingSnapshot.swift', 'Features/NowPlaying/Services/NowPlayingCommand.swift', 'Features/NowPlaying/Services/NowPlayingMonitoring.swift', 'Features/NowPlaying/Services/InactiveAudioOutputRoutingService.swift', 'Features/NowPlaying/Services/AudioOutputRoute.swift', 'Features/NowPlaying/Services/SystemAudioOutputRoutingService.swift', 'Features/NowPlaying/Protocols/AudioOutputRouting.swift', 'Features/NowPlaying/Protocols/LyricsProviding.swift', 'Features/HUD/ViewModels/SoundControlModel.swift', 'Features/HUD/Services/SystemAudioChangeObserver.swift', 'Features/HUD/Services/SystemAudioVolumeService.swift', 'Features/HUD/Services/DisplayDDCProtocol.swift', 'Features/HUD/Services/DisplayDDCVolumeService.swift', 'Shared/UI/Components/MarqueeText.swift', 'Shared/UI/Components/PressedButton.swift', 'Shared/UI/Components/PlaybackSourceButton.swift', 'Shared/UI/Environment/NotchScaleEnvironmentKey.swift', 'Features/Settings/Application/Models/DynamicNotchLanguage.swift', 'Resources/Localization/L10n.swift', 'Features/Notch/Views/NotchView.swift', 'Features/LockScreen/Views/LockScreenLiveActivityOverlayView.swift', 'Features/HomePage/ViewModels/HomePageTools.swift', 'Features/Calculator/Models/MiniCalculatorEngine.swift', 'Features/Calculator/ViewModels/MiniCalculatorModel.swift', 'Features/ScreenshotHub/Services/ScreenshotCaptureFlow.swift', 'Features/ScreenshotHub/Services/ScreenshotRegionSelector.swift', 'Features/ScreenshotHub/ViewModels/ScreenshotCaptureModel.swift']
files += [str(p.relative_to(source)) for p in (source/'Features/NowPlaying/Components').glob('*.swift')]
files += [str(p.relative_to(source)) for p in (source/'Features/NowPlaying/Services/Lyrics').rglob('*.swift')]
output=Path(tempfile.mkdtemp(prefix='dynamicnotch-presentation-'))
bundle=output/'presentation-checks.bundle'
macos=bundle/'Contents/MacOS'; macos.mkdir(parents=True)
(bundle/'Contents/Info.plist').write_bytes(plistlib.dumps({'CFBundleExecutable':'checks','CFBundleIdentifier':'com.codex.presentation-checks','CFBundlePackageType':'BNDL'}))
binary=macos/'checks'
subprocess.run(['xcrun','swiftc','-swift-version','5','-default-isolation','MainActor','-parse-as-library','-target','arm64-apple-macosx26.0']+[str(source/p) for p in files]+[str(root/'tests/standalone/PresentationTestSupport.swift'),str(root/'tests/standalone/PresentationDependencyTests.swift'),'-o',str(binary)],check=True)
for scene in ['primary','lock-overlay','both']:
 result=subprocess.run([str(binary),scene],capture_output=True,text=True)
 print(result.stdout, end='',flush=True)
 if result.returncode:
  print(f'FAIL: {scene} renderer exited {result.returncode}',flush=True)
  print(result.stderr[:2400],flush=True)
  raise SystemExit(1)
