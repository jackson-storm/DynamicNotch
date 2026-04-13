# Project Map

This guide explains what each source file, test file, and key project metadata file is responsible for.
Binary asset variants, duplicated image renditions, and user-local Xcode state files are intentionally omitted to keep the map useful.

## Root Files
- `README.md` — Project overview, installation steps, architecture summary, and preview media.
- `SECURITY.md` — Security reporting policy and disclosure guidance for the repository.
- `LICENSE` — GPLv3 license text for the project.

## Xcode Project Files
- `DynamicNotch.xcodeproj/project.pbxproj` — The Xcode build graph with targets, file references, and build settings.
- `DynamicNotch.xcodeproj/project.xcworkspace/contents.xcworkspacedata` — Workspace metadata that tells Xcode which project to open.
- `DynamicNotch.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved` — Pinned Swift Package Manager dependency versions used by the workspace.
- `DynamicNotch.xcodeproj/xcshareddata/xcschemes/DynamicNotch.xcscheme` — Shared scheme for building and testing the main macOS app target.
- `DynamicNotch.xcodeproj/xcshareddata/xcschemes/DynamicNotchUI.xcscheme` — Shared scheme for UI-focused runs and previews.

## Application
- `Application/SettingsRootView.swift` — Empty placeholder file at the repository root; it is currently unused.
- `DynamicNotch/Application/AppContainer.swift` — Composes services, feature view models, coordinators, and window managers in one place.
- `DynamicNotch/Application/AppDelegate/AppDelegate+Observers.swift` — AppDelegate extension that registers system observers and feature subscriptions.
- `DynamicNotch/Application/AppDelegate/AppDelegate+OutsideClick.swift` — AppDelegate extension that collapses expanded notch content after outside clicks.
- `DynamicNotch/Application/AppDelegate/AppDelegate+Window.swift` — AppDelegate extension that creates, positions, and refreshes the floating notch window.
- `DynamicNotch/Application/AppDelegate/AppDelegate.swift` — Main AppKit delegate that owns lifecycle setup and shared app wiring.
- `DynamicNotch/Application/AppRelauncher.swift` — Utility for restarting the app after settings or environment changes.
- `DynamicNotch/Application/AppVersionText.swift` — Formats the app version and build number for menus and settings screens.
- `DynamicNotch/Application/DynamicNotchApp.swift` — SwiftUI app entry point that exposes the menu bar extra and settings window scene.
- `DynamicNotch/Application/GlobalClickMonitor.swift` — Thin wrapper around NSEvent monitoring for global and local click detection.
- `DynamicNotch/Application/NotchHostingView.swift` — AppKit hosting view that embeds notch SwiftUI content inside the overlay window.
- `DynamicNotch/Application/OverlayPanelWindow.swift` — Borderless overlay panel used to render the notch above normal app windows.
- `DynamicNotch/Application/Settings/SettingsPermissionController.swift` — Coordinates permission status checks, prompts, and deep links for the settings UI.
- `DynamicNotch/Application/Settings/SettingsRootDebugFactory.swift` — Builds debug-only settings dependencies so the root view model stays lean in normal code paths.
- `DynamicNotch/Application/Settings/SettingsRootSections.swift` — Defines settings sections, sidebar groups, search metadata, icons, colors, and reset capabilities.
- `DynamicNotch/Application/Settings/SettingsRootView.swift` — Top-level settings shell with sidebar navigation, search, and per-section detail views.
- `DynamicNotch/Application/Settings/SettingsRootViewModel.swift` — Coordinates section persistence, reset actions, and debug tooling for the settings root screen.
- `DynamicNotch/Application/Settings/SettingsSelectionHistory.swift` — Tracks back and forward history for the selected settings section.
- `DynamicNotch/Application/Info.plist` — Bundle metadata, identifiers, and launch configuration for the macOS app target.

