<p align="center">
  <img src="DynamicNotch/Resources/Assets.xcassets/AppIcon.appiconset/logo256.png" alt="DynamicNotch logo" width="96" />
</p>

<h1 align="center">DynamicNotch</h1>

<p align="center">
  <strong>Turn the MacBook notch into a living native surface.</strong>
</p>

<p align="center">
  DynamicNotch is a native macOS app for notched MacBooks that turns the notch into a live system surface for media,
  downloads, AirDrop, timers, screen recording, connectivity events, lock-screen transitions, and custom hardware HUDs.
</p>

<p align="center">
  <a href="https://t.me/Dynamic_Notch">
    <img src="https://img.shields.io/badge/Telegram-Join%20Channel-26A5E4?style=for-the-badge&logo=telegram&logoColor=white&labelColor=26A5E4" alt="Join the Telegram channel" />
  </a>
  <a href="mailto:evgeniy.petrukovich@icloud.com?subject=A%20question%20about%20Dynamic%20Notch">
    <img src="https://img.shields.io/badge/Email-Contact%20Me-0A84FF?style=for-the-badge&logo=icloud&logoColor=white&labelColor=0A84FF" alt="Send an email about DynamicNotch" />
  </a>
  <a href="https://t.me/id10101101">
    <img src="https://img.shields.io/badge/Telegram-Contact%20Me-229ED9?style=for-the-badge&logo=telegram&logoColor=white&labelColor=229ED9" alt="Contact me on Telegram" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/jackson-storm/DynamicNotch/releases">
    <img src="https://img.shields.io/github/downloads/jackson-storm/DynamicNotch/total?label=downloads" alt="GitHub downloads" />
  </a>
  <img src="https://img.shields.io/badge/macOS-14.6%2B-111111?logo=apple" alt="macOS 14.6 or later" />
  <a href="https://github.com/jackson-storm/DynamicNotch/releases/latest">
    <img src="https://img.shields.io/github/v/release/jackson-storm/DynamicNotch?label=&display_name=tag&sort=semver" alt="Latest release" />
  </a>
  <img src="https://img.shields.io/badge/Swift-5-F05138?logo=swift&logoColor=white" alt="Swift 5" />
  <a href="LICENSE">
    <img src="https://img.shields.io/github/license/jackson-storm/DynamicNotch" alt="License" />
  </a>
</p>

<p>
  <img src="assets/readme/Player.png" alt="DynamicNotch preview" width="100%" />
</p>

## ✨ Why DynamicNotch

DynamicNotch treats the MacBook notch like a compact native surface instead of a static cutout.
It stays close to the hardware shape until something important happens, then expands with queue-driven
presentation, gesture support, and system-aware feature routing.

The app is built with SwiftUI and AppKit, so the notch window, settings UI, and event handling feel
like part of macOS rather than a web-style overlay.

The difference between this project and others is that it is built on its own engine, and not taken from other ready-made repositories. It completely copies the logic, animations, and behavior of a real Dynamic Island on an iPhone, unlike other projects. 

The main goal is to make the project as native as possible, both in terms of design and interaction.

## 🚀 Highlights

- **Live Activities**: Now Playing (media control, album artwork, audio visualizer, customizable progress bar tint style), Downloads progress, AirDrop, Timer, Screen Recording indicator, Focus mode, Personal Hotspot, and Lock Screen media/live activity surfaces.
- **Dynamic Island (Floating Capsule)**: Automatic support for devices without a physical hardware notch (e.g. non-notched MacBooks, iMac, Mac mini, or external monitors). Transitions to a floating capsule shape (`DynamicIslandShape`) when `topInset == 0`, utilizing dynamic, smooth corner radius transitions.
- **Temporary Alerts**: Interactive HUD status for battery charging, low/full battery, Bluetooth connections, Wi-Fi, VPN, Focus-off toggling, and notch size modification settings feedback.
- **Native HUD Replacements**: Beautiful, hardware-inspired HUD overlays for System Volume, Screen Brightness, and Keyboard Backlight.
- **Chained Lyrics Provider**: A dual-provider API engine (`CompositeLyricsProvider`) combining synchronized LRCLIB karaoke lyrics and static Lyrics.ovh database query fallback.
- **Gestures & Swipe Controls**: Native interactive gestures including mouse drag, trackpad swipes, vertical swipe-to-dismiss/restore with adaptive corner radii and swipe-aware blur, and horizontal trackpad/mouse scroll-to-dismiss.
- **Deep Customization**: Personalization options for base notch width/height, stroke options, background styling, animation presets, custom screen/display selection, and fullscreen spaces handling.
- **Refined Animations**: Multi-preset transitions system with separate, dedicated transition tuning parameter `closeLiveActivityCompactContentTransition` to control the exact speed of content insertion when returning to compact mode.

