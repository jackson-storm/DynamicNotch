# Contributing to DynamicNotch

First off, thank you for taking the time to contribute! 🎉

DynamicNotch is built with the goal of bringing a smooth, native, and highly polished iOS-style Dynamic Island experience to macOS. Contributions from the community help make the app more reliable, feature-rich, and accessible to everyone.

Please read through these guidelines to understand how you can help this project grow.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
  - [Reporting Bugs](#reporting-bugs)
  - [Suggesting Enhancements](#suggesting-enhancements)
  - [Localizations and Translations](#localizations-and-translations)
  - [Code Contributions](#code-contributions)
- [Development Setup](#development-setup)
- [Project Architecture](#project-architecture)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Pull Request Checklist](#pull-request-checklist)

---

## Code of Conduct

By participating in this project, you agree to maintain a respectful, welcoming, and collaborative environment. Please be constructive in your feedback and respectful of other contributors.

---

## How Can I Contribute?

### Reporting Bugs

If you find a bug, please check the [Issues](https://github.com/jackson-storm/DynamicNotch/issues) list first to see if it has already been reported. If not, feel free to open a new issue.

When reporting a bug, please include:
1. **macOS Version** (e.g., macOS 14.6) and **Mac model** (e.g., MacBook Pro M3 Max).
2. **App Version** (e.g., latest GitHub release or a custom build).
3. **Clear steps to reproduce** the issue.
4. **Expected behavior** vs. **actual behavior**.
5. **Console logs, screenshots, or screen recordings** showing the bug.

*Note: For security vulnerabilities, please refer to our [Security Policy](SECURITY.md) and email us directly rather than opening a public issue.*

### Suggesting Enhancements

We are always looking for ways to improve the animations, layouts, and feature support of DynamicNotch! If you have an idea:
- Explain the behavior you want to see.
- Provide mockup designs or link to reference materials (like iOS Dynamic Island behaviors).
- Open an issue with the tag `enhancement`.

### Localizations and Translations

DynamicNotch supports multiple languages (English, Russian, Spanish, Simplified Chinese, etc.). If you want to:
- Add translations for an existing language.
- Support a new language.

You can modify or add localizations inside the Xcode project using Swift String Catalogs or target-specific localizations within `DynamicNotch/Resources/Localizable.xcstrings` (if using String Catalogs) or the corresponding translation files.

### Code Contributions

If you'd like to fix a bug or add a feature:
1. Search the open issues or open one to discuss your proposed change.
2. Fork the repository and create a descriptive branch: `git checkout -b feature/my-new-feature` or `bugfix/fix-some-bug`.
3. Keep your changes focused. Avoid submitting large PRs that mix unrelated fixes.

---

## Development Setup

To build and run DynamicNotch locally, you will need:
- A Mac running **macOS 14.6** or later.
- **Xcode 15.0** or later.
- Basic knowledge of Swift, SwiftUI, and AppKit.

### Steps to Run:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/jackson-storm/DynamicNotch.git
   cd DynamicNotch
   ```
2. **Open the project in Xcode:**
   ```bash
   open DynamicNotch.xcodeproj
   ```
3. Xcode will automatically resolve the Swift Package Manager (SPM) dependencies (e.g., Lottie).
4. Select the `DynamicNotch` scheme and your target (My Mac).
5. Click **Run** (`Cmd + R`) to compile and launch the app.

---

## Project Architecture

DynamicNotch uses a modular, features-based architecture. This separation makes it easy to add, modify, or disable specific notch modules.

```
DynamicNotch/
├── Application/        # App lifecycle, AppDelegate, and main entry points
├── Core/               # Shared core infrastructure (window controllers, managers, notification listeners)
├── Features/           # Self-contained modules for specific notch notifications & HUDs
│   ├── Battery/        # Battery charging notifications and HUD indicators
│   ├── Bluetooth/      # Bluetooth accessory connect/disconnect indicators
│   ├── NowPlaying/     # Now Playing media player controls, audio visualizer, lyrics
│   ├── Settings/       # User preferences window, customize sizes, styles
│   └── ...             # Other modules (Timer, Wifi, Focus, VPN, etc.)
├── Shared/             # Global extensions, UI utilities, standard models
└── Resources/          # Assets, Lottie files, localizations, and application icons
```

### Key Concepts:
- **ViewModels**: Manage the logic, state, and event streams using the Combine framework.
- **Views**: Built with SwiftUI for modern, declarative layouts.
- **AppKit Wrappers**: Used to manage the notch overlay window itself, tracking fullscreen workspace shifts, mouse trackpad hover events, and system coordinate conversions.

---

## Coding Guidelines

To keep the codebase maintainable and clean, please adhere to these rules:

1. **Follow Swift API Design Guidelines**: Write clean, self-documenting Swift code. Use meaningful names, swift-native types, and avoid unnecessary force unwraps (`!`).
2. **Architecture Conformity**:
   - If writing a new feature, place it in `DynamicNotch/Features/[FeatureName]`.
   - Keep Views layout-focused and delegate logic to their ViewModels.
3. **Animations**: DynamicNotch prioritizes smooth, premium animations that mimic Apple's native physics-based transitions. Use spring animations (`.spring()` or custom springs) and test behavior transitions extensively.
4. **Formatting**:
   - Use 4 spaces for indentation (Xcode default).
   - Clean up unused imports, dead code, and commented-out snippets.
5. **No Placeholders**: Avoid committing hardcoded dummy assets or debug overrides. Use runtime configuration or settings checks.

---

## Testing

DynamicNotch has a test suite located in the `DynamicNotchTests` folder.

- **Running Tests:** Press `Cmd + U` in Xcode to run all unit tests.
- **Adding Tests:** When adding new features or resolving bugs, please add corresponding tests in `DynamicNotchTests/Features/[FeatureName]` to prevent future regressions.

---

## Pull Request Checklist

Before submitting your pull request, please make sure:
- [ ] The project compiles successfully without errors or warnings.
- [ ] All unit and UI tests pass (`Cmd + U`).
- [ ] Your code follows the project's formatting and style guidelines.
- [ ] Your branch is rebased onto the latest `main` branch.
- [ ] You have provided a clear description of the problem your PR solves and how it was implemented.
- [ ] You have included screenshots or screen recordings for UI changes.

Thank you for contributing to DynamicNotch! 🚀