## Core Enums
- `DynamicNotch/Core/Enums/Notch/NotchState.swift` — Queue events that drive the notch engine state machine.
- `DynamicNotch/Core/Enums/Settings/DynamicNotchLanguage.swift` — Supported in-app language options plus locale helpers for the UI.
- `DynamicNotch/Core/Enums/Settings/LockScreenCustomSoundKind.swift` — User-selectable sound sources for lock-screen transition audio.
- `DynamicNotch/Core/Enums/Settings/NotchAnimationPreset.swift` — Named animation presets that tune notch transition timing and feel.
- `DynamicNotch/Core/Enums/Settings/NotchBackgroundStyle.swift` — Available visual materials and fill styles for the notch surface.
- `DynamicNotch/Core/Enums/Settings/NotchDisplayLocation.swift` — Placement rules for choosing which display hosts the notch overlay.
- `DynamicNotch/Core/Enums/Settings/SettingsAppearanceMode.swift` — Appearance modes used by the settings window and app-level styling.

## Core Models
- `DynamicNotch/Core/Models/AudioOutputRoute.swift` — Value model describing an audio output device that can receive playback.
- `DynamicNotch/Core/Models/BluetoothAudioDevice.swift` — Normalized Bluetooth device snapshot used by view models and notch content.
- `DynamicNotch/Core/Models/DownloadModel.swift` — Download progress snapshot consumed by the downloads feature.
- `DynamicNotch/Core/Models/NotchModel.swift` — The canonical presentation state mirrored by the notch engine and view model.

## Core Protocols
- `DynamicNotch/Core/Protocols/AudioOutputRouting.swift` — Abstraction for listing and switching system audio output devices.
- `DynamicNotch/Core/Protocols/DownloadMonitoring.swift` — Contract for services that publish download activity snapshots.
- `DynamicNotch/Core/Protocols/LockScreenMonitoring.swift` — Contract for services that publish lock-screen state changes.
- `DynamicNotch/Core/Protocols/NetworkMonitoring.swift` — Contract for services that publish Wi-Fi, hotspot, and VPN state.
- `DynamicNotch/Core/Protocols/NotchContentProtocol.swift` — Common interface every piece of notch content implements for the engine.
- `DynamicNotch/Core/Protocols/NotchSettingsProviding.swift` — Read/write surface the notch layer uses to access feature settings.
- `DynamicNotch/Core/Protocols/PowerStateProviding.swift` — Contract for reading and observing battery and charging state.

