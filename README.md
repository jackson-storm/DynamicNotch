<p align="center">
  <img src="DynamicNotch/Resources/Assets.xcassets/AppIcon.appiconset/logo256.png" alt="DynamicNotch logo" width="96" />
</p>

<h1 align="center">DynamicNotch</h1>

<p align="center">
  <strong>Turn the MacBook notch into a living native surface.</strong>
</p>

<p align="center">
  DynamicNotch is a native macOS app for notched MacBooks that turns the notch into a live system surface for media,
  downloads, AirDrop, timers, connectivity events, lock-screen transitions, and custom hardware HUDs.
</p>

<p align="center">
  <a href="https://t.me/Dynamic_Notch">
    <img src="https://img.shields.io/badge/Telegram-Join%20Channel-26A5E4?style=for-the-badge&logo=telegram&logoColor=white" alt="Join the Telegram channel" />
  </a>
  <a href="https://dynamicnotch.evgeniy-petrukovich.workers.dev/download">
    <img src="https://img.shields.io/badge/Website-Open%20Site-111111?style=for-the-badge&logo=safari&logoColor=white" alt="Open the DynamicNotch website" />
  </a>
  <a href="mailto:evgeniy.petrukovich@icloud.com?subject=A%20question%20about%20Dynamic%20Notch">
    <img src="https://img.shields.io/badge/Email-Contact%20Me-0A84FF?style=for-the-badge&logo=icloud&logoColor=white" alt="Send an email about DynamicNotch" />
  </a>
</p>

<p align="center">
  <a href="https://github.com/jackson-storm/DynamicNotch/releases">
    <img src="https://img.shields.io/github/downloads/jackson-storm/DynamicNotch/total?label=downloads" alt="GitHub downloads" />
  </a>
  <a href="https://github.com/jackson-storm/DynamicNotch/releases/latest">
    <img src="https://img.shields.io/github/v/release/jackson-storm/DynamicNotch?display_name=release&sort=semver" alt="Latest release" />
  </a>
  <img src="https://img.shields.io/badge/macOS-14.6%2B-111111?logo=apple" alt="macOS 14.6 or later" />
  <img src="https://img.shields.io/badge/UI-SwiftUI%20%2B%20AppKit-0A84FF" alt="SwiftUI and AppKit" />
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

## 🚀 Highlights

- 🎵 Live activities for Now Playing, Downloads, AirDrop, Timer, Focus, Personal Hotspot, and Lock Screen media/live activity surfaces
- ⚡ Temporary alerts for charging, low battery, full battery, Bluetooth, Wi-Fi, VPN, Focus-off, and notch resize feedback
- 🎚️ Custom hardware HUD replacements for brightness, keyboard brightness, and volume
- 🖱️ Native interactions including tap to expand, mouse drag gestures, trackpad swipes, swipe-to-dismiss, and swipe-to-restore
- 🎨 Personalization for notch width and height, background style, stroke options, animation presets, fullscreen behavior, display placement, and app language
- 🔒 Lock Screen controls for sounds, media panel behavior, widget appearance, tint, and background brightness
- ⚙️ A dedicated settings experience grouped into Application, Media & Files, Connectivity, and System sections

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
- A MacBook with a hardware notch for the intended experience
- Feature-specific permissions as needed:
  - Accessibility for custom HUD interception and some system-level interactions
  - Bluetooth access for accessory status updates
  - Media/Now Playing access where macOS requires it

## 🛠️ Build From Source

```bash
git clone https://github.com/jackson-storm/DynamicNotch.git
cd DynamicNotch
open DynamicNotch.xcodeproj
```

Then run the `DynamicNotch` scheme from Xcode. Swift Package Manager dependencies are resolved by the project.

## 🧪 Run Tests

```bash
xcodebuild -project DynamicNotch.xcodeproj -scheme DynamicNotch -destination 'platform=macOS' test
```

Automated coverage in this repository focuses on notch queue behavior, restore flows, battery and network events,
download monitoring, Now Playing lifecycle, timer handling, and lock-screen-related transitions.

## 🗂️ Repository Layout

```text
DynamicNotch/
├── Application/        # App entry point, app delegate, window setup, and settings shell
├── Core/               # Shared models, protocols, services, and infrastructure
├── Features/
│   ├── AirDrop/
│   ├── Battery/
│   ├── Bluetooth/
│   ├── Download/
│   ├── Focus/
│   ├── HUD/
│   ├── LockScreen/
│   ├── Network/
│   ├── Notch/
│   ├── NowPlaying/
│   ├── Onboarding/
│   ├── Settings/
│   └── Timer/
├── Resources/          # Assets, localization, bundled media
└── Shared/             # Shared UI, helpers, and extensions

DynamicNotchTests/
├── Features/
└── TestSupport/
```

## 🏗️ Architecture at a Glance

- `AppContainer` composes services, monitors, feature view models, coordinators, and window managers.
- `AppDelegate` manages app lifecycle, floating overlay window setup, workspace observers, and lock-screen handoff.
- `NotchEngine` owns the queue-driven notch presentation state machine for live activities, temporary alerts, transitions, and restore flows.
- `NotchViewModel` is the SwiftUI-facing layer for geometry, gestures, interactive resize, and engine-backed presentation state.
- `NotchEventCoordinator` routes system events while feature-specific handlers translate them into notch content.
- `SettingsViewModel` acts as a facade over dedicated settings stores for application, media/files, connectivity, battery, HUD, and lock-screen behavior.
- Feature view models provide domain state for battery, Bluetooth, downloads, network, now playing, timer, AirDrop, and lock screen.

## 🧰 Tech Stack

- SwiftUI for notch content and settings UI
- AppKit for windows, input handling, and macOS integration
- Combine for feature and settings streams
- [Defaults](https://github.com/sindresorhus/Defaults) for preferences
- [Lottie](https://github.com/airbnb/lottie-ios) for animation assets

## 🌍 Localization

The project currently includes localized app content for:

- System language fallback
- English
- Russian
- Spanish
- Simplified Chinese

## 📈 Project Status

DynamicNotch already includes a working native notch window, live activities, temporary alerts, AirDrop handoff,
custom HUD flows, a dedicated settings experience, and lock-screen-specific behavior.

Some lock-screen-related flows depend on private or system-level behavior and can vary across macOS versions and environments.

## 🙏 Acknowledgements

DynamicNotch benefited from ideas and selected implementation details inspired by other open-source work on GitHub.
Thank you to the maintainers and contributors behind these projects:

- [Ebullioscopic/Atoll](https://github.com/Ebullioscopic/Atoll)
- [MrKai77/DynamicNotchKit](https://github.com/MrKai77/DynamicNotchKit)

## 📄 License

DynamicNotch is released under the GNU General Public License v3.0. See [LICENSE](LICENSE) for details.
