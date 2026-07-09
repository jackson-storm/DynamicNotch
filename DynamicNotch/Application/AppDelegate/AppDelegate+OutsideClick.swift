import SwiftUI
import Combine

extension AppDelegate {
    func observeOutsideClickDismissal() {
        notchViewModel.$notchModel
            .map(\.isLiveActivityExpanded)
            .removeDuplicates()
            .sink { [weak self] isEnabled in
                guard let self else { return }

                if isEnabled {
                    startOutsideClickMonitoring()
                } else {
                    stopOutsideClickMonitoring()
                }
            }
            .store(in: &cancellables)
    }

    func startOutsideClickMonitoring() {
        if localClickMonitor == nil {
            localClickMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]
            ) { [weak self] event in
                let sourceWindow = event.window
                let screenLocation =
                    sourceWindow?.convertPoint(toScreen: event.locationInWindow) ??
                    NSEvent.mouseLocation

                Task { @MainActor [weak self] in
                    self?.handleLocalClick(from: sourceWindow, atScreenLocation: screenLocation)
                }

                return event
            }
        }

        globalClickMonitor.start { [weak self] _ in
            let screenLocation = NSEvent.mouseLocation
            Task { @MainActor [weak self] in
                self?.handleGlobalClick(atScreenLocation: screenLocation)
            }
        }
    }

    func stopOutsideClickMonitoring() {
        if let localClickMonitor {
            NSEvent.removeMonitor(localClickMonitor)
        }

        localClickMonitor = nil
        globalClickMonitor.stop()
    }

    @MainActor
    func handleLocalClick(from _: NSWindow?, atScreenLocation screenLocation: NSPoint) {
        guard shouldHandleOutsideClick else { return }
        guard let activeNotchScreenRect else {
            notchViewModel.handleOutsideClick()
            return
        }

        guard !activeNotchScreenRect.contains(screenLocation) else { return }
        notchViewModel.handleOutsideClick()
    }

    @MainActor
    func handleGlobalClick(atScreenLocation screenLocation: NSPoint) {
        guard shouldHandleOutsideClick else { return }
        guard let activeNotchScreenRect else {
            notchViewModel.handleOutsideClick()
            return
        }

        guard !activeNotchScreenRect.contains(screenLocation) else { return }
        notchViewModel.handleOutsideClick()
    }

    @MainActor
    var shouldHandleOutsideClick: Bool {
        notchViewModel.notchModel.isLiveActivityExpanded
    }

    @MainActor
    var activeNotchScreenRect: CGRect? {
        guard let window else { return nil }

        let notchSize = notchViewModel.notchModel.size
        guard notchSize.width > 0, notchSize.height > 0 else { return nil }

        let isVertical = settingsViewModel.homePage.homePageScrollAxis == .vertical
        
        var height = notchSize.height
        var width = notchSize.width
        let originX = floor(window.frame.midX - notchSize.width / 2)

        if shouldShowPageIndicator {
            if isVertical {
                width = notchSize.width + pageIndicatorSize.width + 16
                height = max(notchSize.height, notchSize.height / 2 + pageIndicatorSize.height / 2 + 12)
            } else {
                height += 6 + pageIndicatorSize.height + 35
            }
        }

        let origin = CGPoint(
            x: originX,
            y: window.frame.maxY - height
        )

        return CGRect(origin: origin, size: CGSize(width: width, height: height)).insetBy(dx: -12, dy: -8)
    }

    @MainActor
    var shouldShowPageIndicator: Bool {
        guard let homePageContent = notchViewModel.displayedContent as? HomePageNotchContent else { return false }
        guard settingsViewModel.homePage.isHomePagePageIndicatorEnabled else { return false }
        guard notchViewModel.isDisplayingExpandedLiveActivity else { return false }
        
        let active = homePageContent.settings.homePageOrder.filter { 
            !homePageContent.settings.homePageDisabled.contains($0) 
        }
        return active.count > 1
    }

    @MainActor
    var pageIndicatorSize: CGSize {
        guard let homePageContent = notchViewModel.displayedContent as? HomePageNotchContent else { return .zero }
        let active = homePageContent.settings.homePageOrder.filter { 
            !homePageContent.settings.homePageDisabled.contains($0) 
        }
        let size = settingsViewModel.homePage.homePageIndicatorSize
        let count = CGFloat(active.count)
        if count == 0 { return .zero }
        
        if settingsViewModel.homePage.homePageScrollAxis == .vertical {
            let width = size.dotSize + 2 * size.padding
            let height = count * (size.dotSize + size.spacing) + 2 * size.padding
            return CGSize(width: width, height: height)
        } else {
            let width = count * (size.dotSize + size.spacing) + 2 * size.padding
            let height = size.dotSize + 2 * size.padding
            return CGSize(width: width, height: height)
        }
    }
}