## Core Services
- `DynamicNotch/Core/Services/Bluetooth/BluetoothLEBatteryReader.swift` — Reads battery levels from Bluetooth LE devices through GATT characteristics.
- `DynamicNotch/Core/Services/Bluetooth/BluetoothService+Battery.swift` — BluetoothService extension with battery caching, parsing, and related helpers.
- `DynamicNotch/Core/Services/Bluetooth/BluetoothService+Detection.swift` — BluetoothService extension with device discovery, classification, and event-detection logic.
- `DynamicNotch/Core/Services/Bluetooth/BluetoothService+Lifecycle.swift` — BluetoothService extension with startup, teardown, and observer lifecycle management.
- `DynamicNotch/Core/Services/Bluetooth/BluetoothService.swift` — CoreBluetooth-backed service that tracks device connections and emits Bluetooth events.
- `DynamicNotch/Core/Services/Download/FolderFileDownloadMonitor.swift` — File-system monitor that infers download progress from observed files and folders.
- `DynamicNotch/Core/Services/Download/InactiveDownloadMonitor.swift` — No-op download monitor used in tests and environments without real file observation.
- `DynamicNotch/Core/Services/Focus/DoNotDisturbManager+Metadata.swift` — DoNotDisturbManager helpers for decoding metadata payloads from system signals.
- `DynamicNotch/Core/Services/Focus/DoNotDisturbManager.swift` — Facade over Focus / Do Not Disturb state lookup and active-mode tracking.
- `DynamicNotch/Core/Services/Focus/FocusLogStream.swift` — Streams relevant system log entries so Focus changes can be decoded reliably.
- `DynamicNotch/Core/Services/Focus/FocusMetadataDecoder.swift` — Parses raw Focus metadata into typed values the app can reason about.
- `DynamicNotch/Core/Services/Focus/FocusModeType.swift` — Normalized list of Focus mode categories used by services and UI.
- `DynamicNotch/Core/Services/Focus/FocusService.swift` — High-level service that publishes focus-mode transitions for the notch layer.
- `DynamicNotch/Core/Services/HUD/HardwareHUDMonitor.swift` — Observes hardware HUD-related changes and emits notch-friendly HUD events.
- `DynamicNotch/Core/Services/HUD/SystemAudioVolumeService.swift` — Reads and updates system output volume for the custom HUD experience.
- `DynamicNotch/Core/Services/HUD/SystemDisplayBrightnessService.swift` — Reads and updates display brightness for the custom hardware HUD flow.
- `DynamicNotch/Core/Services/HUD/SystemMediaKeyTap.swift` — Low-level media-key tap used to intercept hardware key presses for custom HUD handling.
- `DynamicNotch/Core/Services/LockScreen/DistributedLockScreenMonitoringService.swift` — Live lock-screen monitor backed by distributed notifications and system signals.
- `DynamicNotch/Core/Services/LockScreen/InactiveLockScreenMonitoringService.swift` — No-op lock-screen monitor used for tests and unsupported environments.
- `DynamicNotch/Core/Services/LockScreen/LockScreenLiveActivityWindowManager.swift` — Manages the lock-screen live-activity window during lock and unlock transitions.
- `DynamicNotch/Core/Services/LockScreen/LockScreenManager.swift` — Central coordinator for lock-screen state, transition timing, and sound playback.
- `DynamicNotch/Core/Services/LockScreen/LockScreenSoundPlayer.swift` — Audio playback abstractions and implementations for lock and unlock sounds.
- `DynamicNotch/Core/Services/Network/NetworkService.swift` — Network monitoring service that tracks Wi-Fi, VPN, and hotspot state changes.
- `DynamicNotch/Core/Services/NowPlaying/InactiveAudioOutputRoutingService.swift` — No-op audio routing service for tests and non-interactive runs.
- `DynamicNotch/Core/Services/NowPlaying/InactiveNowPlayingService.swift` — No-op now playing service used when MediaRemote integration is disabled.
- `DynamicNotch/Core/Services/NowPlaying/MediaKeyCommandDispatcher.swift` — Dispatches play, pause, skip, and related commands through media key semantics.
- `DynamicNotch/Core/Services/NowPlaying/MediaRemoteCommandDispatcher.swift` — Sends transport commands directly through MediaRemote APIs.
- `DynamicNotch/Core/Services/NowPlaying/MediaRemoteElapsedTimeDispatcher.swift` — Synchronizes elapsed-time and scrubbing updates for the now playing experience.
- `DynamicNotch/Core/Services/NowPlaying/MediaRemoteNowPlayingService.swift` — Primary MediaRemote-backed service that publishes live playback state.
- `DynamicNotch/Core/Services/NowPlaying/NowPlayingCommand.swift` — Command vocabulary supported by the now playing control surface.
- `DynamicNotch/Core/Services/NowPlaying/NowPlayingMonitoring.swift` — Protocol describing the publishers exposed by now playing services.
- `DynamicNotch/Core/Services/NowPlaying/NowPlayingSnapshot.swift` — Value snapshot for title, artist, artwork, transport, and progress state.
- `DynamicNotch/Core/Services/NowPlaying/SystemAudioOutputRoutingService.swift` — Concrete audio routing service that queries and switches macOS output devices.
- `DynamicNotch/Core/Services/Power/PowerService.swift` — Battery and charger monitoring service built on top of macOS power APIs.
- `DynamicNotch/Core/Services/NowPlaying/mediaremote-helper.swiftscript` — Standalone helper script that reads MediaRemote metadata and streams JSON snapshots.