## 🎬 Preview

<table>
  <tr>
    <td>
      <video src="https://github.com/user-attachments/assets/88040eb4-a41c-4699-98b7-3242570f4918" controls muted playsinline width="100%"></video>
    </td>
    <td>
      <video src="https://github.com/user-attachments/assets/7ec1661d-ff3e-4dc6-9e76-92b00576094f" controls muted playsinline width="100%"></video>
    </td>
  </tr>
</table>

> The demos show how the notch behaves on light and dark backgrounds. The outline can be disabled in Settings.

## 📦 Installation

1. Download the latest DMG from the [Releases](https://github.com/jackson-storm/DynamicNotch/releases) page.
2. Drag `DynamicNotch` into `Applications`.
3. Launch the app.
4. Grant the permissions needed for the features you want to use.
5. If macOS blocks the first launch, allow it from `System Settings > Privacy & Security`.

## ✅ Requirements

- macOS 14.6 or later
- Works on both notched MacBooks and non-notched displays (automatically rendering as a floating Dynamic Island capsule)
- Feature-specific permissions as needed:
  - Accessibility for custom HUD interception and some system-level interactions
  - Bluetooth access for accessory status updates
  - Screen Recording access for audio-reactive Now Playing visualization where macOS requires it
  - Media/Now Playing access where macOS requires it

## 🛠️ Build From Source

```bash
git clone https://github.com/jackson-storm/DynamicNotch.git
cd DynamicNotch
open DynamicNotch.xcodeproj
```

Then run the `DynamicNotch` scheme from Xcode. Swift Package Manager dependencies are resolved by the project.

## 🗂️ Repository Layout

```text
DynamicNotch/
├── Application/        # App entry point, app delegate, window setup, and settings shell
├── Core/               # Shared models, protocols, services, and infrastructure
├── Features/
│   ├── Battery/
│   ├── Bluetooth/
│   ├── Calendar/
│   ├── Camera/
│   ├── Download/
│   ├── DragAndDrop/
│   ├── Focus/
│   ├── HomePage/
│   ├── HUD/
│   ├── LockScreen/
│   ├── Notch/
│   ├── NowPlaying/
│   ├── Onboarding/
│   ├── ScreenRecording/
│   ├── Settings/
│   ├── Timer/
│   ├── VPN/
│   └── WiFi/
├── Resources/          # Assets, localization, bundled media
└── Shared/             # Shared UI, helpers, and extensions

DynamicNotchTests/
├── Features/
├── Shared/
└── TestSupport/

DynamicNotchUITest/
└── DynamicNotchUITest.swift
```

## 🏗️ Architecture at a Glance

- `AppContainer` composes services, monitors, feature view models, coordinators, and window managers.
- `AppDelegate` manages app lifecycle, floating overlay window setup, workspace observers, and lock-screen handoff.
- `NotchEngine` owns the queue-driven notch presentation state machine for live activities, temporary alerts, transitions, and restore flows.
- `NotchViewModel` is the SwiftUI-facing layer for geometry, gestures, interactive resize, and engine-backed presentation state.
- `NotchEventCoordinator` routes system events while feature-specific handlers translate them into notch content.
- `SettingsViewModel` acts as a facade over dedicated settings stores for application, media/files, connectivity, battery, HUD, and lock-screen behavior.
- Feature view models provide domain state for battery, Bluetooth, calendar, camera, downloads, WiFi, VPN, now playing, screen recording, timer, AirDrop, and lock screen.
- Fullscreen hiding keeps the overlay window alive and hides notch activities until the user leaves fullscreen, so active features can restore cleanly.

## 🧰 Tech Stack

- SwiftUI for notch content and settings UI
- AppKit for windows, input handling, and macOS integration
- Combine for feature and settings streams
- [Lottie](https://github.com/airbnb/lottie-ios) for animation assets

## 🌍 Localization

The project currently includes localized app content for:

- System language fallback
- English
- Russian
- Spanish
- Simplified Chinese

## 🤝 Acknowledgements

Special thanks to the following open-source projects and services that make DynamicNotch possible:

- [Lottie for iOS](https://github.com/airbnb/lottie-ios) — for rendering premium, smooth vector animations.
- [LRCLIB](https://lrclib.net) — for providing the main engine for synchronized lyrics search.
- [Lyrics.ovh](https://lyrics.ovh) — for serving as a fallback database for static song lyrics.
- [mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) — for MediaRemote API integration.

## 📄 License

DynamicNotch is released under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