## Feature: AirDrop
- `DynamicNotch/Features/AirDrop/AirDropController.swift` — Coordinates drag-and-drop handoff from Finder into the notch AirDrop flow.
- `DynamicNotch/Features/AirDrop/AirDropDestinationView.swift` — Drop-target view that validates AirDrop drags and forwards accepted payloads.
- `DynamicNotch/Features/AirDrop/AirDropNotch.swift` — Defines AirDrop live-activity content, layout, and drop-zone presentation.
- `DynamicNotch/Features/AirDrop/AirDropViewModel.swift` — Publishes AirDrop state and emits events consumed by the notch coordinator.

## Feature: Battery
- `DynamicNotch/Features/Battery/BatteryCompactStatusView.swift` — Compact battery status view reused inside battery-related notch surfaces.
- `DynamicNotch/Features/Battery/BatteryNotificationStyle.swift` — Visual style options for temporary battery notifications.
- `DynamicNotch/Features/Battery/ChargerNotch.swift` — Temporary notch content shown when external power is connected.
- `DynamicNotch/Features/Battery/FullPowerNotch.swift` — Temporary notch content shown when the battery reaches a full charge.
- `DynamicNotch/Features/Battery/LowPowerNotch.swift` — Temporary notch content shown when the battery drops into a low-power state.
- `DynamicNotch/Features/Battery/PowerViewModel.swift` — Transforms PowerService updates into battery-specific state and notch events.

## Feature: Bluetooth
- `DynamicNotch/Features/Bluetooth/BluetoothAppearanceStyle.swift` — Appearance presets for Bluetooth live activity and notification content.
- `DynamicNotch/Features/Bluetooth/BluetoothAudioDeviceType.swift` — Categorizes Bluetooth audio devices for icons and display rules.
- `DynamicNotch/Features/Bluetooth/BluetoothBatteryIndicatorStyle.swift` — Display styles for rendering Bluetooth battery levels in notch content.
- `DynamicNotch/Features/Bluetooth/BluetoothNotch.swift` — Notch content definitions for Bluetooth connection and battery updates.
- `DynamicNotch/Features/Bluetooth/BluetoothViewModel.swift` — Bridges BluetoothService state into UI-ready properties and feature events.

## Feature: Download
- `DynamicNotch/Features/Download/DownloadAppearanceStyle.swift` — Appearance presets for the downloads live activity.
- `DynamicNotch/Features/Download/DownloadNotch.swift` — Live-activity content and layout for active downloads inside the notch.
- `DynamicNotch/Features/Download/DownloadProgressIndicatorStyle.swift` — Selectable progress-indicator styles for download UI.
- `DynamicNotch/Features/Download/DownloadViewModel.swift` — Transforms download monitor snapshots into notch-ready state and events.

## Feature: Focus
- `DynamicNotch/Features/Focus/FocusAppearanceStyle.swift` — Appearance presets for Focus live activity content.
- `DynamicNotch/Features/Focus/FocusNotch.swift` — Notch content shown when Focus mode is enabled or disabled.
- `DynamicNotch/Features/Focus/FocusViewModel.swift` — Publishes focus-mode state and emits events for the coordinator.

## Feature: HUD
- `DynamicNotch/Features/HUD/HudContentView.swift` — Shared SwiftUI view that renders the custom hardware HUD content.
- `DynamicNotch/Features/HUD/HudIndicatorStyle.swift` — Indicator styles available for HUD level visualization.
- `DynamicNotch/Features/HUD/HudLevelIndicatorView.swift` — Level meter view used by brightness, keyboard, and volume HUDs.
- `DynamicNotch/Features/HUD/HudLevelStyling.swift` — Styling helpers for mapping HUD values to colors and emphasis.
- `DynamicNotch/Features/HUD/HudNotchContent.swift` — Defines HUD events and the notch content used to render transient hardware changes.
- `DynamicNotch/Features/HUD/HudPresentationKind.swift` — Presentation modes that describe how a HUD should be shown.
- `DynamicNotch/Features/HUD/HudStyle.swift` — High-level style presets for the custom hardware HUD.

## Feature: LockScreen
- `DynamicNotch/Features/LockScreen/LockScreenNotch.swift` — Lock-screen live activity content plus events emitted during lock transitions.
- `DynamicNotch/Features/LockScreen/LockScreenNowPlayingPanel.swift` — Supplementary lock-screen panel that shows now playing controls beside the notch.
- `DynamicNotch/Features/LockScreen/LockScreenPanelManager.swift` — Manages the auxiliary lock-screen panel window, layout, and animations.
- `DynamicNotch/Features/LockScreen/LockScreenSettings.swift` — Shared keys and defaults for lock-screen-related feature settings.
- `DynamicNotch/Features/LockScreen/LockScreenStyle.swift` — Visual style presets for the lock-screen notch experience.
- `DynamicNotch/Features/LockScreen/LockScreenWidgetAppearanceStyle.swift` — Appearance options for lock-screen widget surfaces.
- `DynamicNotch/Features/LockScreen/LockScreenWidgetSurface.swift` — Reusable surface component for lock-screen widgets and small status blocks.
- `DynamicNotch/Features/LockScreen/LockScreenWidgetTintStyle.swift` — Tint options used by lock-screen widget surfaces.

## Feature: Network
- `DynamicNotch/Features/Network/HotspotAppearanceStyle.swift` — Appearance presets for hotspot-related live activity content.
- `DynamicNotch/Features/Network/HotspotNotch.swift` — Notch content shown while Personal Hotspot is active.
- `DynamicNotch/Features/Network/NetworkViewModel.swift` — Combines network monitor updates into Wi-Fi, VPN, and hotspot state for the notch.
- `DynamicNotch/Features/Network/VPNAppearanceStyle.swift` — Appearance presets for VPN-related live activity content.
- `DynamicNotch/Features/Network/VpnNotch.swift` — Notch content shown for VPN connection state.
- `DynamicNotch/Features/Network/WifiNotch.swift` — Temporary notch content shown for Wi-Fi connectivity updates.

## Feature: Notch
- `DynamicNotch/Features/Notch/EventHandlers/NotchConnectivityEventsHandler.swift` — Routes Bluetooth and network feature events into notch engine actions.
- `DynamicNotch/Features/Notch/EventHandlers/NotchFocusEventsHandler.swift` — Routes Focus-mode events into notch engine actions.
- `DynamicNotch/Features/Notch/EventHandlers/NotchHUDEventsHandler.swift` — Routes hardware HUD events into notch engine actions.
- `DynamicNotch/Features/Notch/EventHandlers/NotchMediaEventsHandler.swift` — Routes now playing, downloads, and AirDrop events into notch engine actions.
- `DynamicNotch/Features/Notch/EventHandlers/NotchPowerEventsHandler.swift` — Routes battery and charging events into notch engine actions.
- `DynamicNotch/Features/Notch/EventHandlers/NotchSystemEventsHandler.swift` — Routes system-level notch resize and housekeeping events into the engine.
- `DynamicNotch/Features/Notch/NotchAnimations.swift` — Central collection of animation timings and curves used by notch transitions.
- `DynamicNotch/Features/Notch/NotchBackgroundSurface.swift` — Background renderer for the notch surface, stroke, and material styling.
- `DynamicNotch/Features/Notch/NotchEngine.swift` — Queue-driven state machine that shows, hides, restores, and prioritizes notch content.
- `DynamicNotch/Features/Notch/NotchEventCoordinator.swift` — Top-level router that listens to feature streams and delegates them to specialized handlers.
- `DynamicNotch/Features/Notch/NotchShape.swift` — Custom SwiftUI shape that matches the MacBook notch silhouette.
- `DynamicNotch/Features/Notch/NotchSizeContent.swift` — Temporary notch content and events used while resizing the notch.
- `DynamicNotch/Features/Notch/NotchView.swift` — Primary notch view that binds layout, gestures, and content presentation together.
- `DynamicNotch/Features/Notch/NotchViewModel.swift` — SwiftUI-facing facade over NotchEngine, geometry, gestures, and interaction state.

## Feature: NowPlaying
- `DynamicNotch/Features/NowPlaying/NowPlayingArtworkPalette.swift` — Extracts reusable palette colors from album artwork for adaptive styling.
- `DynamicNotch/Features/NowPlaying/NowPlayingNotch.swift` — Defines the now playing live activity UI, controls, and appearance options.
- `DynamicNotch/Features/NowPlaying/NowPlayingViewModel.swift` — Transforms MediaRemote state into now playing view state and feature events.

## Feature: Onboarding
- `DynamicNotch/Features/Onboarding/OnboardingNotchContent.swift` — Onboarding events, step metadata, and notch content wrappers for first-run guidance.
- `DynamicNotch/Features/Onboarding/OnboardingNotchView.swift` — Shared container view used by the onboarding steps shown inside the notch.
- `DynamicNotch/Features/Onboarding/Steps/OnboardingNotchFirstStepView.swift` — First onboarding step shown in the notch experience.
- `DynamicNotch/Features/Onboarding/Steps/OnboardingNotchSecondStepView.swift` — Second onboarding step shown in the notch experience.
- `DynamicNotch/Features/Onboarding/Steps/OnboardingNotchThirdStepView.swift` — Final onboarding step shown in the notch experience.

## Feature: Settings
- `DynamicNotch/Features/Settings/Application/AboutAppSettingsView.swift` — About page for app metadata, credits, links, and version information.
- `DynamicNotch/Features/Settings/Application/GeneralSettingsView.swift` — Settings page for general application behavior and startup options.
- `DynamicNotch/Features/Settings/Application/NotchSettingsView.swift` — Settings page for notch size, style, animation, and placement preferences.
- `DynamicNotch/Features/Settings/Application/PermissionsSettingsView.swift` — Settings page that explains and links required macOS permissions.
- `DynamicNotch/Features/Settings/Application/SettingsViewModel.swift` — Facade over all settings stores exposed to features and the settings UI.
- `DynamicNotch/Features/Settings/Connectivity/BluetoothSettingsView.swift` — Settings page for Bluetooth activity and notification preferences.
- `DynamicNotch/Features/Settings/Connectivity/FocusSettingsView.swift` — Settings page for Focus live activity and related appearance options.
- `DynamicNotch/Features/Settings/Connectivity/NetworkSettingsView.swift` — Settings page for Wi-Fi, VPN, and hotspot activity preferences.
- `DynamicNotch/Features/Settings/Developer/DebugSettingsView.swift` — Developer page for previewing notch flows and manually triggering debug scenarios.
- `DynamicNotch/Features/Settings/Developer/DebugSettingsViewModel.swift` — View model that assembles debug actions and sample content for previews.
- `DynamicNotch/Features/Settings/Media&Files/AirDropSettingsView.swift` — Settings page for AirDrop live-activity preferences.
- `DynamicNotch/Features/Settings/Media&Files/DownloadsSettingsView.swift` — Settings page for downloads monitoring and presentation preferences.
- `DynamicNotch/Features/Settings/Media&Files/NowPlayingSettingsView.swift` — Settings page for now playing controls, styling, and live-activity behavior.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsAccessibilityModifier.swift` — Accessibility helpers applied across settings controls and pages.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsCardView.swift` — Reusable card container used to group settings controls visually.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsIconBadge.swift` — Small icon badge component for settings section headers and rows.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsMenuRow.swift` — Reusable menu-style row for picker-based settings.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsNotchPreview.swift` — Live miniature notch preview used throughout the settings UI.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsPageScrollView.swift` — Scroll container that provides consistent insets and behavior for settings pages.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsSearchEmptyState.swift` — Empty-state view shown when settings search returns no matching sections.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsSidebarRow.swift` — Sidebar row used to render settings destinations with icons and tinting.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsSliderRow.swift` — Reusable slider row for numeric settings values.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsStrokeToggleRow.swift` — Toggle row specialized for stroke-related appearance settings.
- `DynamicNotch/Features/Settings/Shared/Components/SettingsToggleRow.swift` — Reusable labeled toggle row used across many settings pages.
- `DynamicNotch/Features/Settings/Shared/Stores/ApplicationSettingsStore.swift` — UserDefaults-backed store for application-wide appearance and behavior settings.
- `DynamicNotch/Features/Settings/Shared/Stores/BatterySettingsStore.swift` — UserDefaults-backed store for battery notification preferences.
- `DynamicNotch/Features/Settings/Shared/Stores/ConnectivitySettingsStore.swift` — UserDefaults-backed store for Bluetooth, Wi-Fi, VPN, and Focus preferences.
- `DynamicNotch/Features/Settings/Shared/Stores/GeneralSettingsStorage.swift` — Shared keys, defaults, and storage helpers used by settings stores.
- `DynamicNotch/Features/Settings/Shared/Stores/HUDSettingsStore.swift` — UserDefaults-backed store for brightness, keyboard, and volume HUD preferences.
- `DynamicNotch/Features/Settings/Shared/Stores/LockScreenFeatureSettingsStore.swift` — UserDefaults-backed store for lock-screen live activity preferences.
- `DynamicNotch/Features/Settings/Shared/Stores/MediaAndFilesSettingsStore.swift` — UserDefaults-backed store for now playing, downloads, and AirDrop preferences.
- `DynamicNotch/Features/Settings/Shared/Stores/SettingsStoreBase.swift` — Base observable store that centralizes publishing and reset behavior for settings.
- `DynamicNotch/Features/Settings/System/BatterySettingsView.swift` — Settings page for charger, low-power, and full-battery notification behavior.
- `DynamicNotch/Features/Settings/System/HUDSettingsView.swift` — Settings page for the custom brightness, keyboard, and volume HUD.
- `DynamicNotch/Features/Settings/System/LockScreenSettingsView.swift` — Settings page for lock-screen activity, widgets, and transition audio.

## Shared
- `DynamicNotch/Shared/Extensions/extension+CGFloat.swift` — Shared CGFloat convenience helpers used by layout and animation code.
- `DynamicNotch/Shared/Extensions/extension+Int.swift` — Shared Int convenience helpers for clamping, formatting, or numeric UI.
- `DynamicNotch/Shared/Extensions/extension+NSScreen.swift` — Shared NSScreen helpers for notch geometry, display selection, and positioning.
- `DynamicNotch/Shared/Extensions/extension+View.swift` — Shared SwiftUI View helpers used across features and settings.
- `DynamicNotch/Shared/Localization/L10n.swift` — Typed localization helpers that wrap the string catalog lookup flow.
- `DynamicNotch/Shared/PrivateAPI/DisplayServicesBridge.swift` — Bridges private DisplayServices symbols needed for screen and notch integration.
- `DynamicNotch/Shared/PrivateAPI/SkyLightOperator.swift` — Wrappers around private SkyLight window and space APIs used by the overlay.
- `DynamicNotch/Shared/UI/Components/AdaptiveCustomPicker.swift` — Picker component that adapts its presentation to the surrounding layout.
- `DynamicNotch/Shared/UI/Components/AnimateImage.swift` — Reusable image view with built-in transition and animation behavior.
- `DynamicNotch/Shared/UI/Components/AnimateLevelText.swift` — Animated numeric label used by HUD and level-based interfaces.
- `DynamicNotch/Shared/UI/Components/CustomPicker.swift` — Styled picker component shared across settings and feature UIs.
- `DynamicNotch/Shared/UI/Components/CustomToggle.swift` — Styled toggle implementation shared across the app.
- `DynamicNotch/Shared/UI/Components/MarqueeText.swift` — Auto-scrolling text component for labels that do not fit the available width.
- `DynamicNotch/Shared/UI/Components/PressedButton.swift` — Button style that adds pressed-state feedback for custom controls.
- `DynamicNotch/Shared/UI/Components/PrimaryButton.swift` — Primary accent button style shared across onboarding and settings.
- `DynamicNotch/Shared/UI/Components/TickedSlider.swift` — Slider component with tick marks and richer value presentation.
- `DynamicNotch/Shared/UI/Environment/NotchScaleEnvironmentKey.swift` — SwiftUI environment key for propagating the current notch scale factor.
- `DynamicNotch/Shared/UI/Modifiers/BlurFadeModifier.swift` — View modifier that animates blur and opacity together during transitions.
- `DynamicNotch/Shared/UI/Modifiers/NotchCustomScaleModifier.swift` — View modifier that applies notch-specific scaling behavior to content.
- `DynamicNotch/Shared/UI/Modifiers/NotchMouseSwipeModifier.swift` — View modifier that turns pointer gestures into notch swipe interactions.
- `DynamicNotch/Shared/UI/Modifiers/NotchSwipeDismissModifier.swift` — View modifier that enables swipe-to-dismiss behavior for notch content.
- `DynamicNotch/Shared/UI/Modifiers/ResizeAwareBlurModifier.swift` — View modifier that adjusts blur treatment while the notch is being resized.

## Resources
- `DynamicNotch/Resources/Localization/Localizable.xcstrings` — The app string catalog with localized copy for settings, notch content, and status text.
- `DynamicNotch/Resources/LottieImage/confirm.json` — Lottie animation asset used for confirmation-style moments in the notch UI.
- `DynamicNotch/Resources/LottieImage/star.json` — Lottie animation asset used for celebratory or highlight states.
- `DynamicNotch/Resources/LottieImage/welcome.json` — Lottie animation asset used during welcome and onboarding flows.
- `DynamicNotch/Resources/Sounds/DynamicNotch_lock.mp3` — Bundled sound effect played for supported lock-screen transitions.
- `DynamicNotch/Resources/Sounds/DynamicNotch_unlock.mp3` — Bundled sound effect played for supported unlock transitions.

## Tests
- `DynamicNotchTests/Application/SettingsSelectionHistoryTests.swift` — Tests the back/forward selection history used by the settings sidebar.
- `DynamicNotchTests/Features/Battery/PowerViewModelIntegrationTests.swift` — Integration tests for battery event mapping and PowerViewModel behavior.
- `DynamicNotchTests/Features/Download/DownloadViewModelIntegrationTests.swift` — Integration tests for download state mapping and event emission.
- `DynamicNotchTests/Features/Download/FolderFileDownloadMonitorIntegrationTests.swift` — Integration tests for file-based download monitoring and progress inference.
- `DynamicNotchTests/Features/Network/NetworkViewModelIntegrationTests.swift` — Integration tests for network state transitions and notch-facing output.
- `DynamicNotchTests/Features/Notch/LockScreenManagerIntegrationTests.swift` — Integration tests for lock-screen transition orchestration and restoration logic.
- `DynamicNotchTests/Features/Notch/NotchEventCoordinatorIntegrationTests.swift` — Integration tests for top-level event routing into the notch system.
- `DynamicNotchTests/Features/Notch/NotchViewModelIntegrationTests.swift` — Integration tests for notch presentation state, gestures, and restoration flows.
- `DynamicNotchTests/Features/NowPlaying/NowPlayingArtworkPaletteExtractorTests.swift` — Tests the artwork palette extraction logic used by adaptive now playing colors.
- `DynamicNotchTests/Features/NowPlaying/NowPlayingViewModelIntegrationTests.swift` — Integration tests for now playing session lifecycle and view-model state.
- `DynamicNotchTests/TestSupport/TestDoubles.swift` — Shared fakes, spies, and stub settings used by integration tests.
- `DynamicNotchTests/TestSupport/XCTestCase+Async.swift` — Async XCTest helpers for waiting on publishers and tasks in tests.
